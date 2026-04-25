# MotivationalQuote Provider

## Overview

The MotivationalQuote provider displays daily motivational and inspirational quotes from famous authors and leaders. It provides features for quote navigation, favorites management, and quote sharing.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_motivationalquote.dart`
- Model: `MotivationalQuoteModel` (defined in provider file)

### Data Model

```dart
class Quote {
  final String text;
  final String author;
}

class MotivationalQuoteModel extends ChangeNotifier {
  static final List<Quote> _quotes = [
    Quote(text: "...", author: "Steve Jobs"),
    // ... 49 total quotes
  ];
  
  int _currentQuoteIndex = 0;
  List<int> _favorites = [];
  bool _isInitialized = false;
}
```

### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `isInitialized` | `bool` | Whether model has loaded saved data |
| `currentQuote` | `Quote` | Current displayed quote |
| `totalQuotes` | `int` | Total number of quotes (49) |
| `currentIndex` | `int` | Index of current quote |
| `favorites` | `List<int>` | List of favorite quote indices |
| `isFavorite` | `bool` | Whether current quote is favorited |

### Key Methods

| Method | Description |
|--------|-------------|
| `init()` | Load saved quote index and favorites from SharedPreferences |
| `refresh()` | Trigger UI refresh |
| `getRandomQuote()` | Select random quote based on timestamp |
| `nextQuote()` | Navigate to next quote in sequence |
| `previousQuote()` | Navigate to previous quote in sequence |
| `toggleFavorite()` | Add/remove current quote from favorites |
| `copyQuote()` | Copy current quote text to clipboard |
| `setQuoteIndex(int)` | Set current quote by index |

### SharedPreferences Keys

| Key | Type | Description |
|-----|------|-------------|
| `motivational_quote_last_date` | `String` | Last date quote was shown (YYYY-MM-DD) |
| `motivational_quote_last_index` | `int` | Index of last shown quote |
| `motivational_quote_favorites` | `List<String>` | Favorite quote indices |

### Quote Selection Logic

- Daily quote rotation: Quote index is based on day of month (`DateTime.now().day % 49`)
- If same day, restore saved quote index
- If new day, calculate new daily quote

### Quote Collection

The provider includes 49 inspirational quotes from famous figures including:
- Steve Jobs (3 quotes)
- Albert Einstein (3 quotes)
- Winston Churchill (2 quotes)
- Theodore Roosevelt (2 quotes)
- Buddha, Dalai Lama, Confucius
- Nelson Mandela, Martin Luther King Jr.
- Helen Keller, Anne Frank, Mother Teresa
- Walt Disney, John Lennon, Vincent van Gogh
- C.S. Lewis, Aristotle, Rumi, and many more

## UI Components

### MotivationalQuoteCard

The card displays:
1. **Header**: Quote icon with "Daily Inspiration" title
2. **Favorite indicator**: Heart icon (filled if favorited)
3. **Quote text**: Displayed in italic with quotation marks
4. **Author attribution**: Right-aligned below quote
5. **Navigation controls**: Previous, Random, Next buttons
6. **Copy button**: Copy quote to clipboard
7. **Favorites count**: Shows total favorites if any exist

### Material 3 Components Used

- `Card.filled()` with `Theme.of(context).cardColor` for transparency support
- `IconButton` for navigation and actions
- `Icon(Icons.format_quote)` for quote indicator
- `Icon(Icons.favorite/favorite_border)` for favorite status

## Provider Registration

### In Global.providerList
```dart
Global.providerList = [
  // ... other providers
  providerMotivationalQuote,
];
```

### In MultiProvider (main.dart)
```dart
MultiProvider(
  providers: [
    // ... other models
    ChangeNotifierProvider.value(value: motivationalQuoteModel),
  ],
)
```

## Keywords

The provider registers the following keywords for search:
- quote
- motivational
- inspiration
- inspire
- daily
- wisdom
- motivation

## Testing

Tests verify:
- Provider existence and keywords
- Model initialization
- Quote count (49 quotes)
- Quote properties (text, author)
- Navigation (next/previous/random)
- Index validation (in range)
- Favorites management (add/remove)
- Clipboard copy functionality
- Widget rendering

## Usage Examples

### Navigate to next quote
```dart
motivationalQuoteModel.nextQuote();
```

### Toggle favorite
```dart
await motivationalQuoteModel.toggleFavorite();
```

### Copy quote to clipboard
```dart
motivationalQuoteModel.copyQuote();
```

## Future Enhancements

Potential improvements:
- Add quote categories (success, perseverance, happiness, etc.)
- Share quotes to social media
- Daily notification with new quote
- Quote search functionality
- Custom quote addition
- Export favorites to file