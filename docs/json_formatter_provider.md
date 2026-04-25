# JSON Formatter Provider Implementation

## Overview

The JSON Formatter provider validates and formats JSON input for developers.

## Provider Details

- **Provider Name**: JsonFormatter
- **Keywords**: json, format, validate, pretty, minify, indent, parse
- **Model**: jsonModel

## Features

### Validation

- Real-time JSON validation
- Error message display for invalid JSON
- Visual indication of validity

### Formatting Options

- Indentation: 2, 4, or 8 spaces (SegmentedButton)
- Minify option (compact output)
- Switch toggle for minification

### History

- Save formatted JSON to history (up to 10 entries)
- Load previous JSON inputs from history
- Clear history with confirmation dialog

## Model (JsonModel)

```dart
class JsonModel extends ChangeNotifier {
  String _input = '';
  String _output = '';
  int _indentation = 2;
  bool _minify = false;
  bool _isValid = false;
  String? _errorMessage;
  final List<JsonHistoryEntry> _history = [];
  static const int maxHistory = 10;
  
  void setInput(String value);
  void setIndentation(int value);
  void toggleMinify();
  void _formatJson();
  void addToHistory();
  void clearHistory();
  void useHistoryEntry(JsonHistoryEntry entry);
}
```

## JSON Processing

```dart
import 'dart:convert';

// Parse and validate
final decoded = jsonDecode(input);

// Format with indentation
final encoded = JsonEncoder.withIndent('  ').convert(decoded);

// Minify
final minified = jsonEncode(decoded);
```

## Widget (JsonFormatterCard)

- Card.filled style
- SegmentedButton for indentation selection
- Switch for minify toggle
- TextField for JSON input
- SelectableText for formatted output
- Error message display
- History toggle view

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching
- Model initialization and state
- JSON validation (valid/invalid)
- Formatting with indentation
- Minification
- History operations
- Widget rendering

## Related Files

- `lib/providers/provider_json.dart` - Provider implementation