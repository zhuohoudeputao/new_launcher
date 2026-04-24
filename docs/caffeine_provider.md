# Caffeine Tracker Provider Implementation

## Overview

The Caffeine Tracker provider (`provider_caffeine.dart`) tracks daily caffeine intake from beverages. It helps users monitor their caffeine consumption and stay within recommended daily limits.

## Features

- **Daily tracking**: Track caffeine intake in milligrams (mg)
- **Preset drinks**: Quick add buttons for common beverages (Coffee, Tea, Energy Drinks, etc.)
- **Custom amounts**: Add custom caffeine amounts via dialog
- **Daily limit**: Set and track against a daily caffeine limit (default 400mg)
- **Progress indicator**: Visual progress bar showing consumption relative to limit
- **Over-limit warning**: Alert when exceeding recommended daily limit
- **History tracking**: Stores up to 30 days of caffeine data

## Data Models

### CaffeineEntry
Stores individual caffeine intake entries:
- `date`: When the caffeine was consumed
- `amountMg`: Amount in milligrams
- `limit`: Daily limit at the time of entry
- `drinkType`: Type/name of beverage

### DailyCaffeineSummary
Aggregated daily totals:
- `date`: The day
- `totalMg`: Total caffeine consumed that day
- `limit`: Daily limit for that day

### DrinkOption
Preset beverage options:
- `name`: Beverage name (e.g., "Coffee (8oz)")
- `caffeineMg`: Typical caffeine content
- `icon`: Emoji icon for visual display

## Preset Beverages

The provider includes 8 preset drink options with typical caffeine amounts:

| Beverage | Caffeine (mg) | Icon |
|----------|--------------|------|
| Coffee (8oz) | 95 | ☕ |
| Espresso | 64 | ☕ |
| Tea (8oz) | 26 | 🍵 |
| Green Tea | 28 | 🍵 |
| Energy Drink | 80 | ⚡ |
| Cola (12oz) | 35 | 🥤 |
| Diet Cola | 46 | 🥤 |
| Chocolate Bar | 12 | 🍫 |

## Model Properties

### CaffeineModel
- `isInitialized`: Whether model has been initialized
- `dailyLimit`: Current daily limit (default 400mg)
- `todayMg`: Today's total caffeine intake
- `progress`: Percentage of daily limit consumed
- `limitReached`: Whether daily limit has been reached
- `overLimit`: Whether intake exceeds the limit
- `history`: List of daily summaries (up to 30 days)

## Methods

### CaffeineModel
- `init()`: Initialize model and load persisted data
- `refresh()`: Refresh state and check daily reset
- `addCaffeine(int mg, String type)`: Add caffeine intake
- `addQuickDrink(String type)`: Add from preset drinks
- `removeLastEntry()`: Remove most recent entry
- `setLimit(int limit)`: Update daily limit (50-1000mg)
- `clearHistory()`: Clear all stored history

## UI Components

### CaffeineCard
Main widget displaying caffeine tracking:
- Shows current intake vs limit
- Progress bar with color coding (green when under limit, red when over)
- ActionChips for quick drink selection
- Buttons for custom amount, removing entry, and settings

### Custom Amount Dialog
Dialog for entering custom caffeine amounts:
- Text input field for mg amount
- Add button to confirm

### Limit Settings Dialog
Dialog for adjusting daily caffeine limit:
- Increment/decrement buttons (50mg steps)
- Range: 50-1000mg
- Recommended limit reminder (400mg)

## Health Recommendations

The default 400mg daily caffeine limit aligns with FDA recommendations for most adults. This is roughly equivalent to:
- 4 cups of brewed coffee
- 10 cans of cola
- 2 "energy shot" drinks

Individual caffeine sensitivity varies. Users can adjust the limit based on their personal tolerance.

## Persistence

Data is stored using SharedPreferences:
- `_storageKey`: Individual entries
- `_summaryKey`: Daily summaries
- `_limitKey`: Daily limit setting

Maximum 30 days of history is retained to balance useful data with storage efficiency.

## Keywords

`caffeine coffee tea energy drink cola beverage intake track daily health`

## Testing

Tests cover:
- Model initialization
- Add/remove caffeine entries
- Limit setting and tracking
- Progress calculation
- Limit reached/over limit detection
- History management
- JSON serialization/deserialization
- Widget rendering states

See `test/widget_test.dart` under "Caffeine provider tests" group.