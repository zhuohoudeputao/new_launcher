# Time Provider Implementation

## Overview

The Time provider displays the current local time and optional greeting message in the launcher's main info card list.

## Provider Details

- **Provider Name**: Time
- **Keywords**: time now when is it
- **Settings Keys**: `Time.ShowGreeting`, `Time.ShowSeconds`
- **Widget Key**: Time

## Features

### Time Display

- Current local time in HH:MM format
- Optional seconds display (HH:MM:SS)
- Date display with month name (e.g., "April 25, 14:30")

### Greeting Messages

Time-based greetings with emoji:
- **Night (22:00-06:00)**: "Don't strain yourself too much. Good night 🌙"
- **Early Morning (06:00-09:00)**: "Good morning! It's beautiful outside ☀"
- **Late Morning (09:00-12:00)**: "Good morning ☀"
- **Afternoon (12:00-18:00)**: "Good afternoon! Take a cup of coffee ☕"
- **Evening (18:00-22:00)**: "Have a good night 🌙"

### Timer-Based Updates

- Updates every second if seconds display is enabled
- Updates every minute otherwise (optimized for performance)
- Uses initial delay timer to align with minute boundaries

## Implementation

### Provider Structure

```dart
MyProvider providerTime = MyProvider(
    name: "Time",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Settings

- **Time.ShowGreeting**: Toggle greeting message display (default: true)
- **Time.ShowSeconds**: Toggle seconds display (default: false)

### Widget (_TimeWidget)

StatefulWidget with timer management:
- `_initialTimer`: Delay timer for minute-aligned updates
- `_periodicTimer`: Regular update timer
- `_disposed`: Flag to prevent setState after dispose

### Timer Logic

```dart
if (showSeconds) {
  _periodicTimer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {});
  });
} else {
  final initialDelay = 60 - now.second;
  _initialTimer = Timer(Duration(seconds: initialDelay), () {
    setState(() {});
    _periodicTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {});
    });
  });
}
```

## Month Names

```dart
const Map<int, String> months = {
  1: 'January', 2: 'February', 3: 'March', 4: 'April',
  5: 'May', 6: 'June', 7: 'July', 8: 'August',
  9: 'September', 10: 'October', 11: 'November', 12: 'December'
};
```

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching (time, now, when, is, it)
- Widget rendering with greeting and seconds options

## Related Files

- `lib/providers/provider_time.dart` - Provider implementation
- `lib/data.dart` - InfoModel for widget storage
- `lib/ui.dart` - customInfoWidget helper