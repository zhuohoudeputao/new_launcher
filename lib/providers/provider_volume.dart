import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

VolumeConverterModel volumeConverterModel = VolumeConverterModel();

MyProvider providerVolumeConverter = MyProvider(
    name: "VolumeConverter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Volume Converter',
      keywords: 'volume convert liter gallon ml milliliter quart pint cup fluid ounce cubic meter cm3 in3 cc',
      action: () => volumeConverterModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  volumeConverterModel.init();
  Global.infoModel.addInfoWidget(
      "VolumeConverter",
      ChangeNotifierProvider.value(
          value: volumeConverterModel,
          builder: (context, child) => VolumeConverterCard()),
      title: "Volume Converter");
}

Future<void> _update() async {
  volumeConverterModel.refresh();
}

const Map<String, String> volumeUnits = {
  'liter': 'L',
  'milliliter': 'mL',
  'gallon': 'gal',
  'quart': 'qt',
  'pint': 'pt',
  'cup': 'cup',
  'floz': 'fl oz',
  'm3': 'm³',
  'cm3': 'cm³',
  'in3': 'in³',
};

class VolumeConversionHistory {
  final double inputValue;
  final String inputUnit;
  final double outputValue;
  final String outputUnit;
  final DateTime timestamp;

  VolumeConversionHistory({
    required this.inputValue,
    required this.inputUnit,
    required this.outputValue,
    required this.outputUnit,
    required this.timestamp,
  });

  String get inputSymbol => volumeUnits[inputUnit] ?? inputUnit;
  String get outputSymbol => volumeUnits[outputUnit] ?? outputUnit;
}

class VolumeConverterModel extends ChangeNotifier {
  String _inputUnit = 'liter';
  String _outputUnit = 'gallon';
  String _inputValue = '0';
  String _outputValue = '0';
  bool _isInitialized = false;
  final List<VolumeConversionHistory> _history = [];
  static const int maxHistory = 10;

  String get inputUnit => _inputUnit;
  String get outputUnit => _outputUnit;
  String get inputValue => _inputValue;
  String get outputValue => _outputValue;
  bool get isInitialized => _isInitialized;
  List<VolumeConversionHistory> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  List<String> get availableUnits => volumeUnits.keys.toList();

  void init() {
    _isInitialized = true;
    _convert();
    Global.loggerModel.info("VolumeConverter initialized", source: "VolumeConverter");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("VolumeConverter refreshed", source: "VolumeConverter");
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
    Global.loggerModel.info("Volume units swapped", source: "VolumeConverter");
  }

  void clear() {
    _inputValue = '0';
    _convert();
    notifyListeners();
    Global.loggerModel.info("VolumeConverter cleared", source: "VolumeConverter");
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

    const litersPerUnit = {
      'liter': 1.0,
      'milliliter': 0.001,
      'gallon': 3.785411784,
      'quart': 0.946352946,
      'pint': 0.473176473,
      'cup': 0.2365882365,
      'floz': 0.0295735295625,
      'm3': 1000.0,
      'cm3': 0.001,
      'in3': 0.016387064,
    };

    final literValue = value * (litersPerUnit[fromUnit] ?? 1.0);
    return literValue / (litersPerUnit[toUnit] ?? 1.0);
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

    _history.insert(0, VolumeConversionHistory(
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
    Global.loggerModel.info("Volume conversion added to history", source: "VolumeConverter");
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("VolumeConverter history cleared", source: "VolumeConverter");
  }

  void useHistoryEntry(VolumeConversionHistory entry) {
    _inputUnit = entry.inputUnit;
    _outputUnit = entry.outputUnit;
    _inputValue = entry.inputValue.toString();
    _convert();
    notifyListeners();
  }
}

class VolumeConverterCard extends StatefulWidget {
  @override
  State<VolumeConverterCard> createState() => _VolumeConverterCardState();
}

class _VolumeConverterCardState extends State<VolumeConverterCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final converter = context.watch<VolumeConverterModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!converter.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.water_drop, size: 24),
              SizedBox(width: 12),
              Text("Volume Converter: Loading..."),
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
                  "Volume Converter",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (converter.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.water_drop : Icons.history, size: 18),
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

  Widget _buildConverterView(VolumeConverterModel converter) {
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

  Widget _buildInputSection(VolumeConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.inputUnit, true),
        SizedBox(height: 4),
        _buildValueField(converter, true),
      ],
    );
  }

  Widget _buildOutputSection(VolumeConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.outputUnit, false),
        SizedBox(height: 4),
        _buildValueField(converter, false),
      ],
    );
  }

  Widget _buildUnitDropdown(VolumeConverterModel converter, String currentUnit, bool isInput) {
    final units = converter.availableUnits;

    return DropdownButton<String>(
      value: currentUnit,
      isExpanded: true,
      underline: Container(),
      items: units.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(
            volumeUnits[unit] ?? unit,
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

  Widget _buildValueField(VolumeConverterModel converter, bool isInput) {
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

  Widget _buildHistoryView(VolumeConverterModel converter) {
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
        content: Text("Clear all volume conversion history?"),
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
      context.read<VolumeConverterModel>().clearHistory();
    }
  }
}