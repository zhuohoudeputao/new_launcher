# Currency Provider Fix

## Issue

The `currencyModel` was missing from the `MultiProvider` in `main.dart`. This could cause issues when the `CurrencyCard` tries to access the model through `context.read<CurrencyModel>()` in dialog callbacks.

## Solution

Added the `currencyModel` to the `MultiProvider` list in `main.dart`:

1. Added import: `import 'package:new_launcher/providers/provider_currency.dart';`
2. Added provider: `ChangeNotifierProvider.value(value: currencyModel),`

## Files Changed

- `lib/main.dart` - Added import and provider entry

## Testing

- All 631 tests pass
- APK build successful (52.4MB)

## Pattern

This fix follows the same pattern used for other models like `colorModel`, `randomModel`, `qrModel`, `todoModel`, etc. All provider models should be registered in the global `MultiProvider` to ensure proper state management across the app.