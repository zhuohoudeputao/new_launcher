# Quick Contacts Provider

## Overview

The Quick Contacts provider (also known as Speed Dial) enables quick access to frequently used contacts directly from the launcher. Users can add, edit, and delete contacts for quick calling or messaging.

## Features

- **Quick dial**: Tap a contact to initiate a call
- **Quick SMS**: Tap the message icon to send SMS
- **Contact management**: Add, edit, and delete contacts
- **Maximum storage**: 15 contacts stored (oldest removed when limit exceeded)
- **Persistence**: Contacts saved via SharedPreferences
- **Phone normalization**: Automatically formats phone numbers

## Implementation

### Model: QuickContactsModel

Located in `lib/providers/provider_quickcontacts.dart`.

```dart
class QuickContactsModel extends ChangeNotifier {
  List<QuickContact> _contacts = [];
  static const int maxContacts = 15;
  bool _isInitialized = false;
  
  List<QuickContact> get contacts => List.unmodifiable(_contacts);
  int get length => _contacts.length;
  bool get isInitialized => _isInitialized;
  bool get hasContacts => _contacts.isNotEmpty;
}
```

### Data Model: QuickContact

```dart
class QuickContact {
  final String name;
  final String phone;
  
  QuickContact({required this.name, required this.phone});
}
```

### Card Widget: QuickContactsCard

- Material 3 `Card.filled` style
- Loading state indicator
- Empty state message
- Contact list with actions
- Add and clear buttons

### Dialog Widgets

- `AddContactDialog`: Add new contact with name and phone
- `EditContactDialog`: Edit existing contact

## Usage

### Adding a Contact

```dart
model.addContact('John Doe', '+1234567890');
```

### Calling a Contact

```dart
await model.callContact(index);
// Opens phone dialer with the contact's number
```

### Sending SMS

```dart
await model.smsContact(index);
// Opens SMS app with the contact's number
```

### Deleting a Contact

```dart
model.deleteContact(index);
```

## Keywords

The provider responds to these keywords:
- `contact`
- `contacts`
- `quick`
- `dial`
- `phone`
- `call`
- `speed`
- `speeddial`

## Dependencies

- `url_launcher`: For opening phone dialer and SMS app
- `shared_preferences`: For persistence
- `provider`: For state management

## Phone Number Normalization

Phone numbers are automatically normalized:
- Dashes and spaces removed
- Plus sign preserved for international numbers

Example:
- Input: `123-456-7890` -> Output: `1234567890`
- Input: `+1 (234) 567-890` -> Output: `+1234567890`

## Testing

The provider includes comprehensive tests:
- Model initialization
- Add, update, delete operations
- Persistence and loading
- Phone normalization
- Widget rendering tests
- Dialog tests

See `test/widget_test.dart` under "Quick Contacts provider tests" group.