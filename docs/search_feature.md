# Search Feature Documentation

## Overview

The search functionality allows users to filter info cards by typing in the search box. When the user types text, the app filters the displayed cards to show only those matching the search query.

## Implementation Details

### Components

1. **ActionModel** (`lib/data.dart`)
   - Stores `_searchQuery` to track the current search text
   - `generateSuggestList()` updates both suggestions and stores the search query
   - Provides `searchQuery` getter

2. **InfoModel** (`lib/data.dart`)
   - Maintains `_titleMap` to store titles for each info widget (key -> title mapping)
   - `getFilteredList(String query)` filters cards by matching query against both key and title
   - `addInfoWidget(String key, Widget widget, {String? title})` accepts optional title parameter

3. **Main UI** (`lib/main.dart`)
   - Uses `context.watch<ActionModel>()` to get search query
   - Calls `infoModel.getFilteredList(query)` to get filtered cards
   - Updates `CircularListController.itemCount` to reflect filtered list size

### Filtering Logic

```dart
List<Widget> getFilteredList(String query) {
  if (query.isEmpty) return infoList;
  final lowerQuery = query.toLowerCase().trim();
  if (lowerQuery.isEmpty) return infoList;
  return _infoList.entries
      .where((e) =>
          e.key.toLowerCase().contains(lowerQuery) ||
          (_titleMap[e.key]?.toLowerCase().contains(lowerQuery) ?? false))
      .map((e) => e.value)
      .toList();
}
```

### Circular List Integration

When the search query changes, the filtered list size is updated in the CircularListController to maintain circular scrolling:

```dart
@override
Widget build(BuildContext context) {
  final actionModel = context.watch<ActionModel>();
  String query = actionModel.searchQuery;
  List<Widget> infoList = context.watch<InfoModel>().getFilteredList(query);
  
  if (_circularListController.hasClients) {
    _circularListController.itemCount = infoList.isEmpty ? 1 : infoList.length;
  }
  
  // ... rest of build method
}
```

### Usage

1. User types in the search TextField
2. `onChanged` callback triggers `generateSuggestList(input)`
3. `generateSuggestList` stores the query and updates suggestions
4. Main UI rebuilds with filtered list via `getFilteredList(query)`
5. When query is empty, all cards are shown

## Adding Searchable Titles

When adding info widgets, pass the `title` parameter:

```dart
Global.infoModel.addInfoWidget(
  "app_chrome",
  _buildAppCard(app),
  title: app.appName,  // This enables searching by app name
);
```

## Testing

Tests are located in `test/widget_test.dart` under the groups:
- `InfoModel getFilteredList tests`
- `ActionModel searchQuery tests`
- `ActionModel extended tests` (includes frequency sorting tests)

## Suggestion Sorting by Frequency

As of recent updates, the suggestion list is now sorted by usage frequency to prioritize commonly used actions.

### Sorting Implementation

When generating the suggestion list, actions are sorted by their frequency count (current hour usage):

```dart
void generateSuggestList(String input) {
  final matchingActions = _actionMap.values
      .where((action) => action.canIdentifyBy(input))
      .toList();
  
  matchingActions.sort((a, b) => b.frequency.compareTo(a.frequency));
  
  for (MyAction action in matchingActions) {
    _suggestList.add(action.suggestWidget);
  }
}
```

### Benefits

- Frequently used apps appear first in suggestions
- Reduces search time for common operations
- Automatically adapts to user behavior over time

### Frequency Tracking

Each action tracks usage per hour (24-hour array). The `frequency` getter returns the count for the current hour, ensuring sorting reflects recent usage patterns.
