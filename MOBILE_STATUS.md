# SUNDO mobile status

Open `flutter_sundo` as the Flutter project. The resident redesign is prepared for version **1.2.0+4**. Source/build/release publication and production deployment are separate steps; this document does not certify their completion.

## Resident functionality

- Native Flutter splash, welcome, register, login and five main tabs: Home, Live Map, Schedule, Alerts and Profile. Report Concern opens from Home.
- Clay cards, green controls, supplied logo and illustrated backgrounds. Local morning (06:00–11:59), afternoon (12:00–17:59) and evening/night (18:00–05:59) themes and greetings refresh every minute and when the app resumes.
- Local demo registration/login with email or Philippine mobile number, duplicate-account validation, confirmed passwords and remembered sessions. Credentials use Flutter Secure Storage; account data uses scoped local storage. This does not authenticate a city account.
- Home shows the selected resident area's next published/sample pickup, the shared truck state, unread alerts and working shortcuts.
- Real OpenStreetMap tiles centered on Sipalay, attribution, zoom/recenter/follow/layer controls, read-only route display, elevated numbered collection stops and a draggable tracking sheet.
- One simulated truck moves smoothly through sample A/B/C routes and changes heading. Simulated ETA, route and status are labeled as demo data. Live mode uses actual fleet data and keeps unknown ETA/route information unavailable.
- The private resident marker and accuracy circle require an actual GPS fix. A denied or unavailable fix leaves a selected-area/address view. Resident map tracking stops when that tab is inactive or the app is paused; resident map coordinates are not published to the fleet table.
- Approaching-truck dialog, route-change events, alert categories, read state and preference controls. Live alert history contains observed events rather than seeded mock announcements.
- Today/This Week/Calendar schedule views, month navigation, date markers and collection details.
- Concern types, descriptions up to 300 characters, up to three camera/gallery photos and report history. Demo concerns may use an address when GPS is unavailable; connected submissions require a real GPS fix. Duplicate submission taps are blocked. Local photos are copied to permanent app documents.
- Editable profile/address, saved addresses, location permission status, notification settings and logout. Local resident data stays scoped to its account when users switch on one phone.

## Connected service adapters

Supabase configuration switches sign-in to email/password accounts with verified email and server roles. Mobile-number and social sign-in require additional providers and are not enabled for city accounts.

Residents can submit GPS-tagged concerns with private photos and view their report status, published schedules and actual truck updates. Drivers can share foreground GPS for their assigned truck and complete assigned reports. Staff can verify concerns, assign collection trucks, mark collection complete and create schedules. The database controls privileges; residents cannot assign themselves a privileged role.

Resident fleet updates use the Supabase `trucks` Realtime stream. Driver GPS publishes coordinates, speed and heading. ETA, stops, progress, stage and route geometry need actual operational data from the city; the app does not calculate or substitute demo values for missing live metadata. Truck positions older than two minutes appear offline. Driver/staff data also refreshes while their screen is open.

Optional Firebase initialization, device-token registration and addressed **data-only** message handling are included. An accepted message must match the current/bound resident ID. Token bindings are removed and rotated before logout/account changes; failure leaves the account signed in to allow a safe retry. These adapters have not been tested with a Firebase project. A trusted sender, APNs setup for iOS and OS banner delivery remain unfinished. A background data message may be saved to in-app history; it does not currently display an OS notification.

## Validation and remaining release work

The test suite covers demo authentication, scoped resident storage, schedule/report behavior, map controls/interpolation, push recipient checks, time boundaries and day/night layouts at regular and small phone sizes. Preview rendering uses local fonts/assets and test-controlled data. It does not verify live map tile delivery, physical GPS/camera, remote RLS or notification delivery.

Before public city use:

1. Create Supabase, apply the appropriate schema/migration, configure email delivery and build with public project values. Verify the role, photo and report policies using separate resident/driver/staff accounts.
2. Provision actual staff/drivers/trucks and collection schedules. Supply operational routes/ETA metadata if those features are needed live.
3. Test permissions, real GPS, camera/gallery, poor connectivity and account switching on physical Android devices. Driver GPS is foreground only; there is no background location service.
4. Configure Firebase and a trusted sender if remote alerts are required. Add and verify OS banner delivery separately; permission acceptance alone does not provide alerts.
5. Replace Android development signing with a controlled production signing key before broad distribution. The release build currently uses the Android debug signing configuration.
6. Build/sign/test iOS on macOS with Xcode and an Apple signing team. The generated iOS project has not been compiled on Windows.
7. Review privacy/terms, support contacts and official collection data with the city. No verified city support hotline is bundled.

No Supabase URL/key or Firebase project has been supplied. Remote configuration is not applied by an APK download or Vercel deployment. Demo reports are never automatically uploaded to a future backend.

## Build commands

```powershell
cd flutter_sundo
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Use Flutter 3.47.6 / Dart 3.13.5, Java 17 and the Android SDK. The APK is produced at `build/app/outputs/flutter-apk/app-release.apk`. Backend build flags and iOS permission discovery are documented in [Supabase setup](supabase/README.md).

The configured GitHub Android workflow performs the same analysis/tests before publishing. Its runs were blocked by the account's billing lock during this work; local verification and manual release publication are the available route until Actions is restored.

## Version 1.2.0 verification

Flutter analysis reports no issues and all 55 mobile tests pass, including startup retry, account scope, GPS freshness, map area changes, schedules and responsive day/night layouts. The APK installer passes TypeScript checks and production compilation. Native previews are [daylight](resident-design-day.png), [evening](resident-design-night.png) and [day/evening comparison](design-preview.png).
