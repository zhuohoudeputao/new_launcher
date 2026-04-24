# Sequence Provider Implementation

## Overview

The Sequence provider implements a number sequence generator for the Flutter launcher application. It generates various mathematical sequences including Fibonacci, prime numbers, arithmetic, geometric, triangular, square, and factorial sequences.

## Implementation Details

### Location
- Provider: `lib/providers/provider_sequence.dart`
- Tests: `test/widget_test.dart` (Sequence Provider tests group)

### Model: SequenceModel

The `SequenceModel` class extends `ChangeNotifier` and manages:

- **Sequence Types**: Fibonacci, Prime, Arithmetic, Geometric, Triangular, Square, Factorial
- **Current Sequence**: List of generated numbers
- **Sequence Count**: Number of terms to generate (1-50)
- **Custom Parameters**: Start/step for arithmetic, start/ratio for geometric
- **Generation Count**: Total sequences generated
- **History**: Recent sequence entries (up to 10)

### Features

1. **Fibonacci Sequence**
   - Classic Fibonacci: 0, 1, 1, 2, 3, 5, 8, 13...
   - Each term is sum of two previous terms
   - Default: 10 terms

2. **Prime Numbers**
   - First N prime numbers: 2, 3, 5, 7, 11, 13...
   - Prime numbers are divisible only by 1 and themselves
   - Efficient prime checking algorithm

3. **Arithmetic Sequence**
   - Customizable start and step values
   - Formula: start + n * step
   - Example: start=1, step=2 → 1, 3, 5, 7, 9...

4. **Geometric Sequence**
   - Customizable start and ratio values
   - Formula: start * ratio^n
   - Example: start=1, ratio=2 → 1, 2, 4, 8, 16...

5. **Triangular Numbers**
   - Formula: n*(n+1)/2
   - Sequence: 1, 3, 6, 10, 15, 21...

6. **Square Numbers**
   - Formula: n^2
   - Sequence: 1, 4, 9, 16, 25, 36...

7. **Factorials**
   - Formula: n!
   - Sequence: 1, 2, 6, 24, 120, 720...

### Widget: SequenceCard

The `SequenceCard` widget displays:

- Sequence type selector using SegmentedButton (Fibonacci, Prime, Arithmetic, Geometric)
- Term count slider (1-50)
- Additional sequence types as ActionChips (Triangular, Square, Factorial)
- Current sequence display with sum calculation
- Copy to clipboard button
- History view with clear option
- Edit dialogs for arithmetic/geometric parameters

### Keywords

`sequence, fibonacci, prime, arithmetic, geometric, generate, math, numbers`

## Material 3 Design

- `Card.filled` for card container
- `SegmentedButton` for sequence type selection
- `Slider` for term count adjustment
- `ActionChip` for additional sequence types
- `TextField` with controller for parameter input dialogs
- `SelectableText` for sequence display (copyable)
- `AlertDialog` for parameter dialogs

## Tests

Test coverage includes:

- SequenceEntry properties
- SequenceModel default values
- SequenceModel initialization
- Fibonacci sequence generation (10 terms, 5 terms)
- Prime number generation (10 terms, 5 terms)
- Arithmetic sequence generation (default, custom)
- Geometric sequence generation (default, custom)
- Triangular number generation
- Square number generation
- Factorial generation (10 terms, 5 terms)
- Sequence count setting and validation
- Selected type setting
- History clearing
- History removal
- History loading
- History max limit (10 entries)
- Current sequence display
- Current sequence sum
- Refresh notification
- SequenceType enum values (7 types)
- Provider existence and keywords
- SequenceCard rendering (loading, initialized)
- Provider in Global.providerList

## Algorithm Details

### Fibonacci

```dart
int a = 0, b = 1;
for (int i = 0; i < count; i++) {
  sequence.add(a);
  int next = a + b;
  a = b;
  b = next;
}
```

### Prime Check

```dart
bool _isPrime(int n) {
  if (n < 2) return false;
  if (n == 2) return true;
  if (n % 2 == 0) return false;
  for (int i = 3; i <= sqrt(n); i += 2) {
    if (n % i == 0) return false;
  }
  return true;
}
```

## Future Enhancements

Potential improvements:

- Add more sequence types (Catalan, Lucas, Pell numbers)
- Add negative number support
- Add floating-point sequence support
- Add sequence persistence via SharedPreferences
- Add export to file option
- Add sequence analysis (average, median, variance)
- Add pattern detection in sequences