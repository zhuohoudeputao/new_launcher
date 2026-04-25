import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

SlidingPuzzleModel slidingPuzzleModel = SlidingPuzzleModel();

MyProvider providerSlidingPuzzle = MyProvider(
    name: "SlidingPuzzle",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'SlidingPuzzle',
      keywords: 'sliding puzzle 15 puzzle slide tile game arrange',
      action: () {
        slidingPuzzleModel.init();
        Global.infoModel.addInfoWidget(
            "SlidingPuzzle",
            ChangeNotifierProvider.value(
                value: slidingPuzzleModel,
                builder: (context, child) => SlidingPuzzleCard()),
            title: "Sliding Puzzle");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  slidingPuzzleModel.init();
  Global.infoModel.addInfoWidget(
      "SlidingPuzzle",
      ChangeNotifierProvider.value(
          value: slidingPuzzleModel,
          builder: (context, child) => SlidingPuzzleCard()),
      title: "Sliding Puzzle");
}

Future<void> _update() async {
  slidingPuzzleModel.refresh();
}

class SlidingPuzzleEntry {
  final int moves;
  final bool completed;
  final int difficulty;
  final DateTime timestamp;

  SlidingPuzzleEntry({
    required this.moves,
    required this.completed,
    required this.difficulty,
    required this.timestamp,
  });
}

class SlidingPuzzleModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;

  List<int> _tiles = [];
  int _emptyIndex = 15;
  int _moves = 0;
  bool _isSolved = false;
  int _difficulty = 1;

  int _bestMoves = 0;
  int _gamesPlayed = 0;
  int _gamesWon = 0;

  List<SlidingPuzzleEntry> _history = [];
  static const int maxHistory = 10;

  bool get isInitialized => _isInitialized;
  List<int> get tiles => _tiles;
  int get emptyIndex => _emptyIndex;
  int get moves => _moves;
  bool get isSolved => _isSolved;
  int get difficulty => _difficulty;
  int get bestMoves => _bestMoves;
  int get gamesPlayed => _gamesPlayed;
  int get gamesWon => _gamesWon;
  List<SlidingPuzzleEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  double get winRate => _gamesPlayed > 0 ? _gamesWon / _gamesPlayed * 100 : 0;

  Future<void> init() async {
    _isInitialized = true;
    newGame();
    Global.loggerModel.info("Sliding Puzzle initialized", source: "SlidingPuzzle");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setDifficulty(int level) {
    _difficulty = level;
    newGame();
    notifyListeners();
  }

  void newGame() {
    _tiles = List.generate(16, (i) => i == 15 ? 0 : i + 1);
    _emptyIndex = 15;
    _moves = 0;
    _isSolved = false;
    _shuffleTiles();
    Global.loggerModel.info("New Sliding Puzzle game started (difficulty: $_difficulty)", source: "SlidingPuzzle");
    notifyListeners();
  }

  void _shuffleTiles() {
    int shuffleMoves = _difficulty * 50;
    
    for (int i = 0; i < shuffleMoves; i++) {
      List<int> possibleMoves = _getPossibleMoves();
      if (possibleMoves.isNotEmpty) {
        int randomMove = possibleMoves[_random.nextInt(possibleMoves.length)];
        _swapTiles(randomMove, _emptyIndex);
        _emptyIndex = randomMove;
      }
    }
    
    while (!_isSolvable()) {
      int swap1 = _tiles.indexOf(1);
      int swap2 = _tiles.indexOf(2);
      _swapTiles(swap1, swap2);
    }
  }

  List<int> _getPossibleMoves() {
    List<int> moves = [];
    int row = _emptyIndex ~/ 4;
    int col = _emptyIndex % 4;

    if (row > 0) moves.add(_emptyIndex - 4);
    if (row < 3) moves.add(_emptyIndex + 4);
    if (col > 0) moves.add(_emptyIndex - 1);
    if (col < 3) moves.add(_emptyIndex + 1);

    return moves;
  }

  bool _isSolvable() {
    int inversions = 0;
    for (int i = 0; i < 15; i++) {
      for (int j = i + 1; j < 15; j++) {
        if (_tiles[i] > _tiles[j] && _tiles[i] != 0 && _tiles[j] != 0) {
          inversions++;
        }
      }
    }
    
    int emptyRow = _emptyIndex ~/ 4;
    return (inversions + emptyRow) % 2 == 0;
  }

  bool canMove(int index) {
    int rowDiff = (index ~/ 4) - (_emptyIndex ~/ 4);
    int colDiff = (index % 4) - (_emptyIndex % 4);
    
    return (rowDiff.abs() + colDiff.abs()) == 1;
  }

  void moveTile(int index) {
    if (_isSolved || !canMove(index)) return;

    _swapTiles(index, _emptyIndex);
    _emptyIndex = index;
    _moves++;

    _checkSolved();

    if (_isSolved) {
      _gamesPlayed++;
      _gamesWon++;
      if (_bestMoves == 0 || _moves < _bestMoves) {
        _bestMoves = _moves;
      }
      _addToHistory();
      Global.loggerModel.info("Sliding Puzzle solved! Moves: $_moves", source: "SlidingPuzzle");
    }

    notifyListeners();
  }

  void _swapTiles(int i1, int i2) {
    int temp = _tiles[i1];
    _tiles[i1] = _tiles[i2];
    _tiles[i2] = temp;
  }

  void _checkSolved() {
    for (int i = 0; i < 15; i++) {
      if (_tiles[i] != i + 1) {
        _isSolved = false;
        return;
      }
    }
    _isSolved = _tiles[15] == 0;
  }

  void giveUp() {
    if (!_isSolved) {
      _gamesPlayed++;
      _addToHistory();
      Global.loggerModel.info("Sliding Puzzle game given up. Moves: $_moves", source: "SlidingPuzzle");
      notifyListeners();
    }
  }

  void _addToHistory() {
    _history.insert(0, SlidingPuzzleEntry(
      moves: _moves,
      completed: _isSolved,
      difficulty: _difficulty,
      timestamp: DateTime.now(),
    ));

    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void resetStats() {
    _bestMoves = 0;
    _gamesPlayed = 0;
    _gamesWon = 0;
    newGame();
    Global.loggerModel.info("Sliding Puzzle stats reset", source: "SlidingPuzzle");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("Sliding Puzzle history cleared", source: "SlidingPuzzle");
    notifyListeners();
  }

  String formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  String getDifficultyName() {
    switch (_difficulty) {
      case 1: return "Easy";
      case 2: return "Medium";
      case 3: return "Hard";
      default: return "Easy";
    }
  }
}

class SlidingPuzzleCard extends StatefulWidget {
  @override
  State<SlidingPuzzleCard> createState() => _SlidingPuzzleCardState();
}

class _SlidingPuzzleCardState extends State<SlidingPuzzleCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<SlidingPuzzleModel>();

    if (!game.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.extension, size: 24),
              SizedBox(width: 12),
              Text("Sliding Puzzle: Loading..."),
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
                      "Sliding Puzzle",
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
                        icon: Icon(Icons.refresh, size: 18),
                        onPressed: () => _showResetConfirmation(context),
                        tooltip: "Reset stats",
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

  Widget _buildGameView(BuildContext context, SlidingPuzzleModel game) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoRow(context, game),
        SizedBox(height: 8),
        _buildDifficultySelector(context, game),
        SizedBox(height: 12),
        _buildGrid(context, game),
        if (game.isSolved) ...[
          SizedBox(height: 12),
          Text(
            "Solved!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
        SizedBox(height: 12),
        _buildControls(context, game),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, SlidingPuzzleModel game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoItem(context, "Moves", "${game.moves}"),
        _buildInfoItem(context, "Best", "${game.bestMoves}"),
        _buildInfoItem(context, "Won", "${game.gamesWon}/${game.gamesPlayed}"),
        _buildInfoItem(context, "Rate", "${game.winRate.toStringAsFixed(0)}%"),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildDifficultySelector(BuildContext context, SlidingPuzzleModel game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Difficulty: ", style: TextStyle(fontSize: 12)),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 1, label: Text("Easy")),
            ButtonSegment(value: 2, label: Text("Medium")),
            ButtonSegment(value: 3, label: Text("Hard")),
          ],
          selected: {game.difficulty},
          onSelectionChanged: (Set<int> newSelection) {
            game.setDifficulty(newSelection.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, SlidingPuzzleModel game) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 180,
      height: 180,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            int tile = game.tiles[index];
            bool isMovable = game.canMove(index) && !game.isSolved;

            return GestureDetector(
              onTap: isMovable ? () => game.moveTile(index) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: tile == 0
                      ? Colors.transparent
                      : isMovable
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: tile == 0
                      ? null
                      : Border.all(
                          color: isMovable
                              ? colorScheme.primary.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 2,
                        ),
                ),
                child: Center(
                  child: tile == 0
                      ? null
                      : Text(
                          "$tile",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isMovable
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, SlidingPuzzleModel game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: game.newGame,
          icon: Icon(Icons.refresh, size: 16),
          label: Text("New Game"),
          style: ElevatedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (!game.isSolved && game.moves > 0) ...[
          SizedBox(width: 8),
          TextButton(
            onPressed: () => _showGiveUpConfirmation(context, game),
            child: Text("Give Up"),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryView(BuildContext context, SlidingPuzzleModel game) {
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

  Widget _buildHistoryEntry(BuildContext context, SlidingPuzzleModel game, SlidingPuzzleEntry entry) {
    final timeAgo = game.formatTimeAgo(entry.timestamp);
    final difficultyNames = {1: "Easy", 2: "Medium", 3: "Hard"};

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            entry.completed ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: entry.completed ? Colors.green : Colors.red,
          ),
          SizedBox(width: 8),
          Text(
            "${entry.moves} moves",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8),
          Text(
            difficultyNames[entry.difficulty] ?? "Easy",
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
          SizedBox(width: 8),
          Text(timeAgo, style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reset Stats"),
        content: Text("Reset all game statistics and clear history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<SlidingPuzzleModel>().resetStats();
              context.read<SlidingPuzzleModel>().clearHistory();
              Navigator.pop(context);
            },
            child: Text("Reset"),
          ),
        ],
      ),
    );
  }

  void _showGiveUpConfirmation(BuildContext context, SlidingPuzzleModel game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Give Up"),
        content: Text("Are you sure you want to give up this puzzle?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              game.giveUp();
              Navigator.pop(context);
            },
            child: Text("Give Up"),
          ),
        ],
      ),
    );
  }
}