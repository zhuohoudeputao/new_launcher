import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

MemoryGameModel memoryGameModel = MemoryGameModel();

MyProvider providerMemoryGame = MyProvider(
    name: "MemoryGame",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'MemoryGame',
      keywords: 'memory game cards match flip pairs puzzle remember',
      action: () {
        memoryGameModel.init();
        Global.infoModel.addInfoWidget(
            "MemoryGame",
            ChangeNotifierProvider.value(
                value: memoryGameModel,
                builder: (context, child) => MemoryGameCard()),
            title: "MemoryGame");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  memoryGameModel.init();
  Global.infoModel.addInfoWidget(
      "MemoryGame",
      ChangeNotifierProvider.value(
          value: memoryGameModel,
          builder: (context, child) => MemoryGameCard()),
      title: "MemoryGame");
}

Future<void> _update() async {
  memoryGameModel.refresh();
}

enum MemoryCardState { hidden, flipped, matched }

enum MemoryGameSize { small4x4, large6x6 }

class MemoryCard {
  final int id;
  final String symbol;
  MemoryCardState state;
  int pairId;

  MemoryCard({
    required this.id,
    required this.symbol,
    this.state = MemoryCardState.hidden,
    required this.pairId,
  });
}

class MemoryGameEntry {
  final int moves;
  final MemoryGameSize size;
  final DateTime timestamp;

  MemoryGameEntry({
    required this.moves,
    required this.size,
    required this.timestamp,
  });
}

class MemoryGameModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;

  List<MemoryCard> _cards = [];
  List<int> _flippedCardIds = [];
  int _moves = 0;
  int _matchedPairs = 0;
  MemoryGameSize _gameSize = MemoryGameSize.small4x4;
  bool _isGameOver = false;
  bool _isProcessing = false;

  int _bestMoves4x4 = 0;
  int _bestMoves6x6 = 0;
  int _gamesPlayed = 0;

  List<MemoryGameEntry> _history = [];
  static const int maxHistory = 10;

  static const List<String> _symbols4x4 = [
    '🌟', '🎈', '🌈', '🍀',
    '🔥', '💎', '🎵', '🌸',
  ];

  static const List<String> _symbols6x6 = [
    '🌟', '🎈', '🌈', '🍀', '🔥', '💎',
    '🎵', '🌸', '❤️', '🌙', '⚡', '🌺',
    '🎯', '🏆', '🍀', '🎭', '🎨', '🎪',
  ];

  bool get isInitialized => _isInitialized;
  List<MemoryCard> get cards => _cards;
  int get moves => _moves;
  int get matchedPairs => _matchedPairs;
  MemoryGameSize get gameSize => _gameSize;
  bool get isGameOver => _isGameOver;
  bool get isProcessing => _isProcessing;
  int get totalPairs => _gameSize == MemoryGameSize.small4x4 ? 8 : 18;
  int get bestMoves => _gameSize == MemoryGameSize.small4x4 ? _bestMoves4x4 : _bestMoves6x6;
  int get gamesPlayed => _gamesPlayed;
  List<MemoryGameEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  int get gridSize => _gameSize == MemoryGameSize.small4x4 ? 4 : 6;

  double getProgress() {
    if (totalPairs == 0) return 0;
    return (_matchedPairs * 100) / totalPairs;
  }

  String getSizeLabel(MemoryGameSize size) {
    switch (size) {
      case MemoryGameSize.small4x4:
        return "4x4";
      case MemoryGameSize.large6x6:
        return "6x6";
    }
  }

  Future<void> init() async {
    _isInitialized = true;
    await _loadFromPrefs();
    newGame();
    Global.loggerModel.info("MemoryGame initialized", source: "MemoryGame");
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bestMoves4x4 = prefs.getInt('memoryGame_bestMoves4x4') ?? 0;
      _bestMoves6x6 = prefs.getInt('memoryGame_bestMoves6x6') ?? 0;
      _gamesPlayed = prefs.getInt('memoryGame_gamesPlayed') ?? 0;

      final historyJson = prefs.getStringList('memoryGame_history') ?? [];
      _history = historyJson.map((json) {
        final parts = json.split('|');
        return MemoryGameEntry(
          moves: int.parse(parts[0]),
          size: parts[1] == '4x4' ? MemoryGameSize.small4x4 : MemoryGameSize.large6x6,
          timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])),
        );
      }).toList();
    } catch (e) {
      Global.loggerModel.error("Failed to load MemoryGame data: $e", source: "MemoryGame");
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('memoryGame_bestMoves4x4', _bestMoves4x4);
      prefs.setInt('memoryGame_bestMoves6x6', _bestMoves6x6);
      prefs.setInt('memoryGame_gamesPlayed', _gamesPlayed);

      final historyJson = _history.map((entry) =>
        '${entry.moves}|${getSizeLabel(entry.size)}|${entry.timestamp.millisecondsSinceEpoch}'
      ).toList();
      prefs.setStringList('memoryGame_history', historyJson);
    } catch (e) {
      Global.loggerModel.error("Failed to save MemoryGame data: $e", source: "MemoryGame");
    }
  }

  void refresh() {
    notifyListeners();
  }

  void setSize(MemoryGameSize size) {
    _gameSize = size;
    newGame();
  }

  void newGame() {
    final symbols = _gameSize == MemoryGameSize.small4x4 ? _symbols4x4 : _symbols6x6;
    final pairsCount = symbols.length;

    _cards = [];
    for (int i = 0; i < pairsCount; i++) {
      _cards.add(MemoryCard(id: i * 2, symbol: symbols[i], pairId: i));
      _cards.add(MemoryCard(id: i * 2 + 1, symbol: symbols[i], pairId: i));
    }

    _shuffleCards();
    _flippedCardIds = [];
    _moves = 0;
    _matchedPairs = 0;
    _isGameOver = false;
    _isProcessing = false;

    Global.loggerModel.info("New MemoryGame started with ${getSizeLabel(_gameSize)} grid", source: "MemoryGame");
    notifyListeners();
  }

  void _shuffleCards() {
    for (int i = _cards.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = temp;
    }
  }

  void flipCard(int cardId) {
    if (_isProcessing || _isGameOver) return;

    final cardIndex = _cards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = _cards[cardIndex];
    if (card.state != MemoryCardState.hidden) return;

    card.state = MemoryCardState.flipped;
    _flippedCardIds.add(cardId);
    Global.loggerModel.info("Card $cardId flipped", source: "MemoryGame");

    if (_flippedCardIds.length == 2) {
      _moves++;
      _isProcessing = true;
      notifyListeners();

      _checkMatch();
    } else {
      notifyListeners();
    }
  }

  void _checkMatch() {
    final card1 = _cards.firstWhere((c) => c.id == _flippedCardIds[0]);
    final card2 = _cards.firstWhere((c) => c.id == _flippedCardIds[1]);

    if (card1.pairId == card2.pairId) {
      card1.state = MemoryCardState.matched;
      card2.state = MemoryCardState.matched;
      _matchedPairs++;
      Global.loggerModel.info("Match found! Pair ${card1.pairId}", source: "MemoryGame");

      if (_matchedPairs == totalPairs) {
        _isGameOver = true;
        _gamesPlayed++;
        _updateBestMoves();
        _addToHistory();
        _saveToPrefs();
        Global.loggerModel.info("Game completed in $moves moves!", source: "MemoryGame");
      }

      _flippedCardIds = [];
      _isProcessing = false;
      notifyListeners();
    } else {
      Future.delayed(Duration(milliseconds: 500), () {
        card1.state = MemoryCardState.hidden;
        card2.state = MemoryCardState.hidden;
        _flippedCardIds = [];
        _isProcessing = false;
        Global.loggerModel.info("No match, cards hidden again", source: "MemoryGame");
        notifyListeners();
      });
    }
  }

  void _updateBestMoves() {
    if (_gameSize == MemoryGameSize.small4x4) {
      if (_bestMoves4x4 == 0 || _moves < _bestMoves4x4) {
        _bestMoves4x4 = _moves;
        Global.loggerModel.info("New best score for 4x4: $_moves", source: "MemoryGame");
      }
    } else {
      if (_bestMoves6x6 == 0 || _moves < _bestMoves6x6) {
        _bestMoves6x6 = _moves;
        Global.loggerModel.info("New best score for 6x6: $_moves", source: "MemoryGame");
      }
    }
  }

  void _addToHistory() {
    _history.insert(0, MemoryGameEntry(
      moves: _moves,
      size: _gameSize,
      timestamp: DateTime.now(),
    ));

    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void clearHistory() {
    _history.clear();
    _gamesPlayed = 0;
    _bestMoves4x4 = 0;
    _bestMoves6x6 = 0;
    _saveToPrefs();
    Global.loggerModel.info("MemoryGame history cleared", source: "MemoryGame");
    notifyListeners();
  }

  Color getCardColor(MemoryCardState state, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (state) {
      case MemoryCardState.hidden:
        return colorScheme.primaryContainer;
      case MemoryCardState.flipped:
        return colorScheme.secondaryContainer;
      case MemoryCardState.matched:
        return colorScheme.tertiaryContainer;
    }
  }

  Color getCardBorderColor(MemoryCardState state, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (state) {
      case MemoryCardState.hidden:
        return colorScheme.primary;
      case MemoryCardState.flipped:
        return colorScheme.secondary;
      case MemoryCardState.matched:
        return colorScheme.tertiary;
    }
  }
}

class MemoryGameCard extends StatefulWidget {
  @override
  State<MemoryGameCard> createState() => _MemoryGameCardState();
}

class _MemoryGameCardState extends State<MemoryGameCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<MemoryGameModel>();

    if (!game.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.extension, size: 24),
              SizedBox(width: 12),
              Text("MemoryGame: Loading..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.extension, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Memory Game",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (game.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.extension : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Game" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (game.hasHistory || game.gamesPlayed > 0)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearConfirmation(context),
                        tooltip: "Clear history",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_showHistory)
              _buildHistoryView(context, game)
            else
              _buildGameView(context, game),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView(BuildContext context, MemoryGameModel game) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSizeSelector(context, game),
        SizedBox(height: 12),
        _buildGameGrid(context, game),
        if (game.isGameOver) ...[
          SizedBox(height: 12),
          Text(
            "Completed in ${game.moves} moves!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
        SizedBox(height: 12),
        _buildStatsRow(context, game),
        if (game.isGameOver)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: ElevatedButton.icon(
              onPressed: game.newGame,
              icon: Icon(Icons.refresh, size: 18),
              label: Text("New Game"),
            ),
          ),
      ],
    );
  }

  Widget _buildSizeSelector(BuildContext context, MemoryGameModel game) {
    return SegmentedButton<MemoryGameSize>(
      segments: [
        ButtonSegment(
          value: MemoryGameSize.small4x4,
          label: Text("4x4"),
          icon: Icon(Icons.grid_view, size: 16),
        ),
        ButtonSegment(
          value: MemoryGameSize.large6x6,
          label: Text("6x6"),
          icon: Icon(Icons.apps, size: 16),
        ),
      ],
      selected: {game.gameSize},
      onSelectionChanged: (Set<MemoryGameSize> newSelection) {
        game.setSize(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildGameGrid(BuildContext context, MemoryGameModel game) {
    final gridSize = game.gridSize;
    final cardSize = gridSize == 4 ? 40.0 : 32.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxWidth: gridSize == 4 ? 180 : 210,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: game.cards.length,
        itemBuilder: (context, index) {
          final card = game.cards[index];
          final isHidden = card.state == MemoryCardState.hidden;
          final isMatched = card.state == MemoryCardState.matched;

          return GestureDetector(
            onTap: isHidden && !game.isProcessing ? () => game.flipCard(card.id) : null,
            child: Container(
              width: cardSize,
              height: cardSize,
              decoration: BoxDecoration(
                color: game.getCardColor(card.state, context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: game.getCardBorderColor(card.state, context),
                  width: isMatched ? 2 : 1,
                ),
              ),
              child: Center(
                child: isHidden
                    ? Icon(Icons.help_outline, size: cardSize * 0.5, color: colorScheme.onPrimaryContainer)
                    : Text(
                        card.symbol,
                        style: TextStyle(fontSize: cardSize * 0.6),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, MemoryGameModel game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, "Moves", game.moves.toString(), Theme.of(context).colorScheme.primary),
        _buildStatItem(context, "Pairs", "${game.matchedPairs}/${game.totalPairs}", Theme.of(context).colorScheme.secondary),
        _buildStatItem(context, "Best", game.bestMoves == 0 ? "-" : game.bestMoves.toString(), Theme.of(context).colorScheme.tertiary),
        _buildStatItem(context, "Games", game.gamesPlayed.toString(), Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildHistoryView(BuildContext context, MemoryGameModel game) {
    if (!game.hasHistory) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text("No games played yet", style: TextStyle(fontSize: 12)),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: game.history.length,
        itemBuilder: (context, index) {
          final entry = game.history[index];
          return _buildHistoryEntry(context, game, entry);
        },
      ),
    );
  }

  Widget _buildHistoryEntry(BuildContext context, MemoryGameModel game, MemoryGameEntry entry) {
    final timeAgo = _formatTimeAgo(entry.timestamp);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.emoji_events, size: 16, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 8),
          Text(
            "${entry.moves} moves",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8),
          Text(
            game.getSizeLabel(entry.size),
            style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.secondary),
          ),
          SizedBox(width: 8),
          Text(timeAgo, style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all game history and reset best scores?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<MemoryGameModel>().clearHistory();
              Navigator.pop(context);
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }
}