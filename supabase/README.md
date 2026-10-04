# Activate the SUNDO backend

## 1. Create the project

Create a project in the Supabase dashboard. In SQL Editor, run `schema.sql` once on a new project. It creates resident profiles, reports, truck positions, schedules, a private photo bucket, and access policies.

Reference: https://supabase.com/docs/guides/getting-started/quickstarts/flutter

In Authentication settings, keep email confirmation enabled, set the minimum password length to 8, and configure your email delivery provider before public use. Email/password login is implemented; Google and Facebook login are not enabled.

## 2. Configure and build the app

Copy the project URL and **public anon key** or public publishable key from the project's API settings. Never place a service-role key or database password in the mobile app.

From `flutter_sundo`, run:

```powershell
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR-PUBLIC-KEY
flutter build apk --release --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR-PUBLIC-KEY
```

Without these definitions the APK runs a clearly marked local demo. Tap **Get Started** for the demo or **Log In / Create Account** for the connected service. New accounts must confirm their email before logging in. Everyone registers as a resident; clients cannot grant themselves driver or staff access.

For GitHub builds, add repository **Actions variables** named `SUPABASE_URL` and `SUPABASE_ANON_KEY` with the same public values. The Android workflow reads them when compiling the APK. With empty variables, it produces a demo APK.

## 3. Create city staff and driver access

Have the staff member and driver register and confirm their email. In Authentication → Users, copy their user IDs. A trusted project administrator runs these queries in SQL Editor, replacing the example UUIDs:

```sql
update public.profiles set role='staff' where id='STAFF-USER-UUID';
update public.profiles set role='driver' where id='DRIVER-USER-UUID';
insert into public.trucks(id,driver_id,plate_number,route_name)
values('TRK-01','DRIVER-USER-UUID','ACTUAL-PLATE','Barangay 1 collection');
```

The role is loaded after login. City staff see all reports and can verify, assign trucks, mark collection complete, and create collection schedules. Drivers see reports assigned to their truck and can mark scheduled reports collected. Residents see their own reports and the fleet/schedules.

## 4. Verify the complete workflow

1. On a resident phone, register, confirm email, log in, allow GPS and camera, and submit a report with photos. Check that it appears on the staff account.
2. As staff, verify the report, then assign a truck. Check the report status on the resident phone.
3. As driver, start sharing location. Keep the app open during collection. On the resident map, check the actual truck marker. Data refreshes every 15 seconds; positions older than two minutes display as offline.
4. As driver, mark the assigned report collected. Check the resident and staff status.
5. Create a future schedule as staff and confirm it appears on other accounts.
6. Confirm a second resident cannot read the first resident's reports or photos. Confirm a driver cannot complete a report assigned to another truck. These rules are enforced by the database policies/functions.

The SQL and remote workflows must be tested against your actual project; they cannot be verified without a configured database. No project has been created or deployed by this checkout.

## Release considerations

- Set up an Android release signing key before distributing a production version. The current APK uses the existing development signing configuration.
- Validate permissions and background/foreground behavior on physical phones. Driver tracking is intended for foreground use; a terminated app stops publishing. Old truck positions expire on the resident map.
- Push notifications and background tracking are not implemented. Report status and schedules refresh while the app is open.
- Online report submission requires a connection. Local demo reports are separate from cloud reports and are not automatically uploaded.
- Account recovery currently requires the project administrator to issue a reset through the authentication dashboard.
- Review the app's terms/privacy content and official schedule data with the city before public launch.
