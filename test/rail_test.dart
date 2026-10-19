import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawa/rail.dart';

void main() {
  test('letters right at the finger bend 88 dp left', () {
    expect(railBend(0), closeTo(-88, 0.001));
  });

  test('bend fades with distance', () {
    expect(railBend(95).abs(), lessThan(railBend(0).abs()));
    expect(railBend(400).abs(), lessThan(1));
    expect(railBend(-95), closeTo(railBend(95), 1e-9));
  });

  test('rail starts at 31.1 % height with 19.2 dp pitch', () {
    final g = RailGeometry.of(['★', 'A', 'B'], const Size(384, 823.5));
    expect(g.starY, closeTo(256.1, 0.1));
    expect(g.pitch, 19.2);
    expect(g.centerX, 384 - 30);
  });

  test('a long rail squeezes to fit above the nav bar', () {
    final letters = ['★', for (var i = 0; i < 60; i++) 'x'];
    final g = RailGeometry.of(letters, const Size(384, 823.5),
        bottomInset: 20);
    expect(g.pitch, lessThan(19.2));
    expect(g.yOf(letters.length - 1), lessThanOrEqualTo(823.5 - 20 - 24 + 0.01));
  });

  test('indexAt picks the nearest letter and clamps', () {
    final g = RailGeometry.of(['★', 'A', 'B'], const Size(384, 823.5));
    expect(g.indexAt(g.starY - 100), 0);
    expect(g.indexAt(g.yOf(1) + 5), 1);
    expect(g.indexAt(10000), 2);
  });
}
