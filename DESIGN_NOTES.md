# SUNDO reference design

The supplied twelve-screen reference guides the resident app's layout: a green/cream palette, city/truck scenery, leaf accents, compact cards, rounded form fields, dashboard shortcuts, five bottom tabs and a map tracking sheet. Claymorphism adds soft sculpted shadows, gradients and rounded controls. The reference is implemented with interactive Flutter widgets; screenshots are not used as app screens.

## Preserved brand

The supplied transparent SUNDO logo is unchanged at:

- `flutter_sundo/assets/images/sundo-brand-logo.png`
- `public/sundo-brand-logo.png`

Source PNG SHA-256: `FC06E9D1A9D5FE2FD99F84481D1743E776D71B97CD3C7823B32BF8E3BD83387D`.

Splash, welcome, account screens and installer branding use that asset. Android launcher/adaptive icons and iOS app icons are packaged from the same artwork, with required padding/backgrounds. Run `node scripts/package-brand-icons.mjs` to regenerate platform icons. Operational truck/map markers are separate graphics.

## Native design structure

- `flutter_sundo/lib/features/` contains splash, onboarding, auth, home, live_map, schedule, notifications, report_concern and profile screens; operations retains the connected staff/driver workflows.
- `flutter_sundo/lib/shared/widgets/` holds reusable controls, brand graphics, scenery, time-based backgrounds, schedule/notification components and bottom navigation.
- `flutter_sundo/lib/core/theme/` contains the clay palette and local-time theme controller. The app refreshes its greeting and mood each minute and on resume.
- The environment scene combines morning, noon, sunset and night with fresh clear, cloudy, rain, drizzle and thunderstorm conditions. Wet scenes retain the current time's lighting, including a distinct rainy-night mood. Inputs, cards and text remain interactive native elements across themes. Splash branding uses a constant daytime scope so logo text and subtitle colors do not change at night.
- The live map uses OpenStreetMap tiles rather than a static map image. The default perspective presentation and raised clay markers are visual effects around the actual map. Demo routes are sample paths; live routes come from operational data.
- Outfit and Plus Jakarta Sans fonts are bundled with their OFL licenses, so interface text does not require font downloads.

The earlier city illustration remains at `flutter_sundo/assets/images/clay-city-hero.png` and `public/clay-city-hero.png` for the operations/installer artwork. It was created with the built-in image generation tool using this prompt:

> Production portrait background for SUNDO, inspired by the supplied reference: a green municipal recycling truck on a clean Sipalay road, rounded clay foliage, lime and emerald trees, pale cyan city buildings, warm sunshine, cream clouds and spacious pale blue sky for headings. Matte sculpted materials, soft bevels and ambient shadows. Truck and city in the lower half, foliage at the bottom corners. No phone frame, UI, written words or watermark.

## Fixed branding and dynamic environment update

The splash has two independent layers. Its upper branding plate preserves the existing centered logo, large SUNDO wordmark and **Smart Urban Navigation / for Dynamic Waste Operations** subtitle with their previous colors, sizes and positions. The decorative leaf frames also stay in their existing positions. The lower city/truck scene changes behind a soft blend into that plate; the white rounded bottom card, **Track. Prepare. Collect.** and **Together for a cleaner Sipalay** remain fixed. Background transitions cannot animate or reposition those Flutter branding/card widgets.

The user supplied five matching 1024 × 1536 PNG scenes. They are converted to lossless WebP at the same dimensions, preserving the supplied single truck model, orientation, road, buildings, plants and camera framing. No truck or environment variant was newly generated for this update.

| Environment | Supplied source in `C:/Users/User/Downloads/` | Project asset |
| --- | --- | --- |
| Morning | `ChatGPT Image Oct 5, 2026, 07_07_06 PM-1.png` | `flutter_sundo/assets/images/environment-morning.webp` |
| Noon | `ChatGPT Image Oct 5, 2026, 07_07_09 PM-2.png` | `flutter_sundo/assets/images/environment-noon.webp` |
| Sunset | `ChatGPT Image Oct 5, 2026, 07_07_11 PM-3.png` | `flutter_sundo/assets/images/environment-sunset.webp` |
| Night | `ChatGPT Image Oct 5, 2026, 07_07_14 PM-4.png` | `flutter_sundo/assets/images/environment-night.webp` |
| Rainy | `ChatGPT Image Oct 5, 2026, 07_07_15 PM-5.png` | `flutter_sundo/assets/images/environment-rainy.webp` |

Every variant uses the same fit and alignment. Splash uses `BoxFit.fitWidth` to retain the supplied truck's full cab and tail. On taller phones, the last 48 pixels of the illustration blend into the surrounding surface so the image cannot end in a hard horizontal cut beside the card. The fixed branding plate follows the existing text layout, including accessibility text scaling. A small night-only moon is drawn in the supplied sky coordinates beneath that plate; the truck image is not edited. The branding plate can cover that sky position on compact phones.

Other resident screens receive an edge-to-edge scene through a continuous alpha mask; the previous 220 px illustration band and duplicated Home header/footer image strips are removed. In the 1.4.0 release, this shared backdrop is softer, reaching approximately 22% illustration opacity at its strongest point, so forms, schedules, notifications, reports and profile content remain readable. Splash and welcome retain their stronger illustration treatment. Home's header is content-driven and the demo banner's status inset is not applied a second time. System-bar icon colors follow the time theme, with a fixed dark-icon override on the splash's light branding plate.

Time selection uses device-local hours: **05:00–10:59 morning; 11:00–14:59 noon; 15:00–17:59 sunset; 18:00–04:59 night**. The clock refreshes each minute and on resume. Greetings use Good Morning, Good Afternoon or Good Evening. The current scene stays visible until the requested next asset decodes successfully, then both scenery and underlay use a 900 ms fade; reduced-motion settings switch immediately. Failed image loads retain the current scene, and superseded image requests cannot replace it.

The 1.4.0 release keeps rain and time together. Morning rain has a cool morning treatment; afternoon rain has a warmer treatment; evening/night rain uses dark blue wet scenery. Cloudy conditions use muted lighting, and thunderstorm conditions use the wet scene. These are native color filters over the same supplied rainy/day scenes, rather than newly generated trucks or different city compositions. The filter affects illustration pixels only; the logo, wordmark, subtitle, card, controls and actual map tiles are outside it.

### Location and weather consent in the 1.4.0 release

Before authentication, a first-open dialog offers **Enable local weather** or **Use time only**. Weather is optional and does not require an account. Choosing local weather allows the app to request the phone's foreground location permission. If the phone's Location switch is off, SUNDO can offer its Location settings; it cannot turn that switch on itself. The weather choice is saved on the device and can be changed through **Profile → Location Permission → Location & weather**. The app does not repeatedly request permission during automatic refreshes.

With consent and permission, SUNDO obtains a fresh one-shot device position and rounds latitude/longitude to two decimal places before sending them to [Open-Meteo's model-based current conditions endpoint](https://open-meteo.com/en/docs). Weather coordinates are held in memory rather than persisted, and this feature starts no background GPS stream. Current conditions describe the approximate model area and may differ from rain on an individual street.

If GPS is denied, disabled or unavailable, a supported saved Sipalay barangay/address can supply explicitly city-level weather: the fixed city coordinates 9.7525, 122.4038 are used, rounded in the same way. The banner identifies **Sipalay City (saved area)**; no unverified barangay centroid is invented. Without a reliable saved area, or when weather is switched off, SUNDO uses time-only scenery. Weather state is cleared when the resident identity or saved area changes.

Requests recur every 15 minutes while the app is in the foreground; backgrounding stops polling and invalidates pending results. Both the model timestamp and fetch time must be within 30 minutes. Failed, malformed, unknown or stale results cannot produce a weather banner; unavailable/stale data returns the theme to device-local time. A compact Home banner names clear, cloudy, rain, light rain or thunderstorms, identifies the area, shows the model update age and adds a collection caution for wet conditions. It does not claim an official collection delay or emergency alert.

Weather data by [Open-Meteo](https://open-meteo.com/), [CC BY 4.0](https://open-meteo.com/en/licence). SUNDO transforms current conditions into an artwork/lighting choice; the keyless endpoint is subject to [noncommercial API terms](https://open-meteo.com/en/terms). Linked weather attribution sits in the existing space below the splash card and in Profile's About dialog; it does not move the slogan card.

Run `node scripts/package-environment-assets.mjs C:/Users/User/Downloads` to package the five supplied files. The script validates their common dimensions and compares decoded RGBA pixels after conversion. Current asset checks confirm all five WebP files preserve the original decoded pixels and both logo files retain their original SHA-256.

### Natural leaf asset provenance

The only newly generated artwork in this update is a transparent botanical sprig. It replaces the earlier painted leaves within the same decorative sizes, positions and flip settings, and stays constant across time and weather. The original supplied SUNDO logo is not edited.

- Generated output: `C:/Users/User/.codex/generated_images/01a106ac-6cd6-7d41-bfbd-0dfebfc80608/exec-8e3fa390-9430-4b62-b721-8b673fa3d60f.png`
- Project asset: `flutter_sundo/assets/images/sundo-leaf-sprig.png`
- Transparent PNG dimensions: 1254 × 1254; alpha includes both transparent and opaque pixels.

Exact image-generation prompt:

> Use case: photorealistic-natural. Asset type: transparent PNG botanical decoration for SUNDO mobile UI. Generate a single compact sprig of exactly three fresh tropical green leaves connected to one thin gently curved green stem. Place the stem attachment at the TOP RIGHT corner; the sprig extends diagonally DOWN LEFT like leaves hanging in the upper-right corner of a screen. Natural leaves with detailed branching veins, subtle irregular edges, translucent light along edges, realistic waxy surfaces, lime-to-emerald greens, soft dimensional shading and tiny contact shadows. Three overlapping broad lanceolate pointed leaves placed at different heights along the same stem, matching a roughly square footprint, fill most of canvas with a little clear margin. Calm soft daylight, no dramatic lighting. Transparent background including between leaves, preserve alpha. No pot, flowers, truck, logo, words, watermark, frame, scenery, flat cartoon illustration or vector style. This is a botanical cutout only, kept constant across day/night/weather.

The prior 1.3.0 environment update passed analysis and all 132 tests on GitHub's Linux runner. Version 1.4.0 now passes analysis and all 190 tests locally through the standard Windows SDK, plus 49 native preview tests. Resident screens, supplied truck rim phases, map and rainy-night splash were visually reviewed. The locally compiled 1.4.0+7 APK verifies with the previous signing certificate, and GitHub's published asset digest matches its local SHA-256. See `MOBILE_STATUS.md` for exact metadata. Physical-device testing remains pending; compact splash framing can hide the moon behind the fixed branding plate.

## Supplied operational trucks in the 1.4.0 release

The resident supplied separate side-view and angled map PNGs. Both already have alpha transparency. `scripts/package-supplied-trucks.mjs` copies the original PNG bytes and verifies all decoded RGBA pixels; no truck is regenerated, recolored or replaced with a second model. Original and packaged SHA-256 hashes match:

| Use | Supplied source in `C:/Users/User/AppData/Local/Temp/` | Asset | Dimensions | SHA-256 |
| --- | --- | --- | --- | --- |
| Map | `codex-clipboard-ce9fd9f1-939d-4810-b75b-972007b14064.png` | `flutter_sundo/assets/images/sundo-map-truck.png` | 1254 × 1254 | `00169B01BB325F8F1B4636E631EEA339FDABC3D596A859CE8316B05968692BD5` |
| Side view | `codex-clipboard-ed25bf4f-3284-4ec9-917a-5348471c138c.png` | `flutter_sundo/assets/images/sundo-side-truck.png` | 1536 × 1024 | `21B83C4A45ABBE16D56D82404ED8FCE474D9BE9831181EEB75F832E9C5E73EA3` |

Run from the repository root:

```powershell
node scripts/package-supplied-trucks.mjs "C:/Users/User/AppData/Local/Temp/codex-clipboard-ce9fd9f1-939d-4810-b75b-972007b14064.png" "C:/Users/User/AppData/Local/Temp/codex-clipboard-ed25bf4f-3284-4ec9-917a-5348471c138c.png"
```

The shared `SundoTruckGraphic` uses the side-view artwork in the previous icon bounds. Home, schedule cards, approaching alerts, collection updates, onboarding illustrations and staff truck listings inherit the replacement. The map uses the angled artwork, rotates it to the reported heading and preserves its existing marker footprint. Unknown headings remain explicitly unavailable. Operational icons do not replace the supplied SUNDO logo, wordmark or subtitle.

`SundoVehicleGraphic` keeps the truck body and rubber tires fixed and rotates clipped silver rim pixels from that same image. A caller supplies its phase and movement state; the widget has no independent animation timer and cannot create GPS positions. Map rims rotate only during a fresh, active position interpolation with visual motion enabled. Stopped, stale and offline trucks do not spin. Demo movement remains labelled as simulated; connected movement requires actual operational truck updates. Reduced-motion settings disable rim animation.

Native asset, narrow-layout and wheel-only pixel tests passed for these graphics. Generate the review sheet with `flutter test --dart-define=GENERATE_PREVIEWS=true --update-goldens test/supplied_truck_graphics_test.dart` from `flutter_sundo`; its output is `test/goldens/supplied_truck_rims.png`. The map preview also awaits both supplied PNG decodes before capture.

## Map presentation in 1.2.1

The 3D control projects the real street map into an angled plane. Collection stops use sculpted clay landmark symbols, number badges and depth shadows; their positions come from route data. This provides depth without claiming real terrain elevation, surveyed building footprints or building meshes. The 2D control restores a flat view for street inspection. The supplied SUNDO logo is unchanged; map landmarks and truck graphics are separate operational symbols.

Route chevrons move at evenly spaced distances along the supplied waypoint path. Sampling uses great-circle segments to avoid long-way longitude crossings and skips repeated zero-length legs. These are decorative route indicators, not GPS fixes. Truck heading interpolation follows the shortest arc, so a turn from 359 degrees to 1 degree crosses north smoothly.

Watch follows a fresh truck location with eased camera movement. A north-reset control, route-fit control, tappable collection landmarks and the tracking sheet let residents explore the scene. The Layers panel can pause route/beacon effects. Device reduced-motion settings disable decorative animation and animated camera transitions, and map animations pause outside the active foreground map.

The native OpenStreetMap cache requests tiles only for map viewing, keeps a bounded local cache and honors HTTP cache instructions. It does not prefetch a city or zoom archive. Previously viewed tiles may be reused after a failed connection when the server allows it, but this does not make the truck position fresh or provide offline tracking. OSM attribution remains visible.

## Rendered previews

`flutter_sundo/test/design_preview_test.dart` renders eleven resident views in both day and night themes: splash, welcome, login, register, home, schedule, calendar, notifications, report, profile and the approaching alert. The native map has separate control/layout tests with external tiles and GPS disabled for deterministic testing. These previews do not demonstrate network tile delivery or real device permissions.

Generate preview PNGs from the Flutter project:

```powershell
flutter test --dart-define=GENERATE_PREVIEWS=true --update-goldens test/design_preview_test.dart
```

The resulting images are under `flutter_sundo/test/goldens/`, with `_night` variants. Run `node scripts/render-design-preview.mjs` from the repository root to create [daylight](resident-design-day.png), [evening](resident-design-night.png) and [day/evening comparison](design-preview.png) contact sheets. Layout tests also exercise smaller phone dimensions to catch clipped controls and overflow.

Map previews use a synthetic canvas basemap only in test fixtures, with a visible disclaimer; the installed app continues to use OpenStreetMap. Tests require decoded, fully visible tiles before capturing the preview and verify that day/night changes preserve the mounted tile provider. Generate the three map scenes from `flutter_sundo` with `flutter test --dart-define=GENERATE_PREVIEWS=true --update-goldens test/map_scene_preview_test.dart`, then run `node scripts/render-map-preview.mjs` from the repository root for the [map preview](map-preview.png).

## Installer website

The React/Vercel site is an APK-only installer with the supplied logo, matching city artwork, clay green download controls, installation steps and FAQ. Browser accounts, maps, report tools and simulator pages have been removed. `/download-apk?v=1.4.0` is pinned to the verified 1.4.0 GitHub Release APK. Download redirects use no-store headers.

Web validation uses TypeScript/lint and a production build. Browser inspection was declined by the permission system, so no visual browser QA is claimed. Publication status must be checked separately after releasing/deploying the current source.
