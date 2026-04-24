# Parking Provider Implementation

## Overview

The Parking provider helps users remember where they parked their vehicle and track parking meter time. It provides location storage, optional notes, and a countdown timer for meter expiration.

## Features

- **Location Storage**: Save parking location with custom description (e.g., "Level 2, Spot 15")
- **Optional Notes**: Add additional details like "Near elevator" or "Blue section"
- **Parking Meter Timer**: Set meter time with countdown display
- **Quick Time Add**: Quick preset buttons to add time to meter (+15m, +30m, +60m, +90m, +120m)
- **Pause/Resume Meter**: Control meter timer with pause and resume functionality
- **Expiration Alert**: Visual and notification alert when meter expires
- **Edit Capability**: Update location and notes without resetting meter
- **Persistence**: Parking data persisted via SharedPreferences

## Implementation Details

### Files Created

- `lib/providers/provider_parking.dart` - Main provider implementation

### Data Model

```dart
class ParkingEntry {
  final String location;       // Parking location description
  final String notes;          // Optional additional notes
  final DateTime parkedTime;   // When parking was set
  int meterMinutes;            // Total meter time in minutes
  int meterRemainingSeconds;   // Remaining meter time
  Timer? meterTimer;           // Timer for countdown
  bool meterActive;            // Whether meter timer is running
}
```

### ParkingModel Methods

- `init()` - Load saved parking from SharedPreferences
- `setParking(location, notes, meterMinutes)` - Set new parking location
- `clearParking()` - Clear current parking
- `addMeterTime(minutes)` - Add time to meter
- `pauseMeter()` - Pause meter countdown
- `resumeMeter()` - Resume paused meter
- `updateLocation(location)` - Update location text
- `updateNotes(notes)` - Update notes text
- `saveParking()` - Persist to SharedPreferences

### UI Components

- `ParkingCard` - Main display widget with parking info and meter controls
- `SetParkingDialog` - Dialog for setting new parking location
- `EditParkingDialog` - Dialog for editing existing parking info

## Widget Structure

```
ParkingCard
├── Header (title + clear button)
├── Parking Info (location, notes, duration)
│   ├── Location with edit button
│   └── Notes text
│   └── Parked duration
├── Meter Section (if meter set)
│   ├── Timer display
│   ├── Progress bar
│   ├── Quick add buttons (+15m, +30m, etc.)
│   └── Pause/Resume controls
└── Empty State (no parking)
    └── "Set Parking Location" button
```

## Material 3 Design

- Uses `Card.filled` for consistent styling
- Color coding: primary for active meter, error for expired
- Linear progress indicator for meter time remaining
- ActionChip for quick time add buttons
- IconButton with theme colors for controls

## Keywords

- parking, park, car, vehicle, meter, spot, location, level, garage

## Persistence

- ParkingEntry stored as JSON in SharedPreferences key 'ParkingEntry'
- Timer state saved every minute during countdown
- Timer recreated on app restart if meter was active

## Testing

14 tests added covering:
- ParkingEntry serialization (toJson/fromJson)
- Time display formatting
- Progress calculation
- Expiration detection
- Parked duration calculation
- Model operations (set, clear, add time, update)
- Widget rendering (loading, empty, info states)
- Provider integration tests

## Usage Examples

### Set Parking Location
1. Tap "Set Parking Location" button
2. Enter location (e.g., "Level 2, Spot 15")
3. Optionally add notes (e.g., "Near elevator")
4. Optionally set meter time in minutes
5. Tap "Save"

### Add Meter Time
1. Tap quick add buttons (+15m, +30m, etc.)
2. Time is immediately added to countdown

### Pause/Resume Meter
1. Tap pause button to stop countdown
2. Tap play button to resume

### Edit Parking Info
1. Tap edit icon next to location
2. Update location and/or notes
3. Tap "Save"

### Clear Parking
1. Tap trash icon in header
2. Confirm deletion in dialog