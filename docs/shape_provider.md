# Shape Provider Implementation

## Overview

The Shape provider provides geometry calculations for various 2D and 3D shapes including circles, rectangles, triangles, spheres, cylinders, and cones.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_shape.dart`

### Key Classes

#### ShapeHistoryEntry
- `date`: DateTime when calculation was made
- `shapeType`: Type of shape (circle, rectangle, triangle, sphere, cylinder, cone)
- `inputs`: Map of input values (radius, width, height, base)
- `results`: Map of calculated results (area, perimeter, volume, surface area, etc.)

#### ShapeModel (ChangeNotifier)
- `shapeType`: Current selected shape type
- `inputs`: Current input values
- `history`: List of saved calculations
- `maxHistory`: Maximum 10 history entries stored
- `isInitialized`: Initialization state flag

### Supported Shapes

#### 2D Shapes
1. **Circle**: Radius input, calculates diameter, circumference, area
2. **Rectangle**: Width and height inputs, calculates area, perimeter, diagonal
3. **Triangle**: Base and height inputs, calculates area

#### 3D Shapes
1. **Sphere**: Radius input, calculates diameter, surface area, volume
2. **Cylinder**: Radius and height inputs, calculates volume, surface area
3. **Cone**: Radius and height inputs, calculates volume, surface area

### Calculation Formulas

#### Circle
- Diameter: `2 * radius`
- Circumference: `2 * π * radius`
- Area: `π * radius²`

#### Rectangle
- Area: `width * height`
- Perimeter: `2 * (width + height)`
- Diagonal: `sqrt(width² + height²)`

#### Triangle
- Area: `0.5 * base * height`

#### Sphere
- Diameter: `2 * radius`
- Surface Area: `4 * π * radius²`
- Volume: `(4/3) * π * radius³`

#### Cylinder
- Volume: `π * radius² * height`
- Surface Area: `2 * π * radius * (radius + height)`

#### Cone
- Volume: `(1/3) * π * radius² * height`
- Surface Area: `π * radius * (radius + slant)` where slant = `sqrt(radius² + height²)`

### Key Methods

#### Initialization
- `init()`: Loads saved history from SharedPreferences

#### Shape Management
- `setShapeType(type)`: Set current shape type
- `setInput(key, value)`: Set input value for shape
- `clear()`: Clear all input values
- `hasValidInput()`: Check if inputs are valid for calculation

#### Results
- `results`: Getter that returns calculated results based on shape type and inputs
- `resultLabels`: Getter for result label names
- `resultKeys`: Getter for result keys in results map

#### History
- `saveToHistory()`: Save current calculation to history
- `loadFromHistory(entry)`: Load calculation from history entry
- `clearHistory()`: Clear all history

### UI Components

#### ShapeCard
- Shape type selector (SegmentedButton with 6 shape options)
- Input fields for shape parameters
- Results display with all calculated values
- Save to history button
- Clear button
- History view toggle

### Features

1. **Multiple Shapes**: 6 different 2D and 3D shapes
2. **Real-time Calculation**: Results calculated as input values change
3. **Shape Selector**: SegmentedButton for easy shape switching
4. **History**: Save up to 10 calculations to history
5. **Load from History**: Tap history entry to restore calculation
6. **Clear History**: Clear all saved calculations with confirmation
7. **Persistence**: History saved via SharedPreferences
8. **Emoji Icons**: Visual emoji indicators for each shape type

### Shape Icons
- Circle: ⭕
- Rectangle: ⬛
- Triangle: 🔺
- Sphere: 🔮
- Cylinder: 🛢️
- Cone: 📐

### Keywords
`shape, geometry, circle, rectangle, triangle, sphere, cylinder, cone, area, perimeter, volume, surface, diagonal, radius, diameter`

## Test Coverage

Tests include:
- Provider existence and initialization
- Max history limit
- Shape type selection
- Shape name and icon getters
- Input labels for each shape type
- Result labels for each shape type
- Circle calculations (diameter, circumference, area)
- Rectangle calculations (area, perimeter, diagonal)
- Triangle calculations (area)
- Sphere calculations (diameter, surface area, volume)
- Cylinder calculations (volume, surface area)
- Cone calculations (volume, surface area)
- Invalid input handling
- Has valid input check
- Save/load/clear history
- ShapeHistoryEntry toJson/fromJson
- ShapeHistoryEntry displayText
- Model refresh
- Clear inputs
- Widget rendering (loading and initialized states)
- Global.providerList inclusion

Total tests: 34 Shape-specific tests

## Integration

The Shape provider is integrated into:
- `lib/data.dart`: Added to Global.providerList
- `lib/main.dart`: Added to MultiProvider

## Usage Example

```dart
// Calculate circle properties
shapeModel.setShapeType('circle');
shapeModel.setInput('radius', 5);
final results = shapeModel.results;
// results: {'diameter': 10.0, 'circumference': 31.42, 'area': 78.54}

// Calculate rectangle properties
shapeModel.setShapeType('rectangle');
shapeModel.setInput('width', 6);
shapeModel.setInput('height', 4);
final results = shapeModel.results;
// results: {'area': 24.0, 'perimeter': 20.0, 'diagonal': 7.21}

// Save to history
shapeModel.saveToHistory();

// Load from history
final entry = shapeModel.history.first;
shapeModel.loadFromHistory(entry);

// Clear history
shapeModel.clearHistory();
```