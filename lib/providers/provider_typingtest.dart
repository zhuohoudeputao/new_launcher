import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

TypingTestModel typingTestModel = TypingTestModel();

MyProvider providerTypingTest = MyProvider(
    name: "TypingTest",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'TypingTest',
      keywords: 'typing test speed wpm words per minute type keyboard fast accuracy',
      action: () => typingTestModel.requestFocus(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  typingTestModel.init();
  Global.infoModel.addInfoWidget(
      "TypingTest",
      ChangeNotifierProvider.value(
          value: typingTestModel,
          builder: (context, child) => TypingTestCard()),
      title: "TypingTest");
}

Future<void> _update() async {
  typingTestModel.refresh();
}

class TypingTestModel extends ChangeNotifier {
  static const int maxHistory = 10;

  static const List<String> sampleTexts = [
    "The quick brown fox jumps over the lazy dog near the river bank.",
    "Programming is both an art and a science that requires patience.",
    "Flutter makes it easy to build beautiful mobile applications.",
    "Practice makes perfect when learning new skills every day.",
    "Technology changes rapidly so we must adapt quickly.",
    "Reading books helps expand knowledge and vocabulary daily.",
    "Writing clean code is essential for maintainable software.",
    "A journey of a thousand miles begins with a single step.",
    "Success comes to those who work hard and stay focused.",
    "Learning to type faster can save valuable time each day.",
  ];

  TypingTestState _state = TypingTestState.ready;
  String _currentText = '';
  String _typedText = '';
  DateTime? _startTime;
  int _elapsedSeconds = 0;
  double _wpm = 0;
  double _accuracy = 0;
  int _errors = 0;
  final List<TypingTestResult> _history = [];
  Timer? _timer;
  bool _isInitialized = false;
  bool _focusRequested = false;

  TypingTestState get state => _state;
  String get currentText => _currentText;
  String get typedText => _typedText;
  int get elapsedSeconds => _elapsedSeconds;
  double get wpm => _wpm;
  double get accuracy => _accuracy;
  int get errors => _errors;
  List<TypingTestResult> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  bool get isInitialized => _isInitialized;
  bool get shouldFocus => _focusRequested;

  void init() {
    _isInitialized = true;
    _currentText = sampleTexts[Random().nextInt(sampleTexts.length)];
    Global.loggerModel.info("TypingTest initialized", source: "TypingTest");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void requestFocus() {
    _focusRequested = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _focusRequested = false;
    });
  }

  void startTest() {
    _state = TypingTestState.typing;
    _typedText = '';
    _startTime = DateTime.now();
    _elapsedSeconds = 0;
    _wpm = 0;
    _accuracy = 100;
    _errors = 0;
    _currentText = sampleTexts[Random().nextInt(sampleTexts.length)];

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _calculateStats();
      notifyListeners();
    });

    Global.loggerModel.info("Typing test started", source: "TypingTest");
    requestFocus();
    notifyListeners();
  }

  void updateTypedText(String text) {
    if (_state != TypingTestState.typing) return;

    _typedText = text;

    _errors = 0;
    for (int i = 0; i < _typedText.length && i < _currentText.length; i++) {
      if (_typedText[i] != _currentText[i]) {
        _errors++;
      }
    }

    _calculateStats();

    if (_typedText.length >= _currentText.length) {
      finishTest();
    }

    notifyListeners();
  }

  void _calculateStats() {
    if (_startTime == null || _elapsedSeconds == 0) return;

    final wordsTyped = _typedText.split(' ').where((w) => w.isNotEmpty).length;
    final minutes = _elapsedSeconds / 60.0;
    _wpm = minutes > 0 ? (wordsTyped / minutes).roundToDouble() : 0;

    if (_typedText.isNotEmpty) {
      final correctChars = _typedText.length - _errors;
      _accuracy = (correctChars / _typedText.length * 100).roundToDouble();
    }
  }

  void finishTest() {
    if (_state != TypingTestState.typing) return;

    _timer?.cancel();
    _timer = null;
    _state = TypingTestState.finished;

    _calculateStats();

    final result = TypingTestResult(
      wpm: _wpm,
      accuracy: _accuracy,
      errors: _errors,
      durationSeconds: _elapsedSeconds,
      timestamp: DateTime.now(),
    );

    _addToHistory(result);

    Global.loggerModel.info(
      "Typing test finished: ${_wpm.toStringAsFixed(1)} WPM, ${_accuracy.toStringAsFixed(1)}% accuracy",
      source: "TypingTest",
    );
    notifyListeners();
  }

  void _addToHistory(TypingTestResult result) {
    _history.insert(0, result);
    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void resetTest() {
    _timer?.cancel();
    _timer = null;
    _state = TypingTestState.ready;
    _typedText = '';
    _startTime = null;
    _elapsedSeconds = 0;
    _wpm = 0;
    _accuracy = 100;
    _errors = 0;
    _currentText = sampleTexts[Random().nextInt(sampleTexts.length)];
    Global.loggerModel.info("Typing test reset", source: "TypingTest");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("Typing test history cleared", source: "TypingTest");
    notifyListeners();
  }

  String getCharacterStatus(int index) {
    if (index >= _typedText.length) return 'pending';
    if (index >= _currentText.length) return 'extra';
    if (_typedText[index] == _currentText[index]) return 'correct';
    return 'incorrect';
  }

  double getBestWpm() {
    if (_history.isEmpty) return 0;
    return _history.map((r) => r.wpm).reduce((a, b) => a > b ? a : b);
  }

  double getAverageWpm() {
    if (_history.isEmpty) return 0;
    return _history.map((r) => r.wpm).reduce((a, b) => a + b) / _history.length;
  }
}

enum TypingTestState { ready, typing, finished }

class TypingTestResult {
  final double wpm;
  final double accuracy;
  final int errors;
  final int durationSeconds;
  final DateTime timestamp;

  TypingTestResult({
    required this.wpm,
    required this.accuracy,
    required this.errors,
    required this.durationSeconds,
    required this.timestamp,
  });
}

class TypingTestCard extends StatelessWidget {
  const TypingTestCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TypingTestModel>(
      builder: (context, model, child) {
        if (!model.isInitialized) {
          return Card.filled(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text("Loading TypingTest...", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          );
        }

        return Card.filled(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.keyboard, size: 20, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text("Typing Test", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Spacer(),
                    if (model.state == TypingTestState.ready)
                      TextButton.icon(
                        icon: Icon(Icons.play_arrow, size: 18),
                        label: Text("Start"),
                        onPressed: () => model.startTest(),
                      ),
                  ],
                ),
                SizedBox(height: 12),

                if (model.state == TypingTestState.ready)
                  _buildReadyState(context, model),
                if (model.state == TypingTestState.typing)
                  _buildTypingState(context, model),
                if (model.state == TypingTestState.finished)
                  _buildFinishedState(context, model),

                if (model.hasHistory) _buildHistorySection(context, model),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadyState(BuildContext context, TypingTestModel model) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Sample text to type:", style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            model.currentText,
            style: TextStyle(fontSize: 14, letterSpacing: 0.5),
          ),
        ),
        SizedBox(height: 12),
        Text("Click Start and type the text above as fast as you can!", 
          style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTypingState(BuildContext context, TypingTestModel model) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatBox(context, "Time", "${model.elapsedSeconds}s", Colors.blue),
            _buildStatBox(context, "WPM", "${model.wpm.toStringAsFixed(0)}", Theme.of(context).colorScheme.primary),
            _buildStatBox(context, "Accuracy", "${model.accuracy.toStringAsFixed(0)}%", Colors.green),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: RichText(
            text: TextSpan(
              children: _buildTextSpans(context, model),
              style: TextStyle(fontSize: 14, letterSpacing: 0.5, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          autofocus: model.shouldFocus,
          onChanged: (text) => model.updateTypedText(text),
          decoration: InputDecoration(
            hintText: "Type here...",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context, TypingTestModel model) {
    final spans = <TextSpan>[];
    final text = model.currentText;

    for (int i = 0; i < text.length; i++) {
      final status = model.getCharacterStatus(i);
      Color color;

      switch (status) {
        case 'correct':
          color = Colors.green;
          break;
        case 'incorrect':
          color = Colors.red;
          break;
        case 'pending':
          color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
          break;
        default:
          color = Colors.orange;
      }

      spans.add(TextSpan(
        text: text[i],
        style: TextStyle(color: color),
      ));
    }

    return spans;
  }

  Widget _buildFinishedState(BuildContext context, TypingTestModel model) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 48, color: Colors.green),
        SizedBox(height: 8),
        Text("Test Complete!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatBox(context, "WPM", "${model.wpm.toStringAsFixed(1)}", Theme.of(context).colorScheme.primary),
            _buildStatBox(context, "Accuracy", "${model.accuracy.toStringAsFixed(1)}%", Colors.green),
            _buildStatBox(context, "Time", "${model.elapsedSeconds}s", Colors.blue),
            _buildStatBox(context, "Errors", "${model.errors}", Colors.red),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.refresh, size: 18),
              label: Text("Try Again"),
              onPressed: () => model.startTest(),
            ),
            SizedBox(width: 8),
            TextButton.icon(
              icon: Icon(Icons.close, size: 18),
              label: Text("Reset"),
              onPressed: () => model.resetTest(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, TypingTestModel model) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 8),
        Row(
          children: [
            Text("History", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Spacer(),
            Text("Best: ${model.getBestWpm().toStringAsFixed(0)} WPM", 
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
            SizedBox(width: 8),
            Text("Avg: ${model.getAverageWpm().toStringAsFixed(0)} WPM", 
              style: TextStyle(fontSize: 11, color: Colors.grey)),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18),
              tooltip: "Clear history",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Clear History"),
                    content: Text("Clear all typing test history?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          model.clearHistory();
                          Navigator.pop(context);
                        },
                        child: Text("Clear"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: model.history.take(5).map((result) {
            final timeAgo = _formatTimeAgo(result.timestamp);
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${result.wpm.toStringAsFixed(0)} WPM | ${result.accuracy.toStringAsFixed(0)}% | $timeAgo",
                style: TextStyle(fontSize: 11),
              ),
            );
          }).toList(),
        ),
      ],
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
}