# Password Strength Provider Implementation

## Overview

The Password Strength provider allows users to check the strength of their passwords with real-time analysis and feedback. It provides scoring, strength levels, and suggestions for improving password security.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_passwordstrength.dart`
- Model: `PasswordStrengthModel` (within provider file)
- Widget: `PasswordStrengthCard` (within provider file)

### Registration

The provider is registered in `lib/data.dart`:
```dart
import 'package:new_launcher/providers/provider_passwordstrength.dart';
// ...
static List<MyProvider> providerList = [
  // ...
  providerPasswordStrength,
];
```

The model is added to MultiProvider in `lib/main.dart`:
```dart
import 'package:new_launcher/providers/provider_passwordstrength.dart';
// ...
ChangeNotifierProvider.value(value: passwordStrengthModel),
```

### PasswordStrengthModel

The model manages the state for password strength analysis:

#### Properties
- `isInitialized`: Boolean indicating if the model is initialized
- `password`: Current password being analyzed
- `strengthScore`: Score from 0-100
- `strengthLevel`: Level name (Very Weak, Weak, Medium, Strong, Very Strong)
- `strengthLabel`: Display label for strength
- `strengthColor`: Color for visual indication
- `feedback`: Suggestions for improving the password
- `history`: List of previously checked passwords (max 10)

#### Methods
- `init()`: Initialize the model
- `refresh()`: Notify listeners
- `checkPassword(String password)`: Analyze password strength
- `addToHistory(String password)`: Add password to history
- `removeFromHistory(String password)`: Remove password from history
- `clearHistory()`: Clear all history
- `clearPassword()`: Clear current password and reset state
- `copyToClipboard(String text, BuildContext context)`: Copy to clipboard

### Password Analysis Algorithm

The password strength scoring algorithm considers:

1. **Length Score**:
   - < 6 chars: score += length * 2 (very weak)
   - 6-7 chars: score += 12 + (length - 6) * 4 (short)
   - 8-11 chars: score += 24 + (length - 8) * 4
   - 12-15 chars: score += 40 + (length - 12) * 3
   - 16+ chars: score += 52 + min(length - 16, 20)

2. **Character Type Diversity**:
   - Lowercase letters (a-z): +8 points
   - Uppercase letters (A-Z): +8 points
   - Numbers (0-9): +8 points
   - Special characters (!@#$%^&* etc): +8 points
   - Spaces: +5 points

3. **Penalties**:
   - Repeated characters (aaa, bbb): -10 points
   - Sequential characters (abc, 123): -10 points
   - Common patterns (password, qwerty): -15 points

4. **Strength Levels**:
   - 0-19: Very Weak (red)
   - 20-39: Weak (orange)
   - 40-59: Medium (yellow)
   - 60-79: Strong (light green)
   - 80-100: Very Strong (green)

### PasswordStrengthCard Widget

The UI widget displays:
1. Password input field with show/hide toggle
2. Clear password button
3. Strength indicator with:
   - Strength label and score
   - Progress bar with color coding
4. Feedback suggestions
5. Password history section (if any)

### Material 3 Design

The widget uses Material 3 components:
- `Card.filled` for main container
- `LinearProgressIndicator` for strength visualization
- `IconButton.styleFrom()` for styled buttons
- ColorScheme colors for theme-aware styling

## Keywords

The provider registers the following keywords for search:
- password
- strength
- check
- security
- weak
- strong
- analyze
- score

## Testing

Tests are located in `test/widget_test.dart` under the group 'PasswordStrength provider tests':

- Model initialization tests
- Password strength detection tests (very weak, weak, medium, strong, very strong)
- Feedback generation tests
- Pattern detection tests (repeated, sequential, common)
- History management tests (add, remove, clear, max length)
- Widget rendering tests (loading state, initialized state)
- Provider registration tests

## Usage Example

```dart
// In the UI, the PasswordStrengthCard is automatically added via Global.infoModel
// Users can type a password to check its strength

// Direct usage:
final model = PasswordStrengthModel();
model.init();
model.checkPassword('MyPassword123!');
// model.strengthScore == 49
// model.strengthLevel == 'Medium'
// model.feedback contains suggestions
```

## Dependencies

No external packages required - pure Dart implementation.