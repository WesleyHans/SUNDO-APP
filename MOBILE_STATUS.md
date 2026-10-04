# SUNDO mobile app status

The native Android project is in `flutter_sundo`. Open this directory as the Flutter project.

## What works locally

- Resident screens and navigation, OpenStreetMap display, device GPS, camera/gallery selection.
- Reports saved to device preferences; report photos copied to permanent app documents.
- Profile preferences and report history.
- Reports require an actual GPS fix and cannot be saved twice by repeated taps during a save.

## Connected service implemented

When built with Supabase configuration, the app uses verified email/password accounts and database roles:

- Residents submit GPS-tagged reports and private photos, track their report status, view actual truck positions and published schedules.
- Drivers share foreground GPS positions for their assigned truck and mark assigned collections complete.
- City staff verify reports, assign trucks, mark collections complete and create collection schedules.
- Access rules are defined in `supabase/schema.sql`; privileged roles are assigned by the project administrator.
- See `supabase/README.md` for complete setup and phone-to-phone verification steps.

## Required before a live release

- Create/configure the Supabase project and run the database schema; remote access policies and workflows need verification against this project.
- Supply the project URL and public key when building the connected APK. The default build remains a local demo.
- Provision staff and driver accounts, assign trucks and enter the city's actual collection schedules.
- Push notifications and background truck tracking are not implemented; connected data refreshes while the app is open.
- Production signing key: the Android release build currently uses a development signing key.
- Tests on physical Android devices for permissions, camera, GPS, offline behavior and small screens.
- iOS project and signing if an iPhone release is required.

The demo displays a notice and does not claim locally saved reports were received by the city. Connected login never accepts arbitrary credentials or bypasses authentication through social buttons.

## Build and verification

Use Flutter 3.47.6, Dart 3.13.5, Java 17 and an installed Android SDK.

```powershell
cd flutter_sundo
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Output: `flutter_sundo/build/app/outputs/flutter-apk/app-release.apk`.

The GitHub Android workflow now runs analysis and tests before building, using the same Flutter version. It publishes a GitHub Release when triggered; no changes have been pushed from this workspace.
