import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

PercentageModel percentageModel = PercentageModel();

MyProvider providerPercentage = MyProvider(
  name: "Percentage",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Percentage Calculator',
      keywords: 'percentage percent calc discount ratio rate %',
      action: () => percentageModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await percentageModel.init();
  Global.infoModel.addInfoWidget(
    "Percentage",
    ChangeNotifierProvider.value(
      value: percentageModel,
      builder: (context, child) => PercentageCard(),
    ),
    title: "Percentage Calculator",
  );
}

Future<void> _update() async {
  percentageModel.refresh();
}

enum PercentageMode {
  percentageOf,
  whatPercent,
  percentageChange,
  discount,
}

class PercentageHistory {
  final PercentageMode mode;
  final double value1;
  final double value2;
  final double result;
  final DateTime timestamp;

  PercentageHistory({
    required this.mode,
    required this.value1,
    required this.value2,
    required this.result,
    required this.timestamp,
  });

  String get modeLabel {
    switch (mode) {
      case PercentageMode.percentageOf:
        return '${value1}% of ${value2}';
      case PercentageMode.whatPercent:
        return '${value1} is ?% of ${value2}';
      case PercentageMode.percentageChange:
        return 'Change ${value1} to ${value2}';
      case PercentageMode.discount:
        return '${value1}% off ${value2}';
    }
  }

  String toJson() {
    return jsonEncode({
      'mode': mode.index,
      'value1': value1,
      'value2': value2,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  static PercentageHistory fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return PercentageHistory(
      mode: PercentageMode.values[map['mode'] as int],
      value1: (map['value1'] as num).toDouble(),
      value2: (map['value2'] as num).toDouble(),
      result: (map['result'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class PercentageModel extends ChangeNotifier {
  static const int maxHistory = 10;
  static const String _historyKey = 'percentage_history';

  PercentageMode _mode = PercentageMode.percentageOf;
  String _input1 = '';
  String _input2 = '';
  List<PercentageHistory> _history = [];
  bool _isInitialized = false;

  PercentageMode get mode => _mode;
  String get input1 => _input1;
  String get input2 => _input2;
  List<PercentageHistory> get history => _history;
  bool get isInitialized => _isInitialized;
  bool get hasHistory => _history.isNotEmpty;

  double? get value1 {
    final v = double.tryParse(_input1);
    return v;
  }

  double? get value2 {
    final v = double.tryParse(_input2);
    return v;
  }

  String get modeLabel {
    switch (_mode) {
      case PercentageMode.percentageOf:
        return 'What is X% of Y?';
      case PercentageMode.whatPercent:
        return 'X is what % of Y?';
      case PercentageMode.percentageChange:
        return 'Percentage Change';
      case PercentageMode.discount:
        return 'Discount Calculator';
    }
  }

  double? calculate() {
    final v1 = value1;
    final v2 = value2;
    if (v1 == null || v2 == null) return null;

    switch (_mode) {
      case PercentageMode.percentageOf:
        return v1 / 100 * v2;
      case PercentageMode.whatPercent:
        if (v2 == 0) return null;
        return v1 / v2 * 100;
      case PercentageMode.percentageChange:
        if (v1 == 0) return null;
        return (v2 - v1) / v1 * 100;
      case PercentageMode.discount:
        return v2 - (v1 / 100 * v2);
    }
  }

  String get resultLabel {
    final result = calculate();
    if (result == null) return '';

    switch (_mode) {
      case PercentageMode.percentageOf:
        return '${result.toStringAsFixed(2)}';
      case PercentageMode.whatPercent:
        return '${result.toStringAsFixed(2)}%';
      case PercentageMode.percentageChange:
        final sign = result >= 0 ? '+' : '';
        return '${sign}${result.toStringAsFixed(2)}%';
      case PercentageMode.discount:
        return '\$${result.toStringAsFixed(2)} (saved \$${(value2! - result).toStringAsFixed(2)})';
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    await _loadHistory();
    _isInitialized = true;
    Global.loggerModel.info("Percentage Calculator initialized with ${_history.length} history entries");
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getStringList(_historyKey) ?? [];
    _history = historyStr.map((s) => PercentageHistory.fromJson(s)).toList();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = _history.map((h) => h.toJson()).toList();
    await prefs.setStringList(_historyKey, historyStr);
  }

  void setMode(PercentageMode newMode) {
    _mode = newMode;
    notifyListeners();
  }

  void setInput1(String value) {
    _input1 = value;
    notifyListeners();
  }

  void setInput2(String value) {
    _input2 = value;
    notifyListeners();
  }

  void addToHistory() {
    final result = calculate();
    if (result == null) return;

    final entry = PercentageHistory(
      mode: _mode,
      value1: value1!,
      value2: value2!,
      result: result,
      timestamp: DateTime.now(),
    );

    _history.insert(0, entry);
    if (_history.length > maxHistory) {
      _history.removeLast();
    }
    _saveHistory();
    Global.loggerModel.info("Percentage history saved: ${entry.modeLabel}");
    notifyListeners();
  }

  void loadFromHistory(PercentageHistory entry) {
    _mode = entry.mode;
    _input1 = entry.value1.toString();
    _input2 = entry.value2.toString();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _saveHistory();
    Global.loggerModel.info("Percentage history cleared");
    notifyListeners();
  }

  void clearInputs() {
    _input1 = '';
    _input2 = '';
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class PercentageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<PercentageModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Percentage Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            SegmentedButton<PercentageMode>(
              segments: [
                ButtonSegment(value: PercentageMode.percentageOf, label: Text('X% of Y')),
                ButtonSegment(value: PercentageMode.whatPercent, label: Text('% of Y')),
                ButtonSegment(value: PercentageMode.percentageChange, label: Text('Change')),
                ButtonSegment(value: PercentageMode.discount, label: Text('Discount')),
              ],
              selected: {model.mode},
              onSelectionChanged: (Set<PercentageMode> selection) {
                model.setMode(selection.first);
              },
              style: ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            SizedBox(height: 16),
            _buildInputFields(context, model),
            SizedBox(height: 12),
            _buildResult(context, model),
            if (model.hasHistory) SizedBox(height: 12),
            if (model.hasHistory) _buildHistorySection(context, model),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields(BuildContext context, PercentageModel model) {
    String label1;
    String label2;
    String prefix1 = '';
    String prefix2 = '';

    switch (model.mode) {
      case PercentageMode.percentageOf:
        label1 = 'Percentage (%)';
        label2 = 'Value';
        break;
      case PercentageMode.whatPercent:
        label1 = 'Value';
        label2 = 'Total';
        break;
      case PercentageMode.percentageChange:
        label1 = 'Original';
        label2 = 'New Value';
        prefix1 = '\$';
        prefix2 = '\$';
        break;
      case PercentageMode.discount:
        label1 = 'Discount (%)';
        label2 = 'Price';
        prefix2 = '\$';
        break;
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: label1,
              prefixText: prefix1,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            controller: TextEditingController(text: model.input1),
            onChanged: model.setInput1,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: label2,
              prefixText: prefix2,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            controller: TextEditingController(text: model.input2),
            onChanged: model.setInput2,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context, PercentageModel model) {
    final result = model.calculate();
    final hasResult = result != null;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasResult
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hasResult ? 'Result: ${model.resultLabel}' : 'Enter values',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasResult
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        if (hasResult) SizedBox(width: 8),
        if (hasResult)
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Save to history',
            onPressed: model.addToHistory,
          ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, PercentageModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
            Spacer(),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20),
              tooltip: 'Clear history',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear History'),
                    content: Text('Clear all calculation history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          model.clearHistory();
                          Navigator.pop(context);
                        },
                        child: Text('Clear'),
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
          children: model.history.take(5).map((entry) {
            return ActionChip(
              label: Text(entry.modeLabel, style: TextStyle(fontSize: 12)),
              onPressed: () => model.loadFromHistory(entry),
            );
          }).toList(),
        ),
      ],
    );
  }
}