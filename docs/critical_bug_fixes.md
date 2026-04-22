# Critical Bug Fixes and Code Cleanup

## Overview

This document describes critical bug fixes and code cleanup performed during the automatic development loop.

## Bug Fixes (Loop 1)

### 1. Frequency Increment Bug (action.dart:55)

**Issue**: The frequency increment logic used `_times[DateTime.now().hour - 1]`, which would cause a `RangeError` at midnight (hour 0) since `0 - 1 = -1`.

**Fix**: Changed to `_times[DateTime.now().hour]` to increment the current hour's counter, matching the getter behavior.

```dart
// Before (buggy)
_times[DateTime.now().hour - 1] += 1;

// After (fixed)
_times[DateTime.now().hour] += 1;
```

### 2. HTTP Request Timeout Missing

**Issue**: HTTP requests in `provider_weather.dart` and `provider_wallpaper.dart` had no timeout, causing the app to potentially hang indefinitely.

**Fix**: Added timeout to all HTTP requests:

- Weather API: 10 seconds timeout
- Wallpaper fetch: 15 seconds timeout

### 3. Null Safety Issues in SettingsModel

**Issue**: Multiple `!` operators on `_prefs` could cause runtime errors.

**Fix**: Refactored `SettingsModel` to use proper null-safe access.

### 4. Unsafe Type Cast in runFirstAction

**Issue**: `_suggestList[0] as TextButton` could throw if the widget is not a TextButton.

**Fix**: Added type check before casting.

### 5. Async getValue Return Type

**Issue**: `Global.getValue` returned `Future<dynamic>` but was declared as returning `dynamic`.

**Fix**: Updated return type to `Future<dynamic>`.

## Performance Improvements (Loop 2)

### 1. Search Debounce (data.dart)

**Issue**: `generateSuggestList()` ran on every keystroke without debounce, causing unnecessary rebuilds.

**Fix**: Added 300ms debounce timer to reduce CPU usage during rapid typing.

```dart
void generateSuggestList(String input) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    // ... update suggestions
  });
}
```

### 2. Timer Efficiency (provider_time.dart)

**Issue**: Timer fired every second but only rebuilt when `second == 0` (59 wasted callbacks per minute).

**Fix**: Changed to fire every minute with initial delay aligned to minute boundary.

```dart
// Before: 60 callbacks per minute, only 1 useful
Timer.periodic(Duration(seconds: 1), ...)

// After: 1 callback per minute
final initialDelay = 60 - DateTime.now().second;
Timer(Duration(seconds: initialDelay), () {
  Timer.periodic(Duration(minutes: 1), ...);
});
```

## Code Cleanup (Loop 2)

### Removed Unused Dependencies

Removed from `pubspec.yaml`:
- `sqflite` - Database package never used
- `url_launcher` - Never imported
- `permission_handler` - Never imported

### Removed Outdated TODOs

Removed TODO comments in `provider_app.dart` that were already implemented.

## Tests Added

- **Loop 1**: MyAction, MyProvider, ThemeModel, BackgroundImageModel, ActionModel tests
- **Loop 2**: LoggerModel tests (singleton, log methods, filtering, search, maxLogs limit)
- Debounce tests for ActionModel

## Date

- Loop 1: 2026-04-22
- Loop 2: 2026-04-22