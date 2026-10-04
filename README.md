# SUNDO — Sipalay Smart Waste Navigation

The website is an Android APK installer landing page. It includes a download button, three installation steps and a short FAQ, with the green city illustration and clay design. Browser accounts, maps, reports, simulator views and developer tools have been removed. The mobile application is in `flutter_sundo`.

## Web installer

Use Node.js 20.19+ or 22.12+ (validated with Node 24.19).

```powershell
npm ci
npm run lint
npm run build
npm run dev
```

Vercel builds `dist`. The download button goes through `/download-apk` to the latest GitHub Release asset `SUNDO.apk`. APK files are published as release assets instead of being stored in Git or the website bundle. The previous PWA worker is retired on update so the installer does not offer to install a browser simulator.

## Mobile app and Supabase

Use Flutter 3.47.6, Java 17 and an Android SDK.

```powershell
cd flutter_sundo
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Without backend settings the app is a local demo. To activate verified resident accounts, private report photos, staff workflows and driver GPS, follow [Supabase setup](supabase/README.md) and run [schema.sql](supabase/schema.sql) in a new project. Set GitHub Actions variables `SUPABASE_URL` and `SUPABASE_ANON_KEY` before building the connected APK. Never use a service-role secret in the application.

The existing GitHub workflow builds and publishes the APK after mobile changes reach `main`. New signups are residents. A trusted project administrator assigns driver and staff roles and trucks.

The remote database policies and phone-to-phone workflows must be validated against the configured project. Production signing, physical device testing, push notifications and background GPS remain release tasks. See [mobile status](MOBILE_STATUS.md).

## Design

See [design notes](DESIGN_NOTES.md) for the generated artwork and native screenshot previews. The landing page uses the same city asset with a responsive cream-and-green clay layout. The React browser simulation has been removed; connected features live in Flutter.
