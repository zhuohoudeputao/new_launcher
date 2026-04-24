import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

SequenceModel sequenceModel = SequenceModel();

MyProvider providerSequence = MyProvider(
    name: "Sequence",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Generate Sequence',
      keywords: 'sequence fibonacci prime arithmetic geometric generate math numbers',
      action: () {
        sequenceModel.generateFibonacci(10);
        Global.infoModel.addInfo(
            "Sequence",
            "Sequence Generator",
            subtitle: "Fibonacci, primes, arithmetic sequences",
            icon: Icon(Icons.functions),
            onTap: () => sequenceModel.generateFibonacci(10));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  sequenceModel.init();
  Global.infoModel.addInfoWidget(
      "Sequence",
      ChangeNotifierProvider.value(
          value: sequenceModel,
          builder: (context, child) => SequenceCard()),
      title: "Sequence Generator");
}

Future<void> _update() async {
  sequenceModel.refresh();
}

enum SequenceType {
  fibonacci,
  prime,
  arithmetic,
  geometric,
  triangular,
  square,
  factorial,
}

class SequenceEntry {
  final SequenceType type;
  final List<int> numbers;
  final DateTime timestamp;
  final String description;

  SequenceEntry({
    required this.type,
    required this.numbers,
    required this.timestamp,
    required this.description,
  });
}

class SequenceModel extends ChangeNotifier {
  bool _isInitialized = false;
  SequenceType _selectedType = SequenceType.fibonacci;
  List<int> _currentSequence = [];
  int _sequenceCount = 10;
  int _arithmeticStart = 1;
  int _arithmeticStep = 2;
  int _geometricStart = 1;
  int _geometricRatio = 2;
  int _generationCount = 0;
  List<SequenceEntry> _history = [];
  static const int maxHistory = 10;

  bool get isInitialized => _isInitialized;
  SequenceType get selectedType => _selectedType;
  List<int> get currentSequence => List.from(_currentSequence);
  int get sequenceCount => _sequenceCount;
  int get arithmeticStart => _arithmeticStart;
  int get arithmeticStep => _arithmeticStep;
  int get geometricStart => _geometricStart;
  int get geometricRatio => _geometricRatio;
  int get generationCount => _generationCount;
  List<SequenceEntry> get history => List.from(_history);

  String get currentSequenceDisplay {
    if (_currentSequence.isEmpty) return "No sequence generated";
    return _currentSequence.join(", ");
  }

  String get currentSequenceSum {
    if (_currentSequence.isEmpty) return "0";
    int sum = _currentSequence.reduce((a, b) => a + b);
    return "Sum: $sum";
  }

  void init() {
    _isInitialized = true;
    generateFibonacci(10);
    Global.loggerModel.info("Sequence initialized", source: "Sequence");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setSelectedType(SequenceType type) {
    _selectedType = type;
    notifyListeners();
  }

  void setSequenceCount(int count) {
    _sequenceCount = count.clamp(1, 50);
    notifyListeners();
  }

  void setArithmeticStart(int start) {
    _arithmeticStart = start;
    notifyListeners();
  }

  void setArithmeticStep(int step) {
    _arithmeticStep = step;
    notifyListeners();
  }

  void setGeometricStart(int start) {
    _geometricStart = start;
    notifyListeners();
  }

  void setGeometricRatio(int ratio) {
    _geometricRatio = ratio;
    notifyListeners();
  }

  List<int> generateFibonacci(int count) {
    _currentSequence = [];
    if (count <= 0) return _currentSequence;

    int a = 0, b = 1;
    for (int i = 0; i < count; i++) {
      _currentSequence.add(a);
      int next = a + b;
      a = b;
      b = next;
    }

    _selectedType = SequenceType.fibonacci;
    _generationCount++;
    addToHistory(SequenceType.fibonacci, _currentSequence, "Fibonacci ($count terms)");
    Global.loggerModel.info("Fibonacci generated: ${_currentSequence.take(5).join(',')}...", source: "Sequence");
    notifyListeners();
    return _currentSequence;
  }

  List<int> generatePrimeNumbers(int count) {
    _currentSequence = [];
    if (count <= 0) return _currentSequence;

    int num = 2;
    while (_currentSequence.length < count) {
      if (_isPrime(num)) {
        _currentSequence.add(num);
      }
      num++;
    }

    _selectedType = SequenceType.prime;
    _generationCount++;
    addToHistory(SequenceType.prime, _currentSequence, "Prime numbers ($count terms)");
    Global.loggerModel.info("Prime numbers generated: ${_currentSequence.take(5).join(',')}...", source: "Sequence");
    notifyListeners();
    return _currentSequence;
  }

  bool _isPrime(int n) {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;
    for (int i = 3; i <= sqrt(n); i += 2) {
      if (n % i == 0) return false;
    }
    return true;
  }

  List<int> generateArithmetic(int start, int step, int count) {
    _currentSequence = [];
    if (count <= 0) return _currentSequence;

    for (int i = 0; i < count; i++) {
      _currentSequence.add(start + i * step);
    }

    _arithmeticStart = start;
    _arithmeticStep = step;
    _selectedType = SequenceType.arithmetic;
    _generationCount++;
    addToHistory(SequenceType.arithmetic, _currentSequence, "Arithmetic: start=$start, step=$step ($count terms)");
    Global.loggerModel.info("Arithmetic sequence generated", source: "Sequence");
    notifyListeners();
    return _currentSequence;
  }

  List<int> generateGeometric(int start, int ratio, int count) {
    _currentSequence = [];
    if (count <= 0) return _currentSequence;

    int current = start;
    for (int i = 0; i < count; i++) {
      _currentSequence.add(current);
      current *= ratio;
    }

    _geometricStart = start;
    _geometricRatio = ratio;
    _selectedType = SequenceType.geometric;
    _generationCount++;
    addToHistory(SequenceType.geometric, _currentSequence, "Geometric: start=$start, ratio=$ratio ($count terms)");
    Global.loggerModel.info("Geometric sequence generated", source: "Sequence");
    notifyListeners();
    return _currentSequence;
  }

  List<int> generateTriangular(int count) {
    _currentSequence = [];
    if (count <= 0) return _currentSequence;

    for (int n = 1; n <= count; n++) {
      _currentSequence.add((n * (n + 1)) ~/ 2);
    }

    _selectedType = SequenceType.triangular;
    _generationCount++;
    addToHistory(SequenceType.triangular, _currentSequence, "Triangular numbers ($count terms)");
    Global.loggerModel.info("Triangular numbers generated", source: "Sequence");
    notifyListeners();
    return _currentSequence;
  }

  List<int> generateSquare(int count) {
    _currentSequence = [];
    if (count <= 0) return _currentSequence;

    for (int n = 1; n <= count; n++) {
      _currentSequence.add(n * n);
    }

    _selectedType = SequenceType.square;
    _generationCount++;
    addToHistory(SequenceType.square, _currentSequence, "Square Numbers ($count terms)");
    Global.loggerModel.info("Square numbers generated", source: "Sequence");
    notifyListeners();
    return _currentSequence;
  }

  List<int> generateFactorial(int count) {
    _currentSequence = [];
    if (count <= 0) return _currentSequence;

    int factorial = 1;
    for (int n = 1; n <= count; n++) {
      factorial *= n;
      _currentSequence.add(factorial);
    }

    _selectedType = SequenceType.factorial;
    _generationCount++;
    addToHistory(SequenceType.factorial, _currentSequence, "Factorials ($count terms)");
    Global.loggerModel.info("Factorials generated", source: "Sequence");
    notifyListeners();
    return _currentSequence;
  }

  void generateCurrent() {
    switch (_selectedType) {
      case SequenceType.fibonacci:
        generateFibonacci(_sequenceCount);
        break;
      case SequenceType.prime:
        generatePrimeNumbers(_sequenceCount);
        break;
      case SequenceType.arithmetic:
        generateArithmetic(_arithmeticStart, _arithmeticStep, _sequenceCount);
        break;
      case SequenceType.geometric:
        generateGeometric(_geometricStart, _geometricRatio, _sequenceCount);
        break;
      case SequenceType.triangular:
        generateTriangular(_sequenceCount);
        break;
      case SequenceType.square:
        generateSquare(_sequenceCount);
        break;
      case SequenceType.factorial:
        generateFactorial(_sequenceCount);
        break;
    }
  }

  void addToHistory(SequenceType type, List<int> numbers, String description) {
    if (numbers.isEmpty) return;
    _history.insert(0, SequenceEntry(
      type: type,
      numbers: List.from(numbers),
      timestamp: DateTime.now(),
      description: description,
    ));
    if (_history.length > maxHistory) {
      _history = _history.sublist(0, maxHistory);
    }
  }

  void loadFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _currentSequence = List.from(entry.numbers);
      _selectedType = entry.type;
      notifyListeners();
    }
  }

  void removeFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("Sequence history cleared", source: "Sequence");
  }

  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sequence copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class SequenceCard extends StatefulWidget {
  @override
  State<SequenceCard> createState() => _SequenceCardState();
}

class _SequenceCardState extends State<SequenceCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final seq = context.watch<SequenceModel>();

    if (!seq.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.functions, size: 24),
              SizedBox(width: 12),
              Text("Sequence: Loading..."),
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
              children: [
                Icon(Icons.functions, size: 20),
                SizedBox(width: 8),
                Text(
                  "Sequence Generator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${seq.generationCount}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildTypeSelector(context, seq),
            SizedBox(height: 12),
            _buildSettingsSection(context, seq),
            SizedBox(height: 12),
            _buildSequenceDisplay(context, seq),
            SizedBox(height: 12),
            _buildActions(context, seq),
            SizedBox(height: 8),
            _buildHistorySection(context, seq),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context, SequenceModel seq) {
    return SegmentedButton<SequenceType>(
      segments: [
        ButtonSegment(value: SequenceType.fibonacci, label: Text("Fib"), icon: Icon(Icons.trending_up, size: 16)),
        ButtonSegment(value: SequenceType.prime, label: Text("Prime"), icon: Icon(Icons.star_outline, size: 16)),
        ButtonSegment(value: SequenceType.arithmetic, label: Text("Arith"), icon: Icon(Icons.add, size: 16)),
        ButtonSegment(value: SequenceType.geometric, label: Text("Geo"), icon: Icon(Icons.close, size: 16)),
      ],
      selected: {seq.selectedType},
      onSelectionChanged: (Set<SequenceType> newSelection) {
        seq.setSelectedType(newSelection.first);
        seq.generateCurrent();
      },
      style: ButtonStyle(visualDensity: VisualDensity.comfortable),
    );
  }

  Widget _buildSettingsSection(BuildContext context, SequenceModel seq) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Count: ${seq.sequenceCount}", style: TextStyle(fontSize: 12)),
                SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: seq.sequenceCount.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    onChanged: (value) {
                      seq.setSequenceCount(value.toInt());
                      seq.generateCurrent();
                    },
                  ),
                ),
              ],
            ),
            if (seq.selectedType == SequenceType.arithmetic || seq.selectedType == SequenceType.geometric)
              _buildCustomSettings(context, seq),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: Text("Triangular"),
                  onPressed: () {
                    seq.setSelectedType(SequenceType.triangular);
                    seq.generateTriangular(seq.sequenceCount);
                  },
                ),
                ActionChip(
                  label: Text("Square"),
                  onPressed: () {
                    seq.setSelectedType(SequenceType.square);
                    seq.generateSquare(seq.sequenceCount);
                  },
                ),
                ActionChip(
                  label: Text("Factorial"),
                  onPressed: () {
                    seq.setSelectedType(SequenceType.factorial);
                    seq.generateFactorial(seq.sequenceCount);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSettings(BuildContext context, SequenceModel seq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (seq.selectedType == SequenceType.arithmetic)
          Row(
            children: [
              Text("Start: ${seq.arithmeticStart}", style: TextStyle(fontSize: 12)),
              SizedBox(width: 16),
              Text("Step: ${seq.arithmeticStep}", style: TextStyle(fontSize: 12)),
              SizedBox(width: 8),
              ActionChip(
                label: Text("Edit"),
                onPressed: () => _showArithmeticDialog(context, seq),
              ),
            ],
          ),
        if (seq.selectedType == SequenceType.geometric)
          Row(
            children: [
              Text("Start: ${seq.geometricStart}", style: TextStyle(fontSize: 12)),
              SizedBox(width: 16),
              Text("Ratio: ${seq.geometricRatio}", style: TextStyle(fontSize: 12)),
              SizedBox(width: 8),
              ActionChip(
                label: Text("Edit"),
                onPressed: () => _showGeometricDialog(context, seq),
              ),
            ],
          ),
      ],
    );
  }

  void _showArithmeticDialog(BuildContext context, SequenceModel seq) {
    final startController = TextEditingController(text: seq.arithmeticStart.toString());
    final stepController = TextEditingController(text: seq.arithmeticStep.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Arithmetic Sequence"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: InputDecoration(labelText: "Start"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 8),
            TextField(
              controller: stepController,
              decoration: InputDecoration(labelText: "Step"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final start = int.tryParse(startController.text) ?? 1;
              final step = int.tryParse(stepController.text) ?? 1;
              seq.generateArithmetic(start, step, seq.sequenceCount);
              Navigator.pop(context);
            },
            child: Text("Generate"),
          ),
        ],
      ),
    );
  }

  void _showGeometricDialog(BuildContext context, SequenceModel seq) {
    final startController = TextEditingController(text: seq.geometricStart.toString());
    final ratioController = TextEditingController(text: seq.geometricRatio.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Geometric Sequence"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: InputDecoration(labelText: "Start"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 8),
            TextField(
              controller: ratioController,
              decoration: InputDecoration(labelText: "Ratio"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final start = int.tryParse(startController.text) ?? 1;
              final ratio = int.tryParse(ratioController.text) ?? 2;
              seq.generateGeometric(start, ratio, seq.sequenceCount);
              Navigator.pop(context);
            },
            child: Text("Generate"),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceDisplay(BuildContext context, SequenceModel seq) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              seq.currentSequenceDisplay,
              style: TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
            SizedBox(height: 8),
            Text(
              seq.currentSequenceSum,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, SequenceModel seq) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: Icon(Icons.refresh, size: 16),
          label: Text("Generate"),
          onPressed: () => seq.generateCurrent(),
        ),
        ActionChip(
          avatar: Icon(Icons.copy, size: 16),
          label: Text("Copy"),
          onPressed: () => seq.copyToClipboard(seq.currentSequenceDisplay, context),
        ),
        ActionChip(
          avatar: Icon(Icons.history, size: 16),
          label: Text("History (${seq.history.length})"),
          onPressed: () {
            setState(() {
              _showHistory = !_showHistory;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, SequenceModel seq) {
    if (!_showHistory || seq.history.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("History:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Spacer(),
                if (seq.history.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Clear History"),
                          content: Text("Clear all ${seq.history.length} sequences from history?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                seq.clearHistory();
                                Navigator.pop(context);
                              },
                              child: Text("Clear"),
                            ),
                          ],
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text("Clear", style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              height: seq.history.length * 28.0.clamp(0, 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: seq.history.length,
                itemBuilder: (context, index) {
                  final entry = seq.history[index];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(entry.description, style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      entry.numbers.take(5).join(', ') + (entry.numbers.length > 5 ? '...' : ''),
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                    onTap: () => seq.loadFromHistory(index),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, size: 14),
                      onPressed: () => seq.removeFromHistory(index),
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}