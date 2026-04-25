# Statistics Provider

## Overview

The Statistics provider implements a statistics calculator for the Flutter launcher application. It allows users to calculate statistical measures (mean, median, mode, standard deviation, variance, range, sum, count, min, max) from a set of numbers.

## Implementation

### File Location
- Provider: `lib/providers/provider_statistics.dart`

### Model: StatisticsModel

The model manages the state for statistics calculations:

```dart
class StatisticsModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputNumbers = "";
  double? _mean;
  double? _median;
  List<double>? _mode;
  double? _stdDev;
  double? _variance;
  double? _min;
  double? _max;
  double? _range;
  double? _sum;
  int? _count;
  String _error = "";
  List<String> _history = [];
}
```

## Features

1. **Number Input**: Enter numbers separated by commas or spaces
2. **Mean Calculation**: Calculate average of all numbers
3. **Median Calculation**: Calculate middle value (supports even and odd counts)
4. **Mode Calculation**: Find most frequent value(s) (supports multiple modes)
5. **Standard Deviation**: Calculate population standard deviation
6. **Variance**: Calculate population variance
7. **Min/Max/Range**: Find minimum, maximum, and range
8. **Sum/Count**: Calculate sum and count of numbers
9. **Decimal Support**: Handles decimal numbers
10. **Negative Support**: Handles negative numbers
11. **History Tracking**: Saves up to 10 previous calculations
12. **History Reuse**: Tap history entries to reload previous calculations
13. **Copy to Clipboard**: Copy all statistics to clipboard

## Statistics Calculations

### Mean
Sum of all numbers divided by count.

### Median
Middle value of sorted numbers. For even count, average of two middle values.

### Mode
Most frequent value(s). Multiple values if equal frequency.

### Variance
Average of squared differences from mean.

### Standard Deviation
Square root of variance.

## UI Components

### StatisticsCard

Uses Material 3 Card.filled with:

- Analytics icon and title
- Input TextField for numbers (comma or space separated)
- Calculate and Clear buttons
- Results section showing:
  - Count, Sum, Min, Max, Range
  - Mean, Median, Mode
  - Variance, Standard Deviation
- History section with previous calculations
- Copy all button to copy statistics to clipboard

## Keywords

- statistics, mean, median, mode, stddev, variance, average, calculator, math

## Tests

Located in `test/widget_test.dart` under group "Statistics provider tests":

- Model initialization
- setInputNumbers
- Calculate with valid numbers
- Mean calculation
- Median calculation (odd and even counts)
- Median with unsorted input
- Mode calculation (single and multiple modes)
- Variance calculation
- Standard deviation calculation
- Empty input error
- Invalid input error
- Space separated input
- Mixed comma and space input
- Decimal numbers support
- Negative numbers support
- formatNumber for integers and decimals
- formatMode for single and multiple values
- History operations
- History max limit
- clearInput
- refresh/notifyListeners
- Widget rendering
- Provider registration
- Keyword validation

## Integration

The provider is registered in:
- `lib/data.dart`: Provider import and providerList
- `lib/main.dart`: Model import and MultiProvider