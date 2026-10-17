# 0002 — Flutter (Dart) instead of Kotlin/Compose

**Status:** accepted · 2026-10-17

## Context
A launcher is an Android-only app, so Kotlin + Jetpack Compose is the native choice. The maintainer already knows Flutter and has shipped with it; he has no Compose experience.

## Decision
Kawa's UI and logic are written in Flutter/Dart. Android-only work (listing apps, icons, launching, uninstall, app info, next alarm, package-change events, showing the wallpaper behind the window) lives in one small Kotlin MethodChannel inside the Android host. `dynamic_color` is the only pub package used for platform access; app-listing plugins are avoided because they tend to be abandoned.

## Consequences
- APK ≈ 18 MB instead of ≈ 6 MB.
- Cold start after the OS kills the launcher is ≈ 0.5 s slower; the native launch theme stays black to hide it.
- The maintainer can change Kawa himself, which is the point of owning it.
