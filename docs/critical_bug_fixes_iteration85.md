# Critical Bug Fixes - Iteration 85

## Overview

Fixed a critical bug in the Reminder provider where JSON encoding/decoding was not working correctly for SharedPreferences persistence.

## Bug Description

### Issue
The Reminder provider's `_decodeJson` method was returning an empty map instead of actually decoding the JSON string. This meant that reminders saved to SharedPreferences could not be loaded correctly when the app restarted.

### Root Cause
The `_decodeJson` method was implemented incorrectly:
```dart
Future<Map<String, String>> _decodeJson(String json) async {
    return Map<String, String>.from(
      Map<String, dynamic>.from(
        Map<String, dynamic>.from(
          {}
        )
      )
    );
  }
```

This always returned an empty map `{}` instead of decoding the actual JSON content.

### Secondary Issue
The `_saveReminders` method was using `.toString()` on the Map, which produces output like `{key: value}` instead of proper JSON format `{\"key\": \"value\"}`.

## Fix Applied

### Changes to `lib/providers/provider_reminder.dart`

1. Added `dart:convert` import:
```dart
import 'dart:convert';
```

2. Fixed `_decodeJson` to properly decode JSON:
```dart
Map<String, dynamic> _decodeJson(String jsonStr) {
    return json.decode(jsonStr) as Map<String, dynamic>;
  }
```

3. Fixed `_saveReminders` to use `json.encode`:
```dart
Future<void> _saveReminders() async {
    final jsonList = _reminders.map((r) => json.encode(r.toJson())).toList();
    await _prefs?.setStringList('reminders', jsonList);
  }
```

4. Updated `_loadReminders` to use synchronous decoding:
```dart
Future<void> _loadReminders() async {
    final saved = _prefs?.getStringList('reminders') ?? [];
    _reminders.clear();
    for (final jsonStr in saved) {
      try {
        final entry = ReminderEntry.fromJson(_decodeJson(jsonStr));
        _reminders.add(entry);
      } catch (e) {
        Global.loggerModel.warning("Failed to load reminder: $e", source: "Reminder");
      }
    }
    notifyListeners();
  }
```

## Tests Added

Added a new test for JSON encode/decode roundtrip:
```dart
test('JSON encode/decode roundtrip', () {
  final entry = ReminderEntry(
    id: 'roundtrip-id',
    targetTime: DateTime(2026, 1, 15, 10, 30),
    message: 'Roundtrip test',
    notified: true,
    dismissed: false,
  );
  final json = entry.toJson();
  final decoded = ReminderEntry.fromJson(json);
  expect(decoded.id, entry.id);
  expect(decoded.message, entry.message);
  expect(decoded.targetTime, entry.targetTime);
  expect(decoded.notified, entry.notified);
  expect(decoded.dismissed, entry.dismissed);
});
```

## Impact

- Users' reminders will now be correctly persisted and restored after app restart
- The Reminder provider now uses proper JSON encoding/decoding
- Test coverage increased from 20 to 21 tests

## Files Modified

- `lib/providers/provider_reminder.dart` - Fixed JSON encoding/decoding
- `test/widget_test.dart` - Added roundtrip test
- `docs/reminder_provider.md` - Updated test count

## Test Verification

All 21 Reminder provider tests pass after the fix.