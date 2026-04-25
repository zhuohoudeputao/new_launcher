# Blood Pressure Tracker Provider

## Overview

The Blood Pressure Tracker provider allows users to track and monitor their blood pressure readings over time. It provides comprehensive health monitoring features including category classification, statistics, and historical data tracking.

## Implementation

### Provider File
- `lib/providers/provider_bloodpressure.dart`

### Model
- `BloodPressureModel` - ChangeNotifier-based state management

### Key Features

1. **Blood Pressure Reading Tracking**
   - Systolic (top number) and diastolic (bottom number) values
   - Optional pulse/heart rate recording
   - Optional notes for each reading
   - Custom date selection (within 30 days)

2. **Category Classification**
   - Normal: <120/<80 mmHg
   - Elevated: 120-129/<80 mmHg
   - High Stage 1: 130-139/80-89 mmHg
   - High Stage 2: ≥140/≥90 mmHg
   - Crisis: >180/>120 mmHg

3. **Statistics**
   - Average systolic/diastolic
   - Min/max systolic/diastolic
   - Average pulse (if recorded)
   - Percentage of normal readings
   - Trend indicators (change between readings)

4. **Target BP Setting**
   - Preset options: 120/80, 110/70, 130/85
   - Custom target values

5. **History Management**
   - Maximum 30 entries stored
   - Delete individual entries
   - Clear all history with confirmation

### Data Persistence

Blood pressure entries are persisted via SharedPreferences:
- Key: `blood_pressure_entries` - List of JSON-encoded entries
- Key: `blood_pressure_target_systolic` - Target systolic value
- Key: `blood_pressure_target_diastolic` - Target diastolic value

### UI Components

- `BloodPressureCard` - Main display card showing latest reading and statistics
- `BloodPressureLogDialog` - Dialog for logging new readings
- `BloodPressureTargetDialog` - Dialog for setting target BP

### Material 3 Components Used

- `Card.filled` for main card styling
- Color-coded category indicators
- `ActionChip` for preset target values
- `LinearProgressIndicator` for trends (if applicable)

### Keywords

blood, pressure, bp, systolic, diastolic, heart, pulse, log, track, health, monitor

## Category Classification Logic

```dart
BPCategory getBPCategoryFromValues(int systolic, int diastolic) {
  if (systolic > 180 || diastolic > 120) {
    return BPCategory.crisis;
  }
  if (systolic >= 140 || diastolic >= 90) {
    return BPCategory.highStage2;
  }
  if (systolic >= 130 || diastolic >= 80) {
    return BPCategory.highStage1;
  }
  if (systolic >= 120 && diastolic < 80) {
    return BPCategory.elevated;
  }
  return BPCategory.normal;
}
```

## Blood Pressure Entry Structure

```dart
class BloodPressureEntry {
  final DateTime date;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final String? notes;
}
```

## Integration

The provider is registered in:
- `lib/data.dart` - Added to `Global.providerList`
- `lib/main.dart` - Added to `MultiProvider`

## Usage

Users can:
1. Log blood pressure readings via the "Log" button
2. Set target BP via the "Target" button
3. View history via the "History" button
4. See color-coded category for each reading
5. Track trends over time