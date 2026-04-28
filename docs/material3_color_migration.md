# Material 3 Color Migration

## Overview

This document tracks the migration of hardcoded colors to Material 3 `ColorScheme` tokens across provider files.

## Changes Made

### Provider Files Updated

| File | Changes | Notes |
|------|---------|-------|
| provider_2048.dart | Win/lose text, history colors | Tile colors preserved (classic 2048 look) |
| provider_bloodpressure.dart | Category colors | Semantic colors preserved (green=normal, red=crisis) |
| provider_color.dart | Border colors | Replaced `Colors.grey` with `colorScheme.outline` |
| provider_compass.dart | Center dot | Replaced `Colors.white` with `colorScheme.surface` |
| provider_gratitude.dart | Icon colors | Replaced `Colors.pink` with `colorScheme.tertiary` |
| provider_hangman.dart | Win/lose, stats, history | Replaced `Colors.green/red/grey` with `colorScheme` |
| provider_memorygame.dart | Time ago text | Replaced `Colors.grey` with `colorScheme.onSurfaceVariant` |
| provider_minesweeper.dart | Win/lose, stats, history | Adjacent mine colors preserved (game tradition) |

### Color Token Mapping

| Original | Material 3 Replacement |
|----------|------------------------|
| `Colors.green` (win status) | `colorScheme.primary` |
| `Colors.red` (lose status) | `colorScheme.error` |
| `Colors.grey` (muted text) | `colorScheme.onSurfaceVariant` |
| `Colors.orange` (accent) | `colorScheme.tertiary` |
| `Colors.pink` (brand) | `colorScheme.tertiary` |
| `Colors.white` (contrast) | `colorScheme.surface` |

### Preserved Colors (Intentional)

Some hardcoded colors were intentionally preserved:

1. **2048 Tile Colors**: Classic gradient (grey → orange → amber → purple) is part of the game's identity
2. **Blood Pressure Categories**: Medical semantic colors (green=healthy, red=danger)
3. **Minesweeper Adjacent Mine Counts**: Traditional 1-8 colors (blue, green, red, purple, etc.)
4. **Difficulty Colors**: Game-specific difficulty indicators

## Context Handling

For non-widget contexts (e.g., `_provideActions` functions), use:
```dart
Theme.of(navigatorKey.currentContext!).colorScheme
```

This ensures theme access when `BuildContext` isn't directly available.

## Quality Checklist

- [x] Code compiles without errors
- [x] Flutter analyze passes
- [x] Debug APK builds successfully
- [x] No hardcoded `Colors.green/red/grey` for UI status text
- [x] Semantic game colors preserved appropriately
- [x] Documentation updated