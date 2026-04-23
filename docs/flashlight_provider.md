# Flashlight Provider Implementation

## Overview

The Flashlight provider adds quick flashlight toggle functionality to the launcher. It provides a simple on/off control card that users can use to quickly toggle their device's flashlight.

## Implementation Details

### Location
- Provider file: `lib/providers/provider_flashlight.dart`
- Model: `FlashlightModel`
- Widget: `FlashlightCard`

### Dependencies
- `torch_light: ^1.0.0` - Flutter package for flashlight control

### FlashlightModel

The model manages flashlight state:

```dart
class FlashlightModel extends ChangeNotifier {
  bool _isOn = false;           // Current flashlight state
  bool _isAvailable = false;    // Device flashlight availability
  bool _isInitialized = false;  // Initialization status
  
  bool get isOn => _isOn;
  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;
  
  Future<void> init();          // Initialize and check availability
  Future<void> toggle();        // Toggle flashlight on/off
  Future<void> enable();        // Enable flashlight
  Future<void> disable();       // Disable flashlight
  Future<void> refresh();       // Refresh availability check
}
```

### FlashlightCard

The widget displays:
- Loading state during initialization
- "Flashlight not available" message for devices without flashlight
- On/Off status with toggle switch when available
- Uses `Card.filled` for Material 3 style

### Provider Registration

The provider is registered in:
- `lib/data.dart`: Added to `Global.providerList`
- `lib/main.dart`: Added to `MultiProvider` providers list

### Keywords

The flashlight action responds to these keywords:
- flashlight
- torch
- light
- flash
- lamp
- toggle

## Features

1. **Availability Check**: Automatically detects if device has flashlight
2. **Quick Toggle**: Simple switch control for instant activation
3. **Visual Feedback**: On/Off status with appropriate icons
4. **Error Handling**: Graceful handling of devices without flashlight
5. **Logging**: All flashlight operations logged via LoggerModel

## Material 3 Design

- Uses `Card.filled` for consistent styling
- Icon changes between `Icons.lightbulb` (on) and `Icons.lightbulb_outline` (off)
- Color scheme integration for icon colors
- Switch widget with primary color for active state

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keyword matching
- Model initialization state
- ChangeNotifier functionality
- Card rendering in loading state
- Widget existence

## Integration

The flashlight provider integrates seamlessly with:
- Pull-to-refresh: Refresh checks flashlight availability
- Logging system: All operations logged
- Theme system: Adapts to light/dark themes
- Provider system: Standard MyProvider pattern