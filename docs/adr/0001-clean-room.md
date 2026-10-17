# 0001 — Clean-room build, inspired by Niagara but no Niagara code

**Status:** accepted · 2026-10-17

## Context
Kawa is inspired by Niagara Launcher (proprietary, bitpit). Niagara's APK had been decompiled once for study.

## Decision
Kawa is written from scratch. Nobody working on Kawa reads Niagara's decompiled code; the decompiled output was deleted before the repo was created. Only Niagara's *publicly visible behaviour* (what a user sees on screen) inspires features.

## Consequences
- Kawa can be published under GPL-3.0 without copyright risk.
- Features are re-derived from Android APIs, not copied, so some behaviours will differ from Niagara.
