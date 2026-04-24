# TextEncoder Provider

## Overview

The TextEncoder provider offers text encoding and decoding utilities for developers. It supports multiple encoding formats including Base64, URL encoding, HTML entity encoding, and JSON string escaping.

## Features

### Encoding Modes

1. **Base64**
   - Encode: Converts text to Base64 format
   - Decode: Converts Base64 back to plain text
   - Example: `Hello World` → `SGVsbG8gV29ybGQ=`

2. **URL (Percent Encoding)**
   - Encode: Converts text for safe URL transmission
   - Decode: Converts URL-encoded text back to plain text
   - Example: `hello world` → `hello%20world`

3. **HTML (Entity Encoding)**
   - Encode: Converts special characters to HTML entities
   - Decode: Converts HTML entities back to characters
   - Example: `<div>` → `&lt;div&gt;`
   - Supports: `&`, `<`, `>`, `"`, `'`, spaces, and special symbols

4. **JSON (String Escaping)**
   - Escape: Escapes special characters for JSON strings
   - Unescape: Removes JSON escape sequences
   - Example: `Line1\nLine2` → `Line1\\nLine2`
   - Handles: quotes, backslashes, newlines, tabs, etc.

### Additional Features

- **Real-time encoding**: Output updates as you type
- **Swap operation**: Toggle between encode and decode with one tap
- **History**: Up to 10 previous encodings stored
- **Copy to clipboard**: Quick copy of output
- **Error handling**: Clear error messages for invalid input
- **History loading**: Reuse previous encodings

## Implementation Details

### Model: `TextEncoderModel`

```dart
class TextEncoderModel extends ChangeNotifier {
  String _inputText = "";
  String _outputText = "";
  String _mode = "base64";       // 'base64', 'url', 'html', 'json'
  String _operation = "encode";  // 'encode' or 'decode'
  String? _error;
  List<_HistoryEntry> _history = [];
  
  // Methods
  void setInputText(String text);
  void setMode(String mode);
  void setOperation(String operation);
  void swapOperation();
  void clearInput();
  void addToHistory();
  void loadFromHistory(int index);
  void clearHistory();
}
```

### Provider Registration

```dart
MyProvider providerTextEncoder = MyProvider(
  name: "TextEncoder",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);
```

### Actions Provided

- Base64 Encode
- Base64 Decode
- URL Encode
- URL Decode
- HTML Encode
- HTML Decode
- JSON Escape
- JSON Unescape

### Keywords

```
encode, decode, base64, url, html, json, escape, text, string, convert
```

## UI Components

### TextEncoderCard

The main widget displays:
- Mode selector (SegmentedButton: Base64, URL, HTML, JSON)
- Operation selector (SegmentedButton: Encode, Decode)
- Input text field
- Output display with copy button
- Error display for invalid input
- Action buttons (swap, clear, save to history)
- History section (when visible)

### Material 3 Components Used

- `Card.filled` for main container
- `SegmentedButton` for mode and operation selection
- `TextField` for input
- `SelectableText` for output display
- `IconButton` for actions

## Testing

### Test Coverage

Total: 57 TextEncoder-specific tests

#### Model Tests
- Initialization
- Mode/operation switching
- Base64 encode/decode
- URL encode/decode
- HTML encode/decode
- JSON escape/unescape
- History management
- Notification tests
- Roundtrip tests

#### Widget Tests
- Loading state
- Initialized state
- Output display
- Error display

#### Provider Tests
- Provider registration
- Provider existence in Global.providerList

## Usage Example

```dart
// Base64 encoding
model.setMode('base64');
model.setOperation('encode');
model.setInputText("Hello World");
// Output: "SGVsbG8gV29ybGQ="

// URL decoding
model.setMode('url');
model.setOperation('decode');
model.setInputText("hello%20world");
// Output: "hello world"

// HTML encoding
model.setMode('html');
model.setOperation('encode');
model.setInputText("<script>alert('test')</script>");
// Output: "&lt;script&gt;alert(&apos;test&apos;)&lt;/script&gt;"

// JSON escaping
model.setMode('json');
model.setOperation('encode');
model.setInputText("Line1\nLine2\tTabbed");
// Output: "Line1\\nLine2\\tTabbed"
```

## Error Handling

- Invalid Base64 input: Shows FormatException error
- Invalid URL encoding: Shows decoding error
- Empty input: Produces empty output
- History limit: Maximum 10 entries, oldest removed first

## Files

- `lib/providers/provider_textencoder.dart` - Provider implementation
- `test/widget_test.dart` - Test cases (TextEncoder provider tests group)

## Dependencies

No external packages required. Uses Dart's built-in:
- `dart:convert` for Base64 encoding
- `Uri` for URL encoding/decoding