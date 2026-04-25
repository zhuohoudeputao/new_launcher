import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

FractionCalculatorModel fractionCalculatorModel = FractionCalculatorModel();

MyProvider providerFractionCalculator = MyProvider(
    name: "FractionCalculator",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Fraction Calculator',
      keywords: 'fraction calculator math add subtract multiply divide numerator denominator simplify reduce',
      action: () => fractionCalculatorModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  fractionCalculatorModel.init();
  Global.infoModel.addInfoWidget(
      "FractionCalculator",
      ChangeNotifierProvider.value(
          value: fractionCalculatorModel,
          builder: (context, child) => FractionCalculatorCard()),
      title: "Fraction Calculator");
}

Future<void> _update() async {
  fractionCalculatorModel.refresh();
}

class FractionOperationHistory {
  final String firstFraction;
  final String secondFraction;
  final String operation;
  final String resultFraction;
  final double resultDecimal;
  final DateTime timestamp;

  FractionOperationHistory({
    required this.firstFraction,
    required this.secondFraction,
    required this.operation,
    required this.resultFraction,
    required this.resultDecimal,
    required this.timestamp,
  });

  String get display => '$firstFraction $operation $secondFraction = $resultFraction';

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class Fraction {
  final int numerator;
  final int denominator;

  Fraction(this.numerator, this.denominator);

  bool get isValid => denominator != 0;

  double get decimal => numerator / denominator;

  Fraction simplify() {
    if (numerator == 0) return Fraction(0, 1);
    int gcd = _gcd(numerator.abs(), denominator.abs());
    int newNum = numerator.abs() ~/ gcd;
    int newDen = denominator.abs() ~/ gcd;
    if (numerator < 0 && denominator > 0 || numerator > 0 && denominator < 0) {
      return Fraction(-newNum, newDen);
    }
    return Fraction(newNum, newDen);
  }

  static int _gcd(int a, int b) {
    while (b != 0) {
      int t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  Fraction add(Fraction other) {
    return Fraction(
      numerator * other.denominator + other.numerator * denominator,
      denominator * other.denominator,
    ).simplify();
  }

  Fraction subtract(Fraction other) {
    return Fraction(
      numerator * other.denominator - other.numerator * denominator,
      denominator * other.denominator,
    ).simplify();
  }

  Fraction multiply(Fraction other) {
    return Fraction(
      numerator * other.numerator,
      denominator * other.denominator,
    ).simplify();
  }

  Fraction divide(Fraction other) {
    if (other.numerator == 0) return Fraction(0, 0);
    return Fraction(
      numerator * other.denominator,
      denominator * other.numerator,
    ).simplify();
  }

  static int lcm(int a, int b) {
    return (a * b) ~/ _gcd(a, b);
  }

  String toStringDisplay() {
    Fraction simplified = simplify();
    if (simplified.denominator == 1) {
      return simplified.numerator.toString();
    }
    int wholeNumber = simplified.numerator.abs() ~/ simplified.denominator;
    int remainder = simplified.numerator.abs() % simplified.denominator;
    if (wholeNumber == 0) {
      return '${simplified.numerator}/${simplified.denominator}';
    }
    if (remainder == 0) {
      return '${simplified.numerator < 0 ? "-" : ""}$wholeNumber';
    }
    return '${simplified.numerator < 0 ? "-" : ""}$wholeNumber $remainder/${simplified.denominator}';
  }
}

class FractionCalculatorModel extends ChangeNotifier {
  int _firstNumerator = 1;
  int _firstDenominator = 2;
  int _secondNumerator = 1;
  int _secondDenominator = 4;
  String _operation = '+';
  List<FractionOperationHistory> _history = [];
  bool _isInitialized = false;

  static const int maxHistoryLength = 10;

  int get firstNumerator => _firstNumerator;
  int get firstDenominator => _firstDenominator;
  int get secondNumerator => _secondNumerator;
  int get secondDenominator => _secondDenominator;
  String get operation => _operation;
  List<FractionOperationHistory> get history => _history;
  bool get isInitialized => _isInitialized;
  bool get hasHistory => _history.isNotEmpty;

  Fraction get firstFraction => Fraction(_firstNumerator, _firstDenominator);
  Fraction get secondFraction => Fraction(_secondNumerator, _secondDenominator);

  bool get firstFractionValid => _firstDenominator != 0;
  bool get secondFractionValid => _secondDenominator != 0;

  Fraction? get result {
    if (!firstFractionValid || !secondFractionValid) return null;
    switch (_operation) {
      case '+':
        return firstFraction.add(secondFraction);
      case '-':
        return firstFraction.subtract(secondFraction);
      case '×':
        return firstFraction.multiply(secondFraction);
      case '÷':
        if (secondFraction.numerator == 0) return null;
        return firstFraction.divide(secondFraction);
      default:
        return null;
    }
  }

  String? get resultFractionDisplay {
    if (result == null || !result!.isValid) return null;
    return result!.toStringDisplay();
  }

  double? get resultDecimal {
    if (result == null || !result!.isValid) return null;
    return result!.decimal;
  }

  void init() {
    _isInitialized = true;
    notifyListeners();
  }

  void setFirstNumerator(int value) {
    _firstNumerator = value;
    notifyListeners();
  }

  void setFirstDenominator(int value) {
    _firstDenominator = value;
    notifyListeners();
  }

  void setSecondNumerator(int value) {
    _secondNumerator = value;
    notifyListeners();
  }

  void setSecondDenominator(int value) {
    _secondDenominator = value;
    notifyListeners();
  }

  void setOperation(String op) {
    _operation = op;
    notifyListeners();
  }

  void swapFractions() {
    int tempNum = _firstNumerator;
    int tempDen = _firstDenominator;
    _firstNumerator = _secondNumerator;
    _firstDenominator = _secondDenominator;
    _secondNumerator = tempNum;
    _secondDenominator = tempDen;
    notifyListeners();
  }

  void addToHistory() {
    if (result == null || !result!.isValid) return;

    FractionOperationHistory entry = FractionOperationHistory(
      firstFraction: '${_firstNumerator}/${_firstDenominator}',
      secondFraction: '${_secondNumerator}/${_secondDenominator}',
      operation: _operation,
      resultFraction: resultFractionDisplay!,
      resultDecimal: resultDecimal!,
      timestamp: DateTime.now(),
    );

    _history.insert(0, entry);
    if (_history.length > maxHistoryLength) {
      _history.removeLast();
    }
    notifyListeners();
  }

  void applyFromHistory(FractionOperationHistory entry) {
    List<String> firstParts = entry.firstFraction.split('/');
    List<String> secondParts = entry.secondFraction.split('/');
    if (firstParts.length == 2) {
      _firstNumerator = int.parse(firstParts[0]);
      _firstDenominator = int.parse(firstParts[1]);
    }
    if (secondParts.length == 2) {
      _secondNumerator = int.parse(secondParts[0]);
      _secondDenominator = int.parse(secondParts[1]);
    }
    _operation = entry.operation;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class FractionCalculatorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<FractionCalculatorModel>();

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8),
                  Text('Fraction Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              SizedBox(height: 16),

              _buildFractionInputSection(context, model),
              SizedBox(height: 12),

              _buildOperationSelector(context, model),
              SizedBox(height: 16),

              if (model.firstFractionValid && model.secondFractionValid)
                _buildResultSection(context, model),

              SizedBox(height: 16),
              _buildHistorySection(context, model),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFractionInputSection(BuildContext context, FractionCalculatorModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildFractionInput(context, 'First Fraction', model.firstNumerator, model.firstDenominator,
              (n) => model.setFirstNumerator(n), (d) => model.setFirstDenominator(d), model.firstFractionValid)),
            SizedBox(width: 16),
            Expanded(child: _buildFractionInput(context, 'Second Fraction', model.secondNumerator, model.secondDenominator,
              (n) => model.setSecondNumerator(n), (d) => model.setSecondDenominator(d), model.secondFractionValid)),
          ],
        ),
        SizedBox(height: 8),
        Center(
          child: IconButton(
            icon: Icon(Icons.swap_horiz),
            tooltip: 'Swap fractions',
            onPressed: () => model.swapFractions(),
          ),
        ),
      ],
    );
  }

  Widget _buildFractionInput(BuildContext context, String label, int numerator, int denominator,
    ValueChanged<int> onNumeratorChanged, ValueChanged<int> onDenominatorChanged, bool isValid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Numerator',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: TextEditingController(text: numerator.toString()),
                keyboardType: TextInputType.numberWithOptions(signed: true),
                onChanged: (value) {
                  int? num = int.tryParse(value);
                  if (num != null) onNumeratorChanged(num);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Denominator',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  errorText: isValid ? null : 'Cannot be 0',
                ),
                controller: TextEditingController(text: denominator.toString()),
                keyboardType: TextInputType.numberWithOptions(signed: true),
                onChanged: (value) {
                  int? den = int.tryParse(value);
                  if (den != null) onDenominatorChanged(den);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOperationSelector(BuildContext context, FractionCalculatorModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Operation', style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: '+', label: Text('+')),
            ButtonSegment(value: '-', label: Text('-')),
            ButtonSegment(value: '×', label: Text('×')),
            ButtonSegment(value: '÷', label: Text('÷')),
          ],
          selected: {model.operation},
          onSelectionChanged: (Set<String> newSelection) {
            model.setOperation(newSelection.first);
          },
        ),
      ],
    );
  }

  Widget _buildResultSection(BuildContext context, FractionCalculatorModel model) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Result', style: TextStyle(fontWeight: FontWeight.bold)),
              if (model.result != null && model.result!.isValid)
                TextButton.icon(
                  icon: Icon(Icons.save, size: 18),
                  label: Text('Save'),
                  onPressed: () => model.addToHistory(),
                ),
            ],
          ),
          SizedBox(height: 8),
          if (model.result != null && model.result!.isValid)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${model.firstNumerator}/${model.firstDenominator} ${model.operation} ${model.secondNumerator}/${model.secondDenominator}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '= ${model.resultFractionDisplay}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Decimal: ${model.resultDecimal!.toStringAsFixed(4)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            )
          else
            Text('Division by zero', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, FractionCalculatorModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (model.hasHistory)
          Row(
            children: [
              Text('History', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              TextButton(
                child: Text('Clear'),
                onPressed: () => model.clearHistory(),
              ),
            ],
          ),
        if (model.hasHistory)
          SizedBox(height: 8),
        if (model.hasHistory)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: model.history.map((entry) => ActionChip(
              label: Text(entry.display),
              onPressed: () => model.applyFromHistory(entry),
            )).toList(),
          ),
      ],
    );
  }
}