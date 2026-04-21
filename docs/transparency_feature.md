# Transparency Feature Documentation

## Overview

The transparency feature allows users to adjust the opacity of info cards in the launcher. Card opacity can be adjusted via the Settings page.

## Implementation Details

### Storage

- **Key**: `CardOpacity`
- **Default Value**: `0.7` (70%)
- **Range**: 10% - 100%

### Components

1. **Global** (`lib/data.dart`)
   - Stores `cardOpacityValue` as static variable
   - Provides `cardOpacity` getter
   - Loads saved opacity on app startup (line 77-78)

2. **CardOpacitySlider** (`lib/ui.dart`)
   - UI widget for adjusting opacity in settings
   - Uses Material Slider (9 divisions: 0.1 to 1.0)
   - Displays current value as percentage

3. **Settings Model** (`lib/data.dart`)
   - Creates CardOpacitySlider widget dynamically
   - Handles setting change events

4. **Provider Theme** (`lib/providers/provider_theme.dart`)
   - Uses `Global.cardOpacity` when creating card colors
   - Applies opacity to both light and dark themes

### Usage Flow

1. User opens Settings
2. User adjusts Card Opacity slider
3. Value is saved to SharedPreferences
4. Theme provider is re-initialized
5. All cards are redrawn with new opacity
6. UI rebuilds to show updated opacity

## Code Example

```dart
// In provider_theme.dart
Color cardColor = Colors.white.withOpacity(Global.cardOpacity);

// In ui.dart - customInfoWidget
return Card(
  color: Colors.white.withOpacity(Global.cardOpacity),
  // ...
);
```

## Related Settings

- `CardOpacity` - Card transparency level
- `Theme.Dark` - Enable dark mode
- `Theme.Transparent` - Enable transparent cards