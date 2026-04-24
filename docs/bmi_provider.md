# BMI Calculator Provider Implementation

## Overview

The BMI Calculator provider calculates Body Mass Index (BMI) based on weight and height input, helping users track their health metrics.

## Features

- **Unit System Selection**: Switch between metric (kg/cm) and imperial (lb/ft/in) units
- **Real-time Calculation**: BMI is calculated as values are entered
- **BMI Categories**: Visual indication of BMI category (Underweight, Normal, Overweight, Obese)
- **Color-coded Results**: Different colors for each BMI category for easy visual feedback
- **Calculation History**: Save and review up to 10 previous BMI calculations
- **History Management**: Load previous calculations, clear history

## BMI Categories and Color Coding

| BMI Range | Category | Color Theme |
|-----------|----------|-------------|
| < 18.5 | Underweight | Tertiary |
| 18.5 - 24.9 | Normal | Primary |
| 25 - 29.9 | Overweight | Secondary |
| >= 30 | Obese | Error |

## BMI Formulas

### Metric Units
```
BMI = weight(kg) / (height(m))^2
```

### Imperial Units
```
BMI = (weight(lb) * 703) / (height(in))^2
```

## Data Structure

### BmiEntry
```dart
class BmiEntry {
  final DateTime date;
  final double bmi;
  final double weight;
  final String unit;      // 'metric' or 'imperial'
  final double height;    // cm for metric, inches for imperial
}
```

### BmiModel
- `unit`: Current unit system ('metric' or 'imperial')
- `weight`: Current weight value
- `heightMetric`: Height in cm (metric mode)
- `heightFeet`: Height in feet (imperial mode)
- `heightInches`: Height in inches (imperial mode)
- `calculatedBmi`: Current BMI result
- `history`: List of saved BMI entries

## User Interface

### BmiCard Widget
- **Unit Selector**: SegmentedButton for metric/imperial toggle
- **Weight Input**: TextField for weight entry
- **Height Input**: 
  - Metric: Single TextField for height in cm
  - Imperial: Two TextFields for feet and inches
- **BMI Display**: Large centered BMI value with category indicator
- **Action Buttons**: Clear, Save to History, View History

### History Dialog
- List of previous BMI calculations with:
  - BMI value with color-coded display
  - Category label
  - Weight and height values
  - Date of calculation
- Tap to load previous entry
- Clear all history option

## Persistence

Data is stored using SharedPreferences:
- `bmi_entries`: List of saved BMI calculations (JSON strings)
- `bmi_unit`: Current unit system preference

Maximum history entries: 10 (oldest removed when limit exceeded)

## Provider Registration

```dart
// In lib/data.dart
import 'package:new_launcher/providers/provider_bmi.dart';

Global.providerList = [
  ...
  providerBMI,
];
```

## MultiProvider Integration

```dart
// In lib/main.dart
import 'package:new_launcher/providers/provider_bmi.dart';

MultiProvider(
  providers: [
    ...
    ChangeNotifierProvider.value(value: bmiModel),
  ],
  child: MyApp(),
)
```

## Keywords

The BMI provider responds to these keywords:
- bmi
- body
- mass
- index
- weight
- height
- health
- calculator
- metric
- imperial

## Material 3 Components

- `Card.filled()` for card container
- `SegmentedButton` for unit selection
- `TextField` with `OutlineInputBorder` for input fields
- `ElevatedButton.icon` for save button
- `IconButton` for clear and history buttons
- Color scheme colors for BMI category indicators

## Testing

Tests cover:
- BmiEntry JSON serialization
- BmiModel initialization
- Weight and height setters
- Unit switching
- Metric BMI calculation
- Imperial BMI calculation
- BMI category determination
- Save to history functionality
- History max limit
- Clear history
- Clear current values
- Load from history
- hasHistory getter
- requestFocus functionality
- Provider existence and keywords
- Widget rendering states

Total tests added: 27 tests