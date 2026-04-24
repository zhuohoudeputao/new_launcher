import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

WordleModel wordleModel = WordleModel();

MyProvider providerWordle = MyProvider(
    name: "Wordle",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Wordle',
      keywords: 'wordle word guess game letter puzzle play five',
      action: () {
        wordleModel.init();
        Global.infoModel.addInfoWidget(
            "Wordle",
            ChangeNotifierProvider.value(
                value: wordleModel,
                builder: (context, child) => WordleCard()),
            title: "Wordle");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  wordleModel.init();
  Global.infoModel.addInfoWidget(
      "Wordle",
      ChangeNotifierProvider.value(
          value: wordleModel,
          builder: (context, child) => WordleCard()),
      title: "Wordle");
}

Future<void> _update() async {
  wordleModel.refresh();
}

enum LetterStatus {
  correct,
  present,
  absent,
  unused,
}

class WordleGuess {
  final String word;
  final List<LetterStatus> statuses;

  WordleGuess({required this.word, required this.statuses});
}

class WordleGameEntry {
  final bool won;
  final String word;
  final int attempts;
  final DateTime timestamp;

  WordleGameEntry({
    required this.won,
    required this.word,
    required this.attempts,
    required this.timestamp,
  });
}

class WordleModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;

  final List<String> _words = [
    'about', 'above', 'abuse', 'actor', 'acute',
    'admit', 'adopt', 'adult', 'after', 'again',
    'agent', 'agree', 'ahead', 'alarm', 'album',
    'alert', 'alien', 'align', 'alike', 'alive',
    'allow', 'alloy', 'alone', 'along', 'alpha',
    'alter', 'amaze', 'angel', 'anger', 'angle',
    'angry', 'apart', 'apple', 'apply', 'arena',
    'argue', 'arise', 'armor', 'array', 'arrow',
    'asset', 'avoid', 'award', 'aware', 'awful',
    'basic', 'beach', 'beast', 'begin', 'being',
    'below', 'bench', 'billy', 'birth', 'black',
    'blade', 'blame', 'blind', 'block', 'blood',
    'bloom', 'blown', 'board', 'boost', 'bound',
    'brain', 'brand', 'brave', 'bread', 'break',
    'breed', 'brick', 'brief', 'bring', 'broad',
    'broke', 'brown', 'brush', 'build', 'built',
    'bunch', 'burst', 'buyer', 'cabin', 'cable',
    'calif', 'camera', 'camp', 'canal', 'candy',
    'card', 'cargo', 'carry', 'catch', 'cause',
    'chain', 'chair', 'chart', 'chase', 'cheap',
    'check', 'chest', 'chief', 'child', 'china',
    'chose', 'civil', 'claim', 'class', 'clean',
    'clear', 'climb', 'clock', 'close', 'cloth',
    'cloud', 'coach', 'coast', 'count', 'court',
    'cover', 'craft', 'crash', 'cream', 'crime',
    'cross', 'crowd', 'crown', 'curve', 'cycle',
    'daily', 'dance', 'dated', 'dealt', 'death',
    'debug', 'depth', 'digit', 'dirty', 'disco',
    'doubt', 'dough', 'draft', 'drain', 'drawn',
    'dream', 'dress', 'drill', 'drink', 'drive',
    'drown', 'drunk', 'dusty', 'dutch', 'dwarf',
    'dying', 'eager', 'early', 'earth', 'eight',
    'elite', 'empty', 'enemy', 'enjoy', 'enter',
    'entry', 'equal', 'error', 'essay', 'event',
    'every', 'exact', 'exist', 'extra', 'faith',
    'false', 'fancy', 'fatal', 'fault', 'favor',
    'feast', 'fiber', 'field', 'fifth', 'fifty',
    'fight', 'final', 'first', 'fixed', 'flame',
    'flash', 'flat', 'fleet', 'flesh', 'float',
    'flood', 'floor', 'fluid', 'focus', 'force',
    'forge', 'forth', 'forum', 'found', 'frame',
    'frank', 'fraud', 'fresh', 'front', 'frost',
    'fruit', 'fully', 'fuzzy', 'gauge', 'giant',
    'given', 'glass', 'globe', 'glory', 'goes',
    'going', 'grace', 'grade', 'grain', 'grand',
    'grant', 'graph', 'grasp', 'grass', 'grave',
    'great', 'green', 'gross', 'group', 'grown',
    'guard', 'guess', 'guest', 'guide', 'guilt',
    'happy', 'harsh', 'heart', 'heavy', 'hello',
    'hence', 'herbs', 'high', 'horse', 'hotel',
    'house', 'human', 'ideal', 'image', 'imply',
    'index', 'inner', 'input', 'issue', 'japan',
    'jimmy', 'joint', 'jones', 'judge', 'juice',
    'known', 'label', 'large', 'laser', 'later',
    'laugh', 'layer', 'learn', 'lease', 'least',
    'leave', 'legal', 'level', 'lewis', 'light',
    'limit', 'links', 'liver', 'lives', 'local',
    'loose', 'lover', 'lower', 'lucky', 'lunch',
    'magic', 'major', 'maker', 'march', 'maria',
    'match', 'maybe', 'mayor', 'meant', 'medal',
    'media', 'metal', 'meter', 'might', 'minor',
    'minus', 'mixed', 'model', 'money', 'month',
    'moral', 'motor', 'mount', 'mouse', 'mouth',
    'movie', 'music', 'musty', 'naked', 'naval',
    'nerve', 'never', 'newly', 'night', 'noise',
    'north', 'noted', 'novel', 'nurse', 'occur',
    'ocean', 'offer', 'often', 'olive', 'order',
    'other', 'ought', 'outer', 'owner', 'paint',
    'panel', 'panic', 'paper', 'party', 'patch',
    'pause', 'peace', 'perch', 'phase', 'phone',
    'photo', 'piece', 'pilot', 'pitch', 'place',
    'plain', 'plane', 'plant', 'plate', 'plaza',
    'point', 'polar', 'poll', 'pound', 'power',
    'press', 'price', 'pride', 'prime', 'print',
    'prior', 'prize', 'proof', 'proud', 'prove',
    'pupil', 'queen', 'query', 'quest', 'quick',
    'quiet', 'quite', 'quote', 'radar', 'radio',
    'raise', 'ranch', 'range', 'rapid', 'ratio',
    'reach', 'react', 'ready', 'realm', 'rebel',
    'refer', 'reign', 'relax', 'rely', 'renew',
    'reply', 'reset', 'rider', 'ridge', 'rifle',
    'right', 'rival', 'river', 'robin', 'robot',
    'rocky', 'roman', 'rough', 'round', 'route',
    'royal', 'ruler', 'rural', 'sadly', 'saint',
    'salad', 'sally', 'sandy', 'sarah', 'sauce',
    'scale', 'scene', 'scope', 'score', 'scout',
    'seize', 'sense', 'serve', 'setup', 'seven',
    'shall', 'shame', 'shape', 'share', 'sharp',
    'sheep', 'sheer', 'sheet', 'shelf', 'shell',
    'shift', 'shine', 'shiny', 'shirt', 'shock',
    'shoot', 'shore', 'short', 'shout', 'shown',
    'sight', 'silly', 'simon', 'since', 'sixth',
    'sixty', 'sized', 'skill', 'slave', 'sleep',
    'slide', 'slope', 'small', 'smart', 'smell',
    'smile', 'smith', 'smoke', 'snake', 'snow',
    'solid', 'solve', 'sorry', 'sound', 'south',
    'space', 'spare', 'spark', 'spawn', 'speak',
    'speed', 'spent', 'spill', 'spine', 'spite',
    'split', 'spoke', 'sport', 'spray', 'squad',
    'stack', 'staff', 'stage', 'stain', 'stake',
    'stamp', 'stand', 'stark', 'start', 'state',
    'steam', 'steel', 'steep', 'steer', 'stick',
    'stiff', 'still', 'stock', 'stone', 'stood',
    'stop', 'store', 'storm', 'story', 'stove',
    'strip', 'stuck', 'study', 'stuff', 'style',
    'sugar', 'suite', 'sunny', 'super', 'surge',
    'swamp', 'swarm', 'sweet', 'swell', 'swept',
    'swift', 'swing', 'sword', 'swore', 'sworn',
    'swing', 'table', 'taken', 'taste', 'taxes',
    'teach', 'teeth', 'tempo', 'tenth', 'terms',
    'thank', 'theme', 'thick', 'thief', 'thigh',
    'think', 'third', 'thirty', 'those', 'three',
    'threw', 'throw', 'thumb', 'tiger', 'tight',
    'timer', 'title', 'today', 'token', 'tonic',
    'topic', 'total', 'touch', 'tough', 'toward',
    'tower', 'trace', 'track', 'trade', 'train',
    'trait', 'trash', 'treat', 'trend', 'trial',
    'tribe', 'trick', 'tried', 'trill', 'truck',
    'truly', 'trump', 'trunk', 'trust', 'truth',
    'twice', 'twist', 'uncle', 'under', 'undue',
    'union', 'unite', 'unity', 'until', 'upper',
    'upset', 'urban', 'usage', 'usual', 'valid',
    'value', 'vapor', 'vault', 'venue', 'verse',
    'video', 'virus', 'visit', 'vital', 'vivid',
    'vocal', 'voice', 'volt', 'voter', 'wagon',
    'waist', 'waste', 'watch', 'water', 'weary',
    'weigh', 'weird', 'went', 'wept', 'whale',
    'wheel', 'where', 'which', 'while', 'white',
    'whole', 'whose', 'widow', 'width', 'wired',
    'woman', 'world', 'worry', 'worse', 'worst',
    'worth', 'would', 'wound', 'wrist', 'write',
    'wrong', 'wrote', 'yacht', 'yard', 'yearn',
    'yield', 'young', 'youth', 'zesty', 'zonal',
    'flutter', 'dart', 'android', 'widget', 'provider',
    'material', 'design', 'launcher', 'mobile', 'screen',
    'theme', 'color', 'button', 'keyboard', 'device',
    'battery', 'weather', 'timer', 'clock', 'calculator',
    'notes', 'flashlight', 'camera', 'settings', 'programming',
    'development', 'software', 'engineer', 'puzzle', 'word',
    'guess', 'letter', 'game', 'play', 'win',
    'lose', 'draw', 'score', 'level', 'skill',
    'quick', 'smart', 'fresh', 'clean', 'clear',
    'bright', 'dark', 'light', 'heavy', 'sharp',
  ];

  String _currentWord = '';
  List<WordleGuess> _guesses = [];
  String _currentGuess = '';
  int _maxGuesses = 6;
  bool _gameWon = false;
  bool _gameLost = false;

  String get testWord => _currentWord;
  void setTestWord(String word) {
    _currentWord = word.toLowerCase();
    notifyListeners();
  }

  void setTestGameWon(bool won) {
    _gameWon = won;
    notifyListeners();
  }

  Map<String, LetterStatus> _letterStatuses = {};

  int _wins = 0;
  int _losses = 0;

  List<WordleGameEntry> _history = [];
  static const int maxHistory = 10;

  bool get isInitialized => _isInitialized;
  String get currentWord => _currentWord;
  List<WordleGuess> get guesses => _guesses;
  String get currentGuess => _currentGuess;
  int get maxGuesses => _maxGuesses;
  int get currentAttempt => _guesses.length;
  bool get gameWon => _gameWon;
  bool get gameLost => _gameLost;
  bool get isGameOver => _gameWon || _gameLost;
  int get wins => _wins;
  int get losses => _losses;
  int get totalGames => _wins + _losses;
  List<WordleGameEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  Map<String, LetterStatus> get letterStatuses => _letterStatuses;

  bool get canGuess => !isGameOver && _currentGuess.length == 5 && currentAttempt < _maxGuesses;

  Future<void> init() async {
    _isInitialized = true;
    _initLetterStatuses();
    newGame();
    Global.loggerModel.info("Wordle initialized", source: "Wordle");
    notifyListeners();
  }

  void _initLetterStatuses() {
    _letterStatuses = {};
    for (var letter in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
      _letterStatuses[letter] = LetterStatus.unused;
    }
  }

  void refresh() {
    notifyListeners();
  }

  void newGame() {
    final fiveLetterWords = _words.where((w) => w.length == 5).toList();
    _currentWord = fiveLetterWords[_random.nextInt(fiveLetterWords.length)];
    _guesses = [];
    _currentGuess = '';
    _gameWon = false;
    _gameLost = false;
    _initLetterStatuses();
    Global.loggerModel.info("New Wordle game started with word: $_currentWord", source: "Wordle");
    notifyListeners();
  }

  void addLetter(String letter) {
    if (isGameOver) return;
    if (_currentGuess.length >= 5) return;
    _currentGuess += letter.toLowerCase();
    notifyListeners();
  }

  void removeLetter() {
    if (isGameOver) return;
    if (_currentGuess.isEmpty) return;
    _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
    notifyListeners();
  }

  void submitGuess() {
    if (!canGuess) return;

    final guess = _currentGuess.toLowerCase();
    final statuses = _evaluateGuess(guess);

    _guesses.add(WordleGuess(word: guess, statuses: statuses));

    _updateLetterStatuses(guess, statuses);

    if (guess == _currentWord) {
      _gameWon = true;
      _wins++;
      _addToHistory();
      Global.loggerModel.info("Player wins! Word: $_currentWord in ${_guesses.length} attempts", source: "Wordle");
    } else if (_guesses.length >= _maxGuesses) {
      _gameLost = true;
      _losses++;
      _addToHistory();
      Global.loggerModel.info("Player loses! Word: $_currentWord", source: "Wordle");
    }

    _currentGuess = '';
    notifyListeners();
  }

  List<LetterStatus> _evaluateGuess(String guess) {
    final result = List<LetterStatus>.filled(5, LetterStatus.absent);
    final wordChars = _currentWord.split('');
    final guessChars = guess.split('');
    final used = List<bool>.filled(5, false);

    for (int i = 0; i < 5; i++) {
      if (guessChars[i] == wordChars[i]) {
        result[i] = LetterStatus.correct;
        used[i] = true;
      }
    }

    for (int i = 0; i < 5; i++) {
      if (result[i] != LetterStatus.correct) {
        for (int j = 0; j < 5; j++) {
          if (!used[j] && guessChars[i] == wordChars[j]) {
            result[i] = LetterStatus.present;
            used[j] = true;
            break;
          }
        }
      }
    }

    return result;
  }

  void _updateLetterStatuses(String guess, List<LetterStatus> statuses) {
    for (int i = 0; i < 5; i++) {
      final letter = guess[i];
      final status = statuses[i];
      final currentStatus = _letterStatuses[letter] ?? LetterStatus.unused;

      if (status == LetterStatus.correct) {
        _letterStatuses[letter] = LetterStatus.correct;
      } else if (status == LetterStatus.present && currentStatus != LetterStatus.correct) {
        _letterStatuses[letter] = LetterStatus.present;
      } else if (status == LetterStatus.absent && currentStatus == LetterStatus.unused) {
        _letterStatuses[letter] = LetterStatus.absent;
      }
    }
  }

  void _addToHistory() {
    _history.insert(0, WordleGameEntry(
      won: _gameWon,
      word: _currentWord,
      attempts: _guesses.length,
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
    Global.loggerModel.info("Wordle stats reset", source: "Wordle");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("Wordle history cleared", source: "Wordle");
    notifyListeners();
  }

  double getWinRate() {
    if (totalGames == 0) return 0;
    return _wins / totalGames;
  }

  Color getLetterColor(BuildContext context, LetterStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case LetterStatus.correct:
        return Colors.green;
      case LetterStatus.present:
        return Colors.orange;
      case LetterStatus.absent:
        return colorScheme.surfaceContainerHighest;
      case LetterStatus.unused:
        return colorScheme.surfaceContainerLow;
    }
  }

  Color getLetterTextColor(BuildContext context, LetterStatus status) {
    switch (status) {
      case LetterStatus.correct:
      case LetterStatus.present:
        return Colors.white;
      case LetterStatus.absent:
      case LetterStatus.unused:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
}

class WordleCard extends StatefulWidget {
  @override
  State<WordleCard> createState() => _WordleCardState();
}

class _WordleCardState extends State<WordleCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final wordle = context.watch<WordleModel>();

    if (!wordle.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.text_fields, size: 24),
              SizedBox(width: 12),
              Text("Wordle: Loading..."),
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
                    Icon(Icons.text_fields, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Wordle",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (wordle.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.text_fields : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Game" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (wordle.hasHistory || wordle.totalGames > 0)
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
              _buildHistoryView(context, wordle)
            else
              _buildGameView(context, wordle),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView(BuildContext context, WordleModel wordle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGuessGrid(context, wordle),
        SizedBox(height: 12),
        if (wordle.isGameOver) ...[
          if (wordle.gameLost)
            Text(
              "The word was: ${wordle.currentWord.toUpperCase()}",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          SizedBox(height: 8),
          Text(
            wordle.gameWon ? "You Win!" : "Game Over",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: wordle.gameWon ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: wordle.newGame,
            icon: Icon(Icons.refresh, size: 18),
            label: Text("New Game"),
          ),
        ] else ...[
          _buildCurrentGuessRow(context, wordle),
          SizedBox(height: 12),
          _buildKeyboard(context, wordle),
        ],
        SizedBox(height: 12),
        _buildStatsRow(context, wordle),
      ],
    );
  }

  Widget _buildGuessGrid(BuildContext context, WordleModel wordle) {
    final rows = List<Widget>.generate(wordle.maxGuesses, (rowIndex) {
      if (rowIndex < wordle.guesses.length) {
        final guess = wordle.guesses[rowIndex];
        return _buildGuessRow(context, guess.word, guess.statuses);
      } else if (rowIndex == wordle.guesses.length) {
        return _buildEmptyRow(context, 5);
      } else {
        return _buildEmptyRow(context, 5);
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _buildGuessRow(BuildContext context, String word, List<LetterStatus> statuses) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return _buildLetterBox(
          context,
          word[i].toUpperCase(),
          statuses[i],
        );
      }),
    );
  }

  Widget _buildEmptyRow(BuildContext context, int length) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) => _buildEmptyBox(context)),
    );
  }

  Widget _buildLetterBox(BuildContext context, String letter, LetterStatus status) {
    final color = context.read<WordleModel>().getLetterColor(context, status);
    final textColor = context.read<WordleModel>().getLetterTextColor(context, status);

    return Container(
      width: 36,
      height: 36,
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBox(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildCurrentGuessRow(BuildContext context, WordleModel wordle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final letter = i < wordle.currentGuess.length
            ? wordle.currentGuess[i].toUpperCase()
            : '';
        return _buildCurrentLetterBox(context, letter);
      }),
    );
  }

  Widget _buildCurrentLetterBox(BuildContext context, String letter) {
    return Container(
      width: 36,
      height: 36,
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: letter.isEmpty
            ? Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: letter.isEmpty
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard(BuildContext context, WordleModel wordle) {
    final rows = [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['enter', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'del'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) => _buildKeyboardRow(context, wordle, row)).toList(),
    );
  }

  Widget _buildKeyboardRow(BuildContext context, WordleModel wordle, List<String> row) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: row.map((key) => _buildKeyboardKey(context, wordle, key)).toList(),
    );
  }

  Widget _buildKeyboardKey(BuildContext context, WordleModel wordle, String key) {
    final colorScheme = Theme.of(context).colorScheme;

    if (key == 'enter' || key == 'del') {
      return InkWell(
        onTap: () {
          if (key == 'enter') {
            wordle.submitGuess();
          } else {
            wordle.removeLetter();
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: key == 'enter' ? 50 : 36,
          height: 32,
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Icon(
              key == 'enter' ? Icons.check : Icons.backspace,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    }

    final status = wordle.letterStatuses[key] ?? LetterStatus.unused;
    final color = wordle.getLetterColor(context, status);
    final textColor = wordle.getLetterTextColor(context, status);

    return InkWell(
      onTap: () => wordle.addLetter(key),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 32,
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            key.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, WordleModel wordle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, "Wins", wordle.wins, Colors.green),
        _buildStatItem(context, "Losses", wordle.losses, Colors.red),
        _buildStatItem(context, "Rate", "${(wordle.getWinRate() * 100).toInt()}%", Theme.of(context).colorScheme.primary),
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

  Widget _buildHistoryView(BuildContext context, WordleModel wordle) {
    if (!wordle.hasHistory) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text("No games played yet", style: TextStyle(fontSize: 12)),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: wordle.history.length,
        itemBuilder: (context, index) {
          final entry = wordle.history[index];
          return _buildHistoryEntry(context, wordle, entry);
        },
      ),
    );
  }

  Widget _buildHistoryEntry(BuildContext context, WordleModel wordle, WordleGameEntry entry) {
    final timeAgo = _formatTimeAgo(entry.timestamp);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            entry.won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 16,
            color: entry.won ? Colors.green : Colors.red,
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
            "(${entry.attempts} attempts)",
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              context.read<WordleModel>().resetStats();
              context.read<WordleModel>().clearHistory();
              Navigator.pop(context);
            },
            child: Text("Reset"),
          ),
        ],
      ),
    );
  }
}