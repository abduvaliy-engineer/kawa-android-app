import 'package:flutter/material.dart';

/// Kawa's sizes (dp) and text styles, measured from the reference screenshots
/// (see docs/NEXT.md). Everything is white on the wallpaper, no scrim.
const kRow = 56.0; // one app (Favorites and App List)
const kHeader = 48.0; // one letter header in the App List
const kGap = 24.0; // between Favorites and the App List
const kDotX = 67.0; // centre of the grey dot
const kLabelX = 110.0; // left edge of app labels
const kHeaderX = 42.0; // left edge of header letters
const kRailRight = 30.0; // rail letter centre, from the right edge
const kRailHit = 64.0; // touch strip width on the right edge

/// Set on every style: a style given to AnimatedDefaultTextStyle replaces the
/// theme's font instead of merging with it (labels fell back to Roboto).
const kFont = 'Montserrat';

const _shadow = [Shadow(blurRadius: 8, color: Color(0x80000000))];

const kLabel = TextStyle(
    fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white,
    shadows: _shadow);
const kHeaderText = TextStyle(
    fontFamily: kFont, fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white,
    height: 1.0, shadows: _shadow);
const kClock = TextStyle(
    fontFamily: kFont, fontSize: 45, fontWeight: FontWeight.w300, color: Colors.white,
    height: 1.0, shadows: _shadow);
const kDate = TextStyle(
    fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xE6FFFFFF),
    shadows: _shadow);
const kRailText = TextStyle(
    fontFamily: kFont, fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white,
    height: 1.0, shadows: _shadow);
const kDotColor = Color(0xB3BDBDBD);
const kBubble = Color(0xFFC8C8C8);
