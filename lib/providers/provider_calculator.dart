import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

CalculatorModel calculatorModel = CalculatorModel();

MyProvider providerCalculator = MyProvider(
    name: "Calculator",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Calculator',
      keywords: 'calc calculator math calculate equal',
      action: () => calculatorModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  calculatorModel.init();
  Global.infoModel.addInfoWidget(
      "Calculator",
      ChangeNotifierProvider.value(
          value: calculatorModel,
          builder: (context, child) => CalculatorCard()),
      title: "Calculator");
}

Future<void> _update() async {
  calculatorModel.refresh();
}

class CalculationHistory {
  final String expression;
  final String result;
  final DateTime timestamp;

  CalculationHistory({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}

class CalculatorModel extends ChangeNotifier {
  String _display = '0';
  String _expression = '';
  double? _lastResult;
  bool _isInitialized = false;
  final List<CalculationHistory> _history = [];
  static const int maxHistory = 10;
  String _lastOperator = '';
  double? _lastOperand;

  String get display => _display;
  String get expression => _expression;
  bool get isInitialized => _isInitialized;
  List<CalculationHistory> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("Calculator initialized", source: "Calculator");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Calculator refreshed", source: "Calculator");
  }

  void inputDigit(String digit) {
    if (_display == '0' || _display == 'Error') {
      _display = digit;
    } else {
      _display += digit;
    }
    notifyListeners();
  }

  void inputOperator(String op) {
    if (_display == 'Error') return;
    
    if (_expression.isNotEmpty && _isOperatorChar(_expression[_expression.length - 1])) {
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else {
      _expression += _display + op;
      _display = '0';
    }
    notifyListeners();
  }

  void inputDecimal() {
    if (_display == 'Error') {
      _display = '0.';
    } else if (!_display.contains('.')) {
      _display += '.';
    }
    notifyListeners();
  }

  void clear() {
    _display = '0';
    _expression = '';
    _lastOperator = '';
    _lastOperand = null;
    notifyListeners();
    Global.loggerModel.info("Calculator cleared", source: "Calculator");
  }

  void deleteLastDigit() {
    if (_display == 'Error') {
      clear();
      return;
    }
    if (_display.length > 1) {
      _display = _display.substring(0, _display.length - 1);
    } else {
      _display = '0';
    }
    notifyListeners();
  }

  void calculate() {
    if (_display == 'Error') return;
    
    String fullExpression = _expression + _display;
    if (fullExpression.isEmpty) return;

    try {
      final result = _evaluateExpression(fullExpression);
      final resultStr = _formatResult(result);
      
      _addToHistory(fullExpression, resultStr);
      
      _lastResult = result;
      _display = resultStr;
      _expression = '';
      notifyListeners();
      Global.loggerModel.info("Calculator: $fullExpression = $resultStr", source: "Calculator");
    } catch (e) {
      _display = 'Error';
      _expression = '';
      Global.loggerModel.error("Calculator error: $e", source: "Calculator");
      notifyListeners();
    }
  }

  void calculatePercent() {
    if (_display == 'Error') return;
    
    try {
      final value = double.parse(_display);
      final result = value / 100;
      _display = _formatResult(result);
      notifyListeners();
    } catch (e) {
      _display = 'Error';
      notifyListeners();
    }
  }

  void toggleSign() {
    if (_display == 'Error' || _display == '0') return;
    
    if (_display.startsWith('-')) {
      _display = _display.substring(1);
    } else {
      _display = '-' + _display;
    }
    notifyListeners();
  }

  void useLastResult() {
    if (_lastResult != null) {
      _display = _formatResult(_lastResult!);
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("Calculator history cleared", source: "Calculator");
  }

  double _evaluateExpression(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    
    final tokens = _tokenize(expr);
    return _evaluateTokens(tokens);
  }

  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    String current = '';
    
    for (int i = 0; i < expr.length; i++) {
      final char = expr[i];
      if (_isOperatorChar(char) || char == '(' || char == ')') {
        if (current.isNotEmpty) {
          tokens.add(current);
          current = '';
        }
        if (char == '-' && (tokens.isEmpty || _isOperatorStr(tokens.last) || tokens.last == '(')) {
          current = char;
        } else {
          tokens.add(char);
        }
      } else {
        current += char;
      }
    }
    if (current.isNotEmpty) {
      tokens.add(current);
    }
    
    return tokens;
  }

  bool _isOperatorChar(String char) {
    return char == '+' || char == '-' || char == '*' || char == '/';
  }

  bool _isOperatorStr(String s) {
    return s == '+' || s == '-' || s == '*' || s == '/';
  }

  double _evaluateTokens(List<String> tokens) {
    final values = <double>[];
    final ops = <String>[];
    
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      
      if (token == '(') {
        ops.add(token);
      } else if (token == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          final val2 = values.removeLast();
          final val1 = values.removeLast();
          final op = ops.removeLast();
          values.add(_applyOp(op, val1, val2));
        }
        if (ops.isNotEmpty) ops.removeLast();
      } else if (_isOperatorStr(token)) {
        while (ops.isNotEmpty && _precedence(ops.last) >= _precedence(token)) {
          final val2 = values.removeLast();
          final val1 = values.removeLast();
          final op = ops.removeLast();
          values.add(_applyOp(op, val1, val2));
        }
        ops.add(token);
      } else {
        values.add(double.parse(token));
      }
    }
    
    while (ops.isNotEmpty) {
      final val2 = values.removeLast();
      final val1 = values.removeLast();
      final op = ops.removeLast();
      values.add(_applyOp(op, val1, val2));
    }
    
    return values.isEmpty ? 0 : values.last;
  }

  int _precedence(String op) {
    if (op == '+' || op == '-') return 1;
    if (op == '*' || op == '/') return 2;
    return 0;
  }

  double _applyOp(String op, double a, double b) {
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case '*': return a * b;
      case '/': 
        if (b == 0) throw Exception('Division by zero');
        return a / b;
      default: return 0;
    }
  }

  String _formatResult(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    String result = value.toStringAsFixed(8);
    result = result.replaceAll(RegExp(r'0+$'), '');
    result = result.replaceAll(RegExp(r'\.$'), '');
    return result;
  }

  void _addToHistory(String expression, String result) {
    _history.insert(0, CalculationHistory(
      expression: expression,
      result: result,
      timestamp: DateTime.now(),
    ));
    
    while (_history.length > maxHistory) {
      _history.removeLast();
    }
  }
}

class CalculatorCard extends StatefulWidget {
  @override
  State<CalculatorCard> createState() => _CalculatorCardState();
}

class _CalculatorCardState extends State<CalculatorCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalculatorModel>();
    final colorScheme = Theme.of(context).colorScheme;
    
    if (!calc.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.calculate, size: 24),
              SizedBox(width: 12),
              Text("Calculator: Loading..."),
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
                Text(
                  "Calculator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (calc.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.calculate : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Calculator" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (calc.hasHistory)
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
            SizedBox(height: 8),
            if (_showHistory) _buildHistoryView(calc)
            else _buildCalculatorView(calc),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorView(CalculatorModel calc) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDisplay(calc),
        SizedBox(height: 8),
        _buildKeypad(calc),
      ],
    );
  }

  Widget _buildDisplay(CalculatorModel calc) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            calc.expression,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4),
          Text(
            calc.display,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(CalculatorModel calc) {
    return Column(
      children: [
        _buildKeypadRow(['C', '±', '%', '÷'], calc),
        _buildKeypadRow(['7', '8', '9', '×'], calc),
        _buildKeypadRow(['4', '5', '6', '-'], calc),
        _buildKeypadRow(['1', '2', '3', '+'], calc),
        _buildKeypadRow(['⌫', '0', '.', '='], calc),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys, CalculatorModel calc) {
    return Row(
      children: keys.map((key) => Expanded(child: _buildKeypadButton(key, calc))).toList(),
    );
  }

  Widget _buildKeypadButton(String key, CalculatorModel calc) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOperator = ['+', '-', '×', '÷', '='].contains(key);
    final isFunction = ['C', '±', '%', '⌫'].contains(key);
    
    Color? buttonColor;
    Color textColor;
    
    if (isOperator) {
      buttonColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
    } else if (isFunction) {
      buttonColor = colorScheme.surfaceContainerHigh;
      textColor = colorScheme.onSurface;
    } else {
      buttonColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurface;
    }
    
    return Padding(
      padding: EdgeInsets.all(2),
      child: InkWell(
        onTap: () => _handleKeyPress(key, calc),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              key,
              style: TextStyle(
                fontSize: 20,
                fontWeight: isOperator ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleKeyPress(String key, CalculatorModel calc) {
    switch (key) {
      case 'C':
        calc.clear();
        break;
      case '⌫':
        calc.deleteLastDigit();
        break;
      case '±':
        calc.toggleSign();
        break;
      case '%':
        calc.calculatePercent();
        break;
      case '=':
        calc.calculate();
        break;
      case '+':
      case '-':
      case '×':
      case '÷':
        calc.inputOperator(key);
        break;
      case '.':
        calc.inputDecimal();
        break;
      default:
        if (RegExp(r'[0-9]').hasMatch(key)) {
          calc.inputDigit(key);
        }
    }
  }

  Widget _buildHistoryView(CalculatorModel calc) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: calc.history.length,
        itemBuilder: (context, index) {
          final entry = calc.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(entry.expression),
            subtitle: Text(
              '= ${entry.result}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              calc.inputDigit(entry.result);
              setState(() => _showHistory = false);
            },
          );
        },
      ),
    );
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all calculation history?"),
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
      context.read<CalculatorModel>().clearHistory();
    }
  }
}