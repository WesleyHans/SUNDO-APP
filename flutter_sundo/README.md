# SUNDO native Android app

This directory is the Flutter project. It includes the illustrated claymorphism resident interface and connected resident, driver and city staff workflows.

Use Flutter 3.47.6, Dart 3.13.5, Java 17 and an installed Android SDK.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

The default build opens a local demo. To activate real accounts, shared reports, private photos, schedules and driver GPS, follow `../supabase/README.md` and run `../supabase/schema.sql` in your own project. Build with `SUPABASE_URL` and `SUPABASE_ANON_KEY` as described there.

The existing release signing configuration uses a development key. Configure production signing before public distribution. Device permissions and the connected workflows need validation on physical phones. Background tracking, push notifications and iPhone packaging are not included.

See `../MOBILE_STATUS.md` for the current implementation and remaining release requirements, and `../DESIGN_NOTES.md` for the design assets and rendered previews.
