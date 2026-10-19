#!/usr/bin/env python3
"""Build android/app/src/main/assets/kanji.json for Kanji of the Hour.

Sources (downloaded once at build time; the app itself stays offline):
  - kanji-data by David Gouveia (MIT): KANJIDIC readings/meanings + new JLPT levels
    https://github.com/davidluzgouveia/kanji-data
  - JLPT N5/N4/N3 vocabulary lists (jlpt-word-list by elzup, MIT; vocabulary
    from tanos.co.uk by Jonathan Waller, CC BY): preferred example words
    https://github.com/elzup/jlpt-word-list
  - jmdict-simplified (MIT code) of JMdict "common" words: fallback examples
    https://github.com/scriptin/jmdict-simplified
KANJIDIC and JMdict are property of the EDRDG, used under CC BY-SA 4.0.
The generated kanji.json is therefore CC BY-SA 4.0 (see README).

Usage: tool/build_kanji.py KANJI_JSON JMDICT_COMMON_JSON N5_CSV N4_CSV N3_CSV
"""
import csv
import json
import sys

LEVELS = (5,)  # JLPT N5 only: the user is a beginner

_ROMAJI = {
    'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
    'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
    'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
    'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
    'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
    'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
    'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
    'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
    'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
    'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
    'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
    'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
    'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
    'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
    'わ': 'wa', 'ゐ': 'i', 'ゑ': 'e', 'を': 'o', 'ん': 'n',
    'ゔ': 'vu', 'ぁ': 'a', 'ぃ': 'i', 'ぅ': 'u', 'ぇ': 'e', 'ぉ': 'o',
}
_YOON = {'ゃ': 'a', 'ゅ': 'u', 'ょ': 'o'}


def to_hiragana(s: str) -> str:
    """Katakana → hiragana (on'yomi are written in katakana in some sources)."""
    return ''.join(chr(ord(c) - 0x60) if 'ァ' <= c <= 'ヶ' else c for c in s)


def to_romaji(kana: str) -> str:
    """Hepburn romaji for a hiragana string (じょうず → jouzu)."""
    s = to_hiragana(kana)
    out = []
    i = 0
    while i < len(s):
        c = s[i]
        nxt = s[i + 1] if i + 1 < len(s) else ''
        if c == 'っ':
            # Doubles the next consonant (っち → tchi).
            r = to_romaji(s[i + 1:i + 3] if s[i + 2:i + 3] in _YOON else nxt)
            if r:
                out.append('t' if r.startswith('ch') else r[0])
            i += 1
            continue
        if c == 'ー':
            if out and out[-1]:
                out.append(out[-1][-1])
            i += 1
            continue
        base = _ROMAJI.get(c)
        if base is None:
            out.append(c)
            i += 1
            continue
        if nxt in _YOON and c not in 'ゃゅょ':
            stem = base[:-1]
            if stem in ('sh', 'ch', 'j'):
                out.append(stem + _YOON[nxt])
            else:
                out.append(stem + 'y' + _YOON[nxt])
            i += 2
            continue
        # ん before a vowel or y gets an apostrophe (きんえん → kin'en).
        if c == 'ん' and nxt and _ROMAJI.get(nxt, 'x')[0] in 'aiueoy':
            out.append("n'")
        else:
            out.append(base)
        i += 1
    return ''.join(out)


def clean_reading(r: str) -> str:
    """KANJIDIC kun readings mark okurigana with '.' and affixes with '-'."""
    return to_hiragana(r.replace('.', '').replace('-', '').lstrip('!'))


def primary_reading(k: dict, alone: str = '') -> str:
    """How a beginner meets the kanji: its reading as a word on its own in the
    JLPT list ([alone], e.g. 山 → やま), else the one WaniKani teaches first,
    else the first kun, else the first on."""
    if alone:
        return alone
    for r in (k.get('wk_readings_on') or []) + (k.get('wk_readings_kun') or []):
        if not r.startswith('!'):
            return clean_reading(r)
    if k.get('readings_kun'):
        return clean_reading(k['readings_kun'][0])
    return clean_reading(k['readings_on'][0])


def short_gloss(word: dict) -> str:
    g = word['sense'][0]['gloss'][0]['text']
    return g if len(g) <= 28 else g[:27] + '…'


def load_vocab(paths):
    """[(level, word, kana, meaning)] from the JLPT CSVs, easiest level first."""
    out = []
    for level, path in zip((5, 4, 3), paths):
        with open(path, encoding='utf-8') as f:
            for row in csv.DictReader(f):
                for word in row['expression'].split(';'):
                    word = word.strip()
                    if not word or any(c in word for c in '～~()（）'):
                        continue
                    meaning = row['meaning'].split(';')[0].split(', ')[0].strip()
                    if meaning.count('(') > meaning.count(')'):
                        meaning = meaning[:meaning.rindex('(')].strip()
                    kana = row['reading'].split(';')[0].strip()
                    out.append((level, word, kana, meaning))
    return out


def vocab_examples(kanji: str, vocab, known: set, n=3):
    """Up to n JLPT words containing [kanji]: easier level first, then words
    whose kanji are all N5/N4, then two-character words."""
    scored = []
    for i, (level, word, kana, meaning) in enumerate(vocab):
        if kanji not in word or word == kanji:
            continue
        kanjis = [c for c in word if '\u4e00' <= c <= '\u9fff']
        score = level * 10  # N5 words beat N4 beat N3
        score += 4 if all(c in known for c in kanjis) else 0
        score += 2 if len(word) == 2 else 0
        score -= abs(len(word) - 2)
        scored.append((-score, i, word, kana, meaning))
    scored.sort()
    out, seen = [], set()
    for _, _, word, kana, meaning in scored:
        if word in seen:
            continue
        seen.add(word)
        out.append({'w': word, 'r': kana, 'ro': to_romaji(kana), 'm': meaning})
        if len(out) == n:
            break
    return out


def examples(kanji: str, words_by_kanji: dict, known: set, n=3):
    """Up to n common words containing [kanji], easiest first: words made only
    of N5/N4 kanji, two characters long, with a common reading."""
    scored = []
    for w in words_by_kanji.get(kanji, ()):
        text = next(k['text'] for k in w['kanji'] if kanji in k['text'])
        if text == kanji:
            continue  # the kanji alone is already shown as its reading
        kana = next((k['text'] for k in w['kana'] if k['common']), w['kana'][0]['text'])
        kanjis = [c for c in text if '\u4e00' <= c <= '\u9fff']
        score = 0
        score += 4 if all(c in known for c in kanjis) else 0
        score += 2 if len(text) == 2 else 0
        score -= abs(len(text) - 2)
        score -= len(kana) / 10
        scored.append((-score, int(w['id']), text, kana, short_gloss(w)))
    scored.sort()
    out, seen = [], set()
    for _, _, text, kana, gloss in scored:
        if text in seen:
            continue
        seen.add(text)
        out.append({'w': text, 'r': kana, 'ro': to_romaji(kana), 'm': gloss})
        if len(out) == n:
            break
    return out


def merge(first, fallback, n=3):
    """JLPT examples first, topped up from JMdict."""
    out = list(first)
    for e in fallback:
        if len(out) == n:
            break
        if all(e['w'] != o['w'] for o in out):
            out.append(e)
    return out


def top_up(examples_, fallback, want=2):
    """JMdict words only when the JLPT lists give fewer than [want]; they are
    already ranked to use N5 kanji only where possible."""
    return examples_ if len(examples_) >= want else merge(examples_, fallback, want)


def main(kanji_path, jmdict_path, n5, n4, n3,
         out_path='android/app/src/main/assets/kanji.json'):
    kanji = json.load(open(kanji_path, encoding='utf-8'))
    words = json.load(open(jmdict_path, encoding='utf-8'))['words']
    vocab = load_vocab((n5, n4, n3))
    chosen = {c: k for c, k in kanji.items() if k.get('jlpt_new') in LEVELS}
    known = set(chosen)

    words_by_kanji = {}
    for w in words:
        if not any(k['common'] for k in w['kanji']):
            continue
        for k in w['kanji']:
            for c in set(k['text']):
                if c in known:
                    words_by_kanji.setdefault(c, []).append(w)

    entries = []
    # Easiest first: N5, then N4, then by how often the kanji appears in text.
    for c, k in sorted(chosen.items(),
                       key=lambda kv: (-kv[1]['jlpt_new'], kv[1].get('freq') or 9999)):
        # Only N5 words count, so 外 is そと (N5) and not ほか (N4).
        alone = next((v[2].strip('～~') for v in vocab
                      if v[0] == 5 and v[1] == c), '')
        r = primary_reading(k, alone)
        entries.append({
            'k': c,
            'lv': k['jlpt_new'],
            'r': r,
            'ro': to_romaji(r),
            'm': k['meanings'][0].lower(),
            'ms': [m.lower() for m in k['meanings'][:4]],
            # [kana, romaji] pairs for the Kanji Card.
            'on': [[x, to_romaji(x)] for x in
                   dict.fromkeys(clean_reading(x) for x in k['readings_on'])][:4],
            'kun': [[x, to_romaji(x)] for x in
                    dict.fromkeys(clean_reading(x) for x in k['readings_kun'])][:4],
            # N5 words first; N4 only to top up; JMdict only if nothing else.
            'ex': top_up(merge(vocab_examples(c, [v for v in vocab if v[0] == 5], known),
                               vocab_examples(c, [v for v in vocab if v[0] == 4], known)),
                         examples(c, words_by_kanji, known)),
        })
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump({'license': 'CC BY-SA 4.0: KANJIDIC and JMdict (EDRDG); '
                              'JLPT vocabulary: tanos.co.uk (CC BY); '
                              'kanji-data (D. Gouveia, MIT)',
                   'kanji': entries}, f, ensure_ascii=False, separators=(',', ':'))
    missing = [e['k'] for e in entries if not e['ex']]
    jlpt = sum(1 for e in entries for x in e['ex']
               if any(x['w'] == v[1] for v in vocab))
    print(f"examples from JLPT lists: {jlpt}/{sum(len(e['ex']) for e in entries)}")
    print(f'{len(entries)} kanji -> {out_path}; without examples: {"".join(missing) or "none"}')


if __name__ == '__main__':
    main(*sys.argv[1:])
