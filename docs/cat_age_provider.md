# CatAge Provider Implementation

## Overview

The CatAge provider converts cat age to human equivalent years using a scientifically-based formula. This helps cat owners understand their pet's life stage and approximate human age.

## Implementation Details

### Provider Structure

```dart
MyProvider providerCatAge = MyProvider(
  name: "CatAge",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);
```

### Model Class

The `CatAgeModel` class extends `ChangeNotifier` and provides:

- **State Management**: Tracks the cat's age in years
- **Conversion Logic**: Calculates human equivalent years
- **Life Stage Detection**: Determines cat's developmental stage
- **Human Age Description**: Provides human developmental phase names

### Conversion Formula

The cat age to human years conversion uses the following formula:

- **First year**: 15 human years
- **Second year**: +10 human years (so 2 cat years = 25 human years)
- **Each subsequent year**: +4 human years

This formula is based on veterinary research and differs from dog age conversion:

```dart
double calculateHumanYears(double catYears) {
  if (catYears <= 0) return 0;
  if (catYears < 1) return catYears * 15;
  if (catYears < 2) return 15 + (catYears - 1) * 10;
  return 15 + 10 + (catYears - 2) * 4;
}
```

### Cat Life Stages

The provider defines 7 life stages for cats:

| Cat Age | Life Stage |
|---------|------------|
| 0 | Newborn |
| 0-1 years | Kitten |
| 1-2 years | Junior |
| 3-6 years | Adult |
| 7-10 years | Mature |
| 11-14 years | Senior |
| 15+ years | Geriatric |

### Human Age Descriptions

The provider also maps human equivalent years to developmental phases:

| Human Years | Phase |
|-------------|-------|
| 0 | Newborn |
| 1-2 | Infant |
| 3-12 | Child |
| 13-19 | Teenager |
| 20-39 | Young Adult |
| 40-59 | Adult |
| 60-74 | Middle-aged |
| 75+ | Senior |

### UI Components

#### CatAgeCard Widget

The card displays:
- Title with pets icon
- Age input field (supports decimal values for kittens)
- Human equivalent years display
- Human age description
- Cat age and life stage information
- Formula explanation

#### Features

- **Real-time Conversion**: Updates as user types
- **Decimal Support**: For kittens (e.g., 0.5 years)
- **Clear Button**: Resets input and results
- **Focus Management**: Quick access via action tap

### Keywords

The provider is searchable via these keywords:
- `cat`, `age`, `pet`, `kitten`, `feline`, `human`, `years`, `convert`

### Integration

#### Provider List

Added to `Global.providerList` in `lib/data.dart`:

```dart
providerCatAge,
```

#### MultiProvider

Added to `MultiProvider` in `lib/main.dart`:

```dart
ChangeNotifierProvider.value(value: catAgeModel),
```

## Usage Examples

### Basic Conversion

- 1 cat year → 15 human years (Infant)
- 2 cat years → 25 human years (Young Adult)
- 5 cat years → 37 human years (Young Adult)
- 10 cat years → 57 human years (Adult)
- 15 cat years → 77 human years (Senior)

### Decimal Age (Kittens)

- 0.5 cat years → 7.5 human years (Infant)
- 0.25 cat years → 3.75 human years (Child)

## Testing

Tests include:
- Provider existence in Global.providerList
- Action provision verification
- Model initial state
- Human years calculation for various ages
- Life stage determination
- Human age description mapping
- State management (setCatYears, clear)
- UI widget rendering
- Provider count verification (128 total providers)

## Related Provider

This provider complements the **DogAge** provider, which provides similar functionality for dog owners with a different conversion formula:

- DogAge: 1st year = 15, 2nd year = +9, subsequent years = +4
- CatAge: 1st year = 15, 2nd year = +10, subsequent years = +4

## Material 3 Compliance

The provider uses Material 3 components:
- `Card.filled` for main container
- `TextField` with OutlineInputBorder
- `IconButton` with styleFrom
- ColorScheme colors for visual hierarchy