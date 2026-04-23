# World Clock Provider

## Overview

The World Clock provider displays time in multiple timezones, allowing users to quickly see the current time in different cities around the world.

## Features

- **Multiple timezone display**: Shows time for up to 10 configured timezones
- **Day/night indicators**: Dynamic icons showing sun (day) or moon (night) based on local time
- **Time period labels**: Shows "morning", "afternoon", "evening", or "night" for each timezone
- **Add/remove timezones**: Users can add timezones via dialog or remove by swipe gesture
- **Persistent storage**: Timezone list saved to SharedPreferences
- **Automatic updates**: Time updates every minute

## Supported Timezones

The provider supports 14 common timezones:
- UTC (UTC)
- America/New_York (New York)
- America/Los_Angeles (Los Angeles)
- America/Chicago (Chicago)
- Europe/London (London)
- Europe/Paris (Paris)
- Europe/Berlin (Berlin)
- Asia/Tokyo (Tokyo)
- Asia/Shanghai (Shanghai)
- Asia/Hong_Kong (Hong Kong)
- Asia/Singapore (Singapore)
- Asia/Dubai (Dubai)
- Australia/Sydney (Sydney)
- Pacific/Auckland (Auckland)

## Implementation Details

### Provider Registration

```dart
MyProvider providerWorldClock = MyProvider(
  name: "WorldClock",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);
```

### WorldClockModel

The `WorldClockModel` manages timezone data:
- `timezones`: List of configured timezone identifiers
- `maxTimezones`: Maximum limit of 10 timezones
- `commonTimezones`: Map of timezone IDs to display names

Key methods:
- `init()`: Loads persisted timezones and starts timer
- `addTimezone()`: Adds a timezone (if not duplicate and under limit)
- `removeTimezone()`: Removes a timezone
- `formatTime()`: Returns HH:MM formatted time string
- `getDisplayName()`: Returns friendly city name
- `getDayIcon()`: Returns sun or moon icon based on time
- `getDayPeriod()`: Returns "morning", "afternoon", "evening", or "night"
- `getTimezoneOffset()`: Returns UTC offset for timezone

### WorldClockCard Widget

Displays the timezone list with:
- Title with add button (+ icon)
- Empty state message when no timezones
- ListView of timezone entries
- Each entry shows:
  - Day/night icon (leading)
  - City name (title)
  - Time period (subtitle)
  - Time in HH:MM format (trailing)
- Dismissible gestures to remove timezones
- Long press for confirmation dialog

## Storage

Timezones are stored in SharedPreferences with key `WorldClock.Timezones`.

Default timezones on first launch:
- America/New_York (New York)
- Europe/London (London)
- Asia/Tokyo (Tokyo)

## Keywords

The provider responds to keywords:
- world
- clock
- timezone
- time
- zone
- add
- remove

## UI Components

Uses Material 3 components:
- `Card.filled` for container
- `IconButton` with `IconButton.styleFrom()` for add button
- `ListTile` with dense/compact visual density
- `Dismissible` for swipe-to-delete
- `AlertDialog` for add/remove dialogs
- `FilledButton` for confirm actions

## Tests

Tests cover:
- Provider existence in Global.providerList
- Keywords matching
- WorldClockModel initialization
- Common timezones map contents
- Display name formatting
- Time formatting (HH:MM)
- UTC offset calculation
- Add/remove timezone operations
- Duplicate timezone handling
- Day icon and period calculation
- Max timezone limit (10)
- WorldClockCard widget rendering
- Add button presence

Total World Clock tests: 20 tests