# Regex Tester Provider Implementation

## Overview

The Regex Tester provider tests regular expressions against sample text with real-time matching.

## Provider Details

- **Provider Name**: RegexTester
- **Keywords**: regex, regular, expression, test, match, pattern
- **Model**: regexModel

## Features

### Pattern Testing

- Real-time regex matching
- Highlighted matches with color coding
- Match count and position information

### Regex Options

- Case Sensitive (FilterChip toggle)
- Multiline (FilterChip toggle)
- Dot All (FilterChip toggle)

### Match Information

- Match start/end positions
- Matched text display
- Captured groups display

## Model (RegexModel)

```dart
class RegexModel extends ChangeNotifier {
  String _pattern = '';
  String _testString = '';
  bool _caseSensitive = true;
  bool _multiline = false;
  bool _dotAll = false;
  List<RegexMatch> _matches = [];
  String? _errorMessage;
  final List<RegexHistoryEntry> _history = [];
  static const int maxHistory = 10;
  
  void setPattern(String value);
  void setTestString(String value);
  void toggleCaseSensitive();
  void toggleMultiline();
  void toggleDotAll();
  void _testRegex();
  void addToHistory();
  void clearHistory();
  void useHistoryEntry(RegexHistoryEntry entry);
}
```

### RegexMatch

```dart
class RegexMatch {
  int start;
  int end;
  String matchedText;
  List<String> groups;
}
```

## Widget (RegexTesterCard)

- Card.filled style
- TextField for regex pattern
- TextField for test string
- FilterChip toggles for options
- RichText with highlighted matches
- Match count display
- History toggle view

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching
- Model initialization and state
- Pattern matching
- Option toggles (case sensitive, multiline, dotAll)
- Invalid regex detection
- History operations
- Widget rendering

## Related Files

- `lib/providers/provider_regex.dart` - Provider implementation