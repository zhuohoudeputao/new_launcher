import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

FrequencyConverterModel frequencyConverterModel = FrequencyConverterModel();

MyProvider providerFrequencyConverter = MyProvider(
    name: "FrequencyConverter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Frequency Converter',
      keywords: 'frequency hz khz mhz ghz thz convert audio radio wave signal',
      action: () => frequencyConverterModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  frequencyConverterModel.init();
  Global.infoModel.addInfoWidget(
      "FrequencyConverter",
      ChangeNotifierProvider.value(
          value: frequencyConverterModel,
          builder: (context, child) => FrequencyConverterCard()),
      title: "Frequency Converter");
}

Future<void> _update() async {
  frequencyConverterModel.refresh();
}

const Map<String, String> frequencyUnits = {
  'Hz': 'Hz',
  'kHz': 'kHz',
  'MHz': 'MHz',
  'GHz': 'GHz',
  'THz': 'THz',
};

class FrequencyConversionHistory {
  final double inputValue;
  final String inputUnit;
  final double outputValue;
  final String outputUnit;
  final DateTime timestamp;

  FrequencyConversionHistory({
    required this.inputValue,
    required this.inputUnit,
    required this.outputValue,
    required this.outputUnit,
    required this.timestamp,
  });

  String get inputSymbol => frequencyUnits[inputUnit] ?? inputUnit;
  String get outputSymbol => frequencyUnits[outputUnit] ?? outputUnit;
}

class FrequencyConverterModel extends ChangeNotifier {
  String _inputUnit = 'MHz';
  String _outputUnit = 'kHz';
  String _inputValue = '0';
  String _outputValue = '0';
  bool _isInitialized = false;
  final List<FrequencyConversionHistory> _history = [];
  static const int maxHistory = 10;

  String get inputUnit => _inputUnit;
  String get outputUnit => _outputUnit;
  String get inputValue => _inputValue;
  String get outputValue => _outputValue;
  bool get isInitialized => _isInitialized;
  List<FrequencyConversionHistory> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  List<String> get availableUnits => frequencyUnits.keys.toList();

  void init() {
    _isInitialized = true;
    _convert();
    Global.loggerModel.info("FrequencyConverter initialized", source: "FrequencyConverter");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("FrequencyConverter refreshed", source: "FrequencyConverter");
  }

  void setInputUnit(String unit) {
    _inputUnit = unit;
    if (_inputUnit == _outputUnit) {
      final units = availableUnits;
      final otherUnit = units.firstWhere((u) => u != unit, orElse: () => unit);
      _outputUnit = otherUnit;
    }
    _convert();
    notifyListeners();
  }

  void setOutputUnit(String unit) {
    _outputUnit = unit;
    if (_outputUnit == _inputUnit) {
      final units = availableUnits;
      final otherUnit = units.firstWhere((u) => u != unit, orElse: () => unit);
      _inputUnit = otherUnit;
    }
    _convert();
    notifyListeners();
  }

  void setInputValue(String value) {
    _inputValue = value;
    _convert();
    notifyListeners();
  }

  void swapUnits() {
    final temp = _inputUnit;
    _inputUnit = _outputUnit;
    _outputUnit = temp;

    final tempValue = _outputValue;
    _inputValue = tempValue;
    _outputValue = _inputValue;

    _convert();
    notifyListeners();
    Global.loggerModel.info("Frequency units swapped", source: "FrequencyConverter");
  }

  void clear() {
    _inputValue = '0';
    _convert();
    notifyListeners();
    Global.loggerModel.info("FrequencyConverter cleared", source: "FrequencyConverter");
  }

  void _convert() {
    final input = double.tryParse(_inputValue);
    if (input == null) {
      _outputValue = '0';
      return;
    }

    final result = convert(input, _inputUnit, _outputUnit);
    _outputValue = _formatResult(result);
  }

  static double convert(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    const hertzPerUnit = {
      'Hz': 1.0,
      'kHz': 1000.0,
      'MHz': 1000000.0,
      'GHz': 1000000000.0,
      'THz': 1000000000000.0,
    };

    final hzValue = value * (hertzPerUnit[fromUnit] ?? 1.0);
    return hzValue / (hertzPerUnit[toUnit] ?? 1.0);
  }

  String _formatResult(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    String result = value.toStringAsFixed(6);
    result = result.replaceAll(RegExp(r'0+$'), '');
    result = result.replaceAll(RegExp(r'\.$'), '');
    return result;
  }

  void addToHistory() {
    final input = double.tryParse(_inputValue);
    if (input == null || input == 0) return;

    final output = double.tryParse(_outputValue);
    if (output == null) return;

    _history.insert(0, FrequencyConversionHistory(
      inputValue: input,
      inputUnit: _inputUnit,
      outputValue: output,
      outputUnit: _outputUnit,
      timestamp: DateTime.now(),
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }

    notifyListeners();
    Global.loggerModel.info("Frequency conversion added to history", source: "FrequencyConverter");
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("FrequencyConverter history cleared", source: "FrequencyConverter");
  }

  void useHistoryEntry(FrequencyConversionHistory entry) {
    _inputUnit = entry.inputUnit;
    _outputUnit = entry.outputUnit;
    _inputValue = entry.inputValue.toString();
    _convert();
    notifyListeners();
  }
}

class FrequencyConverterCard extends StatefulWidget {
  @override
  State<FrequencyConverterCard> createState() => _FrequencyConverterCardState();
}

class _FrequencyConverterCardState extends State<FrequencyConverterCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final converter = context.watch<FrequencyConverterModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!converter.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.waves, size: 24),
              SizedBox(width: 12),
              Text("Frequency Converter: Loading..."),
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
                  "Frequency Converter",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (converter.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.waves : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Converter" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (converter.hasHistory)
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
            if (_showHistory) _buildHistoryView(converter)
            else _buildConverterView(converter),
          ],
        ),
      ),
    );
  }

  Widget _buildConverterView(FrequencyConverterModel converter) {
    return Row(
      children: [
        Expanded(child: _buildInputSection(converter)),
        IconButton(
          icon: Icon(Icons.swap_horiz),
          onPressed: converter.swapUnits,
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(child: _buildOutputSection(converter)),
      ],
    );
  }

  Widget _buildInputSection(FrequencyConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.inputUnit, true),
        SizedBox(height: 4),
        _buildValueField(converter, true),
      ],
    );
  }

  Widget _buildOutputSection(FrequencyConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.outputUnit, false),
        SizedBox(height: 4),
        _buildValueField(converter, false),
      ],
    );
  }

  Widget _buildUnitDropdown(FrequencyConverterModel converter, String currentUnit, bool isInput) {
    final units = converter.availableUnits;

    return DropdownButton<String>(
      value: currentUnit,
      isExpanded: true,
      underline: Container(),
      items: units.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(
            frequencyUnits[unit] ?? unit,
            style: TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          if (isInput) {
            converter.setInputUnit(value);
          } else {
            converter.setOutputUnit(value);
          }
        }
      },
    );
  }

  Widget _buildValueField(FrequencyConverterModel converter, bool isInput) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isInput) {
      return TextField(
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
        ),
        controller: TextEditingController(text: converter.inputValue),
        onChanged: (value) => converter.setInputValue(value),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Text(
          converter.outputValue,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildHistoryView(FrequencyConverterModel converter) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: converter.history.length,
        itemBuilder: (context, index) {
          final entry = converter.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text('${entry.inputValue} ${entry.inputSymbol}'),
            subtitle: Text(
              '= ${entry.outputValue} ${entry.outputSymbol}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              converter.useHistoryEntry(entry);
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
        content: Text("Clear all frequency conversion history?"),
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
      context.read<FrequencyConverterModel>().clearHistory();
    }
  }
}