import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

PowerConverterModel powerConverterModel = PowerConverterModel();

MyProvider providerPowerConverter = MyProvider(
    name: "PowerConverter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Power Converter',
      keywords: 'power convert watt kilowatt horsepower hp mw btu energy wattage',
      action: () => powerConverterModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  powerConverterModel.init();
  Global.infoModel.addInfoWidget(
      "PowerConverter",
      ChangeNotifierProvider.value(
          value: powerConverterModel,
          builder: (context, child) => PowerConverterCard()),
      title: "Power Converter");
}

Future<void> _update() async {
  powerConverterModel.refresh();
}

class PowerUnit {
  final String name;
  final String symbol;
  final double toWattFactor;

  const PowerUnit({
    required this.name,
    required this.symbol,
    required this.toWattFactor,
  });
}

const List<PowerUnit> powerUnits = [
  PowerUnit(name: 'Watt', symbol: 'W', toWattFactor: 1.0),
  PowerUnit(name: 'Kilowatt', symbol: 'kW', toWattFactor: 1000.0),
  PowerUnit(name: 'Megawatt', symbol: 'MW', toWattFactor: 1000000.0),
  PowerUnit(name: 'Horsepower', symbol: 'hp', toWattFactor: 745.7),
  PowerUnit(name: 'BTU/hr', symbol: 'BTU/hr', toWattFactor: 0.293071),
];

class PowerConverterModel extends ChangeNotifier {
  String _inputValue = '';
  PowerUnit _inputUnit = powerUnits[0];
  PowerUnit _outputUnit = powerUnits[1];
  String _outputValue = '';
  List<PowerConversionEntry> _history = [];
  bool _initialized = false;

  String get inputValue => _inputValue;
  PowerUnit get inputUnit => _inputUnit;
  PowerUnit get outputUnit => _outputUnit;
  String get outputValue => _outputValue;
  List<PowerConversionEntry> get history => _history;
  bool get initialized => _initialized;
  List<PowerUnit> get availableUnits => powerUnits;

  void init() {
    if (!_initialized) {
      _initialized = true;
      Global.loggerModel.info("PowerConverter initialized", source: "PowerConverter");
    }
  }

  void setInputValue(String value) {
    _inputValue = value;
    _convert();
    notifyListeners();
  }

  void setInputUnit(PowerUnit unit) {
    _inputUnit = unit;
    if (_inputUnit == _outputUnit) {
      final otherUnit = powerUnits.firstWhere((u) => u != unit, orElse: () => powerUnits[0]);
      _outputUnit = otherUnit;
    }
    _convert();
    notifyListeners();
  }

  void setOutputUnit(PowerUnit unit) {
    _outputUnit = unit;
    if (_outputUnit == _inputUnit) {
      final otherUnit = powerUnits.firstWhere((u) => u != unit, orElse: () => powerUnits[0]);
      _inputUnit = otherUnit;
    }
    _convert();
    notifyListeners();
  }

  void swapUnits() {
    final temp = _inputUnit;
    _inputUnit = _outputUnit;
    _outputUnit = temp;
    _convert();
    notifyListeners();
    Global.loggerModel.info("Power units swapped", source: "PowerConverter");
  }

  void _convert() {
    if (_inputValue.isEmpty) {
      _outputValue = '';
      return;
    }

    try {
      final inputNum = double.parse(_inputValue);
      if (inputNum == 0) {
        _outputValue = '0';
        return;
      }

      final watts = inputNum * _inputUnit.toWattFactor;
      final result = watts / _outputUnit.toWattFactor;

      if (result == result.roundToDouble()) {
        _outputValue = result.round().toString();
      } else if (result.abs() < 0.0001) {
        _outputValue = result.toStringAsFixed(6);
      } else if (result.abs() < 1) {
        _outputValue = result.toStringAsFixed(4);
      } else if (result.abs() < 100) {
        _outputValue = result.toStringAsFixed(2);
      } else {
        _outputValue = result.toStringAsFixed(0);
      }
    } catch (e) {
      _outputValue = '';
    }
  }

  void addToHistory() {
    if (_inputValue.isEmpty || _outputValue.isEmpty) return;

    final inputNum = double.tryParse(_inputValue);
    if (inputNum == null || inputNum == 0) return;

    final entry = PowerConversionEntry(
      inputUnit: _inputUnit,
      inputValue: inputNum,
      outputUnit: _outputUnit,
      outputValue: double.parse(_outputValue),
      timestamp: DateTime.now(),
    );

    _history.insert(0, entry);
    if (_history.length > 10) {
      _history.removeLast();
    }
    Global.loggerModel.info("Power conversion added to history", source: "PowerConverter");
    notifyListeners();
  }

  void useHistoryEntry(PowerConversionEntry entry) {
    _inputUnit = entry.inputUnit;
    _outputUnit = entry.outputUnit;
    _inputValue = entry.inputValue.toString();
    _convert();
    Global.loggerModel.info("PowerConverter cleared", source: "PowerConverter");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("PowerConverter history cleared", source: "PowerConverter");
    notifyListeners();
  }

  void clear() {
    _inputValue = '';
    _outputValue = '';
    notifyListeners();
    Global.loggerModel.info("PowerConverter cleared", source: "PowerConverter");
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("PowerConverter refreshed", source: "PowerConverter");
  }
}

class PowerConversionEntry {
  final PowerUnit inputUnit;
  final double inputValue;
  final PowerUnit outputUnit;
  final double outputValue;
  final DateTime timestamp;

  PowerConversionEntry({
    required this.inputUnit,
    required this.inputValue,
    required this.outputUnit,
    required this.outputValue,
    required this.timestamp,
  });
}

class PowerConverterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PowerConverterModel>(
      builder: (context, model, child) {
        if (!model.initialized) {
          return Card.filled(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Card.filled(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text('Power Converter', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                SizedBox(height: 16),
                _buildConverterRow(context, model),
                if (model.history.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildHistorySection(context, model),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConverterRow(BuildContext context, PowerConverterModel model) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Input',
                  suffixText: model.inputUnit.symbol,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => model.setInputValue(value),
                controller: TextEditingController(text: model.inputValue),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<PowerUnit>(
                value: model.inputUnit,
                decoration: InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                ),
                items: model.availableUnits.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text('${unit.name} (${unit.symbol})'),
                  );
                }).toList(),
                onChanged: (unit) {
                  if (unit != null) model.setInputUnit(unit);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.swap_horiz),
              onPressed: () => model.swapUnits(),
              tooltip: 'Swap units',
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Output',
                  suffixText: model.outputUnit.symbol,
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                controller: TextEditingController(text: model.outputValue),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<PowerUnit>(
                value: model.outputUnit,
                decoration: InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(),
                ),
                items: model.availableUnits.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text('${unit.name} (${unit.symbol})'),
                  );
                }).toList(),
                onChanged: (unit) {
                  if (unit != null) model.setOutputUnit(unit);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => model.clear(),
              child: Text('Clear'),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: model.inputValue.isNotEmpty && model.outputValue.isNotEmpty
                  ? () => model.addToHistory()
                  : null,
              child: Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, PowerConverterModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('History', style: Theme.of(context).textTheme.titleSmall),
            TextButton(
              onPressed: () => _showClearHistoryDialog(context, model),
              child: Text('Clear All'),
            ),
          ],
        ),
        SizedBox(height: 8),
        ...model.history.map((entry) => ListTile(
          dense: true,
          leading: Icon(Icons.history, size: 20),
          title: Text('${entry.inputValue.toStringAsFixed(2)} ${entry.inputUnit.symbol} → ${entry.outputValue.toStringAsFixed(2)} ${entry.outputUnit.symbol}'),
          subtitle: Text(_formatTimestamp(entry.timestamp)),
          onTap: () => model.useHistoryEntry(entry),
        )),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showClearHistoryDialog(BuildContext context, PowerConverterModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear History'),
        content: Text('Are you sure you want to clear all conversion history?'),
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
  }
}