# Text Case Converter Provider Implementation

## Overview

The TextCase provider provides text case conversion utilities for developers and writers. It allows converting text between different case styles including uppercase, lowercase, Title Case, Sentence case, camelCase, PascalCase, snake_case, kebab-case, and CONSTANT_CASE.

## Implementation Details

### File Location
`lib/providers/provider_textcase.dart`

### Model Class: `TextCaseModel`

The `TextCaseModel` class extends `ChangeNotifier` and manages:
- Input text value
- Case type selection (9 options)
- Output converted text
- Conversion history

### Features

1. **Case Conversion Types**
   - UPPERCASE: Converts all characters to uppercase
   - lowercase: Converts all characters to lowercase
   - Title Case: Capitalizes first letter of each word
   - Sentence case: Capitalizes first letter only
   - camelCase: First word lowercase, subsequent words capitalized
   - PascalCase: All words capitalized, no separators
   - snake_case: All lowercase with underscores
   - kebab-case: All lowercase with hyphens
   - CONSTANT_CASE: All uppercase with underscores

2. **Word Splitting**
   - Automatically splits words by spaces
   - Handles snake_case and kebab-case input
   - Converts to target case seamlessly

3. **History Management**
   - Stores up to 10 conversion entries
   - Preserves case type for each entry
   - Tap to reload from history

### UI Components

The `TextCaseCard` widget uses Material 3 components:
- `Card.filled` for the main container
- `SegmentedButton` for case type selection
- `TextField` for input with clear button
- `SelectableText` for output display
- `ListTile` for history entries

### Keywords for Search

The provider registers actions with keywords:
- `textcase, case, uppercase, lowercase, title, sentence, camel, pascal, snake, kebab, constant, convert, text`

## Provider Registration

1. Added to `Global.providerList` in `lib/data.dart`
2. Added to `MultiProvider` in `lib/main.dart`
3. Model imported in both files

## Testing

The provider includes comprehensive tests covering:
- Model initialization
- All case conversions (uppercase, lowercase, title, sentence, camel, pascal, snake, kebab, constant)
- Empty input handling
- Snake_case and kebab-case input conversion
- History management (add, limit, apply from history, clear)
- Input clearing
- Notification tests
- UI widget rendering
- Provider registration

Total: 25 TextCase-specific tests

## Usage Example

```dart
final model = TextCaseModel();
await model.init();

// Convert to uppercase
model.setCaseType('uppercase');
model.setInputText('hello world');
// Output: "HELLO WORLD"

// Convert to camelCase
model.setCaseType('camel');
model.setInputText('hello world');
// Output: "helloWorld"

// Convert snake_case to PascalCase
model.setCaseType('pascal');
model.setInputText('hello_world_test');
// Output: "HelloWorldTest"

// Clear input
model.clearInput();
```

## Notes

- Word splitting handles spaces, underscores, and hyphens
- Maximum 10 history entries (oldest removed when exceeded)
- No external packages required (uses Dart's built-in String methods)
- Case conversion is real-time as user types