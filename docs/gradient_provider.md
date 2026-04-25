# Gradient Generator Provider

## Overview

The Gradient Generator provider creates and manages color gradients for designers and developers. It supports linear and radial gradients with customizable directions and color stops.

## Features

- **Gradient Types**: Linear and Radial gradients
- **Gradient Directions**: Horizontal, Vertical, Diagonal Up, Diagonal Down (linear), Center (radial)
- **Color Management**: Add, remove, and customize gradient colors (2-5 colors)
- **Code Export**: Copy CSS and Flutter gradient code
- **History Tracking**: Store up to 10 previous gradients
- **Random Generation**: Generate random gradients with 2-5 colors

## Implementation

### File Location
- Provider: `lib/providers/provider_gradient.dart`
- Model: `GradientModel` (ChangeNotifier)
- Widget: `GradientCard`

### Gradient Types

```dart
enum GradientType {
  linear,
  radial,
}
```

### Gradient Directions

```dart
enum GradientDirection {
  horizontal,
  vertical,
  diagonalUp,
  diagonalDown,
  radialCenter,
}
```

### Model Structure

```dart
class GradientModel extends ChangeNotifier {
  GradientType gradientType;
  GradientDirection gradientDirection;
  List<Color> colors;
  List<GradientHistoryEntry> history;
  
  void init();
  void generateGradient();
  void generateRandomGradient();
  void setGradientType(GradientType type);
  void setGradientDirection(GradientDirection dir);
  void setColor(int index, Color color);
  void addColor();
  void removeColor(int index);
  String getCssGradient();
  String getFlutterGradient();
  void copyCssToClipboard(BuildContext context);
  void copyFlutterToClipboard(BuildContext context);
  void useHistoryEntry(GradientHistoryEntry entry);
  void clearHistory();
}
```

### CSS Output Example

```css
background: linear-gradient(to right, #2196F3, #9C27B0);
background: radial-gradient(circle, #FF5722, #4CAF50, #2196F3);
```

### Flutter Output Example

```dart
LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0x2196F3FF), Color(0x9C27B0FF)])
RadialGradient(colors: [Color(0xFF5722FF), Color(0x4CAF50FF), Color(0x2196F3FF)])
```

## UI Components

### GradientCard
- Type selector (SegmentedButton for Linear/Radial)
- Direction selector (SegmentedButton for directions)
- Gradient preview (80px height container with gradient)
- Color list (tap to change color, tap X to remove)
- Add color button (max 5 colors)
- Random button
- Copy CSS/Flutter buttons
- History view (tap to restore previous gradients)
- Code view (CSS and Flutter code display)

### Color Picker Dialog
- Preset colors (21 Material colors)
- Random color option
- Cancel option

## History Entry Structure

```dart
class GradientHistoryEntry {
  final GradientType gradientType;
  final GradientDirection gradientDirection;
  final List<Color> colors;
  final DateTime timestamp;
  
  String getFormattedTime();
}
```

## Keywords

`gradient, linear, radial, colors, css, flutter, design, background`

## Tests

Test coverage includes:
- Provider existence and initialization
- GradientModel initial values
- Gradient type switching
- Gradient direction switching
- Color management (add, remove, set)
- Color limits (minimum 2, maximum 5)
- Gradient generation
- CSS output format
- Flutter output format
- History management (limit 10 entries)
- History entry reuse
- Clear history
- Gradient type/direction name getters
- GradientHistoryEntry time formatting
- Widget rendering (loading state, initialized state)

Total: 28 tests

## Integration

The Gradient provider is added to:
- `lib/data.dart` imports and providerList
- `lib/main.dart` imports and MultiProvider
- `test/widget_test.dart` imports and tests

Provider count: 111 providers total.