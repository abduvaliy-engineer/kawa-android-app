import 'dart:convert';

import 'package:flutter/material.dart';

import 'native.dart';
import 'style.dart';

/// One example word for a kanji.
class KanjiExample {
  final String word, kana, romaji, meaning;
  const KanjiExample(this.word, this.kana, this.romaji, this.meaning);
}

/// Kanji of the Hour (data: android/app/src/main/assets/kanji.json).
class KanjiEntry {
  final String kanji, kana, romaji, meaning;
  final List<String> meanings;
  final List<(String, String)> on, kun; // (kana, romaji)
  final List<KanjiExample> examples;

  const KanjiEntry({
    required this.kanji,
    required this.kana,
    required this.romaji,
    required this.meaning,
    required this.meanings,
    required this.on,
    required this.kun,
    required this.examples,
  });

  factory KanjiEntry.fromJson(Map<String, dynamic> j) {
    List<(String, String)> pairs(Object? l) => [
          for (final p in (l as List? ?? const []))
            ((p as List)[0] as String, p[1] as String),
        ];
    return KanjiEntry(
      kanji: j['k'] as String,
      kana: j['r'] as String,
      romaji: j['ro'] as String,
      meaning: j['m'] as String,
      meanings: [for (final m in j['ms'] as List) m as String],
      on: pairs(j['on']),
      kun: pairs(j['kun']),
      examples: [
        for (final e in j['ex'] as List)
          KanjiExample(e['w'] as String, e['r'] as String, e['ro'] as String,
              e['m'] as String),
      ],
    );
  }

  static Future<KanjiEntry?> now() async {
    final s = await Native.kanjiNow();
    return s == null
        ? null
        : KanjiEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }
}

/// The Glance block, like the lock-screen widget: big kanji, then
/// reading, meaning and one example.
class KanjiBlock extends StatelessWidget {
  final KanjiEntry entry;
  final VoidCallback onTap;
  const KanjiBlock({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ex = entry.examples.isEmpty ? null : entry.examples.first;
    final small = kDate.copyWith(fontSize: 13);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(entry.kanji,
            style: kClock.copyWith(fontSize: 44)), // CJK falls back to the system font
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${entry.romaji}・${entry.kana}', style: small),
              Text(entry.meaning,
                  style: kLabel.copyWith(
                      fontSize: 17, fontWeight: FontWeight.w500)),
              if (ex != null)
                Text('${ex.word}・${ex.meaning}',
                    style: small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Everything about the kanji: all readings and up to three example words.
Future<void> showKanjiCard(BuildContext context, KanjiEntry e) {
  const dim = Color(0x99FFFFFF);
  Widget readings(String title, List<(String, String)> rs) => rs.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 64,
                child: Text(title, style: const TextStyle(color: dim))),
            Expanded(
              child: Text(rs.map((r) => '${r.$1} ${r.$2}').join('   ·   '),
                  style: const TextStyle(fontSize: 16)),
            ),
          ]),
        );
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(e.kanji,
                  style: const TextStyle(fontSize: 80, height: 1.1)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.romaji}・${e.kana}',
                        style: const TextStyle(fontSize: 16, color: dim)),
                    Text(e.meanings.join(', '),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w500)),
                    const Text('JLPT N5',
                        style: TextStyle(fontSize: 13, color: dim)),
                  ],
                ),
              ),
            ]),
            readings('kun', e.kun),
            readings('on', e.on),
            const SizedBox(height: 16),
            const Divider(),
            for (final x in e.examples)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  SizedBox(
                    width: 96,
                    child: Text(x.word, style: const TextStyle(fontSize: 22)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${x.kana}  ${x.romaji}',
                            style: const TextStyle(color: dim)),
                        Text(x.meaning, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    ),
  );
}
