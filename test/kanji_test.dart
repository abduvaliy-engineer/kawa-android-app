import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawa/kanji.dart';

void main() {
  final data = jsonDecode(
          File('android/app/src/main/assets/kanji.json').readAsStringSync())
      as Map<String, dynamic>;
  final entries = [
    for (final j in data['kanji'] as List)
      KanjiEntry.fromJson(j as Map<String, dynamic>),
  ];

  test('all 79 N5 kanji parse, each with at least one example', () {
    expect(entries, hasLength(79));
    for (final e in entries) {
      expect(e.examples, isNotEmpty, reason: e.kanji);
      expect(e.kana, isNotEmpty, reason: e.kanji);
      expect(e.romaji, matches(RegExp(r"^[a-z']+$")), reason: e.kanji);
    }
  });

  test('beginner readings: a kanji that is a word on its own reads as one', () {
    final byKanji = {for (final e in entries) e.kanji: e};
    expect(byKanji['山']!.kana, 'やま');
    expect(byKanji['人']!.kana, 'ひと');
    expect(byKanji['外']!.kana, 'そと');
    expect(byKanji['手'], isNull); // 手 is N4, not N5
  });

  test('the data carries its CC BY-SA attribution', () {
    expect(data['license'], contains('CC BY-SA'));
  });
}
