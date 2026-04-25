# Calorie Tracker Provider Implementation

## Overview

The Calorie Tracker provider allows users to track daily calorie intake with preset food items and custom calorie entries. It provides a visual progress bar showing calories consumed versus daily goal, and maintains a history of daily calorie summaries.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_calorie.dart`
- Tests: `test/widget_test.dart` (Calorie provider tests group)

### Key Classes

#### CalorieEntry
Stores individual calorie entry with:
- `date`: When the entry was logged
- `amountCal`: Calories consumed
- `goal`: Daily goal at time of entry
- `foodType`: Name of food/item consumed

#### DailyCalorieSummary
Stores daily total with:
- `date`: The date of the summary
- `totalCal`: Total calories consumed that day
- `goal`: Daily goal for that day

#### FoodOption
Preset food items with:
- `name`: Food name (e.g., "Apple", "Banana")
- `calories`: Calorie count
- `icon`: Emoji icon for visual representation

#### CalorieModel
State management class with:
- `todayCal`: Current day's total calories
- `dailyGoal`: Daily calorie goal (default: 2000)
- `progress`: Progress percentage toward goal
- `remainingCal`: Calories remaining before goal
- `goalReached`: Whether goal has been reached
- `overGoal`: Whether over daily goal

### Preset Food Options (12 items)
- Apple (95 cal) 🍎
- Banana (105 cal) 🍌
- Egg (78 cal) 🥚
- Toast (75 cal) 🍞
- Coffee (5 cal) ☕
- Salad (150 cal) 🥗
- Sandwich (350 cal) 🥪
- Pizza Slice (285 cal) 🍕
- Burger (500 cal) 🍔
- Rice (1 cup) (200 cal) 🍚
- Chicken Breast (165 cal) 🍗
- Soup (100 cal) 🥣

### Features

1. **Quick Add**: Tap preset food items to add calories
2. **Custom Add**: Input custom calorie amounts via dialog
3. **Remove Last**: Remove the last added entry
4. **Goal Setting**: Adjust daily calorie goal (100-5000 cal)
5. **Progress Visualization**: Linear progress bar with color coding
6. **Remaining Display**: Shows remaining calories before goal
7. **Over Goal Warning**: Visual warning when exceeding daily goal
8. **History**: Stores up to 30 days of calorie summaries

### Color Coding
- **Tertiary**: Under goal (< 100%)
- **Primary**: Goal reached (100%)
- **Error**: Over goal (> 100%)

### UI Components
- `Card.filled`: Material 3 card container
- `LinearProgressIndicator`: Visual progress display
- `ActionChip`: Quick add buttons for preset foods
- `AlertDialog`: Custom calorie input and goal setting dialogs

### Persistence
- SharedPreferences for calorie entries and daily summaries
- Daily goal stored separately
- Maximum 30 days of history retained

## Test Coverage

Tests verify:
- Model initialization
- Adding calories (preset and custom)
- Removing entries
- Goal setting
- Progress calculation
- Goal reached/over goal detection
- Remaining calories calculation
- Clear history
- Entry serialization (toJson/fromJson)
- Day key generation
- Provider registration in Global.providerList
- Widget rendering (loading and initialized states)

## Usage Example

```dart
// Add calories
calorieModel.addCalorie(95, 'Apple');

// Quick add preset food
calorieModel.addQuickFood('apple');

// Set daily goal
calorieModel.setGoal(1500);

// Remove last entry
calorieModel.removeLastEntry();

// Clear history
await calorieModel.clearHistory();
```

## Integration

The provider is registered in:
- `lib/data.dart`: Import and providerList
- `lib/main.dart`: Import and MultiProvider
- `test/widget_test.dart`: Import and test group

## Keywords
`calorie calories food eat meal intake track daily health nutrition diet`