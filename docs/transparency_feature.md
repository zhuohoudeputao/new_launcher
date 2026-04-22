# Transparency Feature Documentation

## Overview

The transparency feature allows users to adjust the opacity of info cards in the launcher. Card opacity can be adjusted via the Settings page and dynamically updates all cards.

## Implementation Details

### Storage

- **Key**: `CardOpacity`
- **Default Value**: `0.7` (70%)
- **Range**: 10% - 100%

### Components

1. **Global** (`lib/data.dart`)
   - Stores `cardOpacityValue` as static variable
   - Provides `cardOpacity` getter
   - Loads saved opacity on app startup
   - `_refreshTheme()` notifies both themeModel and infoModel

2. **InfoCard** (`lib/ui.dart`)
   - Stateful widget that uses `Theme.of(context).cardColor`
   - Dynamically updates when theme changes
   - Replaces the old `customInfoWidget` which used static color

3. **CardOpacitySlider** (`lib/ui.dart`)
   - UI widget for adjusting opacity in settings
   - Uses Material Slider (9 divisions: 0.1 to 1.0)
   - Displays current value as percentage

4. **Provider Theme** (`lib/providers/provider_theme.dart`)
   - Uses `Global.cardOpacity` when creating card colors
   - Applies opacity to both light and dark themes
   - Calls `Global.infoModel.notifyListeners()` to trigger rebuild

### Usage Flow

1. User opens Settings
2. User adjusts Card Opacity slider
3. `_refreshTheme()` is called
4. Theme provider is re-initialized with new opacity
5. `infoModel.notifyListeners()` triggers rebuild of all cards
6. All `InfoCard` widgets read new `ThemeData.cardColor`
7. UI updates to show new opacity

### Code Example

```dart
// InfoCard uses theme card color
class InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      // ...
    );
  }
}

// Provider theme sets card color with opacity
Color cardColor = Colors.white.withOpacity(Global.cardOpacity);

// Old customInfoWidget wraps InfoCard
Widget customInfoWidget({...}) {
  return InfoCard(title: title, ...);
}
```

## Related Settings

- `CardOpacity` - Card transparency level
- `Theme.Dark` - Enable dark mode
- `Theme.Transparent` - Enable transparent cards