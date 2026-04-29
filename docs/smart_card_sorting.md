# Smart Card Sorting Implementation

## Overview

Smart Card Sorting is a feature that dynamically reorders info cards based on predicted user needs using time-based usage patterns learned from user behavior.

## How It Works

### Pattern Learning

When users interact with cards (tap, use actions), the system records:
- Card key (e.g., "Weather", "Timer", "App")
- Timestamp
- Hour of day (0-23)
- Day of week (1-7)

### Probability Calculation

For each card, probability is calculated using:
- **70% weight**: Time-of-day pattern (hour)
- **30% weight**: Day-of-week pattern

Formula: `probability = (hourUsage / totalUsage) * 0.7 + (dayOfWeekUsage / totalUsage) * 0.3`

### Dynamic Ordering

Cards are sorted by:
1. Higher probability = displayed first (at top of list)
2. Lower probability = displayed later
3. Cards without usage data = maintain original insertion order

## Implementation Details

### InfoModel Methods

```dart
// Get smart-sorted list based on priority map
List<Widget> getSmartSortedInfoList(Map<String, double> priorities)

// Get smart-sorted list with search query
List<Widget> getSmartSortedFilteredList(String query, Map<String, double> priorities)

// Get all card keys
List<String> get infoKeys
```

### SmartSuggestionsModel Methods

```dart
// Get card priorities for current time
Map<String, double> getCardPriorities()

// Get card priorities for specific hour
Map<String, double> getCardPrioritiesForHour(int hour)

// Record card interaction for pattern learning
void recordCardInteraction(String cardKey)
```

### UI Integration (MyHomePage)

```dart
// Smart sorting when no search query
if (query.isEmpty && smartModel.isInitialized && smartModel.uniqueActions > 0) {
  final priorities = smartModel.getCardPriorities();
  infoList = infoModel.getSmartSortedInfoList(priorities);
} else {
  // Standard search filtering
  infoList = infoModel.getFilteredList(query);
}
```

## User Experience

1. **Morning**: Weather, Calendar cards appear first (if user checks them in morning)
2. **Evening**: Timer, Pomodoro cards appear first (if user uses them in evening)
3. **Weekend**: Entertainment, Game cards may appear higher

## Configuration

- **Minimum suggestions**: 3 cards with probability >= threshold
- **Maximum history**: 500 entries stored
- **Probability threshold**: 5% (0.05) minimum for inclusion

## Future Enhancements

1. Automatic card key mapping from provider names
2. Manual priority override settings
3. Context-based patterns (location, activity)
4. Card interaction tracking via tap gestures