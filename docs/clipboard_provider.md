# Clipboard Provider Implementation

## Overview

The Clipboard provider manages clipboard history, allowing users to track, store, and reuse copied text snippets directly from the launcher.

## Features

- **Track clipboard history**: All copied text is saved for future reference
- **Capture from system clipboard**: Import current system clipboard content
- **Copy back to clipboard**: Tap entries to copy them back to system clipboard
- **Manual entry addition**: Add custom text snippets
- **Delete entries**: Remove individual or all entries
- **Timestamp display**: Shows when each entry was created (just now, Xm ago, Xh ago, Xd ago)
- **Persistence**: Entries survive app restarts via SharedPreferences

## Implementation

### File: `lib/providers/provider_clipboard.dart`

### Classes

#### ClipboardEntry
Data model for individual clipboard entries:
- `text`: The copied text content
- `timestamp`: When the entry was created

#### ClipboardModel
State management model extending ChangeNotifier:
- `entries`: List of clipboard entries (max 15)
- `addEntry()`: Add new text to clipboard history
- `copyToSystemClipboard()`: Copy entry to system clipboard
- `captureFromSystemClipboard()`: Import from system clipboard
- `deleteEntry()`: Remove specific entry
- `clearAllEntries()`: Remove all entries

#### ClipboardCard
UI widget displaying clipboard history:
- Card.filled for Material 3 styling
- ListView for entries
- Buttons for add, capture, and clear actions
- Tap to copy functionality with SnackBar feedback

### Provider Registration

Added to `Global.providerList` in `lib/data.dart`:
```dart
providerClipboard,
```

## Usage

### Keywords
`clipboard history copy paste clip text snippet`

### Actions
- Tap any entry to copy it back to system clipboard
- Tap + button to add a new entry manually
- Tap capture button to import current system clipboard
- Tap delete icon to remove individual entries
- Tap clear button to remove all entries

## Data Persistence

Entries are stored in SharedPreferences with key `Clipboard.Entries`:
- Format: `text|timestamp` per entry
- Maximum 15 entries (oldest removed when exceeded)

## Tests

Located in `test/widget_test.dart` under "Clipboard provider tests" group:
- ClipboardEntry JSON serialization
- ClipboardModel initialization and state
- CRUD operations (add, delete, clear)
- Max entries limit behavior
- Widget rendering

## Material 3 Compliance

- Uses `Card.filled` for main container
- ColorScheme for text and icon colors
- `IconButton.styleFrom()` for consistent styling
- SnackBar for copy confirmation feedback

## Dependencies

- `flutter/services.dart` for Clipboard API
- `shared_preferences` for persistence
- `provider` for state management

## Date

- Created: 2026-04-24 (Loop 9)