# Critical Bug Fixes and Code Cleanup

## Overview

This document describes critical bug fixes and code cleanup performed during the automatic development loop.

## Bug Fixes (Loop 1)

### 1. Frequency Increment Bug (action.dart:55)

**Issue**: The frequency increment logic used `_times[DateTime.now().hour - 1]`, which would cause a `RangeError` at midnight (hour 0) since `0 - 1 = -1`.

**Fix**: Changed to `_times[DateTime.now().hour]` to increment the current hour's counter.

### 2. HTTP Request Timeout Missing

**Issue**: HTTP requests in `provider_weather.dart` and `provider_wallpaper.dart` had no timeout.

**Fix**: Added timeout to all HTTP requests (10s for weather, 15s for wallpaper).

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

**Issue**: `generateSuggestList()` ran on every keystroke without debounce.

**Fix**: Added 300ms debounce timer.

### 2. Timer Efficiency (provider_time.dart)

**Issue**: Timer fired every second but only rebuilt when `second == 0` (59 wasted callbacks per minute).

**Fix**: Changed to fire every minute with initial delay aligned to minute boundary.

### 3. Removed Unused Dependencies

Removed from `pubspec.yaml`: `sqflite`, `url_launcher`, `permission_handler`.

## Feature Improvements (Loop 3)

### 1. System Theme Mode (provider_theme.dart)

**Issue**: Theme only supported boolean "dark" setting, not system theme mode.

**Fix**: 
- Added `Theme.Mode` setting with values "light", "dark", "system"
- Added `WidgetsBindingObserver` in `MyApp` to detect system brightness changes
- Theme now follows system brightness when mode is "system"

### 2. CircularListController Tests

**Issue**: Critical UI component for circular scrolling had no tests.

**Fix**: Added 7 unit tests for CircularListController.

### 3. Integration Tests

**Issue**: Integration test was placeholder with `expect(true, true)`.

**Fix**: Added meaningful tests for app launch, search field, background image, and info cards.

### 4. Public refreshTheme Method

**Issue**: `_refreshTheme` was private, preventing external calls.

**Fix**: Made `refreshTheme()` public for use in brightness change callbacks.

## Feature Improvements (Loop 4)

### 1. Log Viewer UI (ui.dart)

**Issue**: LoggerModel existed but no UI to display logs.

**Fix**: Added `LogViewerWidget` with:
- Search bar for filtering by message
- Dropdown filter for log level
- Log list with icons, messages, sources, timestamps
- Clear button to remove all logs

### 2. View Logs Action (provider_system.dart)

**Issue**: No action to view logs.

**Fix**: Added "View logs" action with keywords "logs debug error view".

### 3. Provider Update Trigger (data.dart)

**Issue**: Provider `update()` functions never called.

**Fix**: Added `_triggerProviderUpdate()` in SettingsModel to call provider updates when matching settings change.

### 4. Implemented Provider Updates

**Issue**: `_update()` functions in providers were empty.

**Fix**: 
- `provider_time.dart`: Calls `_provideTime()` to refresh time widget
- `provider_wallpaper.dart`: Calls `_loadSavedWallpaper()` to reload wallpaper

## Tests Summary

| Loop | Tests Added | Total Tests |
|------|-------------|-------------|
| 1 | 16 | 58 |
| 2 | 12 | 70 |
| 3 | 7 | 77 |

## Date

- Loop 1: 2026-04-22
- Loop 2: 2026-04-22
- Loop 3: 2026-04-22
- Loops 4-8: 2026-04-23

## Feature Improvements (Loop 5-8)

### 1. App Statistics Feature (Loop 1, Loop 2)

**Issue**: No tracking of app usage patterns.

**Fix**: Added `AppStatisticsModel` to track:
- Launch counts per app
- Last launch timestamps
- Top 5 most used apps display

**Persistence**: Statistics survive app restarts via SharedPreferences.

### 2. Memory Leak Fix (Loop 3)

**Issue**: `ActionModel.dispose()` never called, leaving `_debounceTimer` active.

**Fix**: Added disposal call in `_MyAppState.dispose()`.

### 3. Recent Apps Limit (Loop 4)

**Issue**: `AppModel.recentApps` could grow unbounded.

**Fix**: Added `maxRecentApps = 20` limit with automatic oldest removal.

### 4. Test Coverage Expansion (Loops 5-8)

Added widget tests for:
- `DarkModeOptionSelector` (4 tests)
- `WallpaperPickerButton` (2 tests)
- `InfoCard` (4 tests)
- `LogViewerWidget` (4 tests)
- `AppModel` limit behavior (3 tests)
- `ActionModel.dispose` (1 test)

## Tests Summary (Updated)

| Loop | Tests Added | Total Tests |
|------|-------------|-------------|
| 1 | 16 | 58 |
| 2 | 12 | 70 |
| 3 | 7 | 77 |
| 4 | 12 | 92 |
| 5 | 4 | 96 |
| 6-7 | 9 | 105 |
| 8 | 8 | 113 |