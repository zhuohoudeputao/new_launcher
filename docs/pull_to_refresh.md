# Pull-to-Refresh Feature

## Overview

The pull-to-refresh feature allows users to refresh all dynamic content in the launcher by pulling down on the card list. This provides a common mobile UX pattern for manually updating weather, time, and other provider data.

## Implementation

### Location
- `lib/main.dart` - Added `RefreshIndicator` wrapping the `ListView.builder`

### Components

#### RefreshIndicator
The `RefreshIndicator` widget wraps the main card list and provides the pull-to-refresh gesture detection:

```dart
RefreshIndicator(
  onRefresh: _refreshAllProviders,
  child: ListView.builder(
    physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
    ...
  ),
)
```

#### Refresh Callback
The `_refreshAllProviders` method in `_MyHomePageState` triggers refresh for all providers:

```dart
Future<void> _refreshAllProviders() async {
  Global.loggerModel.info("Manual refresh triggered", source: "Main");
  for (MyProvider provider in Global.providerList) {
    try {
      await provider.init();
    } catch (e) {
      Global.loggerModel.warning("Provider ${provider.name} refresh error: $e", source: "Main");
    }
  }
}
```

### Physics Configuration
The `ListView` uses `AlwaysScrollableScrollPhysics` with `BouncingScrollPhysics` as the parent to ensure:
- Pull gesture is always possible even when content is minimal
- Smooth bouncing animation on overscroll
- Refresh indicator appears when pulled down

## User Experience

1. User pulls down on the card list
2. Refresh indicator appears (Material 3 style circular progress indicator)
3. All providers are re-initialized (weather, time, apps, etc.)
4. Card content updates with fresh data
5. Refresh indicator disappears

## Benefits

- Consistent with mobile app conventions
- Single gesture to refresh all content
- No need to manually refresh each card individually
- Works even with minimal content in the list

## Testing

Tests are located in `test/widget_test.dart` under the "Pull-to-refresh tests" group:
- `MyHomePage has RefreshIndicator` - Verifies RefreshIndicator widget presence
- `ListView uses AlwaysScrollableScrollPhysics` - Verifies scroll physics configuration
- `_refreshAllProviders calls provider init for all providers` - Verifies provider count

## Future Enhancements

Potential improvements:
- Add refresh progress indicator showing which providers are refreshing
- Add settings to enable/disable auto-refresh on pull
- Add selective refresh (only refresh certain providers)