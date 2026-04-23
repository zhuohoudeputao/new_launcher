# Calendar Provider Implementation

## Overview

The Calendar provider provides a monthly calendar widget for date visualization. Users can view the current month, navigate between months, and see today's date highlighted.

## Implementation Details

### Provider Structure

Located in `lib/providers/provider_calendar.dart`:

```dart
MyProvider providerCalendar = MyProvider(
  name: "Calendar",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);
```

### Features

1. **Monthly Calendar Grid**
   - 7-column grid showing days of the week
   - Weekday headers (S, M, T, W, T, F, S)
   - Days from previous/next months shown as dimmed

2. **Month Navigation**
   - Left/right chevron buttons to navigate months
   - Month title with year display
   - Tap month title to return to current month

3. **Today Highlighting**
   - Today's date shown with primary color circle
   - Non-current month days dimmed
   - Sunday dates shown in error (red) color

4. **Week Number Display**
   - Current week number shown at bottom
   - ISO week number calculation

5. **Automatic Day Change**
   - Timer updates display at midnight
   - Ensures "today" highlight remains accurate

### UI Components

- `CalendarCard`: Main calendar widget
  - Uses `Card.filled` for Material 3 style
  - GridView for calendar grid
  - IconButton for navigation

### Keywords

Users can search for the calendar using:
- calendar, month, date, day, week, schedule

## Testing

Tests are located in `test/widget_test.dart`:

- Provider existence tests
- Global.providerList inclusion test
- Widget rendering tests
- Navigation button tests
- Weekday header display tests

## Integration

The provider is added to `Global.providerList` in `lib/data.dart`:

```dart
providerCalendar,
```

## Date Calculations

### Week Number

Uses ISO week number calculation:
```dart
int _getWeekNumber(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final days = date.difference(firstDayOfYear).inDays;
  return ((days + firstDayOfYear.weekday - 1) / 7).floor() + 1;
}
```

### Days in Month

Generates a complete grid including padding days from previous/next months:
```dart
List<DateTime> _getDaysInMonth(DateTime month) {
  // ... calculates start/end padding
}
```

## Material 3 Compliance

- Uses `Card.filled` component
- ColorScheme colors for highlighting
- Consistent styling with other providers