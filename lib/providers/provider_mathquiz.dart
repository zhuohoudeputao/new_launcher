import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

MathQuizModel mathQuizModel = MathQuizModel();

MyProvider providerMathQuiz = MyProvider(
    name: "MathQuiz",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'MathQuiz',
      keywords: 'math quiz arithmetic mental calculate addition subtraction multiplication division practice',
      action: () => mathQuizModel.requestFocus(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  mathQuizModel.init();
  Global.infoModel.addInfoWidget(
      "MathQuiz",
      ChangeNotifierProvider.value(
          value: mathQuizModel,
          builder: (context, child) => MathQuizCard()),
      title: "MathQuiz");
}

Future<void> _update() async {
  mathQuizModel.refresh();
}

enum MathDifficulty {
  easy,
  medium,
  hard,
}

enum MathOperation {
  addition,
  subtraction,
  multiplication,
  division,
}

class MathProblem {
  final int a;
  final int b;
  final MathOperation operation;
  final int answer;

  MathProblem(this.a, this.b, this.operation, this.answer);

  String get operationSymbol {
    switch (operation) {
      case MathOperation.addition:
        return '+';
      case MathOperation.subtraction:
        return '-';
      case MathOperation.multiplication:
        return '×';
      case MathOperation.division:
        return '÷';
    }
  }

  String get questionString => '$a $operationSymbol $b = ?';

  bool checkAnswer(int userAnswer) => userAnswer == answer;
}

class MathQuizEntry {
  final String question;
  final int correctAnswer;
  final int userAnswer;
  final bool isCorrect;
  final DateTime timestamp;

  MathQuizEntry({
    required this.question,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.timestamp,
  });

  String get resultText => isCorrect ? 'Correct' : 'Wrong';
}

class MathQuizModel extends ChangeNotifier {
  static const int maxHistory = 20;

  MathDifficulty _difficulty = MathDifficulty.easy;
  MathProblem? _currentProblem;
  String _userInput = '';
  int _correctCount = 0;
  int _totalAttempts = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  final List<MathQuizEntry> _history = [];
  Timer? _timer;
  int _timeLimit = 0;
  int _timeRemaining = 0;
  bool _timerActive = false;
  bool _isInitialized = false;
  bool _focusRequested = false;
  bool _showHistory = false;

  MathDifficulty get difficulty => _difficulty;
  MathProblem? get currentProblem => _currentProblem;
  String get userInput => _userInput;
  int get correctCount => _correctCount;
  int get totalAttempts => _totalAttempts;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  List<MathQuizEntry> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  bool get isInitialized => _isInitialized;
  bool get shouldFocus => _focusRequested;
  bool get showHistory => _showHistory;
  int get timeRemaining => _timeRemaining;
  bool get timerActive => _timerActive;
  int get timeLimit => _timeLimit;
  double get accuracy => _totalAttempts > 0 ? (_correctCount / _totalAttempts) * 100 : 0;

  void init() {
    _isInitialized = true;
    generateNewProblem();
    Global.loggerModel.info("MathQuiz initialized", source: "MathQuiz");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setDifficulty(MathDifficulty difficulty) {
    _difficulty = difficulty;
    generateNewProblem();
    Global.loggerModel.info("Difficulty set to ${difficulty.name}", source: "MathQuiz");
    notifyListeners();
  }

  void setTimeLimit(int seconds) {
    _timeLimit = seconds;
    if (_timerActive) {
      _stopTimer();
    }
    if (seconds > 0 && _currentProblem != null) {
      _timeRemaining = seconds;
      _startTimer();
    }
    notifyListeners();
  }

  void generateNewProblem() {
    final random = Random();
    int a, b;
    MathOperation operation;

    final operations = [
      MathOperation.addition,
      MathOperation.subtraction,
      MathOperation.multiplication,
      MathOperation.division,
    ];

    operation = operations[random.nextInt(operations.length)];

    switch (_difficulty) {
      case MathDifficulty.easy:
        a = random.nextInt(10) + 1;
        b = random.nextInt(10) + 1;
        if (operation == MathOperation.subtraction && a < b) {
          final temp = a;
          a = b;
          b = temp;
        }
        if (operation == MathOperation.division) {
          b = random.nextInt(5) + 1;
          a = b * (random.nextInt(5) + 1);
        }
        break;
      case MathDifficulty.medium:
        a = random.nextInt(50) + 1;
        b = random.nextInt(50) + 1;
        if (operation == MathOperation.subtraction && a < b) {
          final temp = a;
          a = b;
          b = temp;
        }
        if (operation == MathOperation.division) {
          b = random.nextInt(10) + 1;
          a = b * (random.nextInt(10) + 1);
        }
        break;
      case MathDifficulty.hard:
        a = random.nextInt(100) + 1;
        b = random.nextInt(100) + 1;
        if (operation == MathOperation.subtraction && a < b) {
          final temp = a;
          a = b;
          b = temp;
        }
        if (operation == MathOperation.division) {
          b = random.nextInt(12) + 1;
          a = b * (random.nextInt(12) + 1);
        }
        if (operation == MathOperation.multiplication) {
          a = random.nextInt(20) + 1;
          b = random.nextInt(20) + 1;
        }
        break;
    }

    int answer;
    switch (operation) {
      case MathOperation.addition:
        answer = a + b;
        break;
      case MathOperation.subtraction:
        answer = a - b;
        break;
      case MathOperation.multiplication:
        answer = a * b;
        break;
      case MathOperation.division:
        answer = a ~/ b;
        break;
    }

    _currentProblem = MathProblem(a, b, operation, answer.toInt());
    _userInput = '';

    if (_timeLimit > 0) {
      _timeRemaining = _timeLimit;
      _startTimer();
    }

    Global.loggerModel.info("Generated problem: ${_currentProblem!.questionString}", source: "MathQuiz");
    notifyListeners();
  }

  void _startTimer() {
    _timerActive = true;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        _timeRemaining--;
        notifyListeners();
      } else {
        _stopTimer();
        _recordAnswer(0, false);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerActive = false;
  }

  void updateInput(String input) {
    _userInput = input.replaceAll(RegExp(r'[^\d]'), '');
    notifyListeners();
  }

  void submitAnswer() {
    if (_currentProblem == null || _userInput.isEmpty) return;

    final userAnswer = int.tryParse(_userInput) ?? 0;
    final isCorrect = _currentProblem!.checkAnswer(userAnswer);

    _stopTimer();
    _recordAnswer(userAnswer, isCorrect);
  }

  void _recordAnswer(int userAnswer, bool isCorrect) {
    if (_currentProblem == null) return;

    _totalAttempts++;

    final entry = MathQuizEntry(
      question: _currentProblem!.questionString,
      correctAnswer: _currentProblem!.answer,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    );

    _history.insert(0, entry);
    if (_history.length > maxHistory) {
      _history.removeLast();
    }

    if (isCorrect) {
      _correctCount++;
      _currentStreak++;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }

    Global.loggerModel.info(
      "Answer: $userAnswer, Correct: ${_currentProblem!.answer}, Result: ${isCorrect ? 'Correct' : 'Wrong'}",
      source: "MathQuiz",
    );

    notifyListeners();
  }

  void nextProblem() {
    generateNewProblem();
  }

  void skipProblem() {
    if (_currentProblem == null) return;

    _stopTimer();
    _recordAnswer(0, false);
    generateNewProblem();
  }

  void toggleHistory() {
    _showHistory = !_showHistory;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _correctCount = 0;
    _totalAttempts = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    Global.loggerModel.info("MathQuiz history cleared", source: "MathQuiz");
    notifyListeners();
  }

  void reset() {
    _stopTimer();
    _correctCount = 0;
    _totalAttempts = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _history.clear();
    _timeLimit = 0;
    _timeRemaining = 0;
    generateNewProblem();
    Global.loggerModel.info("MathQuiz reset", source: "MathQuiz");
    notifyListeners();
  }

  void requestFocus() {
    _focusRequested = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _focusRequested = false;
      notifyListeners();
    });
  }

  String getDifficultyName() {
    switch (_difficulty) {
      case MathDifficulty.easy:
        return 'Easy';
      case MathDifficulty.medium:
        return 'Medium';
      case MathDifficulty.hard:
        return 'Hard';
    }
  }

  String formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class MathQuizCard extends StatefulWidget {
  @override
  State<MathQuizCard> createState() => _MathQuizCardState();
}

class _MathQuizCardState extends State<MathQuizCard> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      context.read<MathQuizModel>().updateInput(_inputController.text);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<MathQuizModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!quiz.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.calculate, size: 24),
              SizedBox(width: 12),
              Text("MathQuiz: Loading..."),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Math Quiz",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(quiz.showHistory ? Icons.calculate : Icons.history, size: 18),
                      onPressed: () => quiz.toggleHistory(),
                      tooltip: quiz.showHistory ? "Quiz" : "History",
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (quiz.hasHistory)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearHistoryConfirmation(context),
                        tooltip: "Clear history",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            if (quiz.showHistory)
              _buildHistoryView(quiz)
            else
              _buildMainView(quiz),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView(MathQuizModel quiz) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDifficultySelector(quiz),
        SizedBox(height: 12),
        _buildTimeSelector(quiz),
        SizedBox(height: 16),
        if (quiz.currentProblem != null)
          _buildProblemView(quiz),
        SizedBox(height: 16),
        _buildStatsRow(quiz),
      ],
    );
  }

  Widget _buildDifficultySelector(MathQuizModel quiz) {
    return SegmentedButton<MathDifficulty>(
      segments: [
        ButtonSegment(
          value: MathDifficulty.easy,
          label: Text("Easy"),
        ),
        ButtonSegment(
          value: MathDifficulty.medium,
          label: Text("Medium"),
        ),
        ButtonSegment(
          value: MathDifficulty.hard,
          label: Text("Hard"),
        ),
      ],
      selected: {quiz.difficulty},
      onSelectionChanged: (Set<MathDifficulty> newSelection) {
        quiz.setDifficulty(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
      ),
    );
  }

  Widget _buildTimeSelector(MathQuizModel quiz) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      children: [
        ActionChip(
          label: Text("No Timer"),
          onPressed: () => quiz.setTimeLimit(0),
          backgroundColor: quiz.timeLimit == 0 ? colorScheme.primaryContainer : null,
        ),
        ActionChip(
          label: Text("10s"),
          onPressed: () => quiz.setTimeLimit(10),
          backgroundColor: quiz.timeLimit == 10 ? colorScheme.primaryContainer : null,
        ),
        ActionChip(
          label: Text("30s"),
          onPressed: () => quiz.setTimeLimit(30),
          backgroundColor: quiz.timeLimit == 30 ? colorScheme.primaryContainer : null,
        ),
        ActionChip(
          label: Text("60s"),
          onPressed: () => quiz.setTimeLimit(60),
          backgroundColor: quiz.timeLimit == 60 ? colorScheme.primaryContainer : null,
        ),
      ],
    );
  }

  Widget _buildProblemView(MathQuizModel quiz) {
    final colorScheme = Theme.of(context).colorScheme;
    final problem = quiz.currentProblem!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quiz.timerActive)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 16, color: quiz.timeRemaining <= 5 ? colorScheme.error : colorScheme.onSurfaceVariant),
                  SizedBox(width: 4),
                  Text(
                    "${quiz.timeRemaining}s",
                    style: TextStyle(
                      color: quiz.timeRemaining <= 5 ? colorScheme.error : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            problem.questionString,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _inputController,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
            decoration: InputDecoration(
              hintText: "Enter answer",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onSubmitted: (_) {
              quiz.submitAnswer();
              _inputController.clear();
              quiz.nextProblem();
              _focusNode.requestFocus();
            },
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.skip_next, size: 18),
                label: Text("Skip"),
                onPressed: () {
                  quiz.skipProblem();
                  _inputController.clear();
                  _focusNode.requestFocus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.check, size: 18),
                label: Text("Submit"),
                onPressed: () {
                  quiz.submitAnswer();
                  _inputController.clear();
                  quiz.nextProblem();
                  _focusNode.requestFocus();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(MathQuizModel quiz) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          "Correct",
          "${quiz.correctCount}",
          Icons.check_circle,
          colorScheme.primary,
          colorScheme.onSurfaceVariant,
        ),
        _buildStatItem(
          "Accuracy",
          "${quiz.accuracy.round()}%",
          Icons.percent,
          colorScheme.secondary,
          colorScheme.onSurfaceVariant,
        ),
        _buildStatItem(
          "Streak",
          "${quiz.currentStreak}",
          Icons.local_fire_department,
          quiz.currentStreak >= 5 ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
          colorScheme.onSurfaceVariant,
        ),
        _buildStatItem(
          "Best",
          "${quiz.bestStreak}",
          Icons.emoji_events,
          colorScheme.tertiary,
          colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, Color labelColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(MathQuizModel quiz) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "History (${quiz.correctCount}/${quiz.totalAttempts})",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: quiz.history.length,
              itemBuilder: (context, index) {
                final entry = quiz.history[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    entry.isCorrect ? Icons.check_circle : Icons.cancel,
                    size: 20,
                    color: entry.isCorrect ? colorScheme.primary : colorScheme.error,
                  ),
                  title: Text(
                    entry.question,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Your: ${entry.userAnswer} | Correct: ${entry.correctAnswer}",
                    style: TextStyle(
                      color: entry.isCorrect ? colorScheme.onSurfaceVariant : colorScheme.error,
                    ),
                  ),
                  trailing: Text(
                    quiz.formatTimeAgo(entry.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all quiz history and reset statistics?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Clear"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<MathQuizModel>().clearHistory();
    }
  }
}