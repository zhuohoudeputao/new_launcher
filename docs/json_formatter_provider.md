# JSON Formatter Provider

## Overview

The JSON Formatter provider is a developer utility for validating and formatting JSON data. It provides real-time validation, configurable formatting options, and history tracking.

## Implementation Details

### Model: JsonModel

Located in `lib/providers/provider_json.dart`, the `JsonModel` class manages:
- Input/output JSON strings
- Validation state and error messages
- Formatting configuration (indentation, minification)
- History of saved JSON entries

### Key Features

1. **Real-time Validation**
   - Validates JSON input as user types
   - Displays error messages for invalid JSON
   - Shows formatted output for valid JSON

2. **Configurable Formatting**
   - Indentation options: 2, 4, or 8 spaces
   - Minification toggle for compact output
   - Uses `JsonEncoder.withIndent()` for formatting

3. **History Management**
   - Save valid JSON to history (max 10 entries)
   - Load previous entries with one tap
   - Clear history with confirmation dialog

4. **Material 3 Components**
   - `Card.filled` for container
   - `SegmentedButton` for indentation selection
   - `Switch` for minification toggle
   - `TextField` for input
   - `SelectableText` for output

## Usage

### Keywords
- json, format, validate, pretty, minify, indent, parse

### Actions
The provider adds one action: "JSON Formatter" which displays the formatter card.

### State Management
- Uses `ChangeNotifier` pattern
- Registered in `MultiProvider` in `main.dart`
- Global instance: `jsonModel`

## Code Structure

```dart
class JsonModel extends ChangeNotifier {
  String _input = '';
  String _output = '';
  bool _isValid = false;
  String _errorMessage = '';
  int _indentSpaces = 2;
  List<JsonHistoryEntry> _history = [];
  bool _showMinified = false;
  
  void setInput(String value);
  void setIndentSpaces(int value);
  void toggleMinified();
  void addToHistory();
  void loadFromHistory(int index);
  void clearHistory();
  void clear();
}
```

## Testing

Tests cover:
- Provider registration in Global.providerList
- Model initialization and state
- JSON validation (valid and invalid)
- Formatting with different indentation levels
- Minification toggle
- History management
- Widget rendering

## Dependencies

- `dart:convert` for JSON encoding/decoding
- `flutter/material.dart` for UI components
- `provider` for state management

## Notes

- History entries include timestamp for display
- Error messages use Material 3 error container colors
- Output is scrollable for large JSON objects
- Clear button appears when input is present