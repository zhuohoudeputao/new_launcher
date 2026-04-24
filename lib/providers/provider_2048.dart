import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

Game2048Model game2048Model = Game2048Model();

MyProvider provider2048 = MyProvider(
    name: "Game2048",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Game2048',
      keywords: '2048 game puzzle number tile slide merge',
      action: () {
        game2048Model.init();
        Global.infoModel.addInfoWidget(
            "Game2048",
            ChangeNotifierProvider.value(
                value: game2048Model,
                builder: (context, child) => Game2048Card()),
            title: "2048");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  game2048Model.init();
  Global.infoModel.addInfoWidget(
      "Game2048",
      ChangeNotifierProvider.value(
          value: game2048Model,
          builder: (context, child) => Game2048Card()),
      title: "2048");
}

Future<void> _update() async {
  game2048Model.refresh();
}

class Game2048Entry {
  final int score;
  final int highestTile;
  final bool completed;
  final int moves;
  final DateTime timestamp;

  Game2048Entry({
    required this.score,
    required this.highestTile,
    required this.completed,
    required this.moves,
    required this.timestamp,
  });
}

class Game2048Model extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;

  List<List<int>> _grid = [];
  int _score = 0;
  int _highestTile = 0;
  int _moves = 0;
  bool _isGameOver = false;
  bool _hasWon = false;

  int _bestScore = 0;
  int _bestTile = 0;
  int _gamesPlayed = 0;
  int _gamesWon = 0;

  List<Game2048Entry> _history = [];
  static const int maxHistory = 10;

  bool get isInitialized => _isInitialized;
  List<List<int>> get grid => _grid;
  int get score => _score;
  int get highestTile => _highestTile;
  int get moves => _moves;
  bool get isGameOver => _isGameOver;
  bool get hasWon => _hasWon;
  int get bestScore => _bestScore;
  int get bestTile => _bestTile;
  int get gamesPlayed => _gamesPlayed;
  int get gamesWon => _gamesWon;
  List<Game2048Entry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  bool get canContinue => !_isGameOver || _hasWon;

  Future<void> init() async {
    _isInitialized = true;
    newGame();
    Global.loggerModel.info("2048 initialized", source: "Game2048");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void newGame() {
    _grid = List.generate(4, (row) => List.generate(4, (col) => 0));
    _score = 0;
    _highestTile = 0;
    _moves = 0;
    _isGameOver = false;
    _hasWon = false;

    _addRandomTile();
    _addRandomTile();

    Global.loggerModel.info("New 2048 game started", source: "Game2048");
    notifyListeners();
  }

  void _addRandomTile() {
    List<List<int>> emptyCells = [];
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        if (_grid[row][col] == 0) {
          emptyCells.add([row, col]);
        }
      }
    }

    if (emptyCells.isEmpty) return;

    List<int> cell = emptyCells[_random.nextInt(emptyCells.length)];
    int row = cell[0];
    int col = cell[1];

    _grid[row][col] = _random.nextInt(10) < 9 ? 2 : 4;

    if (_grid[row][col] > _highestTile) {
      _highestTile = _grid[row][col];
    }
  }

  void move(Direction direction) {
    if (_isGameOver && !_hasWon) return;

    bool moved = false;

    switch (direction) {
      case Direction.up:
        moved = _moveUp();
        break;
      case Direction.down:
        moved = _moveDown();
        break;
      case Direction.left:
        moved = _moveLeft();
        break;
      case Direction.right:
        moved = _moveRight();
        break;
    }

    if (moved) {
      _moves++;
      _addRandomTile();
      _checkGameState();

      if (_score > _bestScore) {
        _bestScore = _score;
      }
      if (_highestTile > _bestTile) {
        _bestTile = _highestTile;
      }

      notifyListeners();
    }
  }

  bool _moveLeft() {
    bool moved = false;
    for (int row = 0; row < 4; row++) {
      List<int> line = _grid[row].where((val) => val != 0).toList();
      List<int> merged = _mergeLine(line);
      List<int> newLine = merged + List.filled(4 - merged.length, 0);

      for (int col = 0; col < 4; col++) {
        if (_grid[row][col] != newLine[col]) {
          moved = true;
        }
        _grid[row][col] = newLine[col];
      }
    }
    return moved;
  }

  bool _moveRight() {
    bool moved = false;
    for (int row = 0; row < 4; row++) {
      List<int> line = _grid[row].where((val) => val != 0).toList();
      List<int> merged = _mergeLine(line.reversed.toList()).reversed.toList();
      List<int> newLine = List.filled(4 - merged.length, 0) + merged;

      for (int col = 0; col < 4; col++) {
        if (_grid[row][col] != newLine[col]) {
          moved = true;
        }
        _grid[row][col] = newLine[col];
      }
    }
    return moved;
  }

  bool _moveUp() {
    bool moved = false;
    for (int col = 0; col < 4; col++) {
      List<int> line = [];
      for (int row = 0; row < 4; row++) {
        if (_grid[row][col] != 0) {
          line.add(_grid[row][col]);
        }
      }
      List<int> merged = _mergeLine(line);
      List<int> newLine = merged + List.filled(4 - merged.length, 0);

      for (int row = 0; row < 4; row++) {
        if (_grid[row][col] != newLine[row]) {
          moved = true;
        }
        _grid[row][col] = newLine[row];
      }
    }
    return moved;
  }

  bool _moveDown() {
    bool moved = false;
    for (int col = 0; col < 4; col++) {
      List<int> line = [];
      for (int row = 0; row < 4; row++) {
        if (_grid[row][col] != 0) {
          line.add(_grid[row][col]);
        }
      }
      List<int> merged = _mergeLine(line.reversed.toList()).reversed.toList();
      List<int> newLine = List.filled(4 - merged.length, 0) + merged;

      for (int row = 0; row < 4; row++) {
        if (_grid[row][col] != newLine[row]) {
          moved = true;
        }
        _grid[row][col] = newLine[row];
      }
    }
    return moved;
  }

  List<int> _mergeLine(List<int> line) {
    List<int> merged = [];
    int i = 0;

    while (i < line.length) {
      if (i + 1 < line.length && line[i] == line[i + 1]) {
        int newValue = line[i] * 2;
        merged.add(newValue);
        _score += newValue;
        if (newValue > _highestTile) {
          _highestTile = newValue;
        }
        i += 2;
      } else {
        merged.add(line[i]);
        i++;
      }
    }

    return merged;
  }

  void _checkGameState() {
    if (_highestTile >= 2048 && !_hasWon) {
      _hasWon = true;
      Global.loggerModel.info("2048 won! Highest tile: $_highestTile", source: "Game2048");
    }

    bool hasEmpty = false;
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        if (_grid[row][col] == 0) {
          hasEmpty = true;
          break;
        }
      }
    }

    if (!hasEmpty) {
      bool canMerge = false;
      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 4; col++) {
          if (col + 1 < 4 && _grid[row][col] == _grid[row][col + 1]) {
            canMerge = true;
          }
          if (row + 1 < 4 && _grid[row][col] == _grid[row + 1][col]) {
            canMerge = true;
          }
        }
      }

      if (!canMerge) {
        _isGameOver = true;
        _gamesPlayed++;
        if (_hasWon) {
          _gamesWon++;
        }
        _addToHistory();
        Global.loggerModel.info("2048 game over! Score: $_score, Moves: $_moves", source: "Game2048");
      }
    }
  }

  void endGame() {
    if (!_isGameOver) {
      _isGameOver = true;
      _gamesPlayed++;
      if (_hasWon) {
        _gamesWon++;
      }
      _addToHistory();
      Global.loggerModel.info("2048 game ended! Score: $_score, Moves: $_moves", source: "Game2048");
      notifyListeners();
    }
  }

  void _addToHistory() {
    _history.insert(0, Game2048Entry(
      score: _score,
      highestTile: _highestTile,
      completed: _hasWon,
      moves: _moves,
      timestamp: DateTime.now(),
    ));

    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void resetStats() {
    _bestScore = 0;
    _bestTile = 0;
    _gamesPlayed = 0;
    _gamesWon = 0;
    newGame();
    Global.loggerModel.info("2048 stats reset", source: "Game2048");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("2048 history cleared", source: "Game2048");
    notifyListeners();
  }

  Color getTileColor(int value, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (value) {
      case 0:
        return colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      case 2:
        return Colors.grey.shade200;
      case 4:
        return Colors.grey.shade300;
      case 8:
        return Colors.orange.shade300;
      case 16:
        return Colors.orange.shade400;
      case 32:
        return Colors.orange.shade500;
      case 64:
        return Colors.deepOrange.shade400;
      case 128:
        return Colors.yellow.shade400;
      case 256:
        return Colors.yellow.shade500;
      case 512:
        return Colors.yellow.shade600;
      case 1024:
        return Colors.amber.shade500;
      case 2048:
        return Colors.amber.shade600;
      default:
        if (value > 2048) {
          return Colors.purple.shade400;
        }
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color getTileTextColor(int value) {
    if (value == 0) return Colors.transparent;
    if (value <= 4) return Colors.grey.shade700;
    return Colors.white;
  }

  String formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

enum Direction { up, down, left, right }

class Game2048Card extends StatefulWidget {
  @override
  State<Game2048Card> createState() => _Game2048CardState();
}

class _Game2048CardState extends State<Game2048Card> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game2048Model>();

    if (!game.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.grid_4x4, size: 24),
              SizedBox(width: 12),
              Text("2048: Loading..."),
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
                    Icon(Icons.grid_4x4, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "2048",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (game.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.grid_4x4 : Icons.history, size: 18),
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

  Widget _buildGameView(BuildContext context, Game2048Model game) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoRow(context, game),
        SizedBox(height: 12),
        _buildGrid(context, game),
        if (game.isGameOver) ...[
          SizedBox(height: 12),
          Text(
            game.hasWon ? "You Won!" : "Game Over",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: game.hasWon ? Colors.green : Colors.red,
            ),
          ),
        ],
        SizedBox(height: 12),
        _buildControls(context, game),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, Game2048Model game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoItem(context, "Score", "${game.score}"),
        _buildInfoItem(context, "Best", "${game.bestScore}"),
        _buildInfoItem(context, "Moves", "${game.moves}"),
        _buildInfoItem(context, "Tile", "${game.highestTile}"),
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

  Widget _buildGrid(BuildContext context, Game2048Model game) {
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
            int row = index ~/ 4;
            int col = index % 4;
            int value = game.grid[row][col];

            return Container(
              decoration: BoxDecoration(
                color: game.getTileColor(value, context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  value > 0 ? "$value" : "",
                  style: TextStyle(
                    fontSize: value >= 1000 ? 14 : value >= 100 ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: game.getTileTextColor(value),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, Game2048Model game) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => game.move(Direction.up),
              icon: Icon(Icons.arrow_upward),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => game.move(Direction.left),
              icon: Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
              ),
            ),
            SizedBox(width: 24),
            IconButton(
              onPressed: () => game.move(Direction.right),
              icon: Icon(Icons.arrow_forward),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => game.move(Direction.down),
              icon: Icon(Icons.arrow_downward),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: game.newGame,
          icon: Icon(Icons.refresh, size: 16),
          label: Text("New Game"),
          style: ElevatedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(BuildContext context, Game2048Model game) {
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

  Widget _buildHistoryEntry(BuildContext context, Game2048Model game, Game2048Entry entry) {
    final timeAgo = game.formatTimeAgo(entry.timestamp);

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
            "${entry.score}",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8),
          Text(
            "Tile: ${entry.highestTile}",
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
          SizedBox(width: 8),
          Text(
            "${entry.moves} moves",
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
              context.read<Game2048Model>().resetStats();
              context.read<Game2048Model>().clearHistory();
              Navigator.pop(context);
            },
            child: Text("Reset"),
          ),
        ],
      ),
    );
  }
}