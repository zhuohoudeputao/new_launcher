# Battery Status Provider

## Overview

The Battery Status Provider displays device battery information in the launcher's main card list. It shows battery level, charging state, and provides refresh functionality.

## Features

- **Battery level display**: Shows current battery percentage
- **Charging state**: Indicates whether device is charging, discharging, full, or connected but not charging
- **Dynamic icon**: Battery icon changes based on level and charging state
- **Color indication**: Battery color changes based on level (green for >50%, orange for 20-50%, red for <20%)
- **Refresh button**: Manual refresh to update battery status
- **Real-time updates**: Listen to battery state changes automatically

## Implementation

### Files

- `lib/providers/provider_battery.dart` - Battery provider implementation

### Dependencies

- `battery_plus: ^6.0.0` - Battery status plugin

### Provider Structure

```dart
MyProvider providerBattery = MyProvider(
    name: "Battery",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### BatteryModel

The `BatteryModel` class manages battery state:

```dart
class BatteryModel extends ChangeNotifier {
  int _level = 0;
  BatteryState _state = BatteryState.unknown;
  bool _isInitialized = false;
  
  int get level => _level;
  BatteryState get state => _state;
  bool get isCharging => _state == BatteryState.charging || 
                          _state == BatteryState.connectedNotCharging;
  bool get isInitialized => _isInitialized;
  
  Future<void> init() async { ... }
  Future<void> refresh() async { ... }
}
```

### BatteryCard Widget

The `BatteryCard` widget displays battery information with Material 3 design:

- Uses `Card.filled` for primary styling
- Shows battery icon, level percentage, and state text
- Includes refresh button with tooltip
- Dynamic icon based on level:
  - `battery_full` (90%+)
  - `battery_6_bar` (70%+)
  - `battery_5_bar` (50%+)
  - `battery_3_bar` (30%+)
  - `battery_2_bar` (20%+)
  - `battery_1_bar` (10%+)
  - `battery_0_bar` (<10%)
  - `battery_charging_full` (when charging)

### Battery States

The provider handles all BatteryState enum values:
- `BatteryState.full` - Battery is fully charged
- `BatteryState.charging` - Device is charging
- `BatteryState.discharging` - Device is using battery
- `BatteryState.connectedNotCharging` - Connected to power but not charging
- `BatteryState.unknown` - State cannot be determined

## Usage

The battery provider is automatically initialized when the app starts. Users can:

1. View battery status in the main card list
2. Type "battery", "power", "charge", or "level" to trigger the battery action
3. Tap the refresh button to update battery status

## Testing

Tests for the battery provider include:
- Provider existence check
- Keywords validation
- BatteryModel initial state
- BatteryCard rendering in loading state
- Battery icon mapping logic

## Integration

The battery provider is added to:
- `Global.providerList` in `lib/data.dart`
- `MultiProvider` in `lib/main.dart`
- Provider list tests updated to expect 8 providers