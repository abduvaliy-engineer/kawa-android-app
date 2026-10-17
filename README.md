# Kawa Launcher 川

A minimal, list-based Android home screen. *Kawa* (川) is Japanese for "river".

- **Offline by design.** The app has no `INTERNET` permission, so it can't go online at all.
- **Glance:** clock, date and your next alarm.
- **Favorites:** a short text-only list of pinned apps.
- **App List:** every app A–Z, with an **Alphabet Rail** on the right edge for jumping.
- **Search:** pinned at the bottom where your thumb is. Swipe down anywhere on the Home to focus it, press Enter to launch the top match.
- **App Menu:** long-press any app to pin/unpin it, open App info, or uninstall.

Vocabulary is in [GLOSSARY.md](GLOSSARY.md), and design decisions are in [docs/adr/](docs/adr/).

## Build and install

Needs Flutter (stable) and the Android SDK (platform 36).

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Then press the Home button on the phone and pick **Kawa** as the default home app. You can also set it under Settings → Apps → Default apps → Home app.

> Release builds are signed with the debug key for now. Debug builds (`flutter run`) add `INTERNET` for hot reload, so install the release build if you want the offline guarantee.

## Samsung note

With a third-party launcher on One UI, swipe up from the bottom and hold for about a second to open Recents. That's a Samsung restriction, not Kawa.

## License

GPL-3.0. See [LICENSE](LICENSE). Kawa is a clean-room project ([ADR 0001](docs/adr/0001-clean-room.md)) and contains no code from other launchers.
