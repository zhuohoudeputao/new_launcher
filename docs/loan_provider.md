# Loan Calculator Provider Implementation

## Overview

The Loan provider calculates loan/mortgage payments, total interest, and generates amortization schedules for financial planning.

## Features

### Payment Calculations
- Monthly payment calculation using standard amortization formula
- Total payment over the entire loan term
- Total interest paid over the loan term
- Interest vs principal percentage ratio

### Amortization Schedule
- Month-by-month breakdown of payments
- Principal portion for each payment
- Interest portion for each payment
- Remaining balance after each payment
- Toggle to show/hide amortization table
- Shows first 12 months with scroll support for long terms

### Input Parameters
- Principal amount with dollar prefix
- Annual interest rate (0.1-30%, default 5%)
- Loan term in years (1-50 years, default 30)

### History
- Track up to 10 loan calculations
- Save calculations with full details
- Load previous calculations from history
- Clear history with confirmation dialog

## Implementation Details

### Model (LoanModel)
- `init()` - Initialize model and load history from SharedPreferences
- `refresh()` - Trigger UI update
- `setPrincipal(double amount)` - Set principal amount
- `setAnnualRate(double rate)` - Set annual interest rate (0.1-30%)
- `setTermYears(int years)` - Set loan term in years (1-50)
- `toggleAmortization()` - Toggle amortization table visibility
- `clear()` - Reset inputs to defaults
- `saveToHistory()` - Save current calculation to history
- `loadFromHistory(entry)` - Load calculation from history
- `clearHistory()` - Clear all history
- `formatAmount(double)` - Format currency values
- `monthlyPayment` getter - Calculate monthly payment
- `totalPayment` getter - Calculate total payment
- `totalInterest` getter - Calculate total interest
- `interestPercentage` getter - Calculate interest percentage
- `amortizationSchedule` getter - Generate full amortization schedule

### Data Classes
- `LoanEntry` - Stores saved calculation details
  - date, principal, annualRate, termYears
  - monthlyPayment, totalInterest, totalPayment
  - toJson/fromJson for persistence
  
- `AmortizationEntry` - Single amortization row
  - month, payment, principal, interest, balance

### Widget (LoanCard)
- StatefulWidget with TextEditingController for inputs
- Material 3 Card.filled styling
- TextField with dollar prefix for principal
- Dual TextField for rate and term
- Result container with surfaceContainerHigh color
- Table widget for amortization display
- History view with ListTile entries
- Confirmation dialog for clearing history

## State Management

- Uses SharedPreferences for history persistence
- ChangeNotifier pattern for UI updates
- Global model instance: `loanModel`
- Max history limit: 10 entries

## Keywords

- loan, calculator, mortgage, payment, interest, amortization, finance

## Usage

The provider is automatically added to the info widget list on app startup. Users can:
1. Enter principal amount, interest rate, and loan term
2. View calculated monthly payment, total payment, and total interest
3. Toggle amortization table for month-by-month breakdown
4. Save calculations to history for future reference
5. Load previous calculations from history
6. Clear history with confirmation

## Amortization Formula

The monthly payment is calculated using the standard loan amortization formula:

```
M = P × (r × (1+r)^n) / ((1+r)^n - 1)
```

Where:
- M = Monthly payment
- P = Principal amount
- r = Monthly interest rate (annual rate / 100 / 12)
- n = Number of payments (term years × 12)

## Files Modified

- `lib/providers/provider_loan.dart` - New provider implementation
- `lib/data.dart` - Added import and provider to Global.providerList
- `lib/main.dart` - Added import and model to MultiProvider
- `test/widget_test.dart` - Added 18 tests for the provider
- `AGENTS.md` - Updated documentation

## Tests Added

- Provider existence and keywords tests
- Model initialization tests
- Setter/getter tests
- Payment calculation tests
- Total payment and interest tests
- Interest percentage tests
- Amortization schedule tests
- History operations tests
- JSON serialization tests
- Widget rendering tests
- Provider list inclusion tests