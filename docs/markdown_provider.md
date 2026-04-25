# Markdown Preview Provider Implementation

## Overview

The Markdown Preview provider allows users to preview markdown text with real-time rendering. It uses the `flutter_markdown` package for proper markdown rendering with Material 3 styling.

## Features

- **Real-time preview**: As you type, the markdown is rendered below
- **History management**: Save up to 10 markdown documents for quick access
- **Selectable text**: Preview text is selectable for easy copying
- **Material 3 styling**: Proper styling for headers, code blocks, blockquotes, etc.

## Implementation Details

### Files Created/Modified

1. **lib/providers/provider_markdown.dart** - Main provider implementation
2. **lib/data.dart** - Added provider import and registration
3. **lib/main.dart** - Added model to MultiProvider

### Dependencies

Added `flutter_markdown: ^0.7.0` to `pubspec.yaml` for markdown rendering.

### Model Structure

```dart
class MarkdownPreviewModel extends ChangeNotifier {
  String _inputText = '';
  bool _isInitialized = false;
  List<MarkdownHistoryEntry> _history = [];
  int _maxHistoryLength = 10;
  
  // Methods: init, setInputText, addToHistory, loadFromHistory, clearInput, clearHistory, refresh
}
```

### History Entry Structure

```dart
class MarkdownHistoryEntry {
  final String text;
  final DateTime timestamp;
  
  String get formattedTime {
    // Returns: 'just now', 'Xm ago', 'Xh ago', 'Xd ago'
  }
}
```

### Widget Structure

```dart
class MarkdownPreviewCard extends StatelessWidget {
  // TextField for input
  // Markdown widget for preview
  // ListView for history entries
  // Clear history with confirmation dialog
}
```

### Markdown StyleSheet

The Markdown widget uses a custom `MarkdownStyleSheet` for Material 3 styling:
- Headers: Bold with proper sizing (h1: 24, h2: 22, h3: 20)
- Paragraph: Standard text with onSurface color
- Code blocks: SurfaceContainerHighest background with primary color
- Blockquotes: onSurfaceVariant color with rounded decoration

### Keywords

```
markdown, preview, md, text, format, render, document
```

## Usage

1. Type markdown text in the input field
2. Preview appears below with proper styling
3. Click save icon to add to history
4. Click history entries to reload previous documents
5. Clear button removes current input
6. Clear History button removes all saved documents

## Tests Added

18 tests added covering:
- Model initialization
- Input text operations
- History management (add, load, clear, max limit)
- Time formatting (just now, minutes, hours, days ago)
- Widget rendering
- Provider registration
- Keywords validation

## Integration

The provider is registered in:
- `Global.providerList` as `providerMarkdownPreview`
- `MultiProvider` with `ChangeNotifierProvider.value(value: markdownPreviewModel)`
- Tests import via `package:new_launcher/providers/provider_markdown.dart`