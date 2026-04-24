import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

SimonModel simonModel = SimonModel();

MyProvider providerSimon = MyProvider(
    name: "Simon",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Simon',
      keywords: 'simon memory sequence color pattern game play repeat',
      action: () => simonModel.init(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  simonModel.init();
  Global.infoModel.addInfoWidget(
      "Simon",
      ChangeNotifierProvider.value(
          value: simonModel,
          builder: (context, child) => SimonCard()),
      title: "Simon");
}

Future<void> _update() async {
  simonModel.refresh();
}

enum SimonColor { red, green, blue, yellow }

enum SimonState { ready, showingSequence, waitingInput, gameOver }

class SimonGameEntry {
  final int level;
  final bool completed;
  final DateTime timestamp;

  SimonGameEntry({
    required this.level,
    required this.completed,
    required this.timestamp,
  });
}

class SimonModel extends ChangeNotifier {
  final Random _random = Random();
  static const int maxHistory = 10;

  SimonState _state = SimonState.ready;
  List<SimonColor> _sequence = [];
  List<SimonColor> _playerInput = [];
  int _currentLevel = 0;
  int _highestLevel = 0;
  int _currentShowingIndex = 0;
  SimonColor? _activeColor;
  Timer? _showTimer;
  bool _isInitialized = false;

  int _gamesPlayed = 0;
  int _gamesCompleted = 0;
  final List<SimonGameEntry> _history = [];

  bool get isInitialized => _isInitialized;
  SimonState get state => _state;
  int get currentLevel => _currentLevel;
  int get highestLevel => _highestLevel;
  SimonColor? get activeColor => _activeColor;
  List<SimonColor> get sequence => List.unmodifiable(_sequence);
  int get gamesPlayed => _gamesPlayed;
  int get gamesCompleted => _gamesCompleted;
  List<SimonGameEntry> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  int get totalGames => _gamesPlayed;

  double getCompletionRate() {
    if (_gamesPlayed == 0) return 0;
    return _gamesCompleted / _gamesPlayed;
  }

  void init() {
    _isInitialized = true;
    _state = SimonState.ready;
    _sequence = [];
    _playerInput = [];
    _currentLevel = 0;
    _currentShowingIndex = 0;
    _activeColor = null;
    _showTimer?.cancel();
    _showTimer = null;
    Global.loggerModel.info("Simon initialized", source: "Simon");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void startGame() {
    _sequence = [];
    _playerInput = [];
    _currentLevel = 0;
    _gamesPlayed++;
    _addToSequence();
    _showSequence();
    Global.loggerModel.info("Simon game started", source: "Simon");
    notifyListeners();
  }

  void _addToSequence() {
    final colors = SimonColor.values;
    _sequence.add(colors[_random.nextInt(colors.length)]);
    _currentLevel = _sequence.length;
  }

  void _showSequence() {
    _state = SimonState.showingSequence;
    _currentShowingIndex = 0;
    _playerInput = [];
    _showNextColor();
  }

  void _showNextColor() {
    if (_currentShowingIndex >= _sequence.length) {
      _state = SimonState.waitingInput;
      _activeColor = null;
      notifyListeners();
      return;
    }

    _activeColor = _sequence[_currentShowingIndex];
    notifyListeners();

    _showTimer?.cancel();
    _showTimer = Timer(Duration(milliseconds: 600), () {
      _activeColor = null;
      notifyListeners();

      _showTimer = Timer(Duration(milliseconds: 300), () {
        _currentShowingIndex++;
        _showNextColor();
      });
    });
  }

  void handleInput(SimonColor color) {
    if (_state != SimonState.waitingInput) return;

    _playerInput.add(color);
    _activeColor = color;
    notifyListeners();

    _showTimer?.cancel();
    _showTimer = Timer(Duration(milliseconds: 200), () {
      _activeColor = null;
      notifyListeners();

      final inputIndex = _playerInput.length - 1;
      if (_playerInput[inputIndex] != _sequence[inputIndex]) {
        _gameOver();
        return;
      }

      if (_playerInput.length == _sequence.length) {
        _gamesCompleted++;
        if (_currentLevel > _highestLevel) {
          _highestLevel = _currentLevel;
        }
        _addToHistory(true);
        _addToSequence();
        Future.delayed(Duration(milliseconds: 500), () {
          _showSequence();
        });
      }
    });
  }

  void _gameOver() {
    _showTimer?.cancel();
    _showTimer = null;
    _state = SimonState.gameOver;
    if (_currentLevel > 1) {
      _highestLevel = _currentLevel - 1;
    }
    _addToHistory(false);
    Global.loggerModel.info("Simon game over at level $_currentLevel", source: "Simon");
    notifyListeners();
  }

  void _addToHistory(bool completed) {
    _history.insert(0, SimonGameEntry(
      level: completed ? _currentLevel : _currentLevel - 1,
      completed: completed,
      timestamp: DateTime.now(),
    ));

    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void resetGame() {
    _showTimer?.cancel();
    _showTimer = null;
    _state = SimonState.ready;
    _sequence = [];
    _playerInput = [];
    _currentLevel = 0;
    _activeColor = null;
    Global.loggerModel.info("Simon game reset", source: "Simon");
    notifyListeners();
  }

  void resetStats() {
    _gamesPlayed = 0;
    _gamesCompleted = 0;
    _highestLevel = 0;
    _history.clear();
    resetGame();
    Global.loggerModel.info("Simon stats reset", source: "Simon");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("Simon history cleared", source: "Simon");
    notifyListeners();
  }

  Color getColorForSimon(SimonColor color, bool isActive) {
    switch (color) {
      case SimonColor.red:
        return isActive ? Colors.red : Colors.red.withValues(alpha: 0.6);
      case SimonColor.green:
        return isActive ? Colors.green : Colors.green.withValues(alpha: 0.6);
      case SimonColor.blue:
        return isActive ? Colors.blue : Colors.blue.withValues(alpha: 0.6);
      case SimonColor.yellow:
        return isActive ? Colors.yellow : Colors.yellow.withValues(alpha: 0.6);
    }
  }
}

class SimonCard extends StatefulWidget {
  @override
  State<SimonCard> createState() => _SimonCardState();
}

class _SimonCardState extends State<SimonCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final simon = context.watch<SimonModel>();

    if (!simon.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.memory, size: 24),
              SizedBox(width: 12),
              Text("Simon: Loading..."),
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
                    Icon(Icons.memory, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Simon",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (simon.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.memory : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Game" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (simon.hasHistory || simon.totalGames > 0)
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
              _buildHistoryView(context, simon)
            else
              _buildGameView(context, simon),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView(BuildContext context, SimonModel simon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Level: ${simon.currentLevel}",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (simon.highestLevel > 0)
          Text(
            "Best: ${simon.highestLevel}",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        SizedBox(height: 12),
        _buildColorButtons(context, simon),
        SizedBox(height: 12),
        if (simon.state == SimonState.ready)
          ElevatedButton.icon(
            onPressed: simon.startGame,
            icon: Icon(Icons.play_arrow, size: 18),
            label: Text("Start"),
          ),
        if (simon.state == SimonState.showingSequence)
          Text(
            "Watch the sequence...",
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
          ),
        if (simon.state == SimonState.waitingInput)
          Text(
            "Repeat the sequence!",
            style: TextStyle(fontSize: 14, color: Colors.green),
          ),
        if (simon.state == SimonState.gameOver) ...[
          Text(
            "Game Over!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          SizedBox(height: 8),
          Text(
            "You reached level ${simon.currentLevel - 1}",
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: simon.startGame,
            icon: Icon(Icons.refresh, size: 18),
            label: Text("Play Again"),
          ),
        ],
        SizedBox(height: 12),
        _buildStatsRow(context, simon),
      ],
    );
  }

  Widget _buildColorButtons(BuildContext context, SimonModel simon) {
    return Container(
      width: 180,
      height: 180,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: SimonColor.values.map((color) {
          final isActive = simon.activeColor == color;
          final canPress = simon.state == SimonState.waitingInput;
          
          return GestureDetector(
            onTap: canPress ? () => simon.handleInput(color) : null,
            child: Container(
              decoration: BoxDecoration(
                color: simon.getColorForSimon(color, isActive),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.transparent,
                  width: isActive ? 3 : 0,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, SimonModel simon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, "Played", simon.gamesPlayed, Theme.of(context).colorScheme.primary),
        _buildStatItem(context, "Completed", simon.gamesCompleted, Colors.green),
        _buildStatItem(context, "Rate", "${(simon.getCompletionRate() * 100).toInt()}%", Colors.orange),
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

  Widget _buildHistoryView(BuildContext context, SimonModel simon) {
    if (!simon.hasHistory) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text("No games played yet", style: TextStyle(fontSize: 12)),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: simon.history.length,
        itemBuilder: (context, index) {
          final entry = simon.history[index];
          return _buildHistoryEntry(context, entry);
        },
      ),
    );
  }

  Widget _buildHistoryEntry(BuildContext context, SimonGameEntry entry) {
    final timeAgo = _formatTimeAgo(entry.timestamp);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            entry.completed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 16,
            color: entry.completed ? Colors.green : Colors.red,
          ),
          SizedBox(width: 8),
          Text(
            "Level ${entry.level}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Text(
            entry.completed ? "Completed" : "Failed",
            style: TextStyle(
              fontSize: 10,
              color: entry.completed ? Colors.green : Colors.red,
            ),
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
              context.read<SimonModel>().resetStats();
              Navigator.pop(context);
            },
            child: Text("Reset"),
          ),
        ],
      ),
    );
  }
}