# SUNDO mobile status

## Version 1.5.11 Today and steady compact weather

Home's left card now shows **Today** with the selected area's actual schedule,
times and published statuses. **Next Collection** selects the next nonterminal
pickup after today's Philippine calendar day. Completed and cancelled rows
remain truthful on Today; the app does not infer completion from elapsed time.
Live timestamps convert once to UTC+8 while demo calendar fields remain local.

Weather and collection cards use seven transparent 3D illustrations matching
the existing SUNDO palette. The Weather card stays **84 logical pixels** high
through fresh, stale, unavailable, checking and disabled states. Tapping its
short summary opens scrollable weather details with the full location,
model-based source, actual observation age and any rain caution. Details retain
the original system text size; the compact summary caps scaling at 1.5.

Weather checks automatically every five minutes in the foreground and on
resume. Overlapping checks share one request. Brief failures retain same-place
observations only while fresh; changed location, revoked access or expired
weather still falls back to the clock. A permission/resume race is covered.
The existing provider, dynamic scenery, smooth fades, map and protected
Splash/Welcome composition remain unchanged.

GitHub run `37728091322` at
`5a825789cb98c5045f22cbdfcd326be46ed1b486` passed Flutter analysis, all **358
tests**, APK compilation and **84 native preview tests**. The final Home,
compact, rain/storm and details captures were visually reviewed; 22 native
Home/weather previews are saved. Widths 320/390 and text scaling up to 2.0
are covered. Installer TypeScript checks and production compilation pass.
PR #14 merged at `a4e8e6735d35d0a2ea4713a2a8e3f9bc00d438d8`; merged runtime
files match the tested source. Physical-device frame rate is not certified.

Android version is **1.5.11+19**. The signed APK is **135,371,064 bytes** with
SHA-256 `bb97a07a80fae488f27836dc8c7db5d7be94e2f0295feeef5b59841390d51e7b`.
APK v2/v3 signing verifies with the same update certificate as v1.5.10,
`9aef25a031654e9ccfe2b4579915b527e215686a1812b87ac0c26a033fbd2a6a`.
16 KB ZIP alignment passes; package `com.sundo.sipalay`, code 19, minimum
API 24, target API 36 and ARM64/ARMv7/x86_64 support are verified.

The published [v1.5.11 release](https://github.com/WesleyHans/SUNDO-APP/releases/tag/v1.5.11)
reports the same **135,371,064-byte** size and SHA-256 as the verified local
package, with status `uploaded` and filename `SUNDO.apk`.

## Version 1.5.10 dynamic Home card scenery

The three Home cards now render the synchronized 24-image scenery set in real
Flutter widgets: a riverside and bridge for Weather, a residential street for
the tomorrow notice, and a city park for Next Collection. Each scene includes
Morning, Noon, Sunset, 6 PM Early Evening, Evening, Night, Cloudy and Rainy.
The original card layout remains, with readable cream/day and dark/night
overlays and protected time/footer chips.

Philippine time selects 5 PM sunset, 6 PM early evening, 6:30 PM evening and
full night from 7 PM until local sunrise. Fresh rain and cloud observations
select weather imagery; stale weather falls back to the clock. Cloudy
conditions cannot restore daylight at night, and rainy imagery dims after
dusk. The midnight greeting still says Good Morning with nighttime scenery.

Images decode before replacing the current frame, then crossfade over 900 ms.
First frames fade in; rapid updates invalidate obsolete requests, and reduced
motion suppresses animations. The existing weather provider, map and protected
Splash/Welcome composition are unchanged.

All 24 lossless WebPs match their source PNGs' decoded pixels. GitHub run
`37709015618` passed analysis, all **331 tests**, APK compilation and **72 native
preview tests**. All eight actual Home states, compact width and large text
were visually reviewed. Installer TypeScript checks and production build pass.
PR #13 merged at `683ab12a9afc01150b5ffd7e608777f6bee8037f`; runtime files match
the tested source commit `b14323328dbca5c1e5c7b796eab57100997dfc7f`.

Android version is **1.5.10+18**. The signed APK has **135,067,178 bytes** and
SHA-256 `9111c0510badb302e39894a80a2da688f3b6d98116635dd0747b9bfa4fbb01e3`.
APK v2/v3 signing verifies with the established update certificate
`9aef25a031654e9ccfe2b4579915b527e215686a1812b87ac0c26a033fbd2a6a`.
16 KB ZIP alignment passes; package `com.sundo.sipalay`, version code 18,
minimum API 24, target API 36 and ARM64/ARMv7/x86_64 support are verified.
Physical-device rendering performance is not certified by native previews.

The published GitHub `v1.5.10` asset reports the same **135,067,178-byte** size
and SHA-256 as the verified local package, with status `uploaded` and filename
`SUNDO.apk`: [release and APK](https://github.com/WesleyHans/SUNDO-APP/releases/tag/v1.5.10).

Production installer deployment `dpl_wA8rD8fr4LKpAb1cs6HBxwi7oAfz` is **READY**
at [sundo-app.vercel.app](https://sundo-app.vercel.app). Public checks return
HTTP 200 for the installer and its JavaScript bundle containing Version 1.5.10.
Both `/download-apk?v=1.5.10` and `/SUNDO.apk?v=1.5.10` return HTTP 200 with
`application/vnd.android.package-archive`, the complete **135,067,178-byte**
package and `attachment; filename=SUNDO.apk`. Installer source was published
at commit `a6527544ff7402a7970ad0d49ed096c011fd0303` before deployment.

## Version 1.5.9 evening twilight and full night

The former night image is preserved byte-for-byte as evening twilight and is
still used at 6 PM. Clear/time-only scenery selects the new user-supplied
blue moon-and-stars artwork from exactly 7 PM Philippine time until local
sunrise. The original decode gating and 900 ms fade handle the change.
Rain retains its existing rainy-night artwork and lighting.

The new 1024 x 1536 image was packaged losslessly and verified against the
source PNG's decoded pixels. Splash paints its extra small moon only during
twilight, avoiding a duplicate moon over the new artwork. Branding, leaves,
card and scenery framing remain fixed; the existing branding plate may cover
the artwork's higher moon on compact phones. Greeting wording, the 5 PM warm
inner surface, weather provider and functional map behavior are unchanged.

Android version is **1.5.9+17**. The local Dart executable is blocked by this
computer's Device Guard policy; validation and compilation use the existing
GitHub workflow. Run `37633389830` succeeded: Flutter analysis reports no
issues, all **305 tests passed**, the APK compiled and native previews rendered.
The actual 6 PM and 7 PM Splash previews were reviewed with branding and leaf
placements preserved. Installer TypeScript checks and production compilation
pass. Publication uses local signing with the established update certificate.

PR #12 merged at `5b49e34bf7dea738e130409d5d0f180e154e3915`.
The locally signed APK has **94,689,653 bytes** and SHA-256
`19c6da9031e559bb352621f141a21ed158e0bc08f044cfc0039c2ef5ea93c2ed`.
APK v2 signing verifies with certificate
`9aef25a031654e9ccfe2b4579915b527e215686a1812b87ac0c26a033fbd2a6a`,
matching previous releases. 16 KB ZIP alignment passes; package
`com.sundo.sipalay`, version code 17, minimum API 24, target API 36 and
ARM64/ARMv7/x86_64 support are verified. Both backend build variables were
empty, retaining the existing local demo configuration.

The published GitHub `v1.5.9` release asset reports the same **94,689,653-byte**
size and SHA-256 as the verified local package. Its downloadable filename is
`SUNDO.apk`: [release and APK](https://github.com/WesleyHans/SUNDO-APP/releases/tag/v1.5.9).

Production installer deployment `dpl_DCgnDUGV4hVv8XqPqwrutAgtUkry` is **READY**
at [sundo-app.vercel.app](https://sundo-app.vercel.app). Public checks return
HTTP 200 for the installer and its JavaScript bundle containing Version 1.5.9.
Both `/download-apk?v=1.5.9` and `/SUNDO.apk?v=1.5.9` return HTTP 200 with
`application/vnd.android.package-archive`, the complete **94,689,653-byte**
package and `attachment; filename=SUNDO.apk`. Installer source was published
at commit `52057c6` before this production deployment.

## Version 1.5.8 inner sunset tint

Inner-page backgrounds acquire a faint warm yellow/cream wash from 5 PM until
calculated local sunset. Rain keeps a more muted warm surface. The surface fades
over 900 ms and follows the current Philippine time even when the next scene
image is delayed. Night restores the existing dark surface. Card surfaces,
functional map surfaces and the full Splash/Welcome artwork are unchanged.
The midnight greeting and independent daylight rules from 1.5.7 remain.

Flutter analysis reports no issues and all **298 tests passed**. Four new native
tests verify the 5 PM surface fade while artwork is delayed, night restoration,
shared tint and fixed leaves across resident tabs, unchanged full-scene pixels
and opaque functional map surfaces. Installer TypeScript checks and production
compilation pass. Android version is **1.5.8+16**.

The release APK has **93,311,434 bytes** and SHA-256
`1460bccb474bcf4b91afeae728bd8d652feafdddd2d75749983e4ff59a387666`.
APK v2 signing verifies with the same published certificate
`9aef25a031654e9ccfe2b4579915b527e215686a1812b87ac0c26a033fbd2a6a`;
16 KB ZIP alignment passes. Package `com.sundo.sipalay`, minimum API 24,
target API 36, and ARM64/ARMv7/x86_64 support remain unchanged.

PR #11 merged at `26faaeeb0e5e095feae0c8580cc1ea8e99594704`.
The published GitHub `v1.5.8` asset reports the same byte count and SHA-256
as the verified local package.

Production installer deployment `dpl_GToAf3iGwE6o7u5p8VoBe5me7d4A` is READY
at `https://sundo-app.vercel.app`. Public checks return HTTP 200 for the site,
the JavaScript bundle with Version 1.5.8, and both `/download-apk` and
`/SUNDO.apk`. Both downloads return the complete 93,311,434-byte Android
package with filename `SUNDO.apk`. Independent GitHub run `37604840056`
succeeded for the merged mobile source, building the APK and native previews.

## Version 1.5.7 Philippine greeting and daylight

Greetings use Philippine Standard Time independently of the phone timezone:
Good Morning from midnight, Good Afternoon from noon and Good Evening from
6 PM. The greeting never controls sunlight. Scenery, clear-weather icons and
the Home sun/moon use estimated local sunrise/sunset by calendar date and the
permitted resolved area, with Sipalay as the offline default. Night remains
through the early morning until sunrise; sunset artwork starts at the requested
5 PM and night starts at calculated sunset. Resolved area coordinates remain
available for daylight when the current weather response expires or fails.

Solar times use offline NOAA equations checked against independent USNO
fixtures. Seasonal, leap-day, timezone and invalid/polar-input cases are covered.
No new dependency, network call or location permission is needed. Open-Meteo
remains the weather provider, with its existing consent and freshness checks.

Scenery replacements still use the existing fades. If an image delays or fails
across sunrise/sunset, a neutral current-mood surface replaces obsolete
day/night artwork. Late initial image decoding applies the latest lighting.
Warm rainy scenery begins at 5 PM instead of 3 PM. Branding, leaf placement,
dashboard layout, Login/Welcome/Splash composition and map behavior are preserved.

Flutter analysis reports no issues and all **294 tests passed**. The 17 solar
tests compare seasonal reference times, leap/year boundaries, literal calendar
fields and fallback behavior. Clock and widget tests verify midnight greetings
with a moon, exact 5 PM sunset, sunrise/sunset lighting, retained resolved areas,
late lighting updates and safe scenery replacement. Installer TypeScript checks
and production compilation pass. Android version is **1.5.7+15**.

PR #10 merged at `9290dcb89a2f20fa46c6d1316d1e296db21d177f`.
The verified local APK has **93,311,434 bytes** and SHA-256
`b3167a7a05194912378dbe191c707dd025994ed9160ae3af60e59474ce28f3d4`.
Its v2 signature and 16 KB alignment checks pass. Package `com.sundo.sipalay`
uses version code 15, minimum API 24 and target API 36, with ARM64, ARMv7 and
x86_64 libraries. Certificate SHA-256
`9aef25a031654e9ccfe2b4579915b527e215686a1812b87ac0c26a033fbd2a6a`
matches the previously published APKs.

GitHub release `v1.5.7` contains `SUNDO.apk` with the identical uploaded
SHA-256. Vercel production deployment `dpl_DsZiwaCkUPwWDy2BFdMVuh6rP3hH`
is ready and aliased to `https://sundo-app.vercel.app`. Public HTTP checks on
7 October 2026 return 200, confirm the installer bundle displays Version 1.5.7,
and follow `/download-apk?v=1.5.7` to the complete 93,311,434-byte APK with the
Android package content type and `SUNDO.apk` attachment filename.

Independent GitHub Actions run `37580598187` completed successfully for the
merged 1.5.7 mobile source, including analysis, tests, APK build and native previews.

## Version 1.5.6 reference Home dashboard

Home now follows the supplied soft green/cream clay dashboard: greeting and
circular account controls, decorated weather card, two balanced collection
cards, and a featured truck card with route scenery, progress and its primary
action. The bottom navigation retains all five destinations with a rounded
surface and green active pill. Existing location and shortcut cards remain
below the main feature. Collection cards become full-width at larger text sizes
instead of squeezing their content into narrow columns.

Reusable Flutter widgets paint faint cloud/leaf/route decorations beneath real
text and controls. A shared 18-second decorative clock pauses off Home, in
background, when TickerMode is disabled and for reduced-motion preferences.
Card entrances finish once; fleet/weather refreshes do not replay them. Buttons
use a small press response, and the current-update chip has a gentle pulse.

Philippine-time greeting, current weather freshness, resident-area schedules and
fleet values remain connected to existing data. The demo notice and simulated
collection label stay explicit; unavailable/stale data does not acquire invented
metrics. Weather refresh still uses the existing consent and refresh callback.
The truck and natural corner-leaf assets, Splash/Welcome composition and Live
Map decoration rules are preserved.

Flutter analysis reports no issues, and all 269 tests passed. Dedicated native
dashboard tests cover 390/320 px, increased text, data states, navigation,
entrance stability and lifecycle/reduced-motion pause behavior. Installer
TypeScript checks and production compilation pass. All 22 existing day/night
screen preview checks pass; three dedicated dashboard captures were visually
reviewed at regular/narrow widths and increased text. Android version is 1.5.6+14.

The final native dashboard checks also verify full resident names with 1.5x
text and whole progress-label glyphs at 250/320 px. PR #9 merged at
`75a1893818c267104b3e23960642d720eabd3cb3`.
The final local APK has 93,229,514 bytes and SHA-256
`b42660ed69bd4e68c847ac9e89e6bcffd06baf53d1093a6fee7c0d5b6b9d4016`.
APK signature verification and 16 KB alignment checks pass. Package
`com.sundo.sipalay` uses version code 14, minimum API 24 and target API 36,
with ARM64, ARMv7 and x86_64 libraries. Its certificate SHA-256
`9aef25a031654e9ccfe2b4579915b527e215686a1812b87ac0c26a033fbd2a6a`
matches the previous locally published releases.

GitHub release `v1.5.6` contains the APK with the matching uploaded SHA-256.
Independent GitHub Actions run `37570204039` completed successfully for the
merged mobile source. Vercel production deployment
`dpl_HkE2dRLas2D67MR2fPCzJzeByj5t` is ready and aliased to
`https://sundo-app.vercel.app`. Public HTTP checks return 200, confirm the bundle
displays Version 1.5.6, and follow the installer download to the complete
93,229,514-byte `SUNDO.apk`. Deployment used Vercel CLI 62.4.0 with the existing
configured account after verifying its SUNDO project access.

## Version 1.5.5 screen and scenery motion

Login, Create Account and page navigation now use gentle fades. One shared
background remains mounted across inner routes and tabs; leaving Splash or Welcome
reveals that scenery together with the new content. A late decoded image fades in,
including full-scene artwork, while weather scene handoffs retain their 900 ms
transition. Reduced-motion settings show ready content immediately. Report
push/pop also fades the departing page instead of removing it abruptly.
Resident tabs retain their scroll/form/map state through a 140 ms fade-out and
260 ms fade-in; rapid selections settle on the last requested tab.

The fixed empty 88/120 px top bands are removed from Profile, Schedule, Alerts and
Report. Actions and filters scroll with the content. Corner leaves keep their
existing asset, sizes and positions; Live Map stays leaf-free. Splash and Welcome
artwork, branding and source layout remain unchanged.

Home adds a compact announcement for tomorrow's collection in the resident's area,
using Philippine calendar dates and the schedule repository. Demo schedules stay
explicitly labeled. Its small map uses an already permitted foreground GPS fix;
it never opens a new permission prompt. Current markers expire after one minute.
Saved-area views are labeled as not current GPS and have no current-location pin.
GPS refreshes pause off Home/in the background, reject retired results, and reuse
a pending native request across quick tab changes. Scenery and mini-map tiles fade
without changing their final geometry.

Android version 1.5.5+13 retains the existing package and signing configuration.
Validation: Flutter analysis is clean, all 260 regression tests passed, and 69
native preview checks passed for auth, Splash, day/night layouts, larger text,
keyboard editors, scrolling controls and leaf-free maps. Installer TypeScript
checks and the production build pass. Native previews use controlled data and do
not certify physical phone GPS or remote city services.
Verified APK: 1.5.5+13, 93,196,594 bytes, SHA-256
`72d810774cc411b90401beb0c49f8670219e02977f54afb945b0babff6cc7e4f`.
APK signature verification and 16 KB alignment checks pass. Certificate SHA-256
`9aef25a031654e9ccfe2b4579915b527e215686a1812b87ac0c26a033fbd2a6a`
matches previous local SUNDO releases. Package `com.sundo.sipalay` targets API 36
with minimum API 24 and includes ARM64, ARMv7 and x86_64 libraries.
PR #8 is merged at `2d16b76189838e9808f68bf8b882e412e22d1e83`.
GitHub release `v1.5.5` contains the APK with the matching uploaded checksum.
Installer labels and all APK redirects now target that verified release.
Independent GitHub Actions run `37460889887` completed successfully for the
merged mobile source. Vercel production deployment
`dpl_4ikfnrbxKFgo9RQnXMEDhzVwiQxd` is ready and aliased to
`https://sundo-app.vercel.app`. Public HTTP checks return 200 for the installer,
confirm its bundle displays Version 1.5.5, and follow the download redirect to
the 93,196,594-byte Android package named `SUNDO.apk`.

## Version 1.5.4 reference leaf placement

This release builds on the restored 1.5.1 checkpoint. It reuses the original
transparent natural leaf asset and keeps Splash and Welcome branding unchanged.
Splash restores two leaves entering from its edges. Login's upper leaf begins in
the status-bar corner, matching the supplied phone reference. Corner stems extend
outside the viewport intentionally; the visible artwork is clipped to the screen.
Leaf sizes and offsets are recovered from the original layout in commit `72cfe29`;
the leaf PNG itself is unchanged.
Login and registration use fixed corner decorations independent of form scrolling.
Home, Schedule, Alerts, Profile and Report use consistent upper-right and lower-left
leaves behind their controls. Resident page-title bars are removed; refresh, filters,
back navigation and profile editing remain available. Live Map has no leaves.
North/route-fit controls remain at the upper left; the redundant route-fit button
was removed from the right column so its remaining controls clear the tracking panel
on short phones.
One shell safe area avoids applying the status-bar inset twice.

The checkpoint's weather freshness, Philippine-time greetings, shared scenery fade,
default route transitions, retained navigation tabs and truck tracking are unchanged.
Android version 1.5.4+12 allows installation over the earlier releases.

The UI audit also fixes larger-text Welcome overflow, photo button clipping,
keyboard space in Report, scrolling in announcement/reminder dialogs and the
premature disposal of profile/city editor controllers during closing animations.
Staff/driver cards use readable night surfaces; city forms display required-field
errors and map labels stay compact. Welcome's normal branding and control positions
remain unchanged, with larger touch targets and keyboard activation for its buttons.
The scenery behind enlarged Welcome text is softened to keep its message readable.

Validation: Flutter analysis is clean; all 227 tests passed. Another 60 native
preview checks passed, including the supplied leaf arrangement, day/night screens,
small phones, enlarged text, keyboard editors, dialogs and leaf-free map controls.
Verified APK: version 1.5.4+12, 92,999,914 bytes, SHA-256
`f62e4803e8a07d59aa87dd57012e8131cdd8eda459bec9046357e7400c40a8a1`.
Its signing certificate matches previous locally signed SUNDO releases.
GitHub release `v1.5.4` contains the matching uploaded APK digest. PR #7 is merged,
and GitHub Actions run `37444870779` passed its independent Android build and
preview checks. The installer passed TypeScript checks and its production build.
Vercel deployment `dpl_2a4oqQfaxMPuXb26M8g4XCtBiFte` is ready under the
`wesleyplatil20200244-7046` account, with `https://sundo-app.vercel.app` assigned
as its production URL. All APK download redirects point to `v1.5.4`.
Production is deployed through the authenticated CLI. Automatic GitHub linking
remains pending: Vercel's project-link API requires installation of the Vercel
GitHub App with access to `WesleyHans/SUNDO-APP` (`https://github.com/apps/vercel`).

## Version 1.5.3 restores the complete 1.5.1 checkpoint

The resident app source, assets and tests match checkpoint
`2a482eedc25a4c3afa84834ea705e42ec34cc83f`. This restores the 1.5.1
layout, leaves, navigation and scenery behavior, including its Philippine-time
greetings and weather freshness fixes. Changes introduced by 1.5.2 and the
unfinished corner-leaf work are removed. Android packaging uses version 1.5.3+11
so residents can install the restored behavior over version 1.5.2.

Validation: Flutter analysis clean and all 198 tests passed. Runtime source,
assets, tests, dependency lockfile, platform files and workflow files compared
directly with the checkpoint and contain no differences.
Verified APK: version 1.5.3+11, 92,917,994 bytes, SHA-256
`05fff5d44a3811184c0695ae3283155f69316c8bcf2eb5b61ff2136751920eee`.
The signing certificate matches the existing installed SUNDO releases.

## Version 1.5.1 weather, scenery and Philippine time fixes

Production greetings and scenery use Philippine Standard Time (UTC+8), independent
of the phone timezone. Good Morning runs 05:00–11:59, Good Afternoon 12:00–17:59
and Good Evening 18:00–04:59. The brighter noon scene still begins at 11:00.
Weather age uses the actual instant, without shifting its timestamp by eight hours.

Instantaneous WMO weather codes determine rain, drizzle and thunderstorms.
Accumulated precipitation no longer overrides clear/cloudy conditions. Weather
refreshes every five minutes while foregrounded; server observations expire after
20 minutes and unsuccessful fetches cannot retain a snapshot beyond ten minutes.
Home offers a manual refresh and explicitly shows unavailable weather while using
time-based scenery. The provider supplies model-based area estimates, not a
guaranteed measurement at the resident's exact spot.

Secondary screens use softer backgrounds. The scenery fade uses one shared alpha
mask to avoid midpoint flashes; expired rain transitions to neutral scenery even
if the dry asset fails to decode. Header leaves stay inside their own app bars and
splash leaves stay within safe bounds. Logo/title/subtitle/card geometry is unchanged.

Validation: Flutter analysis clean and all 198 tests passed. Native Schedule previews
cover clear/cloudy/rain with 32 px system inset and 1.4× text on a 320 px phone.
Splash checks preserve brand/card geometry across environments. Regression checks
cover timezone offsets, noon greetings, stale weather, offline retry and failed
dry-scene decoding. Android release version is 1.5.1+9, 92,917,994 bytes, SHA-256
`7dc433e57e776bdb3500f16282f649edbf59fe20329023de68deff17893cb735`.
The verified signing certificate matches the existing locally signed Android releases.

## Version 1.5.0 directional marker update

Sixteen generated transparent views replace the map's single-sided vehicle.
The marker selects views from GPS heading plus camera rotation, corrects each
illustration's projected bearing, recenters its silhouette and crossfades views.
Existing position interpolation, unknown/stale telemetry and paused animation
behavior are retained. The source PNGs are approximate multi-view artwork; see
`TRUCK_SPRITES.md` for the geometry/perspective limitations. Branding stays fixed.

Validation: Flutter analysis clean, 191 tests passed, all sixteen PNGs checked for
alpha and windshield/compactor color regions, five native directional/map preview
checks passed. APK 1.5.0+8: 92,852,458 bytes, SHA-256
`119355e3a0480f2a3e0944919648ab7b7b4e1b26fd378aa9cc738817a471689d`.
Signing certificate matches the existing local Android APK. Fleet data remains
demo until the city Supabase service is configured.

## Earlier 1.4.0 baseline

Open `flutter_sundo` as the Flutter project. The current Android release is **1.4.0+7**, with optional local weather before login, combined rainy-night scenery and supplied moving truck artwork. Splash branding remains unchanged. Source validation, APK publication and production deployment are separate steps.

## Resident functionality

- Native Flutter splash, welcome, register, login and five main tabs: Home, Live Map, Schedule, Alerts and Profile. Report Concern opens from Home.
- Clay cards, green controls, supplied logo and illustrated backgrounds. Working source now selects morning (05:00–10:59), noon (11:00–14:59), afternoon/sunset (15:00–17:59) and evening/night (18:00–04:59) scenes; time and greetings refresh every minute and when the app resumes.
- Five supplied matching scenes are bundled as lossless WebP. The splash logo, wordmark, subtitle, branding colors/positions, decorative leaf frames and bottom slogan card stay static while only the environment fades over 900 ms. Reduced-motion settings switch the scene immediately. Detailed transparent natural leaves replace the painted leaves without changing their frames. Shared backgrounds use continuous alpha feathering rather than a cut-off 220 px image band; Home removes repeated image strips and its doubled demo status-bar inset.
- Version 1.4.0 offers local weather before login, with an explanation, native foreground permission request and phone Location settings. Device coordinates are validated, rounded to approximately 0.01 degrees and sent to Open-Meteo only after enabling weather; they are not persisted. A genuinely saved Sipalay address offers labeled city-level fallback. Otherwise weather remains unavailable and backgrounds use time. The Profile Location Permission sheet can disable weather independently of map permission.
- Current model conditions distinguish clear, cloudy, rain, drizzle and thunderstorms. Wet daytime and wet night atmospheres retain the same scene composition while respecting time; branding remains unchanged. The compact Home banner names its area/source/update age and optional collection rain caution. Foreground polling runs every five minutes. Failed, malformed, unsupported and stale data produces time-only scenery rather than an invented weather reading. Account changes, revocation, backgrounding and opt-out invalidate pending responses.
- Local demo registration/login with email or Philippine mobile number, duplicate-account validation, confirmed passwords and remembered sessions. Credentials use Flutter Secure Storage; account data uses scoped local storage. This does not authenticate a city account.
- Home shows the selected resident area's next published/sample pickup, the shared truck state, unread alerts and working shortcuts.
- Real OpenStreetMap tiles centered on Sipalay, attribution, zoom/recenter/route-fit controls, north reset, read-only route display, raised clay collection landmarks and a draggable tracking sheet. The default 3D view projects the map into perspective; the 2D control returns to a flat view. Raised symbols do not represent actual building heights or terrain meshes.
- Watch follows a fresh truck position. One simulated truck moves smoothly through sample A/B/C routes and turns using the shortest arc across north. Animated chevrons show direction along supplied route geometry; collection beacons add motion. Simulated ETA, route and status are labeled as demo data. Live mode uses actual fleet data and keeps unknown ETA/route information unavailable.
- Version 1.4.0 uses the supplied angled truck on the map and side view for collection icons across cards, alerts, schedules, notifications and staff operations. Both original PNGs are copied byte-for-byte. The original silver rims rotate only during interpolation between fresh source positions. Body/tires and branding are unchanged. Unknown heading remains unknown until a source heading or two positions establish direction.
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

## Environment update — 1.3.0 validation

After the repository moved to WesleyHans, [cloud build 37323368457](https://github.com/WesleyHans/SUNDO-APP/actions/runs/37323368457) passed Flutter analysis and **all 132 tests**, including exact time boundaries, rain/freshness fallback, foreground polling, fixed splash branding/card geometry, scenery fades, backdrop seams and narrow Home layout. The first cloud run exposed weather cleanup during widget disposal and test cleanup/timing issues; these were fixed before this successful build.

The same run built the APK and passed all nine splash tests again while rendering five native previews. Morning, noon, sunset, night and rainy previews were visually reviewed. The compact 320x640 framing can hide the moon behind the fixed branding plate. Physical-device validation remains pending. Local Windows Application Control still blocks Flutter's compiler; the build used GitHub's Linux runner without changing that policy.

The final APK was re-signed locally using the existing development key so it can update 1.2.1. Its signature verifies, its certificate matches the previous APK, and package metadata confirms `com.sundo.sipalay`, version 1.3.0, code 6, minimum API 24 and target API 36. Size: **72,163,846 bytes**. SHA-256: `df87ee7265bb2ef3aa579c788e27b41baf83e105a6acc4cbbc8810a173645988`. [Release and APK](https://github.com/WesleyHans/SUNDO-APP/releases/tag/v1.3.0).

The workflow retains reviewed APKs as artifacts and never automatically publishes a runner-signed APK. Before publication, use the existing local signing key and verify the resulting certificate/version/checksum. The key is not uploaded to GitHub.

## Local weather and supplied truck update — 1.4.0 release validation

Flutter analysis reported **no issues** and all **190 tests passed locally**. The compiler now runs through the normal Flutter SDK on this Windows computer. Tests include pre-login consent held across the splash timer, GPS-off settings, permission-dialog resume ordering, no pre-consent requests, opt-out, denied/invalid/stale GPS, saved-area fallback, account isolation, out-of-order responses, rainy-night selection and small-screen weather controls.

Another **49 native preview tests passed** while rendering resident screens, seven splash atmospheres, map views, supplied truck rims and Home weather at 320 px with increased text size. The map preview explicitly waits for the truck PNG to decode before capture. Supplied truck pixels, wheel-only rendering changes, fresh source position movement, unknown headings, paused effects, system reduced motion and inactive/background behavior have regression coverage. The previews were visually reviewed. They use local fixture map tiles and test-controlled weather; physical GPS/weather and remote Supabase workflows still need phone validation.

The locally compiled APK verifies with the same certificate as 1.3.0: SHA-256 `9aef25a031654e9ccfe2b4579915b527e215686a1812b87ac0c26a033fbd2a6a`. Package metadata confirms `com.sundo.sipalay`, version 1.4.0, code 7, minimum API 24 and target API 36. Size: **74,878,282 bytes**. APK SHA-256: `d092a469e2eaf7ce0b13515c93a31361d718526b10854461c9834cbaa0e86042`. GitHub reports the identical uploaded digest. [Release and APK](https://github.com/WesleyHans/SUNDO-APP/releases/tag/v1.4.0).

The installer passed TypeScript checks and Vite production compilation. On 6 October 2026, Vercel confirmed production deployment `dpl_7AqHuBjiURhYq2bCM2mLPkYBUXzL` as **READY** and aliased it to [sundo-app.vercel.app](https://sundo-app.vercel.app) under the transferred SUNDO (`sundo3`) team. Project authentication protection remains preview-only. The installer displays 1.4.0 and all APK aliases target the published 1.4.0 asset; primary download redirects use no-store headers. Production readiness and alias were verified through Vercel metadata; a live browser download was not part of this check.

The automatic [Linux build 37350772047](https://github.com/WesleyHans/SUNDO-APP/actions/runs/37350772047) then passed analysis, all **190 tests**, APK compilation and **27 additional preview tests** for merged commit `1341b4555606d3baece7ee91ee7539360109c7c0`. It retained APK and preview artifacts. The public download continues to use the locally verified APK with the existing certificate, rather than the runner's differently signed artifact.

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

The configured GitHub Android workflow performs the same analysis/tests before retaining its build artifact. The former owner's billing lock blocked earlier runs; builds run successfully under WesleyHans following the repository transfer. Release publication follows local signing and verification.

## Local verification for 1.2.1

Flutter analysis reported no issues and all **90 mobile tests passed**, including startup retry, account scope, GPS freshness, perspective controls, transformed map gestures, smooth heading/route interpolation, HTTP and decoded tile caching, day/night provider retention, visual pause with continuing truck updates, lifecycle resume, schedules and responsive layouts. The APK installer passed TypeScript checks and production compilation.

The Android release build completed as `com.sundo.sipalay`, version 1.2.1 (code 5), minimum Android 7.0/API 24. Its APK signature verifies with the Android development certificate. The 62,676,423-byte APK has SHA-256 `f3180c7824ef418da21868dba1b6e48d8c92b23e1039bd5dee86718a2f00e0db`.

Native previews are [the map](map-preview.png), [daylight resident screens](resident-design-day.png), [evening screens](resident-design-night.png) and [day/evening comparison](design-preview.png). Map previews use clearly labeled synthetic test tiles; they validate native rendering and interaction without claiming real map-server or physical GPS verification. The installed app uses OpenStreetMap. No remote backend or physical-device test is certified by these local checks.
