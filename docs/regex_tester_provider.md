# RegexTester Provider

## Overview

The RegexTester provider is a developer utility for testing regular expressions against sample text with real-time matching and highlighted results.

## Features

### Pattern Testing
- Real-time regex pattern matching as you type
- Match highlighting with color-coded display
- Match count and position information
- Invalid regex detection with error messages

### Regex Options
- **Case Sensitive**: Toggle case-sensitive matching
- **Multiline**: Enable multiline mode (^ and $ match line boundaries)
- **Dot All**: Enable dotAll mode (. matches newlines)

### Captured Groups
- Automatic extraction of captured groups from patterns
- Group position information (start, end, matched text)

### History
- Save regex patterns to history (up to 10 entries)
- Load previous patterns from history
- Clear history with confirmation dialog

## Implementation

### Model: RegexModel

```dart
class RegexModel extends ChangeNotifier {
  String _pattern = '';
  String _testString = '';
  List<RegexMatch> _matches = [];
  bool _isValid = true;
  String _errorMessage = '';
  bool _caseSensitive = true;
  bool _multiline = false;
  bool _dotAll = false;
  List<RegexHistoryEntry> _history = [];
  bool _isInitialized = false;

  // Methods:
  void init();
  void setPattern(String value);
  void setTestString(String value);
  void toggleCaseSensitive();
  void toggleMultiline();
  void toggleDotAll();
  void addToHistory();
  void loadFromHistory(int index);
  void clearHistory();
  void clearPattern();
  void clearTestString();
  void clearAll();
  void refresh();
}
```

### Match Structure

```dart
class RegexMatch {
  final int start;
  final int end;
  final String matched;
  final List<String?> groups;
}
```

### History Entry

```dart
class RegexHistoryEntry {
  final String pattern;
  final String testString;
  final int matchCount;
  final DateTime timestamp;
}
```

### Widget: RegexTesterCard

Uses Material 3 components:
- `Card.filled` for container
- `FilterChip` for regex options toggles
- `TextField` for pattern and test string input
- `RichText` for highlighted match display

## Keywords

`regex, regular, expression, test, match, pattern`

## Testing

Provider tests include:
- Provider existence in Global.providerList
- Keywords verification
- Model initialization
- Pattern matching functionality
- Case sensitivity toggling
- Multiline and dotAll options
- Captured groups extraction
- History operations (add, load, clear)
- Widget rendering

## Usage Example

```dart
// Access through Global.infoModel
Global.infoModel.addInfoWidget("RegexTester", RegexTesterCard(), title: "Regex Tester");

// Or use keywords to search
// Type "regex" or "pattern" in search field
```

## Related Providers

- **TextEncoder**: Base64, URL, HTML, JSON encoding/decoding
- **JsonFormatter**: JSON validation and formatting
- **HashGenerator**: MD5, SHA1, SHA256, SHA512 hash generation