# Theme Feature Documentation

## Overview

The theme feature manages the visual appearance of cards in the launcher, including dark mode and transparency settings.

## Settings

### Theme.Dark

- **Type**: Boolean
- **Default**: `false` (light mode)
- **Effect**: Toggles dark/light theme for all cards

### Theme.Transparent

- **Type**: Boolean
- **Default**: `true`
- **Effect**: Enables transparent cards

### CardOpacity

- **Type**: Double
- **Range**: 0.1 - 1.0
- **Default**: 0.7 (70%)
- **Effect**: Sets card transparency level

## Implementation Details

### Provider

- **Name**: `Theme`
- **Location**: `lib/providers/provider_theme.dart`

### Theme Data

1. **Brightness**: Controls overall theme (light/dark)
2. **Card Color**: Background color with opacity applied
3. **Text Color**: Black for light mode, white for dark mode

### Color Schemes

| Mode | Brightness | Card Color | Text Color |
|-----|-----------|-----------|-----------|
| Light | light | white | black87 |
| Dark | dark | grey[850] | white |

## Code Example

```dart
Future<void> _provideTheme() async {
  Brightness brightness = Brightness.light;
  Color cardColor = Colors.white.withOpacity(Global.cardOpacity);
  Color textColor = Colors.black87;

  bool dark = await Global.getValue("Theme.Dark", false);

  if (dark) {
    brightness = Brightness.dark;
    cardColor = Colors.grey[850]?.withOpacity(Global.cardOpacity);
    textColor = Colors.white;
  }

  Global.setTheme(ThemeData(
    brightness: brightness,
    cardColor: cardColor,
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: textColor),
      bodyLarge: TextStyle(color: textColor),
      titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
    ),
  ));
}
```

## Setting Changes

When theme settings are changed, the theme provider is re-initialized:
1. User changes setting in Settings page
2. `SettingsModel` saves new value
3. `Global._refreshTheme()` is called
4. Theme provider re-applies theme
5. UI rebuilds with new colors

## Refresh Command

Users can type "refresh theme" to manually refresh the theme.