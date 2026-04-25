import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

PressureConverterModel pressureConverterModel = PressureConverterModel();

MyProvider providerPressureConverter = MyProvider(
    name: "PressureConverter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Pressure Converter',
      keywords: 'pressure convert pascal bar psi atmosphere atm kpa mpa torr',
      action: () => pressureConverterModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  pressureConverterModel.init();
  Global.infoModel.addInfoWidget(
      "PressureConverter",
      ChangeNotifierProvider.value(
          value: pressureConverterModel,
          builder: (context, child) => PressureConverterCard()),
      title: "Pressure Converter");
}

Future<void> _update() async {
  pressureConverterModel.refresh();
}

class PressureUnit {
  final String name;
  final String symbol;
  final double toPascalFactor;

  const PressureUnit({
    required this.name,
    required this.symbol,
    required this.toPascalFactor,
  });
}

const List<PressureUnit> pressureUnits = [
  PressureUnit(name: 'Pascal', symbol: 'Pa', toPascalFactor: 1.0),
  PressureUnit(name: 'Kilopascal', symbol: 'kPa', toPascalFactor: 1000.0),
  PressureUnit(name: 'Megapascal', symbol: 'MPa', toPascalFactor: 1000000.0),
  PressureUnit(name: 'Bar', symbol: 'bar', toPascalFactor: 100000.0),
  PressureUnit(name: 'Millibar', symbol: 'mbar', toPascalFactor: 100.0),
  PressureUnit(name: 'PSI', symbol: 'psi', toPascalFactor: 6894.76),
  PressureUnit(name: 'Atmosphere', symbol: 'atm', toPascalFactor: 101325.0),
  PressureUnit(name: 'Torr', symbol: 'Torr', toPascalFactor: 133.322),
];

class PressureConverterModel extends ChangeNotifier {
  String _inputValue = '';
  PressureUnit _inputUnit = pressureUnits[0];
  PressureUnit _outputUnit = pressureUnits[3];
  String _outputValue = '';
  List<PressureConversionEntry> _history = [];
  bool _initialized = false;

  String get inputValue => _inputValue;
  PressureUnit get inputUnit => _inputUnit;
  PressureUnit get outputUnit => _outputUnit;
  String get outputValue => _outputValue;
  List<PressureConversionEntry> get history => _history;
  bool get initialized => _initialized;
  List<PressureUnit> get availableUnits => pressureUnits;

  void init() {
    if (!_initialized) {
      _initialized = true;
      Global.loggerModel.info("PressureConverter initialized", source: "PressureConverter");
    }
  }

  void setInputValue(String value) {
    _inputValue = value;
    _convert();
    notifyListeners();
  }

  void setInputUnit(PressureUnit unit) {
    _inputUnit = unit;
    if (_inputUnit == _outputUnit) {
      final otherUnit = pressureUnits.firstWhere((u) => u != unit, orElse: () => pressureUnits[0]);
      _outputUnit = otherUnit;
    }
    _convert();
    notifyListeners();
  }

  void setOutputUnit(PressureUnit unit) {
    _outputUnit = unit;
    if (_outputUnit == _inputUnit) {
      final otherUnit = pressureUnits.firstWhere((u) => u != unit, orElse: () => pressureUnits[0]);
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
    Global.loggerModel.info("Pressure units swapped", source: "PressureConverter");
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

      final pascals = inputNum * _inputUnit.toPascalFactor;
      final result = pascals / _outputUnit.toPascalFactor;

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

    final entry = PressureConversionEntry(
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
    Global.loggerModel.info("Pressure conversion added to history", source: "PressureConverter");
    notifyListeners();
  }

  void useHistoryEntry(PressureConversionEntry entry) {
    _inputUnit = entry.inputUnit;
    _outputUnit = entry.outputUnit;
    _inputValue = entry.inputValue.toString();
    _convert();
    Global.loggerModel.info("PressureConverter loaded from history", source: "PressureConverter");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("PressureConverter history cleared", source: "PressureConverter");
    notifyListeners();
  }

  void clear() {
    _inputValue = '';
    _outputValue = '';
    notifyListeners();
    Global.loggerModel.info("PressureConverter cleared", source: "PressureConverter");
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("PressureConverter refreshed", source: "PressureConverter");
  }
}

class PressureConversionEntry {
  final PressureUnit inputUnit;
  final double inputValue;
  final PressureUnit outputUnit;
  final double outputValue;
  final DateTime timestamp;

  PressureConversionEntry({
    required this.inputUnit,
    required this.inputValue,
    required this.outputUnit,
    required this.outputValue,
    required this.timestamp,
  });
}

class PressureConverterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PressureConverterModel>(
      builder: (context, model, child) {
        if (!model.initialized) {
          return Card.filled(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Card.filled(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.compress, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text('Pressure Converter', style: Theme.of(context).textTheme.titleMedium),
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

  Widget _buildConverterRow(BuildContext context, PressureConverterModel model) {
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
              child: DropdownButtonFormField<PressureUnit>(
                value: model.inputUnit,
                decoration: InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                ),
                items: model.availableUnits.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit.symbol, overflow: TextOverflow.ellipsis),
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
              child: DropdownButtonFormField<PressureUnit>(
                value: model.outputUnit,
                decoration: InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(),
                ),
                items: model.availableUnits.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit.symbol, overflow: TextOverflow.ellipsis),
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

  Widget _buildHistorySection(BuildContext context, PressureConverterModel model) {
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

  void _showClearHistoryDialog(BuildContext context, PressureConverterModel model) {
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