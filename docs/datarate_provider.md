# Data Rate Converter Provider

## Overview

The DataRateConverter provider provides bandwidth/data rate unit conversions for networking professionals. It converts between common data rate units used in networking, telecommunications, and internet connections.

## Implementation Details

### Location
- Provider file: `lib/providers/provider_datarate.dart`

### Features

1. **Unit Conversions**
   - Convert between 5 data rate units: bps, Kbps, Mbps, Gbps, Tbps
   - Real-time conversion as values are entered
   - Swap input/output units with one tap
   - Conversion history (up to 10 entries)
   - Tap history entries to reuse conversions
   - Clear history with confirmation dialog

2. **Supported Units**
   - `bps` - bits per second
   - `Kbps` - kilobits per second (1000 bps)
   - `Mbps` - megabits per second (1000 Kbps)
   - `Gbps` - gigabits per second (1000 Mbps)
   - `Tbps` - terabits per second (1000 Gbps)

3. **Default Settings**
   - Default input unit: Mbps
   - Default output unit: Kbps
   - Base unit: bps (bits per second)

4. **Conversion Formula**
   ```
   bps = value × unitFactor
   result = bps / targetUnitFactor
   ```
   Unit factors (relative to bps):
   - bps: 1
   - Kbps: 1,000
   - Mbps: 1,000,000
   - Gbps: 1,000,000,000
   - Tbps: 1,000,000,000,000

5. **Input Handling**
   - Decimal values supported
   - Negative values supported
   - Invalid input handled gracefully (returns 0)
   - Real-time conversion on input change

6. **History Management**
   - Maximum 10 history entries
   - Oldest entries removed when limit exceeded
   - Zero and invalid values not added to history
   - Clear all history with confirmation dialog
   - Tap history entry to load previous conversion

### Model Class

```dart
class DataRateConverterModel extends ChangeNotifier {
  String _inputUnit = 'Mbps';
  String _outputUnit = 'Kbps';
  String _inputValue = '0';
  String _outputValue = '0';
  bool _isInitialized = false;
  final List<DataRateConversionHistory> _history = [];
  static const int maxHistory = 10;
}
```

### Key Methods

- `init()` - Initialize the converter
- `refresh()` - Notify listeners to refresh UI
- `setInputUnit(String unit)` - Set the input unit
- `setOutputUnit(String unit)` - Set the output unit
- `setInputValue(String value)` - Set input value and convert
- `swapUnits()` - Swap input/output units
- `clear()` - Clear input value to 0
- `addToHistory()` - Add current conversion to history
- `clearHistory()` - Clear all history entries
- `useHistoryEntry(DataRateConversionHistory entry)` - Load history entry
- `convert(double value, String from, String to)` - Static conversion method

### Widget Structure

```dart
class DataRateConverterCard extends StatefulWidget {
  // Uses Card.filled for Material 3 style
  // Contains:
  // - Title row with history toggle and clear button
  // - Converter view with two dropdowns and value fields
  // - History view with ListView.builder
}
```

### UI Components

- `Card.filled` - Material 3 style container
- `DropdownButton<String>` - Unit selection dropdowns
- `TextField` - Input value field (numeric keyboard)
- `IconButton` - Swap, history toggle, clear buttons
- `ListView.builder` - History list display
- `AlertDialog` - Clear history confirmation dialog

### Provider Registration

The provider is registered in:
- `lib/data.dart`: Added to `Global.providerList`
- `lib/main.dart`: Added to `MultiProvider` providers list

### Keywords

The provider responds to search keywords:
- `datarate` - Primary keyword
- `bandwidth` - Network bandwidth term
- `speed` - Network speed
- `bps` - Bits per second
- `mbps` - Megabits per second
- `gbps` - Gigabits per second
- `kbps` - Kilobits per second
- `network` - Network related
- `internet` - Internet speed related

## Test Coverage

Located in `test/widget_test.dart` under `DataRateConverter Provider tests` group.

### Tests Include

1. **Provider Registration**
   - Provider exists in Global.providerList
   - Keywords are registered correctly

2. **Model Initialization**
   - Model starts uninitialized
   - Model is ChangeNotifier
   - Init sets initialized flag
   - Default units are correct

3. **Unit Operations**
   - setInputUnit works
   - setOutputUnit works
   - swapUnits works
   - Prevents same input/output unit

4. **Value Operations**
   - setInputValue works
   - clear works
   - Handles invalid input
   - Handles negative values
   - Handles decimal values
   - Handles zero

5. **Conversion Tests**
   - Mbps to Kbps conversion
   - Kbps to Mbps conversion
   - Mbps to Gbps conversion
   - Gbps to Mbps conversion
   - bps to Kbps conversion
   - Tbps to Gbps conversion
   - Static convert method tests
   - Same unit returns same value

6. **History Tests**
   - History starts empty
   - addToHistory works
   - addToHistory ignores zero
   - addToHistory ignores invalid
   - History max limit (10 entries)
   - clearHistory works
   - useHistoryEntry works

7. **Widget Tests**
   - Loading state renders
   - Initialized state renders
   - Input field exists
   - Dropdowns exist
   - Widget class exists
   - Provider in Global.providerList

## Usage Example

```dart
// Get model instance
final model = context.watch<DataRateConverterModel>();

// Set input value
model.setInputValue('100');

// Change units
model.setInputUnit('Mbps');
model.setOutputUnit('Gbps');

// Get converted value
final output = model.outputValue; // '0.1'

// Swap units
model.swapUnits();

// Add to history
model.addToHistory();
```

## Related Providers

- **SpeedConverter**: Speed unit conversions (km/h, mph, m/s, etc.)
- **FileSizeConverter**: File size conversions (bytes, KB, MB, GB, etc.)
- **VolumeConverter**: Volume unit conversions (liter, gallon, etc.)
- **UnitConverter**: General unit conversions (temperature, length, weight)

## Notes

- Uses SI (International System) prefixes (1000-based, not 1024-based)
- Suitable for network bandwidth and internet speed conversions
- Icon: `Icons.network_check` for visual representation
- Follows Material 3 design patterns with `Card.filled`