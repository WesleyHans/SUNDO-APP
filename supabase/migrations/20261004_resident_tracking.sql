-- Existing projects: apply this before installing the new resident build.
begin;
alter table public.profiles add column if not exists zone text not null default '';
alter table public.profiles add column if not exists street text not null default '';
grant update(name,phone,barangay,zone,street) on public.profiles to authenticated;
create or replace function public.create_resident_profile() returns trigger
language plpgsql security definer set search_path=public as $$ begin
 insert into profiles(id,name,phone,barangay,zone,street) values(new.id,
 coalesce(new.raw_user_meta_data->>'name',''),coalesce(new.raw_user_meta_data->>'phone',''),
 coalesce(new.raw_user_meta_data->>'barangay',''),coalesce(new.raw_user_meta_data->>'zone',''),coalesce(new.raw_user_meta_data->>'street',''));
 return new; end; $$;
alter table public.trucks add column if not exists heading double precision check(heading between 0 and 360);
alter table public.trucks add column if not exists eta_minutes integer check(eta_minutes >= 0);
alter table public.trucks add column if not exists next_stop text;
alter table public.trucks add column if not exists current_area text;
alter table public.trucks add column if not exists progress double precision check(progress between 0 and 1);
alter table public.trucks add column if not exists status text check(status in ('Not Started','On Route','Approaching','Nearby','Completed'));
alter table public.trucks add column if not exists active_route jsonb;
drop function if exists public.publish_position(double precision,double precision,double precision,boolean);
create or replace function public.publish_position(lat double precision,lng double precision,speed double precision,is_active boolean,heading_value double precision default null)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from profiles where id=auth.uid() and role='driver') then
    raise exception 'Driver access required';
  end if;
  if lat is null or lng is null or speed is null or is_active is null
    or lat not between -90 and 90 or lng not between -180 and 180 or speed < 0 then
    raise exception 'Invalid position';
  end if;
  update trucks set latitude=lat,longitude=lng,speed_kmh=speed,active=is_active,updated_at=now(),
    heading=case when heading_value between 0 and 360 then heading_value else null end where driver_id=auth.uid();
  if not found then raise exception 'No truck assigned'; end if;
end; $$;

revoke all on function public.publish_position(double precision,double precision,double precision,boolean,double precision) from public;
grant execute on function public.publish_position(double precision,double precision,double precision,boolean,double precision) to authenticated;

-- Tokens are private per account. Only trusted server code may send FCM messages.
create table if not exists public.device_push_tokens (
  resident_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique,
  updated_at timestamptz not null default now(),
  primary key(resident_id,token)
);
create unique index if not exists device_push_tokens_token_unique on public.device_push_tokens(token);
alter table public.device_push_tokens enable row level security;
revoke all on public.device_push_tokens from anon;
grant select,insert,update,delete on public.device_push_tokens to authenticated;
drop policy if exists push_token_owner on public.device_push_tokens;
create policy push_token_owner on public.device_push_tokens for all to authenticated
  using(resident_id=auth.uid()) with check(resident_id=auth.uid());
-- Publish the public fleet table only. Resident GPS remains local to each device.
do $$ begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime')
 and not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='trucks') then
  alter publication supabase_realtime add table public.trucks;
 end if;
end $$;

commit;
