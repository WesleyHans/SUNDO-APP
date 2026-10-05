# SUNDO mobile status

Open `flutter_sundo` as the Flutter project. The released baseline is **1.2.1+5**. The new time/weather environment update is prepared as **1.3.0+6**; no new APK or installer version is published for it yet. Source validation, APK publication and production deployment are separate steps.

## Resident functionality

- Native Flutter splash, welcome, register, login and five main tabs: Home, Live Map, Schedule, Alerts and Profile. Report Concern opens from Home.
- Clay cards, green controls, supplied logo and illustrated backgrounds. Working source now selects morning (05:00–10:59), noon (11:00–14:59), afternoon/sunset (15:00–17:59) and evening/night (18:00–04:59) scenes; time and greetings refresh every minute and when the app resumes.
- Five supplied matching scenes are bundled as lossless WebP. The splash logo, wordmark, subtitle, branding colors/positions, decorative leaf frames and bottom slogan card stay static while only the environment fades over 900 ms. Reduced-motion settings switch the scene immediately. Detailed transparent natural leaves replace the painted leaves without changing their frames. Shared backgrounds use continuous alpha feathering rather than a cut-off 220 px image band; Home removes repeated image strips and its doubled demo status-bar inset.
- Fresh rainy conditions override the time scene. Open-Meteo model data uses fixed Sipalay coordinates 9.7525, 122.4038, with a foreground request and 15-minute polling. Weather does not request or send resident GPS. Failed, malformed or more-than-30-minute-old conditions fall back to local time; weather artwork is not a local sensor reading or safety warning.
- Local demo registration/login with email or Philippine mobile number, duplicate-account validation, confirmed passwords and remembered sessions. Credentials use Flutter Secure Storage; account data uses scoped local storage. This does not authenticate a city account.
- Home shows the selected resident area's next published/sample pickup, the shared truck state, unread alerts and working shortcuts.
- Real OpenStreetMap tiles centered on Sipalay, attribution, zoom/recenter/route-fit controls, north reset, read-only route display, raised clay collection landmarks and a draggable tracking sheet. The default 3D view projects the map into perspective; the 2D control returns to a flat view. Raised symbols do not represent actual building heights or terrain meshes.
- Watch follows a fresh truck position. One simulated truck moves smoothly through sample A/B/C routes and turns using the shortest arc across north. Animated chevrons show direction along supplied route geometry; collection beacons add motion. Simulated ETA, route and status are labeled as demo data. Live mode uses actual fleet data and keeps unknown ETA/route information unavailable.
- The Layers panel pauses decorative route/beacon effects; system reduced-motion settings also suppress those effects and animated camera transitions. Animations pause when the map tab is inactive or the app is backgrounded. Operational updates remain independent of animation settings.
- A bounded native cache stores requested OpenStreetMap tiles without bulk downloads. It follows HTTP cache freshness and conditional validation, and may reuse previously viewed tiles during a failed connection when permitted by the server. Unvisited areas still need a connection; the OS can reclaim the cache. Base-map caching never extends truck/GPS freshness or caches live tracking updates.
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

The test suite covers demo authentication, scoped resident storage, schedule/report behavior, map controls/interpolation, shortest-arc headings, route-flow spacing, tile-cache behavior, push recipient checks, time boundaries and day/night layouts at regular and small phone sizes. Preview rendering uses local fonts/assets and test-controlled data. It does not verify live map tile delivery, physical GPS/camera, remote RLS or notification delivery.

## Environment update — validation pending

Full Flutter analysis reports no issues for the current source. Regression tests were added for the exact time boundaries, rain/freshness fallback, foreground weather polling, fixed splash branding/card geometry, scenery fades, the former backdrop seam and narrow Home greeting layout. These new tests have **not passed or failed at runtime**: Windows Application Control blocks Flutter's `dartaotruntime.exe` before test compilation, including the normal retry after the user allowed it.

Native test execution, new preview rendering and a new APK build remain pending until the trusted Flutter compiler can run under the computer's security policy. The 90 passing tests and APK checksum in the 1.2.1 section below belong to the previous release. They do not validate or package the environment update. The existing installer continues to distribute that prior APK.

The 1.3.0+6 cloud build was also attempted on the update branch with publication disabled: [build run 37308831832](https://github.com/WesleyHans/SUNDO-APP/actions/runs/37308831832). GitHub stopped it before any build steps with: "The job was not started because your account is locked due to a billing issue." No new APK was produced. Manual workflow runs now default to retaining a successfully checked APK as a review artifact rather than publishing it as the latest download.

Weather data by [Open-Meteo](https://open-meteo.com/), using [model-based current conditions](https://open-meteo.com/en/docs), under [CC BY 4.0](https://open-meteo.com/en/licence). SUNDO transforms current weather into the rainy artwork choice. The current keyless endpoint uses the [noncommercial API terms](https://open-meteo.com/en/terms); production service sizing and any commercial API configuration must be reviewed before a broader rollout. [Design notes](DESIGN_NOTES.md) record supplied scene paths and the exact natural-leaf generation prompt.

## Remaining release work

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

## Local verification for 1.2.1

Flutter analysis reported no issues and all **90 mobile tests passed**, including startup retry, account scope, GPS freshness, perspective controls, transformed map gestures, smooth heading/route interpolation, HTTP and decoded tile caching, day/night provider retention, visual pause with continuing truck updates, lifecycle resume, schedules and responsive layouts. The APK installer passed TypeScript checks and production compilation.

The Android release build completed as `com.sundo.sipalay`, version 1.2.1 (code 5), minimum Android 7.0/API 24. Its APK signature verifies with the Android development certificate. The 62,676,423-byte APK has SHA-256 `f3180c7824ef418da21868dba1b6e48d8c92b23e1039bd5dee86718a2f00e0db`.

Native previews are [the map](map-preview.png), [daylight resident screens](resident-design-day.png), [evening screens](resident-design-night.png) and [day/evening comparison](design-preview.png). Map previews use clearly labeled synthetic test tiles; they validate native rendering and interaction without claiming real map-server or physical GPS verification. The installed app uses OpenStreetMap. No remote backend or physical-device test is certified by these local checks.
