# Next session

v0.2 is done and has been checked on the S23 Ultra: Niagara-style look, bending rail, Section View, slide-to-launch, Settings with the default-Home switch. Kawa is the default Home on the phone.

## Next up: v0.3 Kanji of the Hour (design settled in Q24–Q30)
- Bundle JLPT N5+N4 kanji (~250) offline. Candidate data: davidluzgouveia/kanji-data (MIT; readings and meanings from KANJIDIC, CC BY-SA, credit EDRDG) plus one example word per kanji from JMdict (CC BY-SA). Generate the asset with a script in `tool/`.
- Every hour on the hour; shuffled, no repeats until all have been shown.
- Show: romaji・hiragana (on'yomi converted to hiragana), English meaning, one example word・meaning.
- Where: one Glance line in Kawa, plus a native Android home-screen widget (RemoteViews in Kotlin) that the user adds to the lock screen with Good Lock → LockStar. Good Lock is region-locked, so this is not guaranteed in Uzbekistan.
- Tap → a card in Kawa with all readings and 2–3 examples.

## Polish backlog
- App icon is still the Flutter default.
- Drag-to-reorder Favorites.
