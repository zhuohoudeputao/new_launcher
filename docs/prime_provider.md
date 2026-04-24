# Prime Number Checker Provider

## Overview

The Prime Number Checker provider allows users to check if a number is prime and find its prime factors. It provides a simple interface for mathematical prime number operations.

## Implementation Details

### Model: PrimeModel

Located in `lib/providers/provider_prime.dart`

**State Variables:**
- `_inputNumber`: The number being checked (default: 0)
- `_isPrime`: Boolean indicating if the number is prime
- `_primeFactors`: List of prime factors for non-prime numbers
- `_showFactors`: Toggle for showing factor display
- `_isInitialized`: Initialization state
- `_history`: History of checked numbers (max 10 entries)

**Static Methods:**
- `checkPrime(int n)`: Returns true if n is a prime number
- `findPrimeFactors(int n)`: Returns list of prime factors for n

**Instance Methods:**
- `init()`: Initialize the model
- `setInputNumber(int value)`: Set number and check prime/factors
- `toggleShowFactors()`: Toggle factor display
- `addToHistory()`: Add current number to history
- `loadFromHistory(entry)`: Load a history entry
- `loadHistory()`: Load history from SharedPreferences
- `clearInput()`: Clear current input
- `clearHistory()`: Clear all history
- `refresh()`: Notify listeners

### Prime Number Algorithm

The `checkPrime` method uses an efficient algorithm:
1. Numbers less than 2 are not prime
2. 2 is the only even prime
3. Check divisibility by 2
4. Check divisibility by odd numbers up to sqrt(n)

### Prime Factor Algorithm

The `findPrimeFactors` method finds all prime factors:
1. Divide out all factors of 2
2. Check odd factors from 3 to sqrt(n)
3. Add remaining factor if greater than 2

### Widget: PrimeCard

Uses Material 3 `Card.filled` style with:
- Number input TextField with keyboard type number
- Result display with color-coded container (green for prime, red for non-prime)
- Prime factors display for non-prime numbers
- Save to History button
- History dialog with clear all option
- Time-ago display for history entries

## Keywords

- prime, number, check, factor, math, divisor, isprime, prime factor

## Provider Registration

The provider is registered in `Global.providerList` as `providerPrime`.

### MultiProvider

Added to `main.dart` MultiProvider:
```dart
ChangeNotifierProvider.value(value: primeModel),
```

## Data Persistence

History is saved to SharedPreferences under key `'PrimeHistory'` as a list of JSON-encoded entries:
```dart
{
  'number': int,
  'isPrime': bool,
  'factors': List<int>,
  'timestamp': String
}
```

## Tests

Located in `test/widget_test.dart` under `Prime Provider tests` group:
- Provider existence in Global.providerList
- Model initialization
- Static methods (checkPrime, findPrimeFactors)
- Input handling
- History operations
- Widget rendering tests
- Provider count verification (83 total providers)

Total tests: 18 tests for Prime provider

## Usage

1. Enter a number in the input field
2. The result shows whether the number is prime
3. For non-prime numbers, prime factors are displayed (e.g., 12 = 2 × 2 × 3)
4. Save checked numbers to history
5. Load previous checks from history dialog

## Example Results

| Input | Is Prime | Prime Factors |
|-------|----------|---------------|
| 17    | Yes      | -             |
| 12    | No       | 2 × 2 × 3     |
| 100   | No       | 2 × 2 × 5 × 5 |
| 97    | Yes      | -             |
| 1     | No       | -             |

## Files Modified

- `lib/providers/provider_prime.dart` - New provider implementation
- `lib/data.dart` - Import and providerList update
- `lib/main.dart` - Import and MultiProvider update
- `test/widget_test.dart` - New tests and provider count update