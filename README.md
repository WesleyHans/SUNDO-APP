# SUNDO — Sipalay Smart Waste Navigation

SUNDO is a Flutter mobile app for residents, with connected driver and city staff workflows. The website is an Android APK installer: download, installation steps and a short FAQ. It does not run the mobile app in the browser.

The resident dashboard follows the supplied green and cream clay reference, with balanced collection cards, featured truck, gentle decorative motion and the unchanged SUNDO logo. Version **1.5.9+17** preserves the existing twilight scenery at **6 PM** and fades to the supplied darker blue moon-and-stars scene from **7 PM** Philippine time until local sunrise. Good Morning starts at midnight independently of the dark scenery. Inner-page backgrounds retain their faint warm yellow/cream tint from **5 PM** until calculated local sunset. Existing leaf placements, Splash/Welcome/Login composition, smooth navigation and Open-Meteo weather remain; Live Map has no leaf decorations and retains its original surface. Weather refreshes every five minutes with a manual retry on Home. [Download the APK](https://github.com/WesleyHans/SUNDO-APP/releases/download/v1.5.9/SUNDO.apk). See [sprite integration and artwork limits](TRUCK_SPRITES.md): the generated directional trucks approximate the supplied truck rather than guaranteeing identical 3D geometry.

## Run the mobile app

Use Flutter 3.47.6 / Dart 3.13.5, Java 17 and Android SDK platform 37.0. The app supports Android 7.0 (API 24) and later.

The Gradle build specifies the SDK minor level because the platform is distributed as `android-37.0`. It also applies that setting to the permission plugin without changing downloaded package sources. See [Android SDK build settings](https://developer.android.com/build).

```powershell
cd flutter_sundo
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

APK output: `flutter_sundo/build/app/outputs/flutter-apk/app-release.apk`.

Without backend settings, SUNDO clearly displays **LOCAL DEMO**. Get Started opens a guest demo; Create Account makes a local account on that phone. Demo credentials use secure device storage. Profiles, saved addresses, preferences and report history are scoped to the current local identity. Demo reports stay on the phone and are not sent to the city.

The resident app includes splash/onboarding, registration/login, Home, Live Map, schedules with a calendar, alerts, a concern form and profile settings. The map uses real OpenStreetMap tiles for Sipalay. Demo truck movement and routes are sample operations, while the resident marker requires an actual device GPS fix. Location permission denial shows the selected area without inventing a precise location.

## Live Map in 1.2.1

The default **3D** view adds perspective to the actual street map, with raised clay collection landmarks, depth shadows and animated route chevrons. These landmarks are collection symbols placed at supplied route coordinates; the app does not contain surveyed building heights or terrain meshes. The SUNDO brand logo remains unchanged.

- **Watch** follows a fresh truck position. Truck turns take the shortest rotation through north, and camera transitions ease into the selected view.
- **2D** returns to a flat map for inspecting streets. The north control resets orientation; route fit and tappable collection stops help explore the active route.
- The Layers panel can pause route/beacon effects. System reduced-motion settings also suppress decorative motion and animated camera transitions. Positions continue to reflect incoming operational updates.
- OpenStreetMap tiles are cached as they are viewed, with a bounded device cache and HTTP freshness checks. Previously viewed tiles may remain available during a failed connection when the server permits reuse. This is not a downloadable offline city map; unvisited areas need a connection, and the OS may clear cached tiles.

Cached base maps do not make GPS or truck updates current. Live mode still requires the configured city backend and a fresh truck fix. Route chevrons decorate the supplied route geometry and never substitute for a reported truck position. No map tiles are bulk downloaded.

## Time and local weather scenery

The new splash keeps the supplied logo, SUNDO wordmark, two-line subtitle, corner leaf frames and bottom **Track. Prepare. Collect.** card fixed. Branding colors and positions remain constant when the environment changes. Six supplied scenery illustrations are bundled as lossless WebP assets. The former night illustration remains the twilight asset; the new night illustration uses the user's supplied artwork. On compact phones, the fixed branding plate can cover the new artwork's higher moon.

| Philippine time (UTC+8) | Scene |
| --- | --- |
| Calculated local sunrise–10:59 | Morning |
| 11:00–16:59 while daylight | Noon / afternoon |
| 17:00–calculated local sunset | Sunset |
| After calculated sunset–18:59 | Evening twilight, including 6 PM |
| 19:00 until next local sunrise | Dark blue night |
| Fresh rain, drizzle or thunderstorms during daytime | Rainy atmosphere matched to the time period |
| Fresh rain, drizzle or thunderstorms at night | Dark rainy night atmosphere |

Scene changes fade over 900 ms; system reduced-motion settings select the new scene immediately. Other resident screens use a continuous, softly masked backdrop rather than separate illustration bands. Home's greeting no longer receives a second status-bar inset in the demo shell. Detailed transparent natural leaves replace the painted leaves within their existing frames.

Version 1.5.7 separates greetings from daylight: **Good Morning starts at midnight, Good Afternoon at noon, and Good Evening at 6 PM**. The dark scenery remains until calculated sunrise. Offline solar calculations use the permitted resolved location, or Sipalay otherwise, and track seasonal sunrise/sunset without a new API or permission. Sunset artwork begins at **5 PM**; version 1.5.9 retains twilight after calculated sunset and selects full night from **7 PM**. Missing or delayed artwork uses a neutral current-time surface rather than stale daylight.

On first launch, before account creation or login, an explanation offers **Enable local weather** or **Use time only**. Enabling weather requests foreground device location permission and offers phone Location settings when the switch is off. Valid, recent coordinates are rounded to approximately 0.01 degrees before being sent to [Open-Meteo current model conditions](https://open-meteo.com/en/docs). Coordinates are not saved. A genuinely saved Sipalay address can provide explicitly labeled city-level weather if device location is unavailable; a new guest without an address uses time only. The preference remains available through Profile → Location Permission.

Weather refreshes on foreground entry and every five minutes while foregrounded. Failed, malformed, unsupported, more-than-20-minute-old model conditions or responses fetched more than ten minutes ago fall back to time; no clear-weather claim is invented. Home displays a banner with the area, model source, update age and an optional rain collection caution. Clear, cloudy, rain, drizzle and thunderstorm conditions combine with Philippine daylight. Rainy night uses the same supplied rainy scene with a darker atmosphere; branding stays outside scenery filters. Shared backgrounds remain faint for readable forms and cards.

The supplied angled truck replaces the old map graphic, and the supplied side view replaces collection truck icons in cards, schedules, alerts and staff listings. Original transparent PNGs are bundled without pixel changes. The map preserves position updates, heading and camera rotation. Only the original silver rims rotate while a fresh position is interpolating; inactive tracking, stale positions and reduced motion stop the visual effect. Actual fleet GPS still requires the city backend; the demo route remains labeled simulated.

Weather data by [Open-Meteo](https://open-meteo.com/), under [CC BY 4.0](https://open-meteo.com/en/licence); SUNDO interprets current model conditions into atmospheric scenery. The keyless endpoint follows Open-Meteo's [noncommercial API terms](https://open-meteo.com/en/terms). Commercial distribution or higher request volume requires appropriate API service configuration.

The prior 1.3.0 cloud build passed Flutter analysis, all **132 tests**, APK compilation and nine additional splash preview tests. Its signature and 1.3.0+6 package metadata were verified after signing locally with the existing app key. Windows Application Control blocked local compilation at that time; GitHub's Linux runner produced that build. See [mobile status](MOBILE_STATUS.md) and [artwork provenance](DESIGN_NOTES.md).

The 1.4.0 release passes analysis and **all 190 tests locally** through the standard Windows Flutter SDK. Another **49 native preview tests passed**, and the supplied trucks, readable Home weather, map and rainy-night splash were visually reviewed. The APK compiled locally, its signature matches 1.3.0, and GitHub's uploaded SHA-256 matches the verified local file. Physical-device validation remains pending.

## UI checks in 1.5.4

The screen audit covers resident screens, calendar, forms, alerts, profile editors and map controls on short 320-pixel phones with 1.3 and 1.5 text scaling and an open keyboard. Welcome grows to fit larger text with a softer backdrop behind its message, photo buttons grow with their labels, long announcements and reminder settings scroll, and profile/city editors retain their controllers until the closing animation finishes. Staff cards use readable night surfaces, map labels stay compact and required city form fields show validation feedback. Original branding, screen structure, weather logic and truck movement remain in place. Flutter analysis is clean; all 227 tests and another 60 native preview checks passed.

## Activate the shared backend

Follow [Supabase setup](supabase/README.md). For a **new** project, run [schema.sql](supabase/schema.sql). For a project already using the previous SUNDO schema, apply [the resident tracking migration](supabase/migrations/20261004_resident_tracking.sql).

Build with the project URL and a **public publishable/anon key**:

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR-PUBLIC-KEY
```

These commands run from `flutter_sundo`. Never embed a service-role key, database password or FCM server credential. A trusted administrator assigns staff/driver roles and trucks; all app signups become residents. Connected accounts use Supabase email/password authentication, private report photos, published collection schedules and actual truck updates. Optional Firebase data-message handling is prepared, but no Firebase project or notification sender is provisioned, and OS notification banners are not implemented.

No Supabase project or keys have been supplied for this checkout. Remote policies and phone-to-phone workflows still require verification. The default Android build is a development-signed demo. See [mobile status](MOBILE_STATUS.md) for the remaining release requirements.

## Web APK installer

Use Node.js 20.19+ or 22.12+; Node 24.19 was used locally.

```powershell
npm ci
npm run lint
npm run build
npm run dev
```

Vercel builds `dist`. `/download-apk?v=1.5.9` is pinned to the verified 1.5.9 GitHub Release asset named `SUNDO.apk`, so binaries are kept outside Git and the web bundle. Download redirects use no-store headers. The previous PWA worker is retired to remove the browser simulation. Production address: [sundo-app.vercel.app](https://sundo-app.vercel.app). A successful local build does not itself confirm a new production deployment.

The [Android workflow](.github/workflows/build-apk.yml) runs analysis/tests and retains APK/preview artifacts on mobile changes to `main`. Its public Supabase values come from Actions variables `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Builds now run under WesleyHans after the repository transfer. Before release publication, sign the artifact with the existing local app key and verify its signature, version and checksum; runner-signed builds are never automatically published.

## Project layout

```text
flutter_sundo/lib/
  app/                 Router, app root and resident navigation
  core/                Theme/time, device storage, network and area helpers
  features/            Resident screens plus driver/staff operations
  shared/widgets/      Clay controls, scenery and brand graphics
  models/              Tracking and app models
  repositories/        Local demo and Supabase data adapters
  services/            Backend and optional Firebase message handling
supabase/              Schema, migration and setup instructions
public/                Installer artwork and preserved logo
```

An iOS Runner project is included with bundle ID `com.sundo.sipalay`, iOS 15 minimum, permission descriptions and icons. It must be built and signed on macOS; no iOS build has been verified on Windows. [Design notes](DESIGN_NOTES.md) describe artwork and rendered Flutter previews.
