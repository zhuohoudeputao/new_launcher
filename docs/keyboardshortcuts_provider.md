# KeyboardShortcuts Provider

## Overview

The KeyboardShortcuts provider provides a comprehensive reference of keyboard shortcuts across multiple platforms (Windows, Mac, Linux). It covers common shortcuts for general use, browser, text editing, file management, development, and system operations.

## Implementation

### File Location
`lib/providers/provider_keyboard_shortcuts.dart`

### Provider Definition
```dart
MyProvider providerKeyboardShortcuts = MyProvider(
    name: "KeyboardShortcuts",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Model Class
`KeyboardShortcutsModel` extends `ChangeNotifier` and manages:
- Search query for filtering shortcuts
- Selected shortcut detail view
- Category filtering
- Clipboard copy functionality

### Shortcut Data
`KeyboardShortcut` class contains:
- `action`: Description of what the shortcut does
- `windows`: Windows keyboard shortcut
- `mac`: macOS keyboard shortcut
- `linux`: Linux keyboard shortcut
- `category`: Category enum

### Categories
The provider includes 50 keyboard shortcuts across 6 categories:
- **General**: New Window, Close Window, Zoom, Help, Menu
- **Browser**: New Tab, Close Tab, Refresh, URL Bar, Downloads
- **Text Editing**: Copy, Paste, Cut, Undo, Redo, Find
- **File Manager**: Open, Save, Save As, Print, Rename, Delete
- **Developer**: Go to Line, Toggle Comment, Find in Files, Format Code, Terminal
- **System**: Switch Window, Minimize, Maximize, Lock Screen, Screenshot

### Features
1. **Search**: Filter shortcuts by action or key combination
2. **Category Filter**: ActionChips for category filtering
3. **Detail View**: Tap a shortcut to see all platform variants
4. **Copy All**: Copy shortcut info for all platforms

### UI Components
- `KeyboardShortcutsCard`: Main widget displaying the reference
- Search field with clear button
- Category filter ActionChips
- Shortcut list with ListTile items
- Detail view with platform-specific shortcuts

### Keywords
`keyboard shortcut hotkey key combo shortcut reference`

### Material 3 Components
- `Card.filled` for main container
- `ActionChip` for category filtering
- `TextField` with search decoration
- `ListTile` for shortcut items
- `SelectableText` for key combinations

## Usage

The Keyboard Shortcuts reference appears as an info widget in the main card list. Users can:
1. Search for specific shortcuts
2. Filter by category
3. Tap shortcuts to view all platform variants
4. Copy shortcut information to clipboard