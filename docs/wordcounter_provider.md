# Word Counter Provider

## Overview

The Word Counter provider is a utility for counting characters, words, lines, sentences, and paragraphs in text. It provides real-time text analysis for writers, developers, and anyone who needs to analyze text content.

## Features

- **Character count**: Total characters including spaces
- **Character count (no spaces)**: Characters excluding whitespace
- **Word count**: Number of words separated by whitespace
- **Line count**: Number of lines separated by newline characters
- **Sentence count**: Number of sentences separated by punctuation (.!?)
- **Paragraph count**: Number of paragraphs separated by double newlines
- **Real-time counting**: Updates as text is entered
- **Clear button**: Quick reset of input

## Implementation

### Model (WordCounterModel)

Located in `lib/providers/provider_wordcounter.dart`:

```dart
class WordCounterModel extends ChangeNotifier {
  String _inputText = '';
  int _charCount = 0;
  int _charCountNoSpaces = 0;
  int _wordCount = 0;
  int _lineCount = 0;
  int _sentenceCount = 0;
  int _paragraphCount = 0;
  bool _isInitialized = false;

  // Getters for all counts
  String get inputText => _inputText;
  int get charCount => _charCount;
  int get charCountNoSpaces => _charCountNoSpaces;
  int get wordCount => _wordCount;
  int get lineCount => _lineCount;
  int get sentenceCount => _sentenceCount;
  int get paragraphCount => _paragraphCount;
  bool get isInitialized => _isInitialized;

  void setInputText(String value) {
    _inputText = value;
    _count();
    notifyListeners();
  }

  void _count() {
    // Character count
    _charCount = _inputText.length;
    _charCountNoSpaces = _inputText.replaceAll(RegExp(r'\s'), '').length;
    
    // Word count
    _wordCount = _inputText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    
    // Line count
    _lineCount = _inputText.isEmpty ? 0 : _inputText.split('\n').length;
    
    // Sentence count
    _sentenceCount = _inputText
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .length;
    
    // Paragraph count
    _paragraphCount = _inputText
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .length;
  }

  void clearInput() {
    _inputText = '';
    _charCount = 0;
    _charCountNoSpaces = 0;
    _wordCount = 0;
    _lineCount = 0;
    _sentenceCount = 0;
    _paragraphCount = 0;
    notifyListeners();
  }
}
```

### Widget (WordCounterCard)

The widget displays:
- Text input field with multiline support
- Six count chips showing all statistics
- Clear button when text is present

### Provider Registration

The provider is registered in `lib/data.dart`:

```dart
Global.providerList = [
  ...
  providerWordCounter,
];
```

And the model is added to MultiProvider in `lib/main.dart`:

```dart
MultiProvider(
  providers: [
    ...
    ChangeNotifierProvider.value(value: wordCounterModel),
  ],
)
```

## Keywords

The following keywords trigger the Word Counter card:
- wordcounter
- word
- count
- character
- char
- line
- sentence
- paragraph
- text
- letter

## Testing

Tests are located in `test/widget_test.dart` under the "WordCounter provider tests" group:

- Model initialization
- Character counting (with and without spaces)
- Word counting
- Line counting
- Sentence counting
- Paragraph counting
- Complex text handling
- Clear input functionality
- Listener notifications
- Widget rendering tests

## Material 3 Design

The widget uses Material 3 components:
- `Card.filled` for the main container
- `Chip` with icons for count display
- `TextField` with OutlineInputBorder
- `IconButton` for clear functionality

## Use Cases

1. **Writing**: Check word count for articles, essays, or documents
2. **Development**: Analyze string lengths for UI constraints
3. **Translation**: Verify text length compatibility
4. **Editing**: Quick text statistics for content optimization