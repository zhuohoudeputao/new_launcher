import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

FuelConsumptionModel fuelConsumptionModel = FuelConsumptionModel();

MyProvider providerFuel = MyProvider(
    name: "FuelConsumption",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Fuel Consumption Converter',
      keywords: 'fuel consumption mpg l100km kmL miles gallon liter converter efficiency',
      action: () => fuelConsumptionModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  fuelConsumptionModel.init();
  Global.infoModel.addInfoWidget(
      "FuelConsumption",
      ChangeNotifierProvider.value(
          value: fuelConsumptionModel,
          child: const FuelConsumptionCard()),
      title: "Fuel Consumption");
}

Future<void> _update() async {
  fuelConsumptionModel.refresh();
}

class FuelConsumptionModel extends ChangeNotifier {
  static const String _historyKey = 'fuelconsumption_history';
  static const int _maxHistory = 10;

  String _inputValue = '';
  String _outputValue = '0';
  String _inputUnit = 'mpg';
  String _outputUnit = 'L/100km';
  bool _initialized = false;
  List<FuelConsumptionHistoryEntry> _history = [];

  static final Map<String, String> fuelUnits = {
    'mpg': 'Miles per Gallon (US)',
    'mpguk': 'Miles per Gallon (UK)',
    'L/100km': 'Liters per 100 km',
    'km/L': 'Kilometers per Liter',
    'mi/L': 'Miles per Liter',
  };

  static const List<String> availableUnits = ['mpg', 'mpguk', 'L/100km', 'km/L', 'mi/L'];

  String get inputValue => _inputValue;
  String get outputValue => _outputValue;
  String get inputUnit => _inputUnit;
  String get outputUnit => _outputUnit;
  bool get initialized => _initialized;
  List<FuelConsumptionHistoryEntry> get history => List.unmodifiable(_history);

  void init() {
    if (_initialized) return;
    _initialized = true;
    _loadHistory();
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _history = decoded.map((e) => FuelConsumptionHistoryEntry.fromJson(e)).toList();
      }
    } catch (e) {
      Global.loggerModel.error('FuelConsumption load history error: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_history.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      Global.loggerModel.error('FuelConsumption save history error: $e');
    }
  }

  void setInputValue(String value) {
    _inputValue = value;
    _convert();
    notifyListeners();
  }

  void setInputUnit(String unit) {
    if (unit == _outputUnit) {
      _outputUnit = _inputUnit;
    }
    _inputUnit = unit;
    _convert();
    notifyListeners();
  }

  void setOutputUnit(String unit) {
    if (unit == _inputUnit) {
      _inputUnit = _outputUnit;
    }
    _outputUnit = unit;
    _convert();
    notifyListeners();
  }

  void swapUnits() {
    final temp = _inputUnit;
    _inputUnit = _outputUnit;
    _outputUnit = temp;
    _convert();
    notifyListeners();
  }

  void _convert() {
    if (_inputValue.isEmpty) {
      _outputValue = '0';
      return;
    }

    try {
      final input = double.parse(_inputValue);
      if (input <= 0) {
        _outputValue = '0';
        return;
      }

      final litersPer100km = _toLitersPer100km(input, _inputUnit);
      final output = _fromLitersPer100km(litersPer100km, _outputUnit);

      if (output.isNaN || output.isInfinite) {
        _outputValue = '0';
        return;
      }

      _outputValue = output.toStringAsFixed(4);
    } catch (e) {
      _outputValue = '0';
    }
  }

  double _toLitersPer100km(double value, String unit) {
    switch (unit) {
      case 'mpg':
        return 235.214583 / value;
      case 'mpguk':
        return 282.481 / value;
      case 'L/100km':
        return value;
      case 'km/L':
        return 100 / value;
      case 'mi/L':
        return 160.9344 / value;
      default:
        return value;
    }
  }

  double _fromLitersPer100km(double litersPer100km, String unit) {
    if (litersPer100km == 0) return 0;
    switch (unit) {
      case 'mpg':
        return 235.214583 / litersPer100km;
      case 'mpguk':
        return 282.481 / litersPer100km;
      case 'L/100km':
        return litersPer100km;
      case 'km/L':
        return 100 / litersPer100km;
      case 'mi/L':
        return 160.9344 / litersPer100km;
      default:
        return litersPer100km;
    }
  }

  void addToHistory() {
    if (_inputValue.isEmpty || _outputValue == '0') return;

    final entry = FuelConsumptionHistoryEntry(
      inputValue: _inputValue,
      inputUnit: _inputUnit,
      outputValue: _outputValue,
      outputUnit: _outputUnit,
      timestamp: DateTime.now(),
    );

    _history.insert(0, entry);
    if (_history.length > _maxHistory) {
      _history.removeLast();
    }

    _saveHistory();
    Global.loggerModel.info('FuelConsumption conversion added to history');
    notifyListeners();
  }

  void useHistoryEntry(FuelConsumptionHistoryEntry entry) {
    _inputValue = entry.inputValue;
    _inputUnit = entry.inputUnit;
    _outputUnit = entry.outputUnit;
    _convert();
    Global.loggerModel.info('FuelConsumption using history entry');
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      Global.loggerModel.info('FuelConsumption history cleared');
    } catch (e) {
      Global.loggerModel.error('FuelConsumption clear history error: $e');
    }
    notifyListeners();
  }

  void clear() {
    _inputValue = '';
    _outputValue = '0';
    Global.loggerModel.info('FuelConsumption cleared');
    notifyListeners();
  }

  void refresh() {
    Global.loggerModel.info('FuelConsumption refreshed');
    notifyListeners();
  }
}

class FuelConsumptionHistoryEntry {
  final String inputValue;
  final String inputUnit;
  final String outputValue;
  final String outputUnit;
  final DateTime timestamp;

  FuelConsumptionHistoryEntry({
    required this.inputValue,
    required this.inputUnit,
    required this.outputValue,
    required this.outputUnit,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'inputValue': inputValue,
    'inputUnit': inputUnit,
    'outputValue': outputValue,
    'outputUnit': outputUnit,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FuelConsumptionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      FuelConsumptionHistoryEntry(
        inputValue: json['inputValue'] as String,
        inputUnit: json['inputUnit'] as String,
        outputValue: json['outputValue'] as String,
        outputUnit: json['outputUnit'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  String get formattedTimestamp {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

class FuelConsumptionCard extends StatelessWidget {
  const FuelConsumptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FuelConsumptionModel>(builder: (context, model, child) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_gas_station,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Fuel Consumption',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!model.initialized)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Input',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (value) => model.setInputValue(value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: model.inputUnit,
                          items: FuelConsumptionModel.availableUnits
                              .map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              model.setInputUnit(value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: 'Swap units',
                          onPressed: () => model.swapUnits(),
                        ),
                        Expanded(
                          child: Text(
                            '${model.outputValue} ${model.outputUnit}',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: model.outputUnit,
                          items: FuelConsumptionModel.availableUnits
                              .map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              model.setOutputUnit(value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add to History'),
                          onPressed: () => model.addToHistory(),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          onPressed: () => model.clear(),
                        ),
                      ],
                    ),
                    if (model.history.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'History',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: model.history.length,
                          itemBuilder: (context, index) {
                            final entry = model.history[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                '${entry.inputValue} ${entry.inputUnit} → ${entry.outputValue} ${entry.outputUnit}',
                              ),
                              subtitle: Text(entry.formattedTimestamp),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Use this conversion',
                                onPressed: () => model.useHistoryEntry(entry),
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text('Clear History'),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear History'),
                              content: const Text(
                                  'Are you sure you want to clear all history?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await model.clearHistory();
                          }
                        },
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }
}