# App Number Limit Removal

## Overview

Removed the 20 app limit in the info widget list, allowing all installed apps to be displayed as individual cards in the main launcher list.

## Implementation

### Changes Made

1. **Removed `.take(20)` limit in `lib/providers/provider_app.dart`**
   - Previously: `final topApps = allAppsWithIcons.take(20).toList();`
   - Now: Uses `allAppsWithIcons` directly to create widgets for all apps

2. **Added overflow handling to app cards**
   - Added `maxLines: 1` and `overflow: TextOverflow.ellipsis` to both title and subtitle
   - Prevents RenderFlex overflow when app names or package names are long

### Code Changes

```dart
// Before (limited to 20 apps)
final topApps = allAppsWithIcons.take(20).toList();
final appWidgets = topApps.map((app) => 
  MapEntry("app_${app.packageName}", _buildAppCard(app))
).toList();

// After (all apps)
final appWidgets = allAppsWithIcons.map((app) => 
  MapEntry("app_${app.packageName}", _buildAppCard(app))
).toList();
```

### Overflow Fix

```dart
title: Text(
  app.appName,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),
subtitle: Text(
  app.packageName,
  style: TextStyle(fontSize: 12),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),
```

## Benefits

- All installed apps are now visible in the main card list
- Users can search for any app by typing its name
- Better discoverability for less frequently used apps

## Performance Considerations

- The `AllAppsCard` widget already displays all apps in a GridView
- Individual app cards are created via `addInfoWidgetsBatch()` for efficient single notifyListeners
- Text overflow handling prevents layout issues with long names

## Related Files

- `lib/providers/provider_app.dart` - App provider implementation
- `docs/app_card_feature.md` - App display cards documentation

## Testing

All 1313 tests pass, including:
- AllAppsModel tests
- AllAppsCard widget tests
- App statistics tests