# Random Generator Provider

## Overview

The Random Generator provider provides random generation utilities including coin flip, dice roll, random number generation, and password generation.

## Features

### Coin Flip
- Quick heads/tails flip
- Tap refresh button to flip again
- Uses `Icons.currency_exchange` icon

### Dice Roll
- Multiple dice options: D4, D6, D8, D10, D12, D20, D100
- SegmentedButton for dice type selection
- Real-time roll result display
- Uses `Icons.casino` icon

### Random Number Generator
- Custom min/max range input
- Integer generation within specified range
- Supports negative numbers
- Uses `Icons.pin` icon

### Password Generator
- Configurable length (4-64 characters) via Slider
- Character type options via FilterChip:
  - Lowercase (a-z)
  - Uppercase (A-Z)
  - Numbers (0-9)
  - Symbols (!@#$%^&*()_+-=[]{}|;:,.<>?)
- Copy to clipboard functionality
- Uses `Icons.password` icon

## Model Structure

```dart
class RandomModel extends ChangeNotifier {
  bool _isInitialized = false;
  
  String _coinResult = "";
  String _diceResult = "";
  int _diceSides = 6;
  String _randomNumberResult = "";
  int _randomNumberMin = 1;
  int _randomNumberMax = 100;
  String _passwordResult = "";
  int _passwordLength = 12;
  bool _passwordIncludeLower = true;
  bool _passwordIncludeUpper = true;
  bool _passwordIncludeNumbers = true;
  bool _passwordIncludeSymbols = true;
  
  // Methods
  void init();
  void refresh();
  String flipCoin();
  String rollDice(int sides);
  String generateRandomNumber(int min, int max);
  String generatePassword(int length, {bool? lower, bool? upper, bool? numbers, bool? symbols});
  void setPasswordLength(int length);
  void setPasswordOptions({required bool lower, required bool upper, required bool numbers, required bool symbols});
  void copyToClipboard(String text, BuildContext context);
}
```

## Widget Structure

```dart
class RandomCard extends StatefulWidget {
  // Main card with all generator sections
}

class _RandomCardState extends State<RandomCard> {
  int _selectedDiceIndex = 1;
  final List<int> _diceOptions = [4, 6, 8, 10, 12, 20, 100];
  
  final TextEditingController _minController = TextEditingController(text: '1');
  final TextEditingController _maxController = TextEditingController(text: '100');
  
  // Build methods for each section:
  Widget _buildCoinFlipSection(BuildContext context, RandomModel random);
  Widget _buildDiceSection(BuildContext context, RandomModel random);
  Widget _buildRandomNumberSection(BuildContext context, RandomModel random);
  Widget _buildPasswordSection(BuildContext context, RandomModel random);
  Widget _buildPasswordOptionChip(BuildContext context, RandomModel random, String label, bool selected, ValueChanged<bool> onChanged);
}
```

## Material 3 Components Used

- `Card.filled` - Main card container
- `SegmentedButton` - Dice type selection
- `Slider` - Password length control
- `FilterChip` - Password character type options
- `IconButton.styleFrom()` - Button styling

## Provider Registration

```dart
MyProvider providerRandom = MyProvider(
    name: "Random",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

## Keywords

- coin, flip, heads, tails, toss
- dice, roll, d6, d20, die
- password, generate, secure
- random, number, generate

## Usage in Global Provider List

The Random provider is added to `Global.providerList` in `lib/data.dart`:

```dart
static List<MyProvider> providerList = [
  providerSettings,
  providerWallpaper,
  providerTheme,
  providerTime,
  providerWeather,
  providerApp,
  providerSystem,
  providerBattery,
  providerFlashlight,
  providerNotes,
  providerTimer,
  providerStopwatch,
  providerCalculator,
  providerWorldClock,
  providerCountdown,
  providerUnitConverter,
  providerPomodoro,
  providerClipboard,
  providerTodo,
  providerQRCode,
  providerRandom,
];
```

## Model Registration in main.dart

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: randomModel),
    // ... other providers
  ],
  child: MyApp(),
)
```

## Test Coverage

The Random Generator provider tests include:
- RandomModel existence and initial state
- Initialization tests
- Coin flip functionality
- Dice roll functionality with different sides
- Random number generation with custom ranges
- Password generation with different lengths and options
- Password length and options setters
- NotifyListeners behavior
- Widget rendering tests (loading state, initialized state, with results)
- Provider registration tests

Total Random provider tests: 24 tests