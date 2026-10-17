# Next session: v0.2 redesign to match the reference screenshots

Status: **work in progress, the build is broken.** The Kotlin bridge and pubspec are updated, but the Dart code is not yet.

## Already done (uncommitted at the time of writing, now in the WIP commit)
- Removed `shared_preferences`. In release builds it crashed at startup with `NoSuchMethodError: SharedPreferencesApiRegistrar.getAll` (it calls Kotlin through JNI and R8 strips the method). Favorites now go through the bridge: `getFavorites` / `setFavorites` in `MainActivity.kt`.
- Removed `dynamic_color` (the look is monochrome now) and the `icon` channel method (rows use dots, not icons).
- Bundled the Montserrat font (Light/Regular/Medium, OFL) in `assets/fonts/` and registered it in `pubspec.yaml`.

## Dart work still to do
- `native.dart`: drop `icon()`, add `getFavorites()` / `setFavorites(list)`.
- `apps_model.dart`: drop SharedPreferences and the icon cache, use Native for favorites.
- `main.dart`: drop DynamicColorBuilder. Dark monochrome theme, `fontFamily: 'Montserrat'`.
- `home.dart` / `rail.dart`: restyle to the measurements below.
- Update ADR 0002 (no pub plugins left) and the GLOSSARY Alphabet Rail entry (only letters that have apps are shown).

## Measurements from the Niagara reference screenshots
Phone: 1080×2316 px, density 450 (2.8125 px/dp), so the screen height H ≈ 823 dp.

| Element | Spec |
|---|---|
| Clock | Montserrat Light ~45 sp, left 45 dp, top ≈ 0.24·H |
| Date row (+ alarm) | ~15 sp, centre ≈ 253 dp |
| Glance block height | ≈ 0.367·H (first favorite row starts there) |
| App row (favorites + list) | 56 dp tall; grey dot Ø10 dp centred at x=67 dp; label ~15 sp Regular at x=110 dp, white |
| Section header | its own row, 48 dp tall, letter ~20 sp at x=48 dp, letter centre 31 dp from row top |
| No icons, no visible search bar, no scrim | search appears only on swipe-down |
| Alphabet Rail | ★ then **only letters that have apps** (no greyed ones); pitch 19.2 dp; ~16 sp white; centre x = W−30 dp; ★ centre ≈ 0.311·H |
| Rail touch: bend | letters bend left: dx = −88·exp(−d²/(2·95²)) dp, d = distance from finger |
| Rail touch: bubble | Ø44 dp light grey (#C8C8C8) circle, dark letter, just left of the bent letter at the finger's y |
| Rail touch: section view | the list is replaced by the active letter's section: header centred on ★'s y, apps below |
| Slide-to-launch | slide the finger left into the section and release on an app to launch it; a release on the rail jumps the full list so that section sits at the same y |

Reference screenshots are on the phone: `/sdcard/DCIM/Screenshots/Screenshot_20261017_12*_Niagara Launcher.jpg`.
