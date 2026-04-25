# Reminder Provider Implementation

## Overview

The Reminder provider provides simple timed reminders with notifications for users to track important events and tasks.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_reminder.dart`

### Key Classes

#### ReminderEntry
- `id`: Unique identifier for the reminder
- `targetTime`: DateTime for when the reminder should trigger
- `message`: Custom message for the reminder
- `notified`: Flag indicating if notification was shown
- `dismissed`: Flag indicating if reminder was dismissed

#### ReminderModel (ChangeNotifier)
- `reminders`: List of active reminders
- `expiredReminders`: List of expired but not dismissed reminders
- `maxReminders`: Maximum 10 reminders stored
- `isInitialized`: Initialization state flag

### Key Methods

#### Initialization
- `init()`: Loads saved reminders from SharedPreferences, starts update timer

#### Reminder Management
- `addReminder(targetTime, message)`: Add new reminder with target time and message
- `deleteReminder(id)`: Delete specific reminder
- `dismissReminder(id)`: Mark reminder as dismissed
- `clearAll()`: Clear all reminders
- `clearDismissed()`: Clear only dismissed reminders

#### Timer Management
- `_startUpdateTimer()`: Starts 1-second interval timer for countdown updates
- `_checkExpiredReminders()`: Checks for expired reminders and shows notifications
- `_showNotification(reminder)`: Shows SnackBar notification for expired reminder

### UI Components

#### ReminderCard
- Displays list of active and expired reminders
- Countdown display showing remaining time
- Add reminder button with date/time picker
- Clear all button with confirmation dialog
- Visual indicators for urgency (< 5 minutes)

#### AddReminderDialog
- Message input field
- Date picker button
- Time picker button
- Add/Cancel buttons

### Features

1. **Add Reminders**: Add reminders with custom messages and target date/time
2. **Countdown Display**: Shows remaining time in days/hours/minutes
3. **Expired Detection**: Automatically detects when reminders expire
4. **Notifications**: SnackBar notification when reminder expires
5. **Urgency Indicator**: Visual warning for reminders < 5 minutes away
6. **Persistence**: Reminders saved via SharedPreferences
7. **Maximum Limit**: 10 reminders stored, oldest removed when exceeded

### Keywords
`reminder, alarm, notify, alert, schedule, time, remind`

## Test Coverage

Tests include:
- Provider existence and initialization
- Reminder CRUD operations
- Expired reminder detection
- ReminderEntry toJson/fromJson
- Model refresh
- Widget rendering (loading and initialized states)
- Global.providerList inclusion

## Integration

The Reminder provider is integrated into:
- `lib/data.dart`: Added to Global.providerList
- `lib/main.dart`: Added to MultiProvider

## Usage Example

```dart
// Add a reminder for 1 hour from now
final targetTime = DateTime.now().add(Duration(hours: 1));
await reminderModel.addReminder(targetTime, 'Meeting starts in 1 hour');

// Get active reminders
final reminders = reminderModel.reminders;

// Delete a specific reminder
await reminderModel.deleteReminder(reminder.id);

// Clear all reminders
await reminderModel.clearAll();
```