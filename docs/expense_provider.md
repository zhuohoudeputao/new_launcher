# Expense Tracker Provider

## Overview

The Expense Tracker provider allows users to track daily expenses with categories, amounts, and optional descriptions. It provides a quick way to monitor spending habits.

## Features

- Add expenses with amount and category
- 7 predefined expense categories with emoji icons:
  - Food (🍔)
  - Transport (🚗)
  - Entertainment (🎬)
  - Shopping (🛍️)
  - Bills (📄)
  - Health (💊)
  - Other (📦)
- Optional description/notes for each expense
- Daily, weekly, and monthly totals display
- History view showing recent expenses
- Delete expenses by swipe gesture
- Clear all expenses with confirmation dialog
- Maximum 100 expenses stored (oldest removed when limit exceeded)
- Expenses persisted via SharedPreferences

## Implementation

### File Location
`lib/providers/provider_expense.dart`

### Model Classes

#### ExpenseCategory Enum
```dart
enum ExpenseCategory {
  food('Food', Icons.restaurant, '🍔'),
  transport('Transport', Icons.directions_car, '🚗'),
  entertainment('Entertainment', Icons.movie, '🎬'),
  shopping('Shopping', Icons.shopping_bag, '🛍️'),
  bills('Bills', Icons.receipt, '📄'),
  health('Health', Icons.local_hospital, '💊'),
  other('Other', Icons.more_horiz, '📦');
}
```

#### ExpenseEntry Class
```dart
class ExpenseEntry {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String? description;
  final DateTime date;
}
```

#### ExpenseModel Class
- `init()` - Initialize from SharedPreferences
- `refresh()` - Refresh state
- `addExpense()` - Add new expense
- `deleteExpense()` - Delete expense by ID
- `clearHistory()` - Clear all expenses
- `todayTotal` - Sum of today's expenses
- `weekTotal` - Sum of this week's expenses
- `monthTotal` - Sum of this month's expenses
- `categoryTotals` - Totals by category for today

### UI Components

#### ExpenseCard Widget
- Material 3 Card.filled style
- Shows Today/Week/Month totals
- Add expense button with dialog
- History toggle button
- Dismissible expense items (swipe to delete)
- Clear all button with confirmation

#### Add Expense Dialog
- Amount input field with $ prefix
- Category selection via ChoiceChips
- Optional description field
- Cancel/Add buttons

## Keywords
`expense, money, spend, cost, budget, track, finance, wallet`

## Usage

### Add Expense
1. Tap "Add" button
2. Enter amount in the field
3. Select category from chips
4. Optionally add a note
5. Tap "Add" to save

### View History
1. Tap "History" button
2. See recent expenses with emoji, category, and amount
3. Swipe right-to-left to delete individual expenses

### Clear All
1. Tap delete icon in header
2. Confirm deletion in dialog
3. All expenses removed

## Constants

- `maxEntries = 100` - Maximum stored expenses
- `maxHistoryDays = 30` - Days tracked (future expansion)

## Storage

- Key: `expense_entries`
- Format: JSON array of ExpenseEntry objects
- SharedPreferences persistence

## Tests

21 tests covering:
- Model initialization
- Category values and emoji
- Entry JSON serialization
- Add/delete operations
- Total calculations
- Category totals
- Clear history
- Widget rendering
- Provider existence in Global.providerList

## Integration

Added to `Global.providerList` in `lib/data.dart`.

Total providers: 29
Total tests: 765