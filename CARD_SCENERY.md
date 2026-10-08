# Home card scenery

Version 1.5.10 integrates the generated scenery into real Flutter Home cards. Weather uses the riverside bridge, tomorrow's collection notice uses the residential street, and Next Collection uses the city park. The existing card arrangement, rounded clay surfaces, icons, schedule values and actions remain.

The 24 images are bundled at `flutter_sundo/assets/images/card_scenery/`, with eight fixed-composition variants per location. The three noon references were preserved unchanged; the other images were generated as separate lighting/weather edits of those masters. Main landmarks align visually, although fine foliage, paving, windows and water textures can vary slightly. `scripts/package-card-scenery.mjs` converts the PNG set to lossless WebP and checks decoded RGBA pixels against every source image. Packaging retains the original 1672×941 riverside and 1024×1536 portrait canvases, using 40,317,680 compressed bytes in total.

## Selection

`sundo_card_scenery.dart` selects the current card scene using the existing Philippine clock and fresh Open-Meteo weather. Greeting wording remains independent of scene selection.

| Condition / Philippine time | Card image |
| --- | --- |
| Fresh rain, drizzle or thunderstorm | Rainy, with image-only dimming after dusk and at night |
| Before local solar sunrise, or 7 PM onward | Night (rain retains the wet artwork with night lighting) |
| Fresh cloudy conditions outside full night | Cloudy, dimmed at 6 PM and further at 6:30 PM |
| Sunrise to 10:59 AM, clear or weather unavailable | Morning |
| 11 AM to 4:59 PM, clear or weather unavailable | Noon |
| 5 PM to 5:59 PM, clear or weather unavailable | Sunset |
| 6 PM to 6:29 PM, clear or weather unavailable | Early Evening |
| 6:30 PM to 6:59 PM, clear or weather unavailable | Evening |

Expired weather returns to the time-based image. The existing minute ticker updates these boundaries while Home is open and refreshes after the app resumes. No weather-provider or permission changes are needed.

## Rendering

Each card keeps the same `BoxFit.cover` and bottom alignment across all variants. The new image decodes before replacing the current frame, then crossfades for 900 ms; a late first image also fades into the clay surface. Superseded requests cannot replace a newer target, errors keep the current frame, and listeners are released on disposal. Reduced-motion settings use zero animation duration. Rain/cloud lighting wraps only the background image.

Day/night scrims and darker scenic secondary text preserve readability without removing the background image. Footer and time chips have their own protected surfaces. Splash, Welcome, Login, outer-page art, map surfaces and leaf placement use their existing implementations.

Tests cover Philippine time boundaries, solar sunrise, midnight greeting, fresh/stale weather, all 24 asset decodes, night-sky luminance, deferred first frames, retained old frames, superseded requests, reduced motion and actual Home integration. Native Home preview cases include all eight states, compact width and larger text. Physical phone performance remains a separate check.
