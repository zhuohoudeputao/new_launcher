# Lorem Ipsum Provider Implementation

## Overview

The LoremIpsum provider implements a placeholder text generator that allows users to:
1. Generate Lorem Ipsum text with configurable word count (10-500)
2. Generate multiple paragraphs (1-10)
3. Optionally start with classic "Lorem ipsum dolor sit amet..."
4. Regenerate text with one tap
5. Store generated texts in history (up to 10 entries)

## Implementation Details

### File Structure

- `lib/providers/provider_loremipsum.dart` - Main provider implementation
- Model: `LoremIpsumModel` - State management
- Widget: `LoremIpsumCard` - UI component

### Model: LoremIpsumModel

The model manages:
- Generated text content
- Word count setting (10-500, default 50)
- Paragraph count setting (1-10, default 1)
- Start with classic option (true/false)
- History of generated texts (max 10 entries)
- Initialization state

Key methods:
- `init()` - Initialize and generate initial text
- `setWordCount()` - Set word count (clamped to valid range)
- `setParagraphCount()` - Set paragraph count (clamped to valid range)
- `setStartWithClassic()` - Toggle classic start option
- `generate()` - Generate Lorem Ipsum text
- `addToHistory()` - Add current text to history
- `removeFromHistory()` - Remove specific entry from history
- `clearHistory()` - Clear all history
- `refresh()` - Notify listeners

### Lorem Ipsum Generation Algorithm

The generator uses:
- Classic Latin Lorem Ipsum words pool
- Punctuation (periods every ~8 words, commas every ~15 words)
- Sentence capitalization
- Paragraph separation with double newlines

### Widget: LoremIpsumCard

Features:
- Two sliders for word count and paragraph count
- FilterChip for "Start with classic" toggle
- ElevatedButton for "Generate" action
- SelectableText for generated text display
- History button showing count
- Bottom sheet for history view
- Clear history confirmation dialog

### Material 3 Components Used

- `Card.filled` - Main card container
- `Slider` - Word and paragraph count selection
- `FilterChip` - Classic start toggle
- `ElevatedButton` - Generate and Copy buttons
- `TextButton.icon` - History button
- `SelectableText` - Generated text display
- `AlertDialog` - Clear history confirmation
- `showModalBottomSheet` - History view
- `Card.outlined` - History entries
- `ListTile` - History item display

## Keywords

The provider is searchable with keywords:
- loremipsum, lorem, ipsum, placeholder, text, generate, dummy, sample

## Testing

Tests cover:
- Provider existence in Global.providerList
- Model initialization
- Word count setting and clamping
- Paragraph count setting and clamping
- Classic start toggle
- Text generation with classic start
- Text generation without classic start
- Multiple paragraph generation
- History management (add, remove, clear, max length)
- Listener notifications
- Widget rendering (loading and initialized states)

## Integration

The provider is integrated into the app via:
1. Added to `Global.providerList` in `lib/data.dart`
2. Added to `MultiProvider` in `lib/main.dart`
3. Model exposed as `loremIpsumModel`

## User Experience

1. User opens the app and sees the Lorem Ipsum Generator card
2. User adjusts word count with slider (10-500 words)
3. User adjusts paragraph count with slider (1-10 paragraphs)
4. User toggles "Start with classic" option
5. User taps "Generate" to create new Lorem Ipsum text
6. User can select text to copy manually
7. User can add generated text to history
8. User can view history and clear it when needed

## Use Cases

1. **Design**: Generate placeholder text for mockups and wireframes
2. **Development**: Fill text fields during testing
3. **Writing**: Use as placeholder before final content is ready
4. **Presentations**: Add sample text for demos