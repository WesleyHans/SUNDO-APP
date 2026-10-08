# SUNDO illustrated card icons

The Home weather, Today collection, and Next Collection cards use seven transparent
illustrations generated with the built-in `image_gen` tool. Each subject has soft
3D geometry, gently realistic material highlights, a clear silhouette, and no
text or date numbers. The collection illustrations use SUNDO green and cream;
weather uses blue, cream, and warm gold.

## Runtime assets

All files are in `flutter_sundo/assets/images/card_icons/`. Every asset is a
256 × 256 lossless WebP with a transparent background and a 16-pixel transparent
border. The total encoded size is 221,006 bytes.

| File | Subject | Bytes | Visible alpha occupancy |
| --- | --- | ---: | ---: |
| `weather_sun.webp` | Warm golden sun | 31,914 | 35.72% |
| `weather_moon.webp` | Creamy golden crescent moon | 28,990 | 28.97% |
| `weather_cloud.webp` | White and pale-blue cloud | 19,556 | 29.34% |
| `weather_rain.webp` | Cloud and three blue raindrops | 29,560 | 35.57% |
| `weather_storm.webp` | Blue storm cloud and gold lightning | 27,758 | 36.68% |
| `collection_today.webp` | Recycling bin with small clock | 37,502 | 38.83% |
| `collection_calendar.webp` | Green desk calendar with blank tiles | 45,726 | 54.72% |

The first and last decoded pixels have alpha 0 for all seven files. Alpha
occupancy counts every pixel with alpha greater than 0. This verifies that each
asset is a useful cutout with transparent margins rather than a solid square.

## Sources and generation prompts

The exact seven built-in prompts and stable source/runtime filenames are retained
in `scripts/card-icons-manifest.json`. Generation used one built-in call per
requested asset with `transparent_background: true`; it did not use the image API,
a CLI fallback, or hand-drawn vector substitutes. Original PNG masters were copied
into the local, ignored `output/sundo-card-icons/` directory. The matching raw
master for each asset has the same basename with a `.png` extension.

The original built-in images are preserved in their generated-images folder.
The source manifest in `output/sundo-card-icons/manifest.json` additionally records
their exact local source paths. No existing SUNDO logo or scenery artwork was edited.

## Packaging and review

Run `node scripts/package-card-icons.mjs` with the raw PNG masters available in
`output/sundo-card-icons/`, or pass a different source directory as the first
argument. The script uses Sharp to resample the whole image into a 224-pixel
content canvas and adds 16 pixels of transparent padding on all sides. It does
not redraw, recolor, or remove any part of the illustration. WebP encoding is
lossless after resampling. Generated alpha is preserved.

The script verifies dimensions, channels, transparent corners, and visible alpha
occupancy. It writes per-file SHA-256 hashes and byte sizes to the local
`output/sundo-card-icons/packaging-report.json` and creates
`output/sundo-card-icons/packaged-contact-sheet.png` for visual review.

All seven final WebPs were inspected composited against cream, pale mint, and
dark green at both 224-pixel and 44-pixel display sizes. Subjects remain distinct,
transparent edges are clean, and no background disc or badge is baked into the
image. The contact sheet orders icons as sun, moon, cloud, rain, storm, Today bin,
and Next Collection calendar. Its rows are cream, mint, and dark green.
