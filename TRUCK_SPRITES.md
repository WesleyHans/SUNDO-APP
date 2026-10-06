# SUNDO directional truck sprites

Sixteen transparent 1254 × 1254 PNG source illustrations are in
`flutter_sundo/assets/images/truck_directions/`. Filenames use rounded nominal
GPS headings at 22.5° intervals. Generation used the built-in image_gen tool,
the resident's master truck image, and individual generation calls for each view.
The exact final prompts and source provenance are in `truck-generation-manifest.json`.

## Flutter integration

`SundoDirectionalTruck` selects angle-specific artwork from the GPS heading plus
map camera rotation. It applies a screen-bearing correction for the illustrated
isometric projection and recenters each transparent silhouette. Use this widget
instead of treating the filename as the PNG's raw on-screen front bearing.
North is up; east is right. Known headings wrap across north. Missing headings
show a neutral front view and remain explicitly unavailable in marker semantics.
The existing GPS position interpolation and labeled local-demo route remain the
movement source. No sprite generates its own coordinates.

Views crossfade for 140ms while movement effects are enabled. Paused effects,
stale/stationary trucks and reduced-motion settings render without transitions.
Images decode at 256px for mobile map markers. Branding and side-view card truck
assets are unchanged. The old artwork's rim masks are not applied to new views.

`scripts/inspect-truck-directions.mjs` checks alpha, records silhouette bounds,
and measures the blue windshield / yellow compactor direction for calibration.
It produces a source contact sheet. `directional_truck_preview_test.dart`
produces the calibrated native Flutter preview, and map scene previews show the
marker in the existing map.

## Artwork limitation

These are generated multi-view approximations from bitmap references, not renders
of a shared 3D mesh. Small changes in roof framing, compactor details, perspective,
and projected dimensions remain. Several intermediate source images favor a
nearby three-quarter view; the Flutter calibration aligns their illustrated front
with the requested screen heading. This is a functional directional marker set,
but it does not guarantee identical geometry/camera at all sixteen yaw angles.
An exact production turntable requires one approved 3D truck model rendered at
all angles. Review `test/goldens/directional_trucks.png` for the shipped appearance.
