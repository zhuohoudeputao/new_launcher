# QR Code Provider Implementation

## Overview

The QR Code provider allows users to generate QR codes from text input directly within the launcher. It supports multiple input formats including plain text, URLs, email addresses, and phone numbers.

## Features

- **Multiple input types**: Text, URL, Email, Phone
- **URL auto-prefixing**: Automatically adds `https://` if missing
- **Email formatting**: Adds `mailto:` prefix for email addresses
- **Phone formatting**: Adds `tel:` prefix for phone numbers
- **Copy to clipboard**: Quick copy of QR code text
- **Clear QR code**: Remove current QR code
- **Material 3 design**: Uses `Card.filled` and `SegmentedButton`

## Usage

### Keywords
- `qr`, `qrcode`, `code`, `generate`, `barcode`, `scan`, `share`

### Input Types

1. **Text**: Plain text QR code
2. **URL**: Web addresses (auto-prefixed with `https://`)
3. **Email**: Email addresses (formatted with `mailto:`)
4. **Phone**: Phone numbers (formatted with `tel:`)

## Architecture

### Model: `QRModel`

Located in `lib/providers/provider_qrcode.dart`

```dart
class QRModel extends ChangeNotifier {
  String _currentText = "";
  bool _isInitialized = false;

  String get currentText => _currentText;
  bool get isInitialized => _isInitialized;
  bool get hasQR => _currentText.isNotEmpty;

  void init();
  void refresh();
  void setText(String text);
  void clearText();
}
```

### Widgets

1. **QRCard**: Main card widget displaying the QR code
   - Shows placeholder when no QR code exists
   - Displays QR code image with copy/clear actions
   - Edit button to open generator dialog

2. **QRGeneratorDialog**: Dialog for creating new QR codes
   - SegmentedButton for type selection
   - TextField for input
   - Format text based on selected type

## Dependencies

- `qr_flutter: ^4.1.0` - QR code generation

## Implementation Details

### QR Code Generation

Uses `QrImageView` widget from `qr_flutter` package:

```dart
QrImageView(
  data: qr.currentText,
  version: QrVersions.auto,
  size: 150,
  backgroundColor: Theme.of(context).colorScheme.surface,
)
```

### Text Formatting

The `_formatText` method handles different input types:

```dart
String _formatText(String text) {
  switch (_selectedType) {
    case "url":
      if (!text.startsWith('http://') && !text.startsWith('https://')) {
        return 'https://$text';
      }
      return text;
    case "email":
      return 'mailto:$text';
    case "phone":
      return 'tel:$text';
    default:
      return text;
  }
}
```

### Clipboard Integration

Copy functionality uses Flutter's `Clipboard` API:

```dart
void _copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Text copied to clipboard")),
  );
}
```

## Testing

Tests are located in `test/widget_test.dart` under the "QR Code provider tests" group:

- `QRModel` state management
- Widget rendering (QRCard, QRGeneratorDialog)
- Provider integration
- Text formatting
- Clipboard operations

## UI Components

### QRCard

- Loading state: Shows "QR Code: Loading..." text
- Empty state: Shows placeholder icon and hint text
- Active state: Shows QR code image, truncated text, copy and clear buttons

### QRGeneratorDialog

- SegmentedButton with 4 type options (Text, URL, Email, Phone)
- TextField with dynamic hint text
- Cancel and Generate buttons

## Best Practices

1. **Memory Management**: Dialog's TextEditingController is properly disposed
2. **User Feedback**: SnackBar shown on clipboard copy
3. **Input Validation**: Empty text is not processed
4. **Text Truncation**: Long text is truncated in display
5. **Theme Integration**: All colors use ColorScheme properties