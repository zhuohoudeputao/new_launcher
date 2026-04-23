# Currency Converter Provider

## Overview

The Currency Converter provider allows users to convert between major world currencies using real-time exchange rates from the Frankfurter API.

## Features

- **Real-time exchange rates**: Fetches current rates from Frankfurter API
- **20 supported currencies**: USD, EUR, GBP, JPY, CNY, AUD, CAD, CHF, INR, MXN, KRW, SGD, HKD, NOK, SEK, DKK, NZD, ZAR, RUB, BRL
- **Easy currency switching**: Dropdown selectors for both input and output currencies
- **Swap currencies**: One-tap button to swap from/to currencies
- **Conversion history**: Stores up to 10 recent conversions
- **Rate caching**: Rates cached for 1 hour to reduce API calls
- **Manual refresh**: Refresh button to fetch latest rates

## Implementation Details

### Model: CurrencyModel

Located in `lib/providers/provider_currency.dart`

Key properties:
- `fromCurrency`: Source currency code (default: USD)
- `toCurrency`: Target currency code (default: EUR)
- `inputValue`: Amount to convert
- `outputValue`: Converted amount
- `rates`: Exchange rate data from API
- `history`: List of recent conversions
- `isLoading`: API fetch status
- `error`: Error message if fetch fails

Key methods:
- `init()`: Initialize model and fetch initial rates
- `fetchRates()`: Get exchange rates from API
- `setFromCurrency(currency)`: Change source currency
- `setToCurrency(currency)`: Change target currency
- `setInputValue(value)`: Set amount to convert
- `swapCurrencies()`: Swap source and target currencies
- `addToHistory()`: Save current conversion to history
- `clearHistory()`: Clear all history
- `useHistoryEntry(entry)`: Load a history entry

### Widget: CurrencyCard

Material 3 styled card with:
- Title row with refresh and history buttons
- Conversion row with two currency sections
- Input field for amount
- Output display for converted value
- Timestamp of rate update

### API Integration

Uses Frankfurter API:
- Endpoint: `https://api.frankfurter.app/latest?from={currency}`
- Returns JSON with rates for all currencies
- Free API, no authentication required
- Rates update daily

## Usage

Users can:
1. Select currencies from dropdowns
2. Enter amount to convert
3. See real-time conversion result
4. Tap swap button to reverse direction
5. Tap refresh to get latest rates
6. View history of past conversions
7. Tap history entry to reuse values

## Keywords

- currency, exchange, rate, money, convert
- dollar, euro, pound, yen, yuan
- usd, eur, gbp, jpy, cny

## Test Coverage

Tests include:
- Model initialization
- Default values
- Currency selection
- Input/output handling
- Swap functionality
- History management
- Provider registration
- Widget rendering
- Error handling

## Dependencies

- `http`: HTTP client for API requests
- `provider`: State management
- Flutter Material 3 components