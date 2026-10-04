-- Run once in a new Supabase project's SQL editor.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  phone text not null default '',
  barangay text not null default '',
  role text not null default 'resident' check (role in ('resident','driver','staff'))
);
create function public.create_resident_profile() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id,name,phone,barangay)
  values(new.id, coalesce(new.raw_user_meta_data->>'name',''),
    coalesce(new.raw_user_meta_data->>'phone',''), coalesce(new.raw_user_meta_data->>'barangay',''));
  return new;
end; $$;
create trigger on_resident_signup after insert on auth.users
for each row execute function public.create_resident_profile();
create function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from profiles where id=auth.uid() and role='staff');
$$;
create table public.trucks (
  id text primary key,
  driver_id uuid unique references public.profiles(id),
  plate_number text not null default '',
  route_name text not null default '',
  latitude double precision check(latitude between -90 and 90),
  longitude double precision check(longitude between -180 and 180),
  speed_kmh double precision not null default 0 check(speed_kmh >= 0),
  updated_at timestamptz,
  active boolean not null default false
);
create table public.reports (
  id text primary key,
  resident_id uuid not null references public.profiles(id),
  concern_type text not null,
  description text not null check(length(description) between 1 and 300),
  photo_paths text[] not null default '{}' check(cardinality(photo_paths) <= 3),
  latitude double precision not null check(latitude between -90 and 90),
  longitude double precision not null check(longitude between -180 and 180),
  location_address text not null,
  created_at timestamptz not null default now(),
  status text not null default 'Pending' check(status in ('Pending','Verified','Scheduled','Collected')),
  truck_id text references public.trucks(id),
  check(status <> 'Scheduled' or truck_id is not null)
);
create table public.schedules (
  id bigint generated always as identity primary key,
  barangay text not null,
  waste_type text not null,
  pickup_at timestamptz not null,
  truck_id text references public.trucks(id),
  note text not null default ''
);
alter table public.profiles enable row level security;
alter table public.trucks enable row level security;
alter table public.reports enable row level security;
alter table public.schedules enable row level security;
revoke all on public.profiles,public.trucks,public.reports,public.schedules from anon;
grant select,insert,update on public.reports to authenticated;
grant select,insert,update,delete on public.trucks,public.schedules to authenticated;
grant usage,select on sequence public.schedules_id_seq to authenticated;
grant select on public.profiles to authenticated;
grant update(name,phone,barangay) on public.profiles to authenticated;
revoke update on public.profiles from authenticated;
grant update(name,phone,barangay) on public.profiles to authenticated;
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid() or public.is_staff());
create policy profile_edit on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy truck_read on public.trucks for select to authenticated using(true);
create policy truck_staff_write on public.trucks for all to authenticated using(public.is_staff()) with check(public.is_staff());
create policy report_read on public.reports for select to authenticated using(
  resident_id=auth.uid() or public.is_staff() or exists(select 1 from public.trucks t where t.id=truck_id and t.driver_id=auth.uid())
);
create policy report_create on public.reports for insert to authenticated with check(
  resident_id=auth.uid() and status='Pending' and truck_id is null
  and exists(select 1 from public.profiles where id=auth.uid() and role='resident')
  and not exists(select 1 from unnest(photo_paths) p where p not like auth.uid()::text || '/' || id || '/%')
);
create policy report_review on public.reports for update to authenticated using(public.is_staff()) with check(public.is_staff());
create policy schedule_read on public.schedules for select to authenticated using(true);
create policy schedule_manage on public.schedules for all to authenticated using(public.is_staff()) with check(public.is_staff());
create index reports_resident_created on public.reports(resident_id,created_at desc);
create index reports_truck_status on public.reports(truck_id,status);
create index schedules_pickup on public.schedules(pickup_at);

create function public.publish_position(lat double precision,lng double precision,speed double precision,is_active boolean)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from profiles where id=auth.uid() and role='driver') then
    raise exception 'Driver access required';
  end if;
  if lat is null or lng is null or speed is null or is_active is null
    or lat not between -90 and 90 or lng not between -180 and 180 or speed < 0 then
    raise exception 'Invalid position';
  end if;
  update trucks set latitude=lat,longitude=lng,speed_kmh=speed,active=is_active,updated_at=now() where driver_id=auth.uid();
  if not found then raise exception 'No truck assigned'; end if;
end; $$;
create function public.complete_report(report_id text) returns void
language plpgsql security definer set search_path=public as $$
begin
  update reports r set status='Collected' where r.id=report_id and r.status='Scheduled'
    and exists(select 1 from trucks t join profiles p on p.id=t.driver_id
      where t.id=r.truck_id and t.driver_id=auth.uid() and p.role='driver');
  if not found then raise exception 'Scheduled report not assigned to this driver'; end if;
end; $$;
revoke all on function public.create_resident_profile() from public;
revoke all on function public.is_staff(), public.publish_position(double precision,double precision,double precision,boolean), public.complete_report(text) from public;
grant execute on function public.is_staff(), public.publish_position(double precision,double precision,double precision,boolean), public.complete_report(text) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('report-photos','report-photos',false,5242880,array['image/jpeg','image/png']);
create policy photo_create on storage.objects for insert to authenticated with check(
  bucket_id='report-photos' and (storage.foldername(name))[1]=auth.uid()::text
  and exists(select 1 from profiles where id=auth.uid() and role='resident')
);
create policy photo_read on storage.objects for select to authenticated using(
  bucket_id='report-photos' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_staff()
    or exists(select 1 from reports r join trucks t on t.id=r.truck_id
      where t.driver_id=auth.uid() and name=any(r.photo_paths)))
);
create policy photo_remove on storage.objects for delete to authenticated using(
  bucket_id='report-photos' and (storage.foldername(name))[1]=auth.uid()::text
  and not exists(select 1 from reports r where name=any(r.photo_paths))
);
