# Dog Age Provider Implementation

## Overview

The Dog Age provider (`providerDogAge`) provides a calculator for converting dog age to human equivalent years using a scientifically-based formula.

## Implementation Details

### File Location
- Provider file: `lib/providers/provider_dog_age.dart`
- Model class: `DogAgeModel`
- Widget: `DogAgeCard`

### Model State

```dart
class DogAgeModel extends ChangeNotifier {
  double _dogYears = 0;
  bool _focusInput = false;
}
```

### Conversion Formula

The scientific formula for dog-to-human age conversion:
- First year of dog's life = 15 human years
- Second year = +9 human years (so 2 dog years = 24 human years)
- Each subsequent year = +4 human years

```dart
double calculateHumanYears(double dogYears) {
  if (dogYears <= 0) return 0;
  if (dogYears < 1) return dogYears * 15;
  if (dogYears < 2) return 15 + (dogYears - 1) * 9;
  return 15 + 9 + (dogYears - 2) * 4;
}
```

### Human Age Descriptions

```dart
String getHumanAgeDescription(double humanYears) {
  if (humanYears <= 0) return "Newborn";
  if (humanYears < 3) return "Infant";
  if (humanYears < 13) return "Child";
  if (humanYears < 20) return "Teenager";
  if (humanYears < 40) return "Young Adult";
  if (humanYears < 60) return "Adult";
  if (humanYears < 75) return "Middle-aged";
  return "Senior";
}
```

### Dog Life Stages

```dart
String getLifeStage(double dogYears) {
  if (dogYears <= 0) return "Newborn";
  if (dogYears < 0.5) return "Puppy";
  if (dogYears < 1) return "Young Puppy";
  if (dogYears < 3) return "Young Adult";
  if (dogYears < 7) return "Adult";
  if (dogYears < 10) return "Senior";
  return "Geriatric";
}
```

### UI Components

- **DogAgeCard**: Main widget displaying the calculator
  - TextField for dog age input
  - Human years result display with large font
  - Human age description
  - Dog life stage indicator
  - Formula explanation section
  - Clear button when value is present

### Provider Registration

The provider is registered in:
1. `lib/data.dart` - Added to `Global.providerList`
2. `lib/main.dart` - Added to `MultiProvider`

### Keywords

`dog, age, pet, puppy, canine, human, years, convert`

## Test Coverage

Tests are located in `test/widget_test.dart` under the "DogAge Provider Tests" group:

- Provider existence in Global.providerList
- Provider provides actions
- Model initial state
- calculateHumanYears for various inputs (1, 2, 3, 5, 0, partial)
- getHumanAgeDescription for all age ranges
- getLifeStage for all dog life stages
- setDogYears and clear methods
- requestFocus sets flag
- notifyListeners on setDogYears
- Widget rendering tests
- Keyword validation

## Usage

1. Enter dog's age in years (supports decimals for puppies)
2. View calculated human equivalent years
3. See human age description and dog life stage
4. Formula explanation is shown below the result

## Material 3 Components

- `Card.filled` - Main card container
- `TextField` - Dog age input
- `Icon(Icons.pets)` - Dog icon indicator
- `Container` with rounded corners - Result display box