import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

ExponentModel exponentModel = ExponentModel();

MyProvider providerExponent = MyProvider(
    name: "Exponent",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'ExponentCalculator',
      keywords: 'exponent power root square cube log logarithm math calculate',
      action: () => exponentModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await exponentModel.init();
  Global.infoModel.addInfoWidget(
      "ExponentCalculator",
      ChangeNotifierProvider.value(
          value: exponentModel,
          builder: (context, child) => ExponentCard()),
      title: "Exponent Calculator");
}

Future<void> _update() async {
  exponentModel.refresh();
}

class ExponentHistoryEntry {
  final DateTime date;
  final String operation;
  final double base;
  final double exponent;
  final double result;

  ExponentHistoryEntry({
    required this.date,
    required this.operation,
    required this.base,
    required this.exponent,
    required this.result,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'operation': operation,
      'base': base,
      'exponent': exponent,
      'result': result,
    });
  }

  static ExponentHistoryEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ExponentHistoryEntry(
      date: DateTime.parse(map['date'] as String),
      operation: map['operation'] as String,
      base: (map['base'] as num).toDouble(),
      exponent: (map['exponent'] as num).toDouble(),
      result: (map['result'] as num).toDouble(),
    );
  }
}

class ExponentModel extends ChangeNotifier {
  static const int maxHistory = 10;
  static const String _storageKey = 'exponent_history';

  List<ExponentHistoryEntry> _history = [];
  double _base = 0;
  double _exponent = 0;
  String _operation = 'power';
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  double get base => _base;
  double get exponent => _exponent;
  String get operation => _operation;
  List<ExponentHistoryEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;

  double get result {
    if (_base == 0 && _operation != 'log' && _operation != 'ln') return 0;
    
    switch (_operation) {
      case 'power':
        return pow(_base, _exponent).toDouble();
      case 'sqrt':
        if (_base < 0) return double.nan;
        return sqrt(_base);
      case 'cbrt':
        if (_base < 0) return -pow(-_base, 1/3).toDouble();
        return pow(_base, 1/3).toDouble();
      case 'nthroot':
        if (_base < 0 && _exponent % 2 == 0) return double.nan;
        if (_base < 0) return -pow(-_base, 1/_exponent).toDouble();
        return pow(_base, 1/_exponent).toDouble();
      case 'log':
        if (_base <= 0 || _exponent <= 0) return double.nan;
        return log(_base) / log(_exponent);
      case 'ln':
        if (_base <= 0) return double.nan;
        return log(_base);
      default:
        return 0;
    }
  }

  String get operationLabel {
    switch (_operation) {
      case 'power':
        return 'Power (x^y)';
      case 'sqrt':
        return 'Square Root';
      case 'cbrt':
        return 'Cube Root';
      case 'nthroot':
        return 'Nth Root';
      case 'log':
        return 'Logarithm (log base y)';
      case 'ln':
        return 'Natural Log (ln)';
      default:
        return '';
    }
  }

  String get resultLabel {
    if (result.isNaN || result.isInfinite) return 'Invalid';
    
    if (result == result.roundToDouble()) {
      return result.round().toString();
    }
    
    if (result.abs() < 0.0001 || result.abs() > 1000000) {
      return result.toStringAsExponential(6);
    }
    
    return result.toStringAsFixed(6);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => ExponentHistoryEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Exponent Calculator initialized with ${_history.length} entries", source: "Exponent");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Exponent Calculator refreshed", source: "Exponent");
  }

  void setBase(double value) {
    _base = value;
    notifyListeners();
  }

  void setExponent(double value) {
    _exponent = value;
    notifyListeners();
  }

  void setOperation(String op) {
    _operation = op;
    notifyListeners();
  }

  void clear() {
    _base = 0;
    _exponent = 0;
    _operation = 'power';
    notifyListeners();
    Global.loggerModel.info("Exponent Calculator cleared", source: "Exponent");
  }

  void saveToHistory() {
    if (_base == 0 && _operation != 'ln') return;
    if (result.isNaN || result.isInfinite) return;

    _history.insert(0, ExponentHistoryEntry(
      date: DateTime.now(),
      operation: _operation,
      base: _base,
      exponent: _exponent,
      result: result,
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }
    _save();
    notifyListeners();
    Global.loggerModel.info("Exponent calculation saved to history", source: "Exponent");
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void loadFromHistory(ExponentHistoryEntry entry) {
    _base = entry.base;
    _exponent = entry.exponent;
    _operation = entry.operation;
    notifyListeners();
    Global.loggerModel.info("Loaded exponent from history", source: "Exponent");
  }

  void clearHistory() {
    _history.clear();
    _save();
    notifyListeners();
    Global.loggerModel.info("Exponent history cleared", source: "Exponent");
  }
}

class ExponentCard extends StatefulWidget {
  @override
  State<ExponentCard> createState() => _ExponentCardState();
}

class _ExponentCardState extends State<ExponentCard> {
  bool _showHistory = false;
  final TextEditingController _baseController = TextEditingController();
  final TextEditingController _exponentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _baseController.addListener(_onBaseChanged);
    _exponentController.addListener(_onExponentChanged);
  }

  @override
  void dispose() {
    _baseController.removeListener(_onBaseChanged);
    _exponentController.removeListener(_onExponentChanged);
    _baseController.dispose();
    _exponentController.dispose();
    super.dispose();
  }

  void _onBaseChanged() {
    final value = double.tryParse(_baseController.text);
    if (value != null) {
      context.read<ExponentModel>().setBase(value);
    } else if (_baseController.text.isEmpty) {
      context.read<ExponentModel>().setBase(0);
    }
  }

  void _onExponentChanged() {
    final value = double.tryParse(_exponentController.text);
    if (value != null) {
      context.read<ExponentModel>().setExponent(value);
    } else if (_exponentController.text.isEmpty) {
      context.read<ExponentModel>().setExponent(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exp = context.watch<ExponentModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!exp.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.functions, size: 24),
              SizedBox(width: 12),
              Text("Exponent Calculator: Loading..."),
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
                  "Exponent Calculator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (exp.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.calculate : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Calculator" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (exp.hasHistory)
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
            if (_showHistory) _buildHistoryView(exp)
            else _buildCalculatorView(exp),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorView(ExponentModel exp) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOperationSelector(exp),
        SizedBox(height: 8),
        _buildInputs(exp),
        SizedBox(height: 12),
        if (exp.base != 0 || exp.operation == 'ln') _buildResult(exp),
        SizedBox(height: 8),
        _buildActionButtons(exp),
      ],
    );
  }

  Widget _buildOperationSelector(ExponentModel exp) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'power', label: Text('Power')),
        ButtonSegment(value: 'sqrt', label: Text('Sqrt')),
        ButtonSegment(value: 'cbrt', label: Text('Cbrt')),
        ButtonSegment(value: 'nthroot', label: Text('Nth')),
        ButtonSegment(value: 'log', label: Text('Log')),
        ButtonSegment(value: 'ln', label: Text('Ln')),
      ],
      selected: {exp.operation},
      onSelectionChanged: (Set<String> selection) {
        context.read<ExponentModel>().setOperation(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildInputs(ExponentModel exp) {
    final colorScheme = Theme.of(context).colorScheme;
    final showExponent = exp.operation == 'power' || exp.operation == 'nthroot' || exp.operation == 'log';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _baseController,
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            labelText: _getInputLabel(exp.operation),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
          style: TextStyle(fontSize: 18),
        ),
        if (showExponent) SizedBox(height: 8),
        if (showExponent)
          TextField(
            controller: _exponentController,
            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: _getExponentLabel(exp.operation),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            style: TextStyle(fontSize: 18),
          ),
      ],
    );
  }

  String _getInputLabel(String operation) {
    switch (operation) {
      case 'power':
        return 'Base (x)';
      case 'sqrt':
        return 'Number';
      case 'cbrt':
        return 'Number';
      case 'nthroot':
        return 'Number';
      case 'log':
        return 'Number';
      case 'ln':
        return 'Number';
      default:
        return 'Base';
    }
  }

  String _getExponentLabel(String operation) {
    switch (operation) {
      case 'power':
        return 'Exponent (y)';
      case 'nthroot':
        return 'Root degree (n)';
      case 'log':
        return 'Base (y)';
      default:
        return 'Exponent';
    }
  }

  Widget _buildResult(ExponentModel exp) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            exp.operationLabel,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            exp.resultLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: exp.result.isNaN ? colorScheme.error : colorScheme.primary,
            ),
          ),
          if (!exp.result.isNaN && !exp.result.isInfinite)
            Text(
              _buildExpressionDisplay(exp),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  String _buildExpressionDisplay(ExponentModel exp) {
    switch (exp.operation) {
      case 'power':
        return '${exp.base}^${exp.exponent}';
      case 'sqrt':
        return 'sqrt(${exp.base})';
      case 'cbrt':
        return 'cbrt(${exp.base})';
      case 'nthroot':
        return '${exp.exponent}th root of ${exp.base}';
      case 'log':
        return 'log${exp.exponent}(${exp.base})';
      case 'ln':
        return 'ln(${exp.base})';
      default:
        return '';
    }
  }

  Widget _buildActionButtons(ExponentModel exp) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: (exp.base != 0 || exp.operation == 'ln') && !exp.result.isNaN ? () => exp.saveToHistory() : null,
          icon: Icon(Icons.save, size: 18),
          label: Text("Save"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            exp.clear();
            _baseController.clear();
            _exponentController.clear();
          },
          icon: Icon(Icons.clear_all, size: 18),
          label: Text("Clear"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(ExponentModel exp) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: exp.history.length,
        itemBuilder: (context, index) {
          final entry = exp.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.functions, size: 20),
            title: Text(_buildHistoryExpression(entry)),
            subtitle: Text(
              "= ${entry.result == entry.result.roundToDouble() ? entry.result.round() : entry.result.toStringAsFixed(4)}",
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              context.read<ExponentModel>().loadFromHistory(entry);
              _baseController.text = entry.base.toString();
              _exponentController.text = entry.exponent.toString();
              setState(() => _showHistory = false);
            },
          );
        },
      ),
    );
  }

  String _buildHistoryExpression(ExponentHistoryEntry entry) {
    switch (entry.operation) {
      case 'power':
        return '${entry.base}^${entry.exponent}';
      case 'sqrt':
        return 'sqrt(${entry.base})';
      case 'cbrt':
        return 'cbrt(${entry.base})';
      case 'nthroot':
        return '${entry.exponent}th root of ${entry.base}';
      case 'log':
        return 'log${entry.exponent}(${entry.base})';
      case 'ln':
        return 'ln(${entry.base})';
      default:
        return '';
    }
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all exponent calculation history?"),
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
      context.read<ExponentModel>().clearHistory();
    }
  }
}