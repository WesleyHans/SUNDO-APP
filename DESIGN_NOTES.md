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
- Morning uses cool blue daylight; afternoon adds a warmer sky tint; evening uses dark surfaces, a moon, stars and city-window glow. Inputs, cards and text remain interactive native elements across themes.
- The live map uses OpenStreetMap tiles rather than a static map image. The default perspective presentation and raised clay markers are visual effects around the actual map. Demo routes are sample paths; live routes come from operational data.
- Outfit and Plus Jakarta Sans fonts are bundled with their OFL licenses, so interface text does not require font downloads.

The city illustration is stored at `flutter_sundo/assets/images/clay-city-hero.png` and `public/clay-city-hero.png`. It was created with the built-in image generation tool using this prompt:

> Production portrait background for SUNDO, inspired by the supplied reference: a green municipal recycling truck on a clean Sipalay road, rounded clay foliage, lime and emerald trees, pale cyan city buildings, warm sunshine, cream clouds and spacious pale blue sky for headings. Matte sculpted materials, soft bevels and ambient shadows. Truck and city in the lower half, foliage at the bottom corners. No phone frame, UI, written words or watermark.

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

The React/Vercel site is an APK-only installer with the supplied logo, matching city artwork, clay green download controls, installation steps and FAQ. Browser accounts, maps, report tools and simulator pages have been removed. `/download-apk` opens the latest GitHub Release `SUNDO.apk` asset.

Web validation uses TypeScript/lint and a production build. Browser inspection was declined by the permission system, so no visual browser QA is claimed. Publication status must be checked separately after releasing/deploying the current source.
