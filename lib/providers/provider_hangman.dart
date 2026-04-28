import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

HangmanModel hangmanModel = HangmanModel();

MyProvider providerHangman = MyProvider(
    name: "Hangman",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Hangman',
      keywords: 'hangman word guess game letter puzzle play',
      action: () {
        hangmanModel.init();
        Global.infoModel.addInfoWidget(
            "Hangman",
            ChangeNotifierProvider.value(
                value: hangmanModel,
                builder: (context, child) => HangmanCard()),
            title: "Hangman");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  hangmanModel.init();
  Global.infoModel.addInfoWidget(
      "Hangman",
      ChangeNotifierProvider.value(
          value: hangmanModel,
          builder: (context, child) => HangmanCard()),
      title: "Hangman");
}

Future<void> _update() async {
  hangmanModel.refresh();
}

class HangmanGameEntry {
  final bool won;
  final String word;
  final int wrongGuesses;
  final DateTime timestamp;

  HangmanGameEntry({
    required this.won,
    required this.word,
    required this.wrongGuesses,
    required this.timestamp,
  });
}

class HangmanModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;

  final List<String> _words = [
    'flutter', 'dart', 'android', 'mobile', 'application',
    'widget', 'provider', 'material', 'design', 'launcher',
    'keyboard', 'button', 'screen', 'theme', 'color',
    'device', 'battery', 'weather', 'timer', 'clock',
    'calculator', 'notes', 'flashlight', 'camera', 'settings',
    'flutter', 'programming', 'development', 'software', 'engineer',
    'hangman', 'word', 'guess', 'letter', 'game',
    'puzzle', 'play', 'win', 'lose', 'draw',
  ];

  String _currentWord = '';
  Set<String> _guessedLetters = {};
  Set<String> _wrongLetters = {};
  int _maxWrongGuesses = 6;
  bool _gameWon = false;
  bool _gameLost = false;

  int _wins = 0;
  int _losses = 0;

  List<HangmanGameEntry> _history = [];
  static const int maxHistory = 10;

  bool get isInitialized => _isInitialized;
  String get currentWord => _currentWord;
  Set<String> get guessedLetters => _guessedLetters;
  Set<String> get wrongLetters => _wrongLetters;
  int get wrongGuessCount => _wrongLetters.length;
  int get maxWrongGuesses => _maxWrongGuesses;
  bool get gameWon => _gameWon;
  bool get gameLost => _gameLost;
  bool get isGameOver => _gameWon || _gameLost;
  int get wins => _wins;
  int get losses => _losses;
  int get totalGames => _wins + _losses;
  List<HangmanGameEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;

  String get displayedWord {
    return _currentWord.split('').map((letter) {
      return _guessedLetters.contains(letter.toLowerCase()) ? letter : '_';
    }).join(' ');
  }

  int get remainingGuesses => _maxWrongGuesses - _wrongLetters.length;

  List<String> get availableLetters {
    return 'abcdefghijklmnopqrstuvwxyz'.split('').where((letter) {
      return !_guessedLetters.contains(letter) && !_wrongLetters.contains(letter);
    }).toList();
  }

  Future<void> init() async {
    _isInitialized = true;
    newGame();
    Global.loggerModel.info("Hangman initialized", source: "Hangman");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void newGame() {
    _currentWord = _words[_random.nextInt(_words.length)];
    _guessedLetters.clear();
    _wrongLetters.clear();
    _gameWon = false;
    _gameLost = false;
    Global.loggerModel.info("New Hangman game started with word: $_currentWord", source: "Hangman");
    notifyListeners();
  }

  void guessLetter(String letter) {
    if (isGameOver) return;
    if (_guessedLetters.contains(letter) || _wrongLetters.contains(letter)) return;

    final lowerLetter = letter.toLowerCase();

    if (_currentWord.toLowerCase().contains(lowerLetter)) {
      _guessedLetters.add(lowerLetter);
      Global.loggerModel.info("Correct guess: $letter", source: "Hangman");
      _checkWin();
    } else {
      _wrongLetters.add(lowerLetter);
      Global.loggerModel.info("Wrong guess: $letter", source: "Hangman");
      _checkLose();
    }

    notifyListeners();
  }

  void _checkWin() {
    final wordLetters = _currentWord.toLowerCase().split('').toSet();
    if (_guessedLetters.containsAll(wordLetters)) {
      _gameWon = true;
      _wins++;
      _addToHistory();
      Global.loggerModel.info("Player wins! Word: $_currentWord", source: "Hangman");
    }
  }

  void _checkLose() {
    if (_wrongLetters.length >= _maxWrongGuesses) {
      _gameLost = true;
      _losses++;
      _addToHistory();
      Global.loggerModel.info("Player loses! Word: $_currentWord", source: "Hangman");
    }
  }

  void _addToHistory() {
    _history.insert(0, HangmanGameEntry(
      won: _gameWon,
      word: _currentWord,
      wrongGuesses: _wrongLetters.length,
      timestamp: DateTime.now(),
    ));

    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void resetStats() {
    _wins = 0;
    _losses = 0;
    newGame();
    Global.loggerModel.info("Hangman stats reset", source: "Hangman");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("Hangman history cleared", source: "Hangman");
    notifyListeners();
  }

  String getHangmanStage(int wrongCount) {
    switch (wrongCount) {
      case 0:
        return '''
   _____
  |     |
  |      
  |      
  |      
  |_____
''';
      case 1:
        return '''
   _____
  |     |
  |     O
  |      
  |      
  |_____
''';
      case 2:
        return '''
   _____
  |     |
  |     O
  |     |
  |      
  |_____
''';
      case 3:
        return '''
   _____
  |     |
  |     O
  |    /|
  |      
  |_____
''';
      case 4:
        return '''
   _____
  |     |
  |     O
  |    /|\\
  |      
  |_____
''';
      case 5:
        return '''
   _____
  |     |
  |     O
  |    /|\\
  |    / 
  |_____
''';
      case 6:
        return '''
   _____
  |     |
  |     O
  |    /|\\
  |    / \\
  |_____
''';
      default:
        return '''
   _____
  |     |
  |     O
  |    /|\\
  |    / \\
  |_____
''';
    }
  }

  double getWinRate() {
    if (totalGames == 0) return 0;
    return _wins / totalGames;
  }
}

class HangmanCard extends StatefulWidget {
  @override
  State<HangmanCard> createState() => _HangmanCardState();
}

class _HangmanCardState extends State<HangmanCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final hangman = context.watch<HangmanModel>();

    if (!hangman.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.spellcheck, size: 24),
              SizedBox(width: 12),
              Text("Hangman: Loading..."),
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
                    Icon(Icons.spellcheck, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Hangman",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hangman.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.spellcheck : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Game" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (hangman.hasHistory || hangman.totalGames > 0)
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
              _buildHistoryView(context, hangman)
            else
              _buildGameView(context, hangman),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView(BuildContext context, HangmanModel hangman) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHangmanFigure(context, hangman),
        SizedBox(height: 12),
        Text(
          hangman.displayedWord,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        if (hangman.isGameOver) ...[
          SizedBox(height: 8),
          if (hangman.gameLost)
            Text(
              "The word was: ${hangman.currentWord}",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          SizedBox(height: 8),
          Text(
            hangman.gameWon ? "You Win!" : "You Lose!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: hangman.gameWon ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (!hangman.isGameOver) ...[
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, size: 14, color: Theme.of(context).colorScheme.error),
              SizedBox(width: 4),
              Text(
                "Wrong: ${hangman.wrongGuessCount}/${hangman.maxWrongGuesses}",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildLetterButtons(context, hangman),
        ],
        SizedBox(height: 12),
        _buildStatsRow(context, hangman),
        if (hangman.isGameOver)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: ElevatedButton.icon(
              onPressed: hangman.newGame,
              icon: Icon(Icons.refresh, size: 18),
              label: Text("New Game"),
            ),
          ),
      ],
    );
  }

  Widget _buildHangmanFigure(BuildContext context, HangmanModel hangman) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        hangman.getHangmanStage(hangman.wrongGuessCount),
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'monospace',
          color: hangman.gameLost ? colorScheme.error : colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildLetterButtons(BuildContext context, HangmanModel hangman) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableLetters = hangman.availableLetters;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: availableLetters.map((letter) {
        return InkWell(
          onTap: () => hangman.guessLetter(letter),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                letter.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(BuildContext context, HangmanModel hangman) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, "Wins", hangman.wins, Theme.of(context).colorScheme.primary),
        _buildStatItem(context, "Losses", hangman.losses, Theme.of(context).colorScheme.error),
        _buildStatItem(context, "Rate", "${(hangman.getWinRate() * 100).toInt()}%", Theme.of(context).colorScheme.primary),
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

  Widget _buildHistoryView(BuildContext context, HangmanModel hangman) {
    if (!hangman.hasHistory) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text("No games played yet", style: TextStyle(fontSize: 12)),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: hangman.history.length,
        itemBuilder: (context, index) {
          final entry = hangman.history[index];
          return _buildHistoryEntry(context, hangman, entry);
        },
      ),
    );
  }

  Widget _buildHistoryEntry(BuildContext context, HangmanModel hangman, HangmanGameEntry entry) {
    final timeAgo = _formatTimeAgo(entry.timestamp);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            entry.won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 16,
            color: entry.won ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
          ),
          SizedBox(width: 8),
          Text(
            entry.word.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          Text(
            "(${entry.wrongGuesses} wrong)",
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 8),
          Text(timeAgo, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
              context.read<HangmanModel>().resetStats();
              context.read<HangmanModel>().clearHistory();
              Navigator.pop(context);
            },
            child: Text("Reset"),
          ),
        ],
      ),
    );
  }
}