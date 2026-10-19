# Next session

Done and checked on the S23 Ultra: v0.2 look, Settings and default Home, the Favorites picker, and v0.3 Kanji of the Hour on the Home (Glance block + Kanji Card).

## Not verified yet
- **The widget hasn't been seen running.** It's registered (`dumpsys appwidget` lists `KanjiWidget`, category home_screen|keyguard), but Kawa has no widget host and Good Lock isn't installed yet. Next step: Good Lock → LockStar → add "Kanji of the Hour", then confirm it changes at :00 and that tapping it opens the Kanji Card.
- The hourly change is an inexact alarm, so in doze it can arrive a few minutes late. Opening Kawa also refreshes the widget.

## Backlog
- App icon is still the Flutter default.
- Drag-to-reorder Favorites.
- Kanji: an N4 mode later (`LEVELS` in tool/build_kanji.py), maybe pull from the user's AnkiDroid deck.
