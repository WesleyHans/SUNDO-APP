# SUNDO reference design

The supplied twelve-screen reference guides the green palette, city/truck artwork, leaf accents, rounded panels and compact mobile layouts. Claymorphism is applied through sculpted gradients, rim highlights, layered soft shadows and rounded controls.

- New Flutter splash and welcome screens: `flutter_sundo/lib/screens/clay_splash_screen.dart` and `clay_welcome_screen.dart`.
- Shared Flutter scenery: `flutter_sundo/lib/widgets/scenic_backdrop.dart`.
- The React website is now a responsive APK-only installer landing page with the matching clay city artwork. Browser simulation screens were removed.
- The generated city illustration is saved at `flutter_sundo/assets/images/clay-city-hero.png` and `public/clay-city-hero.png`.
- Native screens are rendered by `flutter_sundo/test/design_preview_test.dart`; preview PNGs are in `flutter_sundo/test/goldens`.
- Bundled Outfit and Plus Jakarta Sans fonts keep the native interface independent of font downloads. Their OFL licenses are included alongside the font files.

The illustration was created with the built-in image generation tool using this prompt:

> Production portrait background for SUNDO, inspired by the supplied reference: a green municipal recycling truck on a clean Sipalay road, rounded clay foliage, lime and emerald trees, pale cyan city buildings, warm sunshine, cream clouds and spacious pale blue sky for headings. Matte sculpted materials, soft bevels and ambient shadows. Truck and city in the lower half, foliage at the bottom corners. No phone frame, UI, written words or watermark.

Deployment is tracked through GitHub/Vercel; see the latest deployment status rather than treating local files as deployed. Browser inspection was declined by the permission system for both the deployment and local web preview. Web validation therefore consists of TypeScript checks and a successful production build; native visual verification uses rendered Flutter screens.
