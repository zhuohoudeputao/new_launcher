import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

TicTacToeModel ticTacToeModel = TicTacToeModel();

MyProvider providerTicTacToe = MyProvider(
    name: "TicTacToe",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'TicTacToe',
      keywords: 'tic tac toe game ttt xo grid board play',
      action: () {
        ticTacToeModel.init();
        Global.infoModel.addInfoWidget(
            "TicTacToe",
            ChangeNotifierProvider.value(
                value: ticTacToeModel,
                builder: (context, child) => TicTacToeCard()),
            title: "TicTacToe");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  ticTacToeModel.init();
  Global.infoModel.addInfoWidget(
      "TicTacToe",
      ChangeNotifierProvider.value(
          value: ticTacToeModel,
          builder: (context, child) => TicTacToeCard()),
      title: "TicTacToe");
}

Future<void> _update() async {
  ticTacToeModel.refresh();
}

enum TTTSymbol { empty, x, o }

enum TTTResult { none, playerWin, computerWin, draw }

class TTTGameEntry {
  final TTTResult result;
  final List<TTTSymbol> board;
  final DateTime timestamp;

  TTTGameEntry({
    required this.result,
    required this.board,
    required this.timestamp,
  });
}

class TicTacToeModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;

  List<TTTSymbol> _board = List.filled(9, TTTSymbol.empty);
  TTTSymbol _playerSymbol = TTTSymbol.x;
  TTTSymbol _computerSymbol = TTTSymbol.o;
  TTTResult _gameResult = TTTResult.none;
  bool _isGameOver = false;
  List<int> _winningLine = [];

  int _wins = 0;
  int _losses = 0;
  int _draws = 0;

  List<TTTGameEntry> _history = [];
  static const int maxHistory = 10;

  bool get isInitialized => _isInitialized;
  List<TTTSymbol> get board => _board;
  TTTSymbol get playerSymbol => _playerSymbol;
  TTTSymbol get computerSymbol => _computerSymbol;
  TTTResult get gameResult => _gameResult;
  bool get isGameOver => _isGameOver;
  List<int> get winningLine => _winningLine;
  int get wins => _wins;
  int get losses => _losses;
  int get draws => _draws;
  int get totalGames => _wins + _losses + _draws;
  List<TTTGameEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;

  void init() {
    _isInitialized = true;
    resetBoard();
    Global.loggerModel.info("TicTacToe initialized", source: "TicTacToe");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void resetBoard() {
    _board = List.filled(9, TTTSymbol.empty);
    _gameResult = TTTResult.none;
    _isGameOver = false;
    _winningLine = [];
    notifyListeners();
  }

  void newGame() {
    resetBoard();
  }

  bool canPlay(int index) {
    return !_isGameOver && _board[index] == TTTSymbol.empty;
  }

  void playerMove(int index) {
    if (!canPlay(index)) return;

    _board[index] = _playerSymbol;
    Global.loggerModel.info("Player move at $index", source: "TicTacToe");

    if (_checkWin(_playerSymbol)) {
      _gameResult = TTTResult.playerWin;
      _isGameOver = true;
      _wins++;
      _addToHistory();
      Global.loggerModel.info("Player wins!", source: "TicTacToe");
      notifyListeners();
      return;
    }

    if (_checkDraw()) {
      _gameResult = TTTResult.draw;
      _isGameOver = true;
      _draws++;
      _addToHistory();
      Global.loggerModel.info("Draw!", source: "TicTacToe");
      notifyListeners();
      return;
    }

    _computerMove();
  }

  void _computerMove() {
    int move = _findBestMove();
    if (move == -1) return;

    _board[move] = _computerSymbol;
    Global.loggerModel.info("Computer move at $move", source: "TicTacToe");

    if (_checkWin(_computerSymbol)) {
      _gameResult = TTTResult.computerWin;
      _isGameOver = true;
      _losses++;
      _addToHistory();
      Global.loggerModel.info("Computer wins!", source: "TicTacToe");
      notifyListeners();
      return;
    }

    if (_checkDraw()) {
      _gameResult = TTTResult.draw;
      _isGameOver = true;
      _draws++;
      _addToHistory();
      Global.loggerModel.info("Draw!", source: "TicTacToe");
      notifyListeners();
      return;
    }

    notifyListeners();
  }

  int _findBestMove() {
    List<int> emptySpaces = [];
    for (int i = 0; i < 9; i++) {
      if (_board[i] == TTTSymbol.empty) {
        emptySpaces.add(i);
      }
    }

    if (emptySpaces.isEmpty) return -1;

    int winMove = _findWinningMove(_computerSymbol);
    if (winMove != -1) return winMove;

    int blockMove = _findWinningMove(_playerSymbol);
    if (blockMove != -1) return blockMove;

    if (_board[4] == TTTSymbol.empty) return 4;

    List<int> corners = [0, 2, 6, 8];
    List<int> emptyCorners = corners.where((c) => _board[c] == TTTSymbol.empty).toList();
    if (emptyCorners.isNotEmpty) {
      return emptyCorners[_random.nextInt(emptyCorners.length)];
    }

    List<int> edges = [1, 3, 5, 7];
    List<int> emptyEdges = edges.where((e) => _board[e] == TTTSymbol.empty).toList();
    if (emptyEdges.isNotEmpty) {
      return emptyEdges[_random.nextInt(emptyEdges.length)];
    }

    return emptySpaces[_random.nextInt(emptySpaces.length)];
  }

  int _findWinningMove(TTTSymbol symbol) {
    for (int i = 0; i < 9; i++) {
      if (_board[i] == TTTSymbol.empty) {
        _board[i] = symbol;
        if (_checkWin(symbol)) {
          _board[i] = TTTSymbol.empty;
          return i;
        }
        _board[i] = TTTSymbol.empty;
      }
    }
    return -1;
  }

  bool _checkWin(TTTSymbol symbol) {
    final winPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final pattern in winPatterns) {
      if (_board[pattern[0]] == symbol &&
          _board[pattern[1]] == symbol &&
          _board[pattern[2]] == symbol) {
        _winningLine = pattern;
        return true;
      }
    }
    return false;
  }

  bool _checkDraw() {
    return !_board.contains(TTTSymbol.empty);
  }

  void _addToHistory() {
    _history.insert(0, TTTGameEntry(
      result: _gameResult,
      board: List.from(_board),
      timestamp: DateTime.now(),
    ));

    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void resetStats() {
    _wins = 0;
    _losses = 0;
    _draws = 0;
    resetBoard();
    Global.loggerModel.info("TicTacToe stats reset", source: "TicTacToe");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("TicTacToe history cleared", source: "TicTacToe");
    notifyListeners();
  }

  String getSymbolText(TTTSymbol symbol) {
    switch (symbol) {
      case TTTSymbol.x:
        return "X";
      case TTTSymbol.o:
        return "O";
      case TTTSymbol.empty:
        return "";
    }
  }

  Color getSymbolColor(TTTSymbol symbol, BuildContext context) {
    switch (symbol) {
      case TTTSymbol.x:
        return Theme.of(context).colorScheme.primary;
      case TTTSymbol.o:
        return Theme.of(context).colorScheme.error;
      case TTTSymbol.empty:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String getResultText(TTTResult result) {
    switch (result) {
      case TTTResult.playerWin:
        return "You Win!";
      case TTTResult.computerWin:
        return "Computer Wins!";
      case TTTResult.draw:
        return "Draw!";
      case TTTResult.none:
        return "";
    }
  }

  Color getResultColor(TTTResult result, BuildContext context) {
    switch (result) {
      case TTTResult.playerWin:
        return Colors.green;
      case TTTResult.computerWin:
        return Colors.red;
      case TTTResult.draw:
        return Theme.of(context).colorScheme.secondary;
      case TTTResult.none:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  double getWinRate() {
    if (totalGames == 0) return 0;
    return _wins / totalGames;
  }
}

class TicTacToeCard extends StatefulWidget {
  @override
  State<TicTacToeCard> createState() => _TicTacToeCardState();
}

class _TicTacToeCardState extends State<TicTacToeCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final ttt = context.watch<TicTacToeModel>();

    if (!ttt.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.grid_on, size: 24),
              SizedBox(width: 12),
              Text("TicTacToe: Loading..."),
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
                    Icon(Icons.grid_on, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Tic Tac Toe",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ttt.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.grid_on : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Game" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (ttt.hasHistory || ttt.totalGames > 0)
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
              _buildHistoryView(context, ttt)
            else
              _buildGameView(context, ttt),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView(BuildContext context, TicTacToeModel ttt) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGameBoard(context, ttt),
        if (ttt.isGameOver) ...[
          SizedBox(height: 12),
          Text(
            ttt.getResultText(ttt.gameResult),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ttt.getResultColor(ttt.gameResult, context),
            ),
          ),
        ],
        SizedBox(height: 12),
        _buildStatsRow(context, ttt),
        if (ttt.isGameOver)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: ElevatedButton.icon(
              onPressed: ttt.newGame,
              icon: Icon(Icons.refresh, size: 18),
              label: Text("New Game"),
            ),
          ),
      ],
    );
  }

  Widget _buildGameBoard(BuildContext context, TicTacToeModel ttt) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 120,
      height: 120,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final isWinningCell = ttt.winningLine.contains(index);
            final symbol = ttt.board[index];

            return GestureDetector(
              onTap: () => ttt.playerMove(index),
              child: Container(
                decoration: BoxDecoration(
                  color: isWinningCell
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    ttt.getSymbolText(symbol),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ttt.getSymbolColor(symbol, context),
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

  Widget _buildStatsRow(BuildContext context, TicTacToeModel ttt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, "Wins", ttt.wins, Colors.green),
        _buildStatItem(context, "Losses", ttt.losses, Colors.red),
        _buildStatItem(context, "Draws", ttt.draws, Theme.of(context).colorScheme.secondary),
        _buildStatItem(context, "Rate", "${(ttt.getWinRate() * 100).toInt()}%", Theme.of(context).colorScheme.primary),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildHistoryView(BuildContext context, TicTacToeModel ttt) {
    if (!ttt.hasHistory) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text("No games played yet", style: TextStyle(fontSize: 12)),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: ttt.history.length,
        itemBuilder: (context, index) {
          final entry = ttt.history[index];
          return _buildHistoryEntry(context, ttt, entry);
        },
      ),
    );
  }

  Widget _buildHistoryEntry(BuildContext context, TicTacToeModel ttt, TTTGameEntry entry) {
    final timeAgo = _formatTimeAgo(entry.timestamp);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getResultIcon(entry.result),
            size: 16,
            color: ttt.getResultColor(entry.result, context),
          ),
          SizedBox(width: 8),
          Text(
            ttt.getResultText(entry.result),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ttt.getResultColor(entry.result, context),
            ),
          ),
          SizedBox(width: 8),
          Text(timeAgo, style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  IconData _getResultIcon(TTTResult result) {
    switch (result) {
      case TTTResult.playerWin:
        return Icons.emoji_events;
      case TTTResult.computerWin:
        return Icons.sentiment_dissatisfied;
      case TTTResult.draw:
        return Icons.handshake;
      case TTTResult.none:
        return Icons.help_outline;
    }
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
              context.read<TicTacToeModel>().resetStats();
              context.read<TicTacToeModel>().clearHistory();
              Navigator.pop(context);
            },
            child: Text("Reset"),
          ),
        ],
      ),
    );
  }
}