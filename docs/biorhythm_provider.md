# Biorhythm Provider Implementation

## Overview

The Biorhythm provider calculates biological rhythm cycles based on the user birthdate. It tracks three primary cycles:
- Physical cycle (23 days)
- Emotional cycle (28 days)
- Intellectual cycle (33 days)

## Architecture

### Model (BiorhythmModel)

The `BiorhythmModel` class extends `ChangeNotifier` and manages:
- Birthdate persistence via SharedPreferences
- Target date selection for analysis
- Cycle calculation logic

### Key Properties

```dart
static const int physicalCycle = 23;
static const int emotionalCycle = 28;
static const int intellectualCycle = 33;
```

### Key Methods

- `calculateCycleValue(birthdate, targetDate, cycleLength)` - Returns sine value for a cycle
- `getPhysicalValue(birthdate, targetDate)` - Calculates physical cycle value
- `getEmotionalValue(birthdate, targetDate)` - Calculates emotional cycle value
- `getIntellectualValue(birthdate, targetDate)` - Calculates intellectual cycle value
- `getCycleStatus(value)` - Returns status string (High, Rising, Low, Falling, Critical)
- `getCycleEmoji(value)` - Returns emoji indicator for cycle phase
- `getDaysInCycle(birthdate, targetDate, cycleLength)` - Returns current day position in cycle

### Cycle Calculation Formula

The cycle values are calculated using sine wave function:
```dart
double calculateCycleValue(DateTime birthdate, DateTime targetDate, int cycleLength) {
  int days = targetDate.difference(birthdate).inDays;
  double sineValue = sin(2 * pi * days / cycleLength);
  return sineValue;
}
```

Values range from -1.0 (low point) to 1.0 (high point):
- Value > 0.5: High phase (peak)
- Value > 0: Rising phase
- Value < -0.5: Low phase (minimum)
- Value < 0: Falling phase
- Value ≈ 0: Critical day (transition)

## Widget (BiorhythmCard)

The `BiorhythmCard` widget displays:
- Birthdate selection button
- Target date selector
- Three cycle rows with progress indicators
- Overall energy summary

### UI Components

- `Card.filled` with Material 3 styling
- `LinearProgressIndicator` for cycle visualization
- `showDatePicker` integration for date selection
- Color-coded cycle bars based on status

## Provider Registration

### In main.dart

```dart
import 'package:new_launcher/providers/provider_biorhythm.dart';

// In MultiProvider:
ChangeNotifierProvider.value(value: biorhythmModel),
```

### In data.dart

```dart
import 'package:new_launcher/providers/provider_biorhythm.dart';

// In providerList:
providerBiorhythm,
```

## Keywords

```
biorhythm, cycle, physical, emotional, intellectual, rhythm, birthdate
```

## Tests

The provider includes comprehensive tests for:
- Model initialization
- Cycle calculation accuracy
- Cycle status and emoji mapping
- Birthdate and target date operations
- Widget rendering
- Provider registration verification

## Usage

1. User enters birthdate via date picker
2. Optionally selects target date for analysis
3. Provider calculates three cycle values
4. UI displays cycle status with progress bars
5. Overall energy summary shows combined state

## Persistence

- Birthdate stored in SharedPreferences key: `biorhythm_birthdate`
- Selected target date stored in SharedPreferences key: `biorhythm_selected_date`