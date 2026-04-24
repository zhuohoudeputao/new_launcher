# Debt Tracker Provider

## Overview

The Debt Tracker provider allows users to track debts and loans with people, showing who owes them money and who they owe money to, including amounts and optional due dates.

## Features

- Track debts owed to you and debts owed by you
- Optional due dates with overdue detection
- Mark debts as paid/unpaid
- Net balance calculation (owed to me - owed by me)
- Overdue debt alerts
- History view with all debt entries
- Maximum 20 entries stored (oldest removed when limit exceeded)
- Debt entries persisted via SharedPreferences

## Usage

### Adding a Debt

1. Tap the "Add" button on the Debt Tracker card
2. Select whether the debt is "Owed to Me" or "Owed by Me" using SegmentedButton
3. Enter the person's name
4. Enter the amount
5. Optionally set a due date using the date picker
6. Optionally add a description
7. Tap "Add" to save

### Managing Debts

- View unpaid debts in the main card display (up to 5 shown)
- Tap "History" to view all debt entries
- In history view, tap the check icon to mark a debt as paid
- Tap the undo icon to mark a paid debt as unpaid
- Tap the delete icon to remove a debt entry
- Clear all entries with the "Clear All" button

### Net Balance

The card displays:
- **Owed to Me**: Total amount others owe you (green)
- **Owed by Me**: Total amount you owe others (red)
- **Net Balance**: Difference between the two (green if positive, red if negative)

### Overdue Detection

- Debts with due dates show "Due in X days" or "Overdue X days"
- Overdue indicator badge appears in the header when any debt is overdue
- Overdue debts are highlighted with error color

## Keywords

`debt, loan, money, owe, borrow, lend, tracker, owed`

## Model Structure

### DebtEntry

```dart
class DebtEntry {
  final String id;           // Unique identifier
  final String personName;   // Name of person involved
  final double amount;       // Amount of the debt
  final bool isOwedToMe;     // True if owed to user, false if owed by user
  final DateTime date;       // Date debt was recorded
  final DateTime? dueDate;   // Optional due date
  final String? description; // Optional description
  final bool isPaid;         // Whether debt is paid
}
```

### DebtModel

```dart
class DebtModel extends ChangeNotifier {
  static const int maxEntries = 20;  // Maximum stored entries
  
  List<DebtEntry> get entries;       // All entries
  List<DebtEntry> get unpaidEntries; // Unpaid entries
  List<DebtEntry> get paidEntries;   // Paid entries
  List<DebtEntry> get owedToMe;      // Unpaid debts owed to user
  List<DebtEntry> get owedByMe;      // Unpaid debts owed by user
  List<DebtEntry> get overdueEntries; // Overdue unpaid debts
  
  double get totalOwedToMe;  // Sum of owed to user
  double get totalOwedByMe;  // Sum of owed by user
  double get netBalance;     // Difference (owedToMe - owedByMe)
  
  int get unpaidCount;       // Count of unpaid entries
  int get paidCount;         // Count of paid entries
  
  void addEntry(...);        // Add new debt
  void markAsPaid(id);       // Mark debt as paid
  void markAsUnpaid(id);     // Mark debt as unpaid
  void deleteEntry(id);      // Delete debt entry
  void clearAll();           // Clear all entries
}
```

## UI Components

### DebtCard

- Uses `Card.filled` for Material 3 style
- Shows summary with owed to me, owed by me, and net balance
- Displays up to 5 unpaid debts with details
- Overdue badge indicator when any debt is overdue
- Add and History buttons

### AddDebtDialog

- SegmentedButton for debt type selection
- Person name TextField
- Amount TextField with dollar prefix
- Optional due date picker
- Optional description TextField

## Material 3 Design

- Card.filled for main display
- SegmentedButton for debt type selection
- ColorScheme for semantic colors:
  - Green for owed to user
  - Red for owed by user
  - Error color for overdue debts

## Persistence

Debt entries are stored in SharedPreferences as a list of JSON strings under the key `debt_entries`.

## Testing

Tests cover:
- Model initialization and state
- Add, mark paid/unpaid, delete operations
- Overdue detection logic
- Max entries limit
- JSON serialization/deserialization
- Widget rendering (loading, empty, entries states)
- Provider integration with Global.providerList