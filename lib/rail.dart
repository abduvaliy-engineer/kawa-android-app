import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'style.dart';

/// How far (dp, negative = left) a rail letter bends away from the edge when
/// it is [d] dp above or below the finger.
double railBend(double d) => -88 * math.exp(-(d * d) / (2 * 95 * 95));

/// Where every Alphabet Rail letter sits on screen.
class RailGeometry {
  final List<String> letters;
  final double starY; // centre of ★
  final double pitch; // distance between letter centres
  final double centerX; // letter centre when not bent

  const RailGeometry(this.letters, this.starY, this.pitch, this.centerX);

  /// ★ at 31.1 % of the screen height, 19.2 dp per letter, squeezed if the
  /// letters would run into the navigation bar.
  factory RailGeometry.of(List<String> letters, Size screen,
      {double bottomInset = 0}) {
    final starY = screen.height * 0.311;
    final room = screen.height - bottomInset - 24 - starY;
    final n = math.max(1, letters.length - 1);
    return RailGeometry(letters, starY, math.min(19.2, room / n),
        screen.width - kRailRight);
  }

  double yOf(int i) => starY + i * pitch;
  double get top => starY - pitch / 2 - 12;
  double get bottom => yOf(letters.length - 1) + pitch / 2 + 12;

  int indexAt(double y) =>
      ((y - starY) / pitch).round().clamp(0, letters.length - 1);
}

/// Draws the rail. While [fingerY] is set the letters bend around the finger
/// and a bubble shows the [active] letter.
class AlphabetRail extends StatelessWidget {
  final RailGeometry geo;
  final double? fingerY;
  final String? active;

  const AlphabetRail(
      {super.key, required this.geo, this.fingerY, this.active});

  double _dx(int i) => fingerY == null ? 0 : railBend(geo.yOf(i) - fingerY!);

  @override
  Widget build(BuildContext context) {
    final ai = active == null ? -1 : geo.letters.indexOf(active!);
    return Stack(clipBehavior: Clip.none, children: [
      for (var i = 0; i < geo.letters.length; i++)
        Positioned(
          left: geo.centerX + _dx(i) - 16,
          top: geo.yOf(i) - 12,
          width: 32,
          height: 24,
          child: Center(
            child: Text(
              geo.letters[i],
              style: i == ai
                  ? kRailText.copyWith(fontWeight: FontWeight.w600)
                  : kRailText,
            ),
          ),
        ),
      if (ai >= 0 && fingerY != null)
        Positioned(
          left: geo.centerX + _dx(ai) - 16 - 52,
          top: fingerY! - 22,
          width: 44,
          height: 44,
          child: Container(
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: kBubble, shape: BoxShape.circle),
            child: Text(geo.letters[ai],
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202020),
                    height: 1.0)),
          ),
        ),
    ]);
  }
}
