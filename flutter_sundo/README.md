# SUNDO native Android app

This directory is the Flutter project. It includes the illustrated claymorphism resident interface and connected resident, driver and city staff workflows.

The current source is the **1.4.0 candidate**. It adds optional local weather before sign-in, weather/time combinations including rainy night, a compact Home weather banner, softer secondary-screen scenery and the resident's supplied truck icons. APK publication and candidate validation are tracked in `../MOBILE_STATUS.md`; the released 1.3.0 APK does not include these candidate changes.

The perspective street map introduced in 1.2.1 retains raised clay collection symbols, animated route indicators, smooth truck turns, Watch follow mode and a 2D view. These symbols provide visual depth rather than surveyed terrain/building meshes. Reduced-motion settings and a Layers switch can suppress visual animation. Only viewed OpenStreetMap tiles are cached; unvisited areas and live truck updates still require connectivity.

## Optional location and weather

First open offers **Enable local weather** or **Use time only**, before an account is created or signed in. Enabling weather requests the device's foreground location permission. If phone Location is off, the app can open Location settings for the user to turn it on. Weather remains optional; its saved choice can be changed in **Profile → Location Permission → Location & weather**. The map's location use is managed separately.

With consent, a fresh one-shot position is rounded to two decimal places and sent to Open-Meteo for model-based current conditions. Weather coordinates are not persisted and there is no weather background GPS stream. Automatic refresh occurs every 15 minutes while SUNDO is open, without repeatedly requesting permission. The model and fetch timestamps must both be within 30 minutes. Conditions are approximate and can differ from weather on a specific street.

When device location is denied, disabled or unavailable, a supported saved Sipalay area can provide city-level weather labelled **Sipalay City (saved area)**. Without reliable location/weather, SUNDO falls back to time only and hides the weather banner. Turning weather off clears its snapshot and stops weather requests.

The device clock selects morning (05:00–10:59), noon (11:00–14:59), sunset (15:00–17:59) and night (18:00–04:59). Clear, cloudy, rain, drizzle and thunderstorm conditions combine with that period. Rainy night uses a dark lighting treatment over the original wet scene; no new truck/city layout is generated. Background changes fade smoothly, and branding/cards stay separate from illustration effects. The Home banner identifies the weather area and update age; wet-weather cautions do not represent an official delay announcement.

## Supplied truck graphics

`assets/images/sundo-side-truck.png` and `assets/images/sundo-map-truck.png` are exact copies of the resident's transparent PNGs. Their source hashes and packaging command are recorded in `../DESIGN_NOTES.md`. `SundoTruckGraphic` replaces the former flat truck within existing icon sizes; the SUNDO brand logo, wordmark and subtitle remain unchanged.

The map's supplied angled truck follows incoming positions/headings. Its wheel rims use pixels clipped from the same image and rotate only during an externally driven, fresh active movement transition. The widget has no independent movement timer. Stopped or stale trucks remain still, reduced motion disables spinning, and demo movement stays labelled as simulated. Real truck GPS requires configured operational data.

## Build and verification

Use Flutter 3.47.6, Dart 3.13.5, Java 17 and an installed Android SDK.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

Generate the candidate's native truck review sheet, where the compiler is available:

```powershell
flutter test --dart-define=GENERATE_PREVIEWS=true --update-goldens test/supplied_truck_graphics_test.dart
```

This writes `test/goldens/supplied_truck_rims.png`. The candidate also includes tests for weather permission/fallback, stale data, combined themes, weather-banner readability and unchanged splash branding. Read the actual test/build results before treating the candidate as released. Local Windows Flutter compilation is currently blocked by Application Control; Linux CI can run the native checks.

The default build opens a local demo. To activate real accounts, shared reports, private photos, schedules and driver GPS, follow `../supabase/README.md` and run `../supabase/schema.sql` in your own project. Build with `SUPABASE_URL` and `SUPABASE_ANON_KEY` as described there.

The existing release signing configuration uses a development key. Configure production signing before public distribution. Device permissions and the connected workflows need validation on physical phones. Driver GPS is foreground only. Optional Firebase addressed data-message handling exists, but no Firebase project/sender is provisioned and OS notification banners are not implemented. An iOS project is included; it still needs compilation, signing and testing on macOS.

See `../MOBILE_STATUS.md` for the current implementation and remaining release requirements, and `../DESIGN_NOTES.md` for the design assets and rendered previews.
