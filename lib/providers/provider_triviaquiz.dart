import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

TriviaQuizModel triviaQuizModel = TriviaQuizModel();

MyProvider providerTriviaQuiz = MyProvider(
    name: "TriviaQuiz",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'TriviaQuiz',
      keywords: 'trivia quiz knowledge question answer game science history geography sports entertainment fun facts learn',
      action: () => triviaQuizModel.requestFocus(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  triviaQuizModel.init();
  Global.infoModel.addInfoWidget(
      "TriviaQuiz",
      ChangeNotifierProvider.value(
          value: triviaQuizModel,
          builder: (context, child) => TriviaQuizCard()),
      title: "TriviaQuiz");
}

Future<void> _update() async {
  triviaQuizModel.refresh();
}

enum TriviaCategory {
  science,
  history,
  geography,
  sports,
  entertainment,
}

class TriviaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final TriviaCategory category;
  final String? explanation;

  TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
    this.explanation,
  });

  String get correctAnswer => options[correctIndex];
  
  bool checkAnswer(int selectedIndex) => selectedIndex == correctIndex;
}

class TriviaQuizEntry {
  final String question;
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;
  final TriviaCategory category;
  final DateTime timestamp;

  TriviaQuizEntry({
    required this.question,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.category,
    required this.timestamp,
  });

  String get resultText => isCorrect ? 'Correct' : 'Wrong';
}

// Trivia questions database
final List<TriviaQuestion> _triviaDatabase = [
  // Science questions
  TriviaQuestion(
    question: "What is the chemical symbol for gold?",
    options: ["Au", "Ag", "Fe", "Cu"],
    correctIndex: 0,
    category: TriviaCategory.science,
    explanation: "Au comes from the Latin word 'aurum'.",
  ),
  TriviaQuestion(
    question: "How many planets are in our solar system?",
    options: ["7", "8", "9", "10"],
    correctIndex: 1,
    category: TriviaCategory.science,
    explanation: "There are 8 planets after Pluto was reclassified.",
  ),
  TriviaQuestion(
    question: "What is the hardest natural substance on Earth?",
    options: ["Steel", "Titanium", "Diamond", "Quartz"],
    correctIndex: 2,
    category: TriviaCategory.science,
    explanation: "Diamond is the hardest known natural material.",
  ),
  TriviaQuestion(
    question: "What gas do plants absorb from the atmosphere?",
    options: ["Oxygen", "Nitrogen", "Carbon Dioxide", "Hydrogen"],
    correctIndex: 2,
    category: TriviaCategory.science,
    explanation: "Plants use CO2 in photosynthesis.",
  ),
  TriviaQuestion(
    question: "What is the speed of light in km/s?",
    options: ["150,000", "300,000", "450,000", "600,000"],
    correctIndex: 1,
    category: TriviaCategory.science,
    explanation: "Light travels at approximately 300,000 km/s.",
  ),
  TriviaQuestion(
    question: "What is the largest organ in the human body?",
    options: ["Heart", "Liver", "Skin", "Brain"],
    correctIndex: 2,
    category: TriviaCategory.science,
    explanation: "The skin is the largest organ by surface area.",
  ),
  TriviaQuestion(
    question: "What element has the atomic number 1?",
    options: ["Helium", "Hydrogen", "Oxygen", "Carbon"],
    correctIndex: 1,
    category: TriviaCategory.science,
    explanation: "Hydrogen is the first element on the periodic table.",
  ),
  TriviaQuestion(
    question: "What is the boiling point of water in Celsius?",
    options: ["90°C", "100°C", "110°C", "120°C"],
    correctIndex: 1,
    category: TriviaCategory.science,
    explanation: "Water boils at 100°C at standard pressure.",
  ),
  
  // History questions
  TriviaQuestion(
    question: "Who was the first President of the United States?",
    options: ["Thomas Jefferson", "John Adams", "George Washington", "Benjamin Franklin"],
    correctIndex: 2,
    category: TriviaCategory.history,
    explanation: "George Washington served from 1789-1797.",
  ),
  TriviaQuestion(
    question: "In which year did World War II end?",
    options: ["1943", "1944", "1945", "1946"],
    correctIndex: 2,
    category: TriviaCategory.history,
    explanation: "WWII ended in 1945 with Germany's surrender in May and Japan's in September.",
  ),
  TriviaQuestion(
    question: "Who painted the Mona Lisa?",
    options: ["Michelangelo", "Leonardo da Vinci", "Raphael", "Donatello"],
    correctIndex: 1,
    category: TriviaCategory.history,
    explanation: "Leonardo da Vinci painted it around 1503-1519.",
  ),
  TriviaQuestion(
    question: "What ancient civilization built the pyramids?",
    options: ["Romans", "Greeks", "Egyptians", "Persians"],
    correctIndex: 2,
    category: TriviaCategory.history,
    explanation: "The Egyptian pyramids were built as tombs for pharaohs.",
  ),
  TriviaQuestion(
    question: "Who discovered America in 1492?",
    options: ["Vasco da Gama", "Christopher Columbus", "Ferdinand Magellan", "Amerigo Vespucci"],
    correctIndex: 1,
    category: TriviaCategory.history,
    explanation: "Columbus reached the Americas on October 12, 1492.",
  ),
  TriviaQuestion(
    question: "What was the name of the first satellite in space?",
    options: ["Apollo", "Sputnik", "Explorer", "Voyager"],
    correctIndex: 1,
    category: TriviaCategory.history,
    explanation: "Sputnik 1 was launched by the USSR in 1957.",
  ),
  TriviaQuestion(
    question: "Who wrote the Declaration of Independence?",
    options: ["Benjamin Franklin", "John Adams", "Thomas Jefferson", "George Washington"],
    correctIndex: 2,
    category: TriviaCategory.history,
    explanation: "Thomas Jefferson was the primary author.",
  ),
  
  // Geography questions
  TriviaQuestion(
    question: "What is the largest continent by area?",
    options: ["Africa", "North America", "Asia", "Europe"],
    correctIndex: 2,
    category: TriviaCategory.geography,
    explanation: "Asia covers about 44.58 million km².",
  ),
  TriviaQuestion(
    question: "What is the longest river in the world?",
    options: ["Amazon", "Mississippi", "Nile", "Yangtze"],
    correctIndex: 2,
    category: TriviaCategory.geography,
    explanation: "The Nile is approximately 6,650 km long.",
  ),
  TriviaQuestion(
    question: "What country has the most population?",
    options: ["USA", "India", "China", "Russia"],
    correctIndex: 2,
    category: TriviaCategory.geography,
    explanation: "China has over 1.4 billion people.",
  ),
  TriviaQuestion(
    question: "What is the capital of Japan?",
    options: ["Osaka", "Kyoto", "Tokyo", "Nagoya"],
    correctIndex: 2,
    category: TriviaCategory.geography,
    explanation: "Tokyo has been Japan's capital since 1868.",
  ),
  TriviaQuestion(
    question: "What is the smallest country in the world?",
    options: ["Monaco", "San Marino", "Vatican City", "Liechtenstein"],
    correctIndex: 2,
    category: TriviaCategory.geography,
    explanation: "Vatican City is only 0.44 km².",
  ),
  TriviaQuestion(
    question: "What ocean is the largest?",
    options: ["Atlantic", "Indian", "Pacific", "Arctic"],
    correctIndex: 2,
    category: TriviaCategory.geography,
    explanation: "The Pacific Ocean covers about 165 million km².",
  ),
  TriviaQuestion(
    question: "What is the highest mountain in the world?",
    options: ["K2", "Mount Everest", "Mount Kilimanjaro", "Mount Fuji"],
    correctIndex: 1,
    category: TriviaCategory.geography,
    explanation: "Mount Everest is 8,848 meters tall.",
  ),
  
  // Sports questions
  TriviaQuestion(
    question: "How many players are on a soccer team?",
    options: ["9", "10", "11", "12"],
    correctIndex: 2,
    category: TriviaCategory.sports,
    explanation: "Each team has 11 players on the field.",
  ),
  TriviaQuestion(
    question: "What sport does Tiger Woods play?",
    options: ["Tennis", "Golf", "Basketball", "Football"],
    correctIndex: 1,
    category: TriviaCategory.sports,
    explanation: "Tiger Woods is a legendary golfer.",
  ),
  TriviaQuestion(
    question: "How many rings are on the Olympic flag?",
    options: ["4", "5", "6", "7"],
    correctIndex: 1,
    category: TriviaCategory.sports,
    explanation: "The five rings represent the five continents.",
  ),
  TriviaQuestion(
    question: "What country hosted the 2016 Summer Olympics?",
    options: ["China", "UK", "Brazil", "Japan"],
    correctIndex: 2,
    category: TriviaCategory.sports,
    explanation: "Rio de Janeiro, Brazil hosted in 2016.",
  ),
  TriviaQuestion(
    question: "What is the national sport of Japan?",
    options: ["Karate", "Judo", "Sumo", "Kendo"],
    correctIndex: 2,
    category: TriviaCategory.sports,
    explanation: "Sumo is considered Japan's national sport.",
  ),
  TriviaQuestion(
    question: "How many points is a touchdown in American football?",
    options: ["4", "5", "6", "7"],
    correctIndex: 2,
    category: TriviaCategory.sports,
    explanation: "A touchdown scores 6 points.",
  ),
  
  // Entertainment questions
  TriviaQuestion(
    question: "Who directed the movie 'Titanic'?",
    options: ["Steven Spielberg", "James Cameron", "Christopher Nolan", "Martin Scorsese"],
    correctIndex: 1,
    category: TriviaCategory.entertainment,
    explanation: "James Cameron directed Titanic in 1997.",
  ),
  TriviaQuestion(
    question: "What is the name of Harry Potter's owl?",
    options: ["Errol", "Hedwig", "Pigwidgeon", "Scabbers"],
    correctIndex: 1,
    category: TriviaCategory.entertainment,
    explanation: "Hedwig was Harry's snowy owl.",
  ),
  TriviaQuestion(
    question: "Who played Jack in the movie 'Titanic'?",
    options: ["Brad Pitt", "Leonardo DiCaprio", "Tom Hanks", "Johnny Depp"],
    correctIndex: 1,
    category: TriviaCategory.entertainment,
    explanation: "Leonardo DiCaprio played Jack Dawson.",
  ),
  TriviaQuestion(
    question: "What animated movie features a clownfish named Nemo?",
    options: ["Shark Tale", "Finding Nemo", "The Little Mermaid", "Moana"],
    correctIndex: 1,
    category: TriviaCategory.entertainment,
    explanation: "Finding Nemo was released by Pixar in 2003.",
  ),
  TriviaQuestion(
    question: "How many Harry Potter books are there?",
    options: ["5", "6", "7", "8"],
    correctIndex: 2,
    category: TriviaCategory.entertainment,
    explanation: "J.K. Rowling wrote 7 Harry Potter books.",
  ),
  TriviaQuestion(
    question: "What is the highest-grossing film of all time?",
    options: ["Titanic", "Avatar", "Avengers: Endgame", "Star Wars"],
    correctIndex: 1,
    category: TriviaCategory.entertainment,
    explanation: "Avatar (2009) earned over 2.8 billion dollars.",
  ),
  TriviaQuestion(
    question: "Who wrote the song 'Bohemian Rhapsody'?",
    options: ["The Beatles", "Led Zeppelin", "Queen", "Pink Floyd"],
    correctIndex: 2,
    category: TriviaCategory.entertainment,
    explanation: "Freddie Mercury of Queen wrote this song.",
  ),
];

class TriviaQuizModel extends ChangeNotifier {
  static const int maxHistory = 20;

  TriviaCategory? _selectedCategory;
  TriviaQuestion? _currentQuestion;
  int? _selectedAnswer;
  bool? _answerSubmitted;
  int _correctCount = 0;
  int _totalAttempts = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  final List<TriviaQuizEntry> _history = [];
  Timer? _timer;
  int _timeLimit = 0;
  int _timeRemaining = 0;
  bool _timerActive = false;
  bool _isInitialized = false;
  bool _focusRequested = false;
  bool _showHistory = false;
  final Random _random = Random();

  TriviaCategory? get selectedCategory => _selectedCategory;
  TriviaQuestion? get currentQuestion => _currentQuestion;
  int? get selectedAnswer => _selectedAnswer;
  bool? get answerSubmitted => _answerSubmitted;
  int get correctCount => _correctCount;
  int get totalAttempts => _totalAttempts;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  List<TriviaQuizEntry> get history => List.unmodifiable(_history);
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
    generateNewQuestion();
    Global.loggerModel.info("TriviaQuiz initialized with ${_triviaDatabase.length} questions", source: "TriviaQuiz");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setCategory(TriviaCategory? category) {
    _selectedCategory = category;
    generateNewQuestion();
    Global.loggerModel.info("Category set to ${category?.name ?? 'All'}", source: "TriviaQuiz");
    notifyListeners();
  }

  void setTimeLimit(int seconds) {
    _timeLimit = seconds;
    if (_timerActive) {
      _stopTimer();
    }
    if (seconds > 0 && _currentQuestion != null) {
      _timeRemaining = seconds;
      _startTimer();
    }
    notifyListeners();
  }

  void generateNewQuestion() {
    List<TriviaQuestion> availableQuestions;
    
    if (_selectedCategory != null) {
      availableQuestions = _triviaDatabase
          .where((q) => q.category == _selectedCategory)
          .toList();
    } else {
      availableQuestions = _triviaDatabase;
    }
    
    if (availableQuestions.isEmpty) {
      _currentQuestion = null;
      notifyListeners();
      return;
    }
    
    _currentQuestion = availableQuestions[_random.nextInt(availableQuestions.length)];
    _selectedAnswer = null;
    _answerSubmitted = null;

    if (_timeLimit > 0) {
      _timeRemaining = _timeLimit;
      _startTimer();
    }

    Global.loggerModel.info("Generated question: ${_currentQuestion!.question}", source: "TriviaQuiz");
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
        _recordAnswer(-1, false);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerActive = false;
  }

  void selectAnswer(int index) {
    if (_answerSubmitted != null) return;
    _selectedAnswer = index;
    notifyListeners();
  }

  void submitAnswer() {
    if (_currentQuestion == null || _selectedAnswer == null || _answerSubmitted != null) return;

    _stopTimer();
    final isCorrect = _currentQuestion!.checkAnswer(_selectedAnswer!);
    _answerSubmitted = isCorrect;
    _recordAnswer(_selectedAnswer!, isCorrect);
    notifyListeners();
  }

  void _recordAnswer(int selectedIndex, bool isCorrect) {
    if (_currentQuestion == null) return;

    _totalAttempts++;

    final entry = TriviaQuizEntry(
      question: _currentQuestion!.question,
      correctAnswer: _currentQuestion!.correctAnswer,
      userAnswer: selectedIndex >= 0 ? _currentQuestion!.options[selectedIndex] : "No Answer",
      isCorrect: isCorrect,
      category: _currentQuestion!.category,
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
      "Answer: ${selectedIndex >= 0 ? _currentQuestion!.options[selectedIndex] : 'Timeout'}, Correct: ${_currentQuestion!.correctAnswer}, Result: ${isCorrect ? 'Correct' : 'Wrong'}",
      source: "TriviaQuiz",
    );

    notifyListeners();
  }

  void nextQuestion() {
    generateNewQuestion();
  }

  void skipQuestion() {
    if (_currentQuestion == null) return;

    _stopTimer();
    _recordAnswer(-1, false);
    generateNewQuestion();
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
    Global.loggerModel.info("TriviaQuiz history cleared", source: "TriviaQuiz");
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
    _selectedCategory = null;
    generateNewQuestion();
    Global.loggerModel.info("TriviaQuiz reset", source: "TriviaQuiz");
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

  String getCategoryName(TriviaCategory category) {
    switch (category) {
      case TriviaCategory.science:
        return 'Science 🔬';
      case TriviaCategory.history:
        return 'History 📜';
      case TriviaCategory.geography:
        return 'Geography 🌍';
      case TriviaCategory.sports:
        return 'Sports ⚽';
      case TriviaCategory.entertainment:
        return 'Entertainment 🎬';
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

class TriviaQuizCard extends StatefulWidget {
  @override
  State<TriviaQuizCard> createState() => _TriviaQuizCardState();
}

class _TriviaQuizCardState extends State<TriviaQuizCard> {
  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<TriviaQuizModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!quiz.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.quiz, size: 24),
              SizedBox(width: 12),
              Text("TriviaQuiz: Loading..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.quiz, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Trivia Quiz",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(quiz.showHistory ? Icons.quiz : Icons.history, size: 18),
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
                _buildHistoryView(quiz, colorScheme)
              else
                _buildMainView(quiz, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(TriviaQuizModel quiz, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCategorySelector(quiz, colorScheme),
        SizedBox(height: 12),
        _buildTimeSelector(quiz, colorScheme),
        SizedBox(height: 16),
        if (quiz.currentQuestion != null)
          _buildQuestionView(quiz, colorScheme),
        SizedBox(height: 16),
        _buildStatsRow(quiz, colorScheme),
      ],
    );
  }

  Widget _buildCategorySelector(TriviaQuizModel quiz, ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ActionChip(
          label: Text("All"),
          onPressed: () => quiz.setCategory(null),
          backgroundColor: quiz.selectedCategory == null ? colorScheme.primaryContainer : null,
        ),
        ActionChip(
          label: Text("Science 🔬"),
          onPressed: () => quiz.setCategory(TriviaCategory.science),
          backgroundColor: quiz.selectedCategory == TriviaCategory.science ? colorScheme.primaryContainer : null,
        ),
        ActionChip(
          label: Text("History 📜"),
          onPressed: () => quiz.setCategory(TriviaCategory.history),
          backgroundColor: quiz.selectedCategory == TriviaCategory.history ? colorScheme.primaryContainer : null,
        ),
        ActionChip(
          label: Text("Geography 🌍"),
          onPressed: () => quiz.setCategory(TriviaCategory.geography),
          backgroundColor: quiz.selectedCategory == TriviaCategory.geography ? colorScheme.primaryContainer : null,
        ),
        ActionChip(
          label: Text("Sports ⚽"),
          onPressed: () => quiz.setCategory(TriviaCategory.sports),
          backgroundColor: quiz.selectedCategory == TriviaCategory.sports ? colorScheme.primaryContainer : null,
        ),
        ActionChip(
          label: Text("Entertainment 🎬"),
          onPressed: () => quiz.setCategory(TriviaCategory.entertainment),
          backgroundColor: quiz.selectedCategory == TriviaCategory.entertainment ? colorScheme.primaryContainer : null,
        ),
      ],
    );
  }

  Widget _buildTimeSelector(TriviaQuizModel quiz, ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      children: [
        ActionChip(
          label: Text("No Timer"),
          onPressed: () => quiz.setTimeLimit(0),
          backgroundColor: quiz.timeLimit == 0 ? colorScheme.primaryContainer : null,
        ),
        ActionChip(
          label: Text("15s"),
          onPressed: () => quiz.setTimeLimit(15),
          backgroundColor: quiz.timeLimit == 15 ? colorScheme.primaryContainer : null,
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

  Widget _buildQuestionView(TriviaQuizModel quiz, ColorScheme colorScheme) {
    final question = quiz.currentQuestion!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quiz.getCategoryName(question.category),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (quiz.timerActive)
                Row(
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
            ],
          ),
          SizedBox(height: 12),
          Text(
            question.question,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = quiz.selectedAnswer == index;
            final showResult = quiz.answerSubmitted != null;
            
            Color backgroundColor = colorScheme.surface;
            Color textColor = colorScheme.onSurface;
            IconData? trailingIcon;
            
            if (showResult) {
              if (index == question.correctIndex) {
                backgroundColor = colorScheme.primaryContainer;
                textColor = colorScheme.onPrimaryContainer;
                trailingIcon = Icons.check_circle;
              } else if (isSelected && !quiz.answerSubmitted!) {
                backgroundColor = colorScheme.errorContainer;
                textColor = colorScheme.onErrorContainer;
                trailingIcon = Icons.cancel;
              }
            } else if (isSelected) {
              backgroundColor = colorScheme.secondaryContainer;
              textColor = colorScheme.onSecondaryContainer;
            }
            
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: showResult ? null : () => quiz.selectAnswer(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (trailingIcon != null)
                        Icon(trailingIcon, color: textColor, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (quiz.answerSubmitted != null && question.explanation != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, size: 16, color: colorScheme.onTertiaryContainer),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.explanation!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 12),
          if (quiz.answerSubmitted == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.skip_next, size: 18),
                  label: Text("Skip"),
                  onPressed: () => quiz.skipQuestion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.check, size: 18),
                  label: Text("Submit"),
                  onPressed: quiz.selectedAnswer != null ? () {
                    quiz.submitAnswer();
                  } : null,
                ),
              ],
            )
          else
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_forward, size: 18),
              label: Text("Next Question"),
              onPressed: () => quiz.nextQuestion(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(TriviaQuizModel quiz, ColorScheme colorScheme) {
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

  Widget _buildHistoryView(TriviaQuizModel quiz, ColorScheme colorScheme) {
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
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "Your: ${entry.userAnswer} | Correct: ${entry.correctAnswer}",
                    style: TextStyle(
                      fontSize: 11,
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
        content: Text("Clear all trivia quiz history and reset statistics?"),
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
      context.read<TriviaQuizModel>().clearHistory();
    }
  }
}