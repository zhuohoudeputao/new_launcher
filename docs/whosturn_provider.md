# WhosTurn Provider

## Overview

The WhosTurn provider is a utility for tracking whose turn it is in multiplayer games (board games, card games, etc.). It provides a simple interface to add players, manage turns, and view turn history.

## Features

- Add/remove players (up to 10)
- Track current turn with visual indicator
- Next/previous turn navigation
- Random player selection
- Turn history tracking (up to 20 entries)
- Persistent storage via SharedPreferences

## Implementation Details

### Location
- Provider: `lib/providers/provider_whosturn.dart`
- Model: `WhosTurnModel` (ChangeNotifier pattern)

### Models

#### PlayerItem
```dart
class PlayerItem {
  final String name;
  final DateTime createdAt;
}
```

#### TurnEntry
```dart
class TurnEntry {
  final int playerIndex;
  final String playerName;
  final DateTime timestamp;
}
```

### Constants
- `maxPlayers`: 10 - Maximum number of players allowed
- `maxHistory`: 20 - Maximum turn history entries

### Key Methods

#### WhosTurnModel
- `init()` - Initialize and load persisted data
- `addPlayer(name)` - Add a new player
- `updatePlayer(index, name)` - Update player name
- `deletePlayer(index)` - Remove a player
- `nextTurn()` - Advance to next player
- `previousTurn()` - Go to previous player
- `randomPlayer()` - Select random player
- `setCurrentPlayer(index)` - Set specific player as current
- `clearHistory()` - Clear turn history
- `clearAllPlayers()` - Remove all players
- `formatTimestamp(timestamp)` - Format time as "just now", "Xm ago", "Xh ago", "Xd ago"

### Keywords
`whosturn turn player game board card next who`

## UI Components

### WhosTurnCard
- Shows current player prominently with styled container
- Displays all players with numbered indicators
- Current player highlighted with primary color
- Next/Previous/Random buttons for navigation
- Toggle history view button
- Clear all players button with confirmation dialog

### AddPlayerDialog
- TextField for player name input
- Shows maximum players limit

### EditPlayerDialog
- Edit player name
- Delete player option

## Material 3 Design
- Uses `Card.filled` for main container
- Uses `Card` with custom color for player items
- Primary container color for current player highlight
- IconButtons with colorScheme styles

## Testing

Tests cover:
- Provider existence in Global.providerList
- WhosTurnModel as ChangeNotifier
- Initial values and initialization
- Player CRUD operations
- Turn navigation (next, previous, random, set)
- History management
- Max limits enforcement
- Persistence via SharedPreferences
- Widget rendering states

## Usage Example

```dart
// Add players
whosTurnModel.addPlayer('Alice');
whosTurnModel.addPlayer('Bob');
whosTurnModel.addPlayer('Charlie');

// Current player is Alice (index 0)
whosTurnModel.getCurrentPlayerName(); // Returns "Alice"

// Next turn
whosTurnModel.nextTurn(); // Now Bob's turn

// Previous turn
whosTurnModel.previousTurn(); // Back to Alice

// Random selection
whosTurnModel.randomPlayer(); // Random player selected

// Set specific player
whosTurnModel.setCurrentPlayer(2); // Now Charlie's turn
```