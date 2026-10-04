# Activate SUNDO's shared services

The default APK is a clearly marked local demo. This repository contains Supabase adapters and SQL, but no Supabase project or keys have been supplied and no remote policies have been verified. Vercel hosts the installer; it does not create the mobile database.

## 1. Prepare Supabase

Create a Supabase project and open SQL Editor. Choose the script for your database:

- **New project:** run [schema.sql](schema.sql) once. It creates profiles, private concern reports, trucks, schedules, a private `report-photos` bucket, device tokens and access policies.
- **Existing project with the previous SUNDO schema:** back up the database and apply [20261004_resident_tracking.sql](migrations/20261004_resident_tracking.sql). It adds address fields and tracking metadata, updates the position RPC and adds private device-token storage. Do not rerun the new-project schema over existing tables.

Keep email confirmation enabled, require at least eight password characters and configure email delivery before public use. City sign-in currently uses email/password; phone, Google and Facebook auth are not enabled. Password recovery requires administrator assistance through the authentication dashboard until an app recovery flow is added.

The schema enables Realtime publication for `public.trucks` when the Supabase publication exists. Confirm that table is enabled in your project's Realtime publication. Resident GPS is not a published fleet coordinate; GPS attached to a submitted concern is protected by report access policies.

## 2. Configure the Flutter build

Copy the project URL and **public publishable or anon key** from project API settings. The flag remains named `SUPABASE_ANON_KEY` and accepts the public key. Never put a service-role secret, database password, FCM server credential or signing private key in the app.

From `flutter_sundo`:

```powershell
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR-PUBLIC-KEY
flutter build apk --release --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR-PUBLIC-KEY
```

Get Started opens sample operations even in a configured build. Log In/Create Account uses the connected service when Supabase is configured. New accounts confirm email before login when confirmation is enabled. Empty backend flags produce the local demo, where accounts are stored on the device and are unrelated to city accounts.

For the Android GitHub workflow, add repository **Actions variables** `SUPABASE_URL` and `SUPABASE_ANON_KEY` with these public values. The workflow reads them at compile time; Vercel environment variables do not configure a previously built APK. Actions was blocked by the account's billing lock during this work, so a local build/manual GitHub Release is required until the account can run workflows again.

## 3. Provision city accounts and trucks

Have staff and drivers register and confirm email. Copy their user UUIDs from Authentication → Users. A trusted project administrator runs the following in SQL Editor, replacing every placeholder:

```sql
update public.profiles set role = 'staff' where id = 'STAFF-USER-UUID';
update public.profiles set role = 'driver' where id = 'DRIVER-USER-UUID';
insert into public.trucks(id, driver_id, plate_number, route_name)
values ('TRK-01', 'DRIVER-USER-UUID', 'ACTUAL-PLATE', 'ACTUAL-COLLECTION-ROUTE');
```

Each driver is assigned one truck. App signups always become residents; client profile updates cannot change the role. Log in again after changing a role to load the appropriate interface.

Staff can review/verify concerns, assign trucks, mark collections complete and create future schedules. Drivers share GPS while the app remains open and complete their assigned scheduled concerns. Residents can read their own reports, public fleet data and collection schedules. Private report photos use short-lived signed URLs for authorized viewers.

Enter the city's real collection schedules through the staff screen. Barangay labels should match resident collection areas so Home can select the appropriate next pickup.

## 4. Supply actual operational metadata

Driver `publish_position` updates coordinates, speed, active state, timestamp and heading. It does **not** calculate ETA, optimize routes or generate collection stops. Live values remain unavailable until the city publishes them through trusted operational tooling.

The optional `trucks` columns are `eta_minutes`, `next_stop`, `current_area`, `progress` (0–1), `status` and `active_route`. Valid status labels are `Not Started`, `On Route`, `Approaching`, `Nearby` and `Completed`. `active_route` is JSON with:

- `id` and `name`: string identifiers/labels.
- `waypoints`: arrays of `[latitude, longitude]` using actual route coordinates.
- `collection_points`: objects with integer `number`, string `name`, numeric `latitude` and numeric `longitude`.

Use community collection stops rather than residents' private coordinates. The mobile interface displays this route read-only. Sample A/B/C route simulation is available only in demo mode and is not seeded into the connected database.

## 5. Optional Firebase data messages

Firebase is optional and disabled unless all four public Firebase app values are supplied: `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` and `FIREBASE_PROJECT_ID`. Register the Android app as `com.sundo.sipalay` in your Firebase project. Add these build flags alongside the Supabase flags using the values for that registered platform:

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR-PUBLIC-KEY --dart-define=FIREBASE_API_KEY=YOUR-PUBLIC-FIREBASE-KEY --dart-define=FIREBASE_APP_ID=YOUR-ANDROID-APP-ID --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR-SENDER-ID --dart-define=FIREBASE_PROJECT_ID=YOUR-FIREBASE-PROJECT
```

In a connected account, Profile → Notification Settings → Manage Phone Permission can request permission and register the device token. `device_push_tokens` rows are private to their resident, and each token is unique. Logout/account changes remove the outgoing token binding and rotate the device token before sign-out; a failed removal keeps the account signed in for a retry.

A trusted server sender must be created separately. It should authorize the intended resident, respect notification preferences and send **data-only** FCM messages to that resident's registered tokens. Expected string data fields are `resident_id`, `title`, `message`, `category` and `type`. `resident_id` must equal the signed-in/bound Supabase user UUID. Messages containing an FCM `notification` payload are rejected by the app because the OS could display them before the resident check.

Accepted foreground data messages enter in-app Alerts. The background handler may save them to that resident's local history; it does not display an OS banner. Delivery depends on platform background restrictions. Firebase provisioning, the sender, delivery verification and OS banner presentation are **not completed** by these adapters. Do not claim push notifications work merely because permission was granted. Never place Firebase Admin credentials in Flutter.

## 6. Verify with separate phones/accounts

1. Register a resident, confirm email, sign in, permit GPS/camera and submit a concern with a photo. Confirm staff sees it and another resident cannot read it or its photo.
2. Staff verifies the concern and assigns a truck. Confirm the resident sees its updated status and only that truck's driver can complete it.
3. Driver starts sharing GPS with the app open. Confirm the resident map receives actual coordinates through Realtime and shows stale/offline state when updates stop. Positions expire after two minutes.
4. Driver completes the assigned scheduled concern. Confirm resident/staff status updates.
5. Staff creates a future collection schedule. Confirm it appears in Schedule and is selected on Home only for the matching resident area.
6. Deny/revoke resident location permission, pause the app and switch tabs. Confirm no fabricated precise resident marker appears and tracking resumes only with an actual permitted fix.
7. Switch resident accounts on one phone. Confirm reports, saved addresses, read state and alerts are isolated. If Firebase is configured, verify outgoing token removal and addressed-message rejection before enabling a sender.

These checks must run against the actual project. Unit/widget tests alone cannot validate remote RLS, email delivery, physical GPS/camera or Firebase delivery.

## Android and iOS release preparation

Android currently uses a development/debug signing key even for `--release`. Configure a controlled production signing key before broad distribution. Test offline/error states and foreground tracking on physical devices. There is no background driver location service; terminating the app stops reliable location publication.

The iOS Runner project uses bundle ID `com.sundo.sipalay`, iOS 15 minimum, logo-derived app icons, secure-storage keychain entitlement and location/camera/photo usage descriptions. Build and sign it on macOS with Xcode and an Apple team. No iOS binary was compiled on Windows. Use platform-specific Firebase app values; remote messages on iOS also require APNs credentials and Apple capabilities, which are not provisioned here.

The pinned `permission_handler_apple` package uses Swift Package Manager and discovers permissions from `ios/Runner/Info.plist` for normal Flutter CLI builds. If Xcode.app cannot discover the project from its working directory, point it to the absolute plist path before restarting Xcode:

```bash
launchctl setenv PERMISSION_HANDLER_INFO_PLIST /absolute/path/to/flutter_sundo/ios/Runner/Info.plist
```

Reset the affected Xcode package/build caches if permissions were previously compiled out, then resolve packages and test permission prompts on a device. Online concerns require a connection and actual GPS; local demo reports remain separate and are not automatically uploaded later. City privacy/terms, support contacts and official operational data still require review before public launch.
