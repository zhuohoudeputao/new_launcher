# Cron Expression Parser Provider

## Overview

The Cron Expression Parser provider allows developers to parse and understand cron expressions. It provides human-readable descriptions and calculates the next scheduled run times for any valid cron expression.

## Features

- **Parse cron expressions**: Validates and parses standard 5-field cron expressions (minute, hour, day of month, month, day of week)
- **Human-readable description**: Converts cron expressions into readable text (e.g., "Every minute", "at minute 0, at hour 9")
- **Next run times**: Calculates the next 5 scheduled execution times
- **Syntax support**:
  - Wildcards (`*`) - all values
  - Specific values (`0`, `15`, `30`)
  - Ranges (`1-5`, `9-17`)
  - Steps (`*/15`, `0-30/10`)
  - Comma-separated lists (`0,15,30,45`)
- **History tracking**: Save and load previous expressions (up to 10 entries)

## Cron Expression Format

The standard cron expression has 5 fields:

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6) (Sunday=0)
│ │ │ │ │
* * * * *
```

## Examples

| Expression | Description |
|------------|-------------|
| `* * * * *` | Every minute |
| `0 * * * *` | Every hour at minute 0 |
| `0 0 * * *` | Every day at midnight |
| `0 9 * * *` | Every day at 9:00 AM |
| `0 9-17 * * *` | Every hour from 9 AM to 5 PM |
| `*/15 * * * *` | Every 15 minutes |
| `0 */2 * * *` | Every 2 hours |
| `0 0 1 * *` | First day of every month at midnight |
| `0 0 * * 0` | Every Sunday at midnight |
| `0 0 1 1 *` | January 1st at midnight |

## Implementation Details

### Model: `CronModel`

Located in `lib/providers/provider_cron.dart`

**Properties**:
- `expression`: The current cron expression string
- `description`: Human-readable description of the schedule
- `isValid`: Whether the expression is valid
- `errorMessage`: Error message if expression is invalid
- `nextRuns`: List of next 5 scheduled execution times
- `history`: List of saved expressions (max 10)
- `isInitialized`: Whether the model has been initialized

**Methods**:
- `init()`: Initialize the model
- `setExpression(String value)`: Parse a new cron expression
- `addToHistory()`: Save current expression to history
- `loadFromHistory(int index)`: Load expression from history
- `clearHistory()`: Clear all history entries
- `clearExpression()`: Clear current expression
- `refresh()`: Trigger notifyListeners

### Widget: `CronExpressionParserCard`

Displays:
- Input field for cron expression
- Error display for invalid expressions
- Human-readable description in a highlighted box
- Next 5 scheduled run times with relative time indicators
- Save/Clear buttons
- History section with timestamp indicators

### Provider: `providerCronExpressionParser`

- **Name**: `CronExpressionParser`
- **Keywords**: `cron expression schedule parser time crontab job`

## Testing

Tests are located in `test/widget_test.dart` under the "Cron Expression Parser Provider tests" group.

**Test coverage**:
- Provider existence and initialization
- Expression parsing (valid and invalid)
- Wildcard, range, step, and comma-separated value parsing
- Description generation
- Next runs calculation
- History operations (add, load, clear)
- Widget rendering
- Provider count verification (100 total)

## Usage

The Cron Expression Parser card appears in the main info list by default. Users can:

1. Enter a cron expression in the input field
2. See the human-readable description instantly
3. View the next 5 scheduled execution times
4. Save expressions to history for quick reference
5. Load previous expressions from history

## Material 3 Design

- Uses `Card.filled` for consistent styling
- Primary color for icons and highlights
- Error container for invalid expression display
- Primary container for description display
- Secondary container for run time badges

## Files Modified

- `lib/providers/provider_cron.dart` - New provider implementation
- `lib/data.dart` - Added import and provider to Global.providerList
- `lib/main.dart` - Added import and model to MultiProvider
- `test/widget_test.dart` - Added tests for the new provider

## Notes

- The parser uses standard cron syntax (5 fields)
- Next runs are calculated from the current time
- Maximum 500000 iterations to find next runs (for infrequent schedules like monthly)
- History entries are limited to 10 to prevent excessive storage