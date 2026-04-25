# Palette Provider

## Overview

The Palette provider generates cohesive color palettes using color theory principles. It complements the existing Color provider (which generates single random colors) by providing harmonious color combinations for designers and developers.

## Features

- **6 palette types** based on color theory:
  - **Complementary**: Two colors opposite on the color wheel (180° apart)
  - **Analogous**: Colors adjacent on the color wheel (±30°)
  - **Triadic**: Three colors evenly spaced (120° apart)
  - **Split Complementary**: Base color + two colors adjacent to its complement
  - **Tetradic**: Four colors forming a rectangle on the color wheel (90° apart)
  - **Monochromatic**: Variations of a single color (different shades/tints)

- **Base color selection**: Set custom base color for palette generation
- **Random palette generation**: Generate new palettes with random base colors
- **HEX color output**: Copy individual colors or entire palette as HEX values
- **History tracking**: Save up to 10 palette generations
- **Copy to clipboard**: Tap color swatches to copy HEX value

## Implementation

### File Structure

- `lib/providers/provider_palette.dart` - Main provider implementation

### Classes

#### PaletteModel

ChangeNotifier model managing palette state:
- `_paletteType`: Current palette type enum
- `_currentPalette`: List of generated colors
- `_baseColor`: Base color for palette generation
- `_history`: List of palette history entries

#### PaletteType Enum

Six palette types with corresponding generation methods:
- `complementary` - `_generateComplementary()`
- `analogous` - `_generateAnalogous()`
- `triadic` - `_generateTriadic()`
- `splitComplementary` - `_generateSplitComplementary()`
- `tetradic` - `_generateTetradic()`
- `monochromatic` - `_generateMonochromatic()`

#### PaletteHistoryEntry

History entry class storing:
- `paletteType`: Type of generated palette
- `colors`: List of colors in the palette
- `baseColor`: Original base color
- `timestamp`: Generation time

### Color Generation Algorithm

Uses HSV (Hue, Saturation, Value) color space for palette generation:

1. Convert base color to HSV
2. Calculate target hue angles based on palette type
3. Generate colors at calculated hue positions
4. Convert back to RGB Color

Example for Triadic palette:
```dart
// Base hue at 0°
// Generate colors at 0°, 120°, 240°
return [
  HSVColor.fromAHSV(1.0, baseHSV.hue, baseHSV.saturation, baseHSV.value).toColor(),
  HSVColor.fromAHSV(1.0, (baseHSV.hue + 120) % 360, baseHSV.saturation, baseHSV.value).toColor(),
  HSVColor.fromAHSV(1.0, (baseHSV.hue + 240) % 360, baseHSV.saturation, baseHSV.value).toColor(),
];
```

### UI Components

#### PaletteCard

Main widget displaying:
- Palette type selector (SegmentedButton)
- Color preview grid with copy functionality
- Base color display
- Action buttons (New Palette, Clear History)
- Optional history view

### Integration

Added to:
- `lib/data.dart` imports and `Global.providerList`
- `lib/main.dart` imports and `MultiProvider`

## Keywords

`palette color scheme harmony complementary analogous triadic monochromatic tetradic split design`

## Tests

24 tests covering:
- Provider existence and initialization
- Palette type generation for all 6 types
- Color count validation for each palette type
- Base color setting
- History management (limit, clear, use entry)
- Color to HEX conversion
- Palette type names and descriptions
- History entry formatting
- Widget rendering states
- Provider count verification

## Usage Examples

### Generate Complementary Palette

```dart
paletteModel.setPaletteType(PaletteType.complementary);
paletteModel.generatePalette();
// Returns 2 colors: base + complement (180° apart)
```

### Generate Triadic Palette

```dart
paletteModel.setPaletteType(PaletteType.triadic);
paletteModel.generatePalette();
// Returns 3 colors evenly spaced (120° apart)
```

### Set Custom Base Color

```dart
paletteModel.setBaseColor(Color(0xFF2196F3));
paletteModel.generatePalette();
// Generates palette based on blue base color
```

## Material 3 Components

Uses Material 3 components:
- `Card.filled` for main card and sub-cards
- `SegmentedButton` for palette type selection
- `ElevatedButton.icon` for action buttons
- `IconButton.styleFrom` for icon styling
- `withValues(alpha)` for color opacity