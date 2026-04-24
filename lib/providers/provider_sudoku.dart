import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

SudokuModel sudokuModel = SudokuModel();

MyProvider providerSudoku = MyProvider(
    name: "Sudoku",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Sudoku',
      keywords: 'sudoku puzzle logic grid numbers game',
      action: () {
        sudokuModel.init();
        Global.infoModel.addInfoWidget(
            "Sudoku",
            ChangeNotifierProvider.value(
                value: sudokuModel,
                builder: (context, child) => SudokuCard()),
            title: "Sudoku");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  sudokuModel.init();
  Global.infoModel.addInfoWidget(
      "Sudoku",
      ChangeNotifierProvider.value(
          value: sudokuModel,
          builder: (context, child) => SudokuCard()),
      title: "Sudoku");
}

Future<void> _update() async {
  sudokuModel.refresh();
}

enum SudokuDifficulty { easy, medium, hard }

class SudokuGameEntry {
  final SudokuDifficulty difficulty;
  final bool completed;
  final int errorsCount;
  final int timeSeconds;
  final DateTime timestamp;

  SudokuGameEntry({
    required this.difficulty,
    required this.completed,
    required this.errorsCount,
    required this.timeSeconds,
    required this.timestamp,
  });
}

class SudokuModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;

  List<List<int>> _puzzle = [];
  List<List<int>> _solution = [];
  List<List<int>> _userInput = [];
  List<List<bool>> _isFixed = [];
  List<List<bool>> _hasError = [];

  SudokuDifficulty _difficulty = SudokuDifficulty.easy;
  int _selectedNumber = 0;
  int _selectedRow = -1;
  int _selectedCol = -1;

  int _gamesPlayed = 0;
  int _gamesCompleted = 0;
  int _totalErrors = 0;
  int _bestTimeEasy = 0;
  int _bestTimeMedium = 0;
  int _bestTimeHard = 0;

  List<SudokuGameEntry> _history = [];
  static const int maxHistory = 10;

  DateTime? _startTime;
  int _elapsedSeconds = 0;

  bool get isInitialized => _isInitialized;
  List<List<int>> get puzzle => _puzzle;
  List<List<int>> get userInput => _userInput;
  List<List<bool>> get isFixed => _isFixed;
  List<List<bool>> get hasError => _hasError;
  SudokuDifficulty get difficulty => _difficulty;
  int get selectedNumber => _selectedNumber;
  int get selectedRow => _selectedRow;
  int get selectedCol => _selectedCol;
  int get gamesPlayed => _gamesPlayed;
  int get gamesCompleted => _gamesCompleted;
  int get totalErrors => _totalErrors;
  int get elapsedSeconds => _elapsedSeconds;
  List<SudokuGameEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;

  Future<void> init() async {
    _isInitialized = true;
    _difficulty = SudokuDifficulty.easy;
    newGame();
    Global.loggerModel.info("Sudoku initialized", source: "Sudoku");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setDifficulty(SudokuDifficulty difficulty) {
    _difficulty = difficulty;
    newGame();
  }

  void newGame() {
    _generatePuzzle();
    _selectedNumber = 0;
    _selectedRow = -1;
    _selectedCol = -1;
    _startTime = DateTime.now();
    _elapsedSeconds = 0;
    Global.loggerModel.info("New Sudoku game started (${_difficulty.name})", source: "Sudoku");
    notifyListeners();
  }

  void _generatePuzzle() {
    _solution = _generateFullSolution();
    _puzzle = List.generate(9, (row) => List.generate(9, (col) => _solution[row][col]));
    _isFixed = List.generate(9, (row) => List.generate(9, (col) => false));
    _hasError = List.generate(9, (row) => List.generate(9, (col) => false));
    _userInput = List.generate(9, (row) => List.generate(9, (col) => _solution[row][col]));

    int cellsToRemove;
    switch (_difficulty) {
      case SudokuDifficulty.easy:
        cellsToRemove = 30;
        break;
      case SudokuDifficulty.medium:
        cellsToRemove = 40;
        break;
      case SudokuDifficulty.hard:
        cellsToRemove = 50;
        break;
    }

    List<int> positions = List.generate(81, (i) => i);
    positions.shuffle(_random);

    for (int i = 0; i < cellsToRemove && i < positions.length; i++) {
      int pos = positions[i];
      int row = pos ~/ 9;
      int col = pos % 9;
      _puzzle[row][col] = 0;
      _userInput[row][col] = 0;
      _isFixed[row][col] = false;
    }

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_puzzle[row][col] != 0) {
          _isFixed[row][col] = true;
        }
      }
    }
  }

  List<List<int>> _generateFullSolution() {
    List<List<int>> grid = List.generate(9, (row) => List.generate(9, (col) => 0));
    _fillGrid(grid);
    return grid;
  }

  bool _fillGrid(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1);
          numbers.shuffle(_random);

          for (int num in numbers) {
            if (_isValidPlacement(grid, row, col, num)) {
              grid[row][col] = num;
              if (_fillGrid(grid)) {
                return true;
              }
              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isValidPlacement(List<List<int>> grid, int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (grid[row][i] == num) return false;
      if (grid[i][col] == num) return false;
    }

    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (grid[i][j] == num) return false;
      }
    }

    return true;
  }

  void selectCell(int row, int col) {
    if (_isFixed[row][col]) return;
    _selectedRow = row;
    _selectedCol = col;
    notifyListeners();
  }

  void selectNumber(int number) {
    _selectedNumber = number;
    if (_selectedRow >= 0 && _selectedCol >= 0) {
      placeNumber(number);
    }
    notifyListeners();
  }

  void placeNumber(int number) {
    if (_selectedRow < 0 || _selectedCol < 0) return;
    if (_isFixed[_selectedRow][_selectedCol]) return;

    _userInput[_selectedRow][_selectedCol] = number;

    if (number != 0 && number != _solution[_selectedRow][_selectedCol]) {
      _hasError[_selectedRow][_selectedCol] = true;
      _totalErrors++;
      Global.loggerModel.info("Incorrect placement at (${_selectedRow}, ${_selectedCol})", source: "Sudoku");
    } else {
      _hasError[_selectedRow][_selectedCol] = false;
    }

    if (_checkCompletion()) {
      _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      _gamesPlayed++;
      _gamesCompleted++;
      _updateBestTime();
      _addToHistory(true);
      Global.loggerModel.info("Sudoku completed in ${_elapsedSeconds}s with ${_totalErrors} errors", source: "Sudoku");
    }

    notifyListeners();
  }

  void clearCell() {
    if (_selectedRow < 0 || _selectedCol < 0) return;
    if (_isFixed[_selectedRow][_selectedCol]) return;

    _userInput[_selectedRow][_selectedCol] = 0;
    _hasError[_selectedRow][_selectedCol] = false;
    notifyListeners();
  }

  bool _checkCompletion() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_userInput[row][col] != _solution[row][col]) {
          return false;
        }
      }
    }
    return true;
  }

  bool get isCompleted => _checkCompletion();

  void _updateBestTime() {
    switch (_difficulty) {
      case SudokuDifficulty.easy:
        if (_bestTimeEasy == 0 || _elapsedSeconds < _bestTimeEasy) {
          _bestTimeEasy = _elapsedSeconds;
        }
        break;
      case SudokuDifficulty.medium:
        if (_bestTimeMedium == 0 || _elapsedSeconds < _bestTimeMedium) {
          _bestTimeMedium = _elapsedSeconds;
        }
        break;
      case SudokuDifficulty.hard:
        if (_bestTimeHard == 0 || _elapsedSeconds < _bestTimeHard) {
          _bestTimeHard = _elapsedSeconds;
        }
        break;
    }
  }

  void giveUp() {
    _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
    _gamesPlayed++;
    _addToHistory(false);
    Global.loggerModel.info("Sudoku game abandoned", source: "Sudoku");
    newGame();
  }

  void _addToHistory(bool completed) {
    _history.insert(0, SudokuGameEntry(
      difficulty: _difficulty,
      completed: completed,
      errorsCount: _totalErrors,
      timeSeconds: _elapsedSeconds,
      timestamp: DateTime.now(),
    ));

    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void resetStats() {
    _gamesPlayed = 0;
    _gamesCompleted = 0;
    _totalErrors = 0;
    _bestTimeEasy = 0;
    _bestTimeMedium = 0;
    _bestTimeHard = 0;
    newGame();
    Global.loggerModel.info("Sudoku stats reset", source: "Sudoku");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("Sudoku history cleared", source: "Sudoku");
    notifyListeners();
  }

  String getDifficultyText(SudokuDifficulty difficulty) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        return "Easy";
      case SudokuDifficulty.medium:
        return "Medium";
      case SudokuDifficulty.hard:
        return "Hard";
    }
  }

  Color getDifficultyColor(SudokuDifficulty difficulty, BuildContext context) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        return Colors.green;
      case SudokuDifficulty.medium:
        return Colors.orange;
      case SudokuDifficulty.hard:
        return Colors.red;
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  double getCompletionRate() {
    if (_gamesPlayed == 0) return 0;
    return _gamesCompleted / _gamesPlayed;
  }

  int getEmptyCellsCount() {
    int count = 0;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_userInput[row][col] == 0) {
          count++;
        }
      }
    }
    return count;
  }

  int getFilledCellsCount() {
    return 81 - getEmptyCellsCount();
  }

  double getProgressPercentage() {
    return getFilledCellsCount() / 81;
  }
}

class SudokuCard extends StatefulWidget {
  @override
  State<SudokuCard> createState() => _SudokuCardState();
}

class _SudokuCardState extends State<SudokuCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final sudoku = context.watch<SudokuModel>();

    if (!sudoku.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.grid_4x4, size: 24),
              SizedBox(width: 12),
              Text("Sudoku: Loading..."),
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
                      "Sudoku",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sudoku.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.grid_4x4 : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Game" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (sudoku.hasHistory || sudoku.gamesPlayed > 0)
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
              _buildHistoryView(context, sudoku)
            else
              _buildGameView(context, sudoku),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView(BuildContext context, SudokuModel sudoku) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDifficultySelector(context, sudoku),
        SizedBox(height: 8),
        _buildInfoRow(context, sudoku),
        SizedBox(height: 12),
        _buildSudokuGrid(context, sudoku),
        SizedBox(height: 12),
        _buildNumberSelector(context, sudoku),
        if (sudoku.isCompleted) ...[
          SizedBox(height: 12),
          Text(
            "Completed!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
        SizedBox(height: 12),
        _buildActionButtons(context, sudoku),
      ],
    );
  }

  Widget _buildDifficultySelector(BuildContext context, SudokuModel sudoku) {
    return SegmentedButton<SudokuDifficulty>(
      segments: [
        ButtonSegment(
          value: SudokuDifficulty.easy,
          label: Text("Easy", style: TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: SudokuDifficulty.medium,
          label: Text("Medium", style: TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: SudokuDifficulty.hard,
          label: Text("Hard", style: TextStyle(fontSize: 12)),
        ),
      ],
      selected: {sudoku.difficulty},
      onSelectionChanged: (Set<SudokuDifficulty> newSelection) {
        sudoku.setDifficulty(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, SudokuModel sudoku) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoItem(context, "Time", sudoku.formatTime(sudoku.elapsedSeconds)),
        _buildInfoItem(context, "Errors", "${sudoku.totalErrors}"),
        _buildInfoItem(context, "Progress", "${(sudoku.getProgressPercentage() * 100).toInt()}%"),
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

  Widget _buildSudokuGrid(BuildContext context, SudokuModel sudoku) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 200,
      height: 200,
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
            crossAxisCount: 9,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            int row = index ~/ 9;
            int col = index % 9;
            int value = sudoku.userInput[row][col];
            bool isFixed = sudoku.isFixed[row][col];
            bool hasError = sudoku.hasError[row][col];
            bool isSelected = sudoku.selectedRow == row && sudoku.selectedCol == col;

            bool isBoxBorder = (row % 3 == 0 && row > 0) || (col % 3 == 0 && col > 0);

            return GestureDetector(
              onTap: () => sudoku.selectCell(row, col),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : hasError
                          ? colorScheme.errorContainer.withValues(alpha: 0.3)
                          : colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isBoxBorder
                        ? colorScheme.outline.withValues(alpha: 0.8)
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: isBoxBorder ? 1.5 : 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    value > 0 ? "$value" : "",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
                      color: hasError
                          ? colorScheme.error
                          : isFixed
                              ? colorScheme.onSurface
                              : colorScheme.primary,
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

  Widget _buildNumberSelector(BuildContext context, SudokuModel sudoku) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 1; i <= 9; i++)
          _buildNumberButton(context, sudoku, i),
        _buildNumberButton(context, sudoku, 0, icon: Icons.clear),
      ],
    );
  }

  Widget _buildNumberButton(BuildContext context, SudokuModel sudoku, int number, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = sudoku.selectedNumber == number;

    return GestureDetector(
      onTap: () => sudoku.selectNumber(number),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 16, color: colorScheme.onSurfaceVariant)
              : Text(
                  "$number",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SudokuModel sudoku) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: sudoku.newGame,
          icon: Icon(Icons.refresh, size: 16),
          label: Text("New"),
          style: ElevatedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
        TextButton.icon(
          onPressed: () => _showGiveUpConfirmation(context, sudoku),
          icon: Icon(Icons.flag, size: 16),
          label: Text("Give Up"),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(BuildContext context, SudokuModel sudoku) {
    if (!sudoku.hasHistory) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text("No games played yet", style: TextStyle(fontSize: 12)),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: sudoku.history.length,
        itemBuilder: (context, index) {
          final entry = sudoku.history[index];
          return _buildHistoryEntry(context, sudoku, entry);
        },
      ),
    );
  }

  Widget _buildHistoryEntry(BuildContext context, SudokuModel sudoku, SudokuGameEntry entry) {
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
            sudoku.getDifficultyText(entry.difficulty),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: sudoku.getDifficultyColor(entry.difficulty, context),
            ),
          ),
          SizedBox(width: 8),
          Text(
            "${entry.timeSeconds}s",
            style: TextStyle(fontSize: 12),
          ),
          SizedBox(width: 8),
          Text(
            "${entry.errorsCount} err",
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
              context.read<SudokuModel>().resetStats();
              context.read<SudokuModel>().clearHistory();
              Navigator.pop(context);
            },
            child: Text("Reset"),
          ),
        ],
      ),
    );
  }

  void _showGiveUpConfirmation(BuildContext context, SudokuModel sudoku) {
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
              sudoku.giveUp();
              Navigator.pop(context);
            },
            child: Text("Give Up"),
          ),
        ],
      ),
    );
  }
}