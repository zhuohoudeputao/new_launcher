# Color Generator Provider

## Overview

The Color Generator provider provides color generation and manipulation utilities including random color generation, HEX/RGB conversion, and clipboard copy functionality.

## Features

### Random Color Generation
- Generate random colors with one tap
- Display color preview in a visual container
- Uses `Icons.palette` icon

### HEX Color Input
- Input custom HEX color values
- Format: #RRGGBB (6-character hex)
- Auto-conversion to RGB values
- Copy HEX value to clipboard

### RGB Color Input
- Input custom RGB values (R, G, B)
- Range: 0-255 with automatic clamping
- Apply button to set custom colors
- Copy RGB value to clipboard

### Color Info Display
- Shows color type (Light/Dark)
- Displays contrast color indicator
- Visual preview with contrast text

## Model Structure

```dart
class ColorModel extends ChangeNotifier {
  bool _isInitialized = false;
  
  Color _currentColor = Colors.blue;
  String _hexColor = "#2196F3";
  String _rgbColor = "33, 150, 243";
  int _red = 33;
  int _green = 150;
  int _blue = 243;
  
  // Methods
  void init();
  void refresh();
  void generateRandomColor();
  void setColorFromHex(String hex);
  void setColorFromRGB(int r, int g, int b);
  void copyToClipboard(String text, BuildContext context);
  bool isLightColor();
  Color getContrastColor();
}
```

## Widget Structure

```dart
class ColorCard extends StatefulWidget {
  @override
  State<ColorCard> createState() => _ColorCardState();
}

class _ColorCardState extends State<ColorCard> {
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _rController = TextEditingController();
  final TextEditingController _gController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  
  // Build methods for each section:
  Widget _buildColorPreview(BuildContext context, ColorModel color);
  Widget _buildColorInfo(BuildContext context, ColorModel color);
  Widget _buildHexInput(BuildContext context, ColorModel color);
  Widget _buildRGBInput(BuildContext context, ColorModel color);
}
```

## Material 3 Components Used

- `Card.filled` - Main card container
- `SelectableText` - HEX and RGB value display
- `TextField` - HEX and RGB input
- `IconButton.styleFrom()` - Button styling

## Provider Registration

```dart
MyProvider providerColor = MyProvider(
    name: "Color",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

## Keywords

- color, random, generate, hex, rgb, picker, palette

## Usage in Global Provider List

The Color provider is added to `Global.providerList` in `lib/data.dart`:

```dart
static List<MyProvider> providerList = [
  providerSettings,
  providerWallpaper,
  providerTheme,
  providerTime,
  providerWeather,
  providerApp,
  providerSystem,
  providerBattery,
  providerFlashlight,
  providerNotes,
  providerTimer,
  providerStopwatch,
  providerCalculator,
  providerWorldClock,
  providerCountdown,
  providerUnitConverter,
  providerPomodoro,
  providerClipboard,
  providerTodo,
  providerQRCode,
  providerRandom,
  providerColor,
];
```

## Model Registration in main.dart

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: colorModel),
    // ... other providers
  ],
  child: MyApp(),
)
```

## Test Coverage

The Color Generator provider tests include:
- ColorModel existence and initial state
- Initialization tests
- Random color generation
- HEX color setting and conversion
- RGB color setting and conversion
- Light/dark color detection
- Contrast color calculation
- NotifyListeners behavior
- Widget rendering tests (loading state, initialized state, with custom color)
- Provider registration tests
- HEX and RGB format validation
- RGB value clamping

Total Color provider tests: 22 tests