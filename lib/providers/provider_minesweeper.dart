import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

MinesweeperModel minesweeperModel = MinesweeperModel();

MyProvider providerMinesweeper = MyProvider(
    name: "Minesweeper",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Minesweeper',
      keywords: 'minesweeper mine bomb puzzle grid reveal flag game',
      action: () {
        minesweeperModel.init();
        Global.infoModel.addInfoWidget(
            "Minesweeper",
            ChangeNotifierProvider.value(
                value: minesweeperModel,
                builder: (context, child) => MinesweeperCard()),
            title: "Minesweeper");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  minesweeperModel.init();
  Global.infoModel.addInfoWidget(
      "Minesweeper",
      ChangeNotifierProvider.value(
          value: minesweeperModel,
          builder: (context, child) => MinesweeperCard()),
      title: "Minesweeper");
}

Future<void> _update() async {
  minesweeperModel.refresh();
}

enum MinesweeperDifficulty { easy, medium, hard }
enum MinesweeperCellState { hidden, revealed, flagged, exploded }

class MinesweeperCell {
  final int row;
  final int col;
  bool isMine;
  int adjacentMines;
  MinesweeperCellState state;

  MinesweeperCell({
    required this.row,
    required this.col,
    this.isMine = false,
    this.adjacentMines = 0,
    this.state = MinesweeperCellState.hidden,
  });
}

class MinesweeperGameEntry {
  final MinesweeperDifficulty difficulty;
  final bool completed;
  final int timeSeconds;
  final int revealedCount;
  final DateTime timestamp;

  MinesweeperGameEntry({
    required this.difficulty,
    required this.completed,
    required this.timeSeconds,
    required this.revealedCount,
    required this.timestamp,
  });
}

class MinesweeperModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;

  List<List<MinesweeperCell>> _grid = [];
  int _gridRows = 8;
  int _gridCols = 8;
  int _totalMines = 10;
  MinesweeperDifficulty _difficulty = MinesweeperDifficulty.easy;

  int _revealedCount = 0;
  int _flaggedCount = 0;
  bool _isGameOver = false;
  bool _isWin = false;
  bool _firstClick = true;

  int _gamesPlayed = 0;
  int _gamesWon = 0;
  int _bestTimeEasy = 0;
  int _bestTimeMedium = 0;
  int _bestTimeHard = 0;

  List<MinesweeperGameEntry> _history = [];
  static const int maxHistory = 10;

  DateTime? _startTime;
  int _elapsedSeconds = 0;

  bool get isInitialized => _isInitialized;
  List<List<MinesweeperCell>> get grid => _grid;
  int get gridRows => _gridRows;
  int get gridCols => _gridCols;
  int get totalMines => _totalMines;
  MinesweeperDifficulty get difficulty => _difficulty;
  int get revealedCount => _revealedCount;
  int get flaggedCount => _flaggedCount;
  bool get isGameOver => _isGameOver;
  bool get isWin => _isWin;
  int get gamesPlayed => _gamesPlayed;
  int get gamesWon => _gamesWon;
  int get elapsedSeconds => _elapsedSeconds;
  List<MinesweeperGameEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  int get remainingFlags => _totalMines - _flaggedCount;
  int get totalCells => _gridRows * _gridCols;
  int get safeCells => totalCells - _totalMines;

  Future<void> init() async {
    _isInitialized = true;
    await _loadFromPrefs();
    newGame();
    Global.loggerModel.info("Minesweeper initialized", source: "Minesweeper");
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _gamesPlayed = prefs.getInt('minesweeper_gamesPlayed') ?? 0;
      _gamesWon = prefs.getInt('minesweeper_gamesWon') ?? 0;
      _bestTimeEasy = prefs.getInt('minesweeper_bestTimeEasy') ?? 0;
      _bestTimeMedium = prefs.getInt('minesweeper_bestTimeMedium') ?? 0;
      _bestTimeHard = prefs.getInt('minesweeper_bestTimeHard') ?? 0;

      final historyJson = prefs.getStringList('minesweeper_history') ?? [];
      _history = historyJson.map((json) {
        final parts = json.split('|');
        return MinesweeperGameEntry(
          difficulty: _parseDifficulty(parts[0]),
          completed: parts[1] == 'true',
          timeSeconds: int.parse(parts[2]),
          revealedCount: int.parse(parts[3]),
          timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[4])),
        );
      }).toList();
    } catch (e) {
      Global.loggerModel.error("Failed to load Minesweeper data: $e", source: "Minesweeper");
    }
  }

  MinesweeperDifficulty _parseDifficulty(String s) {
    switch (s) {
      case 'easy': return MinesweeperDifficulty.easy;
      case 'medium': return MinesweeperDifficulty.medium;
      case 'hard': return MinesweeperDifficulty.hard;
      default: return MinesweeperDifficulty.easy;
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('minesweeper_gamesPlayed', _gamesPlayed);
      prefs.setInt('minesweeper_gamesWon', _gamesWon);
      prefs.setInt('minesweeper_bestTimeEasy', _bestTimeEasy);
      prefs.setInt('minesweeper_bestTimeMedium', _bestTimeMedium);
      prefs.setInt('minesweeper_bestTimeHard', _bestTimeHard);

      final historyJson = _history.map((entry) =>
        '${getDifficultyText(entry.difficulty)}|${entry.completed}|${entry.timeSeconds}|${entry.revealedCount}|${entry.timestamp.millisecondsSinceEpoch}'
      ).toList();
      prefs.setStringList('minesweeper_history', historyJson);
    } catch (e) {
      Global.loggerModel.error("Failed to save Minesweeper data: $e", source: "Minesweeper");
    }
  }

  void refresh() {
    notifyListeners();
  }

  void setDifficulty(MinesweeperDifficulty difficulty) {
    _difficulty = difficulty;
    newGame();
  }

  void newGame() {
    switch (_difficulty) {
      case MinesweeperDifficulty.easy:
        _gridRows = 8;
        _gridCols = 8;
        _totalMines = 10;
        break;
      case MinesweeperDifficulty.medium:
        _gridRows = 10;
        _gridCols = 10;
        _totalMines = 20;
        break;
      case MinesweeperDifficulty.hard:
        _gridRows = 12;
        _gridCols = 12;
        _totalMines = 35;
        break;
    }

    _grid = List.generate(_gridRows, (row) =>
      List.generate(_gridCols, (col) =>
        MinesweeperCell(row: row, col: col)));

    _revealedCount = 0;
    _flaggedCount = 0;
    _isGameOver = false;
    _isWin = false;
    _firstClick = true;
    _startTime = null;
    _elapsedSeconds = 0;

    Global.loggerModel.info("New Minesweeper game started (${getDifficultyText(_difficulty)})", source: "Minesweeper");
    notifyListeners();
  }

  void _placeMines(int excludeRow, int excludeCol) {
    int minesPlaced = 0;
    while (minesPlaced < _totalMines) {
      int row = _random.nextInt(_gridRows);
      int col = _random.nextInt(_gridCols);

      if ((row == excludeRow && col == excludeCol) ||
          (row == excludeRow - 1 && col == excludeCol) ||
          (row == excludeRow + 1 && col == excludeCol) ||
          (row == excludeRow && col == excludeCol - 1) ||
          (row == excludeRow && col == excludeCol + 1) ||
          (row == excludeRow - 1 && col == excludeCol - 1) ||
          (row == excludeRow - 1 && col == excludeCol + 1) ||
          (row == excludeRow + 1 && col == excludeCol - 1) ||
          (row == excludeRow + 1 && col == excludeCol + 1)) {
        continue;
      }

      if (!_grid[row][col].isMine) {
        _grid[row][col].isMine = true;
        minesPlaced++;
      }
    }

    _calculateAdjacentMines();
  }

  void _calculateAdjacentMines() {
    for (int row = 0; row < _gridRows; row++) {
      for (int col = 0; col < _gridCols; col++) {
        if (!_grid[row][col].isMine) {
          _grid[row][col].adjacentMines = _countAdjacentMines(row, col);
        }
      }
    }
  }

  int _countAdjacentMines(int row, int col) {
    int count = 0;
    for (int r = row - 1; r <= row + 1; r++) {
      for (int c = col - 1; c <= col + 1; c++) {
        if (r >= 0 && r < _gridRows && c >= 0 && c < _gridCols) {
          if (_grid[r][c].isMine) count++;
        }
      }
    }
    return count;
  }

  void revealCell(int row, int col) {
    if (_isGameOver) return;
    if (_grid[row][col].state == MinesweeperCellState.revealed) return;
    if (_grid[row][col].state == MinesweeperCellState.flagged) return;

    if (_firstClick) {
      _firstClick = false;
      _startTime = DateTime.now();
      _placeMines(row, col);
    }

    if (_grid[row][col].isMine) {
      _grid[row][col].state = MinesweeperCellState.exploded;
      _isGameOver = true;
      _isWin = false;
      _elapsedSeconds = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;
      _gamesPlayed++;
      _revealAllMines();
      _addToHistory(false);
      _saveToPrefs();
      Global.loggerModel.info("Mine hit at ($row, $col)! Game over.", source: "Minesweeper");
      notifyListeners();
      return;
    }

    _revealCellRecursive(row, col);

    if (_revealedCount == safeCells) {
      _isGameOver = true;
      _isWin = true;
      _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      _gamesPlayed++;
      _gamesWon++;
      _updateBestTime();
      _addToHistory(true);
      _saveToPrefs();
      Global.loggerModel.info("Minesweeper completed in ${_elapsedSeconds}s!", source: "Minesweeper");
    }

    notifyListeners();
  }

  void _revealCellRecursive(int row, int col) {
    if (row < 0 || row >= _gridRows || col < 0 || col >= _gridCols) return;
    if (_grid[row][col].state != MinesweeperCellState.hidden) return;
    if (_grid[row][col].isMine) return;

    _grid[row][col].state = MinesweeperCellState.revealed;
    _revealedCount++;

    if (_grid[row][col].adjacentMines == 0) {
      for (int r = row - 1; r <= row + 1; r++) {
        for (int c = col - 1; c <= col + 1; c++) {
          _revealCellRecursive(r, c);
        }
      }
    }
  }

  void _revealAllMines() {
    for (int row = 0; row < _gridRows; row++) {
      for (int col = 0; col < _gridCols; col++) {
        if (_grid[row][col].isMine && _grid[row][col].state != MinesweeperCellState.exploded) {
          _grid[row][col].state = MinesweeperCellState.revealed;
        }
      }
    }
  }

  void toggleFlag(int row, int col) {
    if (_isGameOver) return;
    if (_grid[row][col].state == MinesweeperCellState.revealed) return;

    if (_grid[row][col].state == MinesweeperCellState.flagged) {
      _grid[row][col].state = MinesweeperCellState.hidden;
      _flaggedCount--;
    } else {
      _grid[row][col].state = MinesweeperCellState.flagged;
      _flaggedCount++;
    }

    Global.loggerModel.info("Flag toggled at ($row, $col)", source: "Minesweeper");
    notifyListeners();
  }

  void _updateBestTime() {
    switch (_difficulty) {
      case MinesweeperDifficulty.easy:
        if (_bestTimeEasy == 0 || _elapsedSeconds < _bestTimeEasy) {
          _bestTimeEasy = _elapsedSeconds;
        }
        break;
      case MinesweeperDifficulty.medium:
        if (_bestTimeMedium == 0 || _elapsedSeconds < _bestTimeMedium) {
          _bestTimeMedium = _elapsedSeconds;
        }
        break;
      case MinesweeperDifficulty.hard:
        if (_bestTimeHard == 0 || _elapsedSeconds < _bestTimeHard) {
          _bestTimeHard = _elapsedSeconds;
        }
        break;
    }
  }

  void _addToHistory(bool completed) {
    _history.insert(0, MinesweeperGameEntry(
      difficulty: _difficulty,
      completed: completed,
      timeSeconds: _elapsedSeconds,
      revealedCount: _revealedCount,
      timestamp: DateTime.now(),
    ));

    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void resetStats() {
    _gamesPlayed = 0;
    _gamesWon = 0;
    _bestTimeEasy = 0;
    _bestTimeMedium = 0;
    _bestTimeHard = 0;
    newGame();
    _saveToPrefs();
    Global.loggerModel.info("Minesweeper stats reset", source: "Minesweeper");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _saveToPrefs();
    Global.loggerModel.info("Minesweeper history cleared", source: "Minesweeper");
    notifyListeners();
  }

  String getDifficultyText(MinesweeperDifficulty difficulty) {
    switch (difficulty) {
      case MinesweeperDifficulty.easy: return "easy";
      case MinesweeperDifficulty.medium: return "medium";
      case MinesweeperDifficulty.hard: return "hard";
    }
  }

  String getDifficultyLabel(MinesweeperDifficulty difficulty) {
    switch (difficulty) {
      case MinesweeperDifficulty.easy: return "Easy";
      case MinesweeperDifficulty.medium: return "Medium";
      case MinesweeperDifficulty.hard: return "Hard";
    }
  }

  Color getDifficultyColor(MinesweeperDifficulty difficulty) {
    switch (difficulty) {
      case MinesweeperDifficulty.easy: return Colors.green;
      case MinesweeperDifficulty.medium: return Colors.orange;
      case MinesweeperDifficulty.hard: return Colors.red;
    }
  }

  int get bestTime {
    switch (_difficulty) {
      case MinesweeperDifficulty.easy: return _bestTimeEasy;
      case MinesweeperDifficulty.medium: return _bestTimeMedium;
      case MinesweeperDifficulty.hard: return _bestTimeHard;
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  double getWinRate() {
    if (_gamesPlayed == 0) return 0;
    return _gamesWon / _gamesPlayed;
  }

  double getProgressPercentage() {
    return _revealedCount / safeCells;
  }

  Color getCellColor(MinesweeperCell cell, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (cell.state) {
      case MinesweeperCellState.hidden:
        return colorScheme.surfaceContainerHighest;
      case MinesweeperCellState.flagged:
        return colorScheme.tertiaryContainer;
      case MinesweeperCellState.exploded:
        return colorScheme.errorContainer;
      case MinesweeperCellState.revealed:
        if (cell.adjacentMines > 0) {
          return _getNumberColor(cell.adjacentMines, context).withValues(alpha: 0.2);
        }
        return colorScheme.surface;
    }
  }

  Color _getNumberColor(int number, BuildContext context) {
    switch (number) {
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.red;
      case 4: return Colors.purple;
      case 5: return Colors.orange;
      case 6: return Colors.cyan;
      case 7: return Colors.black;
      case 8: return Colors.grey;
      default: return Theme.of(context).colorScheme.onSurface;
    }
  }

  Color getCellTextColor(MinesweeperCell cell, BuildContext context) {
    if (cell.state == MinesweeperCellState.revealed && cell.adjacentMines > 0) {
      return _getNumberColor(cell.adjacentMines, context);
    }
    return Theme.of(context).colorScheme.onSurface;
  }
}

class MinesweeperCard extends StatefulWidget {
  @override
  State<MinesweeperCard> createState() => _MinesweeperCardState();
}

class _MinesweeperCardState extends State<MinesweeperCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<MinesweeperModel>();

    if (!game.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.warning_amber, size: 24),
              SizedBox(width: 12),
              Text("Minesweeper: Loading..."),
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
                    Icon(Icons.warning_amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Minesweeper",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (game.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.warning_amber : Icons.history, size: 18),
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

  Widget _buildGameView(BuildContext context, MinesweeperModel game) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDifficultySelector(context, game),
        SizedBox(height: 8),
        _buildInfoRow(context, game),
        SizedBox(height: 12),
        _buildGameGrid(context, game),
        if (game.isGameOver) ...[
          SizedBox(height: 12),
          Text(
            game.isWin ? "You Win!" : "Game Over!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: game.isWin ? Colors.green : Colors.red,
            ),
          ),
        ],
        SizedBox(height: 12),
        _buildStatsRow(context, game),
        SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: game.newGame,
          icon: Icon(Icons.refresh, size: 18),
          label: Text("New Game"),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector(BuildContext context, MinesweeperModel game) {
    return SegmentedButton<MinesweeperDifficulty>(
      segments: [
        ButtonSegment(
          value: MinesweeperDifficulty.easy,
          label: Text("Easy", style: TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: MinesweeperDifficulty.medium,
          label: Text("Medium", style: TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: MinesweeperDifficulty.hard,
          label: Text("Hard", style: TextStyle(fontSize: 12)),
        ),
      ],
      selected: {game.difficulty},
      onSelectionChanged: (Set<MinesweeperDifficulty> newSelection) {
        game.setDifficulty(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, MinesweeperModel game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoItem(context, "Time", game.formatTime(game.elapsedSeconds)),
        _buildInfoItem(context, "Flags", "${game.remainingFlags}"),
        _buildInfoItem(context, "Progress", "${(game.getProgressPercentage() * 100).toInt()}%"),
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

  Widget _buildGameGrid(BuildContext context, MinesweeperModel game) {
    final gridSize = game.gridRows == 8 ? 24.0 : game.gridRows == 10 ? 20.0 : 18.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxWidth: game.gridCols * gridSize + 8,
      ),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: game.gridCols,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: game.gridRows * game.gridCols,
        itemBuilder: (context, index) {
          int row = index ~/ game.gridCols;
          int col = index % game.gridCols;
          final cell = game.grid[row][col];

          return GestureDetector(
            onTap: () => game.revealCell(row, col),
            onLongPress: () => game.toggleFlag(row, col),
            child: Container(
              width: gridSize,
              height: gridSize,
              decoration: BoxDecoration(
                color: game.getCellColor(cell, context),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: _buildCellContent(context, game, cell),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCellContent(BuildContext context, MinesweeperModel game, MinesweeperCell cell) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (cell.state) {
      case MinesweeperCellState.hidden:
        return Icon(Icons.crop_square, size: 16, color: colorScheme.onSurfaceVariant);
      case MinesweeperCellState.flagged:
        return Icon(Icons.flag, size: 16, color: colorScheme.tertiary);
      case MinesweeperCellState.exploded:
        return Icon(Icons.warning, size: 16, color: colorScheme.error);
      case MinesweeperCellState.revealed:
        if (cell.isMine) {
          return Icon(Icons.warning, size: 16, color: colorScheme.error);
        } else if (cell.adjacentMines > 0) {
          return Text(
            "${cell.adjacentMines}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: game.getCellTextColor(cell, context),
            ),
          );
        }
        return SizedBox.shrink();
    }
  }

  Widget _buildStatsRow(BuildContext context, MinesweeperModel game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, "Won", "${game.gamesWon}/${game.gamesPlayed}", Colors.green),
        _buildStatItem(context, "Win Rate", "${(game.getWinRate() * 100).toInt()}%", Theme.of(context).colorScheme.primary),
        _buildStatItem(context, "Best", game.bestTime == 0 ? "-" : game.formatTime(game.bestTime), Theme.of(context).colorScheme.tertiary),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildHistoryView(BuildContext context, MinesweeperModel game) {
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

  Widget _buildHistoryEntry(BuildContext context, MinesweeperModel game, MinesweeperGameEntry entry) {
    final timeAgo = _formatTimeAgo(entry.timestamp);

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
            game.getDifficultyLabel(entry.difficulty),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: game.getDifficultyColor(entry.difficulty),
            ),
          ),
          SizedBox(width: 8),
          Text(
            "${entry.timeSeconds}s",
            style: TextStyle(fontSize: 12),
          ),
          SizedBox(width: 8),
          Text(
            "${entry.revealedCount} cells",
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
        content: Text("Clear all game history and reset statistics?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<MinesweeperModel>().clearHistory();
              context.read<MinesweeperModel>().resetStats();
              Navigator.pop(context);
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }
}