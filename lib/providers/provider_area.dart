import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

AreaConverterModel areaConverterModel = AreaConverterModel();

MyProvider providerAreaConverter = MyProvider(
    name: "AreaConverter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Area Converter',
      keywords: 'area convert square meter kilometer centimeter hectare acre foot yard inch mile sq m2 km2',
      action: () => areaConverterModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  areaConverterModel.init();
  Global.infoModel.addInfoWidget(
      "AreaConverter",
      ChangeNotifierProvider.value(
          value: areaConverterModel,
          builder: (context, child) => AreaConverterCard()),
      title: "Area Converter");
}

Future<void> _update() async {
  areaConverterModel.refresh();
}

const Map<String, String> areaUnits = {
  'm2': 'm²',
  'km2': 'km²',
  'cm2': 'cm²',
  'mm2': 'mm²',
  'hectare': 'ha',
  'acre': 'ac',
  'ft2': 'ft²',
  'yd2': 'yd²',
  'in2': 'in²',
  'mi2': 'mi²',
};

class AreaConversionHistory {
  final double inputValue;
  final String inputUnit;
  final double outputValue;
  final String outputUnit;
  final DateTime timestamp;

  AreaConversionHistory({
    required this.inputValue,
    required this.inputUnit,
    required this.outputValue,
    required this.outputUnit,
    required this.timestamp,
  });

  String get inputSymbol => areaUnits[inputUnit] ?? inputUnit;
  String get outputSymbol => areaUnits[outputUnit] ?? outputUnit;
}

class AreaConverterModel extends ChangeNotifier {
  String _inputUnit = 'm2';
  String _outputUnit = 'acre';
  String _inputValue = '0';
  String _outputValue = '0';
  bool _isInitialized = false;
  final List<AreaConversionHistory> _history = [];
  static const int maxHistory = 10;

  String get inputUnit => _inputUnit;
  String get outputUnit => _outputUnit;
  String get inputValue => _inputValue;
  String get outputValue => _outputValue;
  bool get isInitialized => _isInitialized;
  List<AreaConversionHistory> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  List<String> get availableUnits => areaUnits.keys.toList();

  void init() {
    _isInitialized = true;
    _convert();
    Global.loggerModel.info("AreaConverter initialized", source: "AreaConverter");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("AreaConverter refreshed", source: "AreaConverter");
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
    Global.loggerModel.info("Area units swapped", source: "AreaConverter");
  }

  void clear() {
    _inputValue = '0';
    _convert();
    notifyListeners();
    Global.loggerModel.info("AreaConverter cleared", source: "AreaConverter");
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

    const squareMetersPerUnit = {
      'm2': 1.0,
      'km2': 1000000.0,
      'cm2': 0.0001,
      'mm2': 0.000001,
      'hectare': 10000.0,
      'acre': 4046.8564224,
      'ft2': 0.09290304,
      'yd2': 0.83612736,
      'in2': 0.00064516,
      'mi2': 2589988.110336,
    };

    final squareMeterValue = value * (squareMetersPerUnit[fromUnit] ?? 1.0);
    return squareMeterValue / (squareMetersPerUnit[toUnit] ?? 1.0);
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

    _history.insert(0, AreaConversionHistory(
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
    Global.loggerModel.info("Area conversion added to history", source: "AreaConverter");
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("AreaConverter history cleared", source: "AreaConverter");
  }

  void useHistoryEntry(AreaConversionHistory entry) {
    _inputUnit = entry.inputUnit;
    _outputUnit = entry.outputUnit;
    _inputValue = entry.inputValue.toString();
    _convert();
    notifyListeners();
  }
}

class AreaConverterCard extends StatefulWidget {
  @override
  State<AreaConverterCard> createState() => _AreaConverterCardState();
}

class _AreaConverterCardState extends State<AreaConverterCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final converter = context.watch<AreaConverterModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!converter.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.square_foot, size: 24),
              SizedBox(width: 12),
              Text("Area Converter: Loading..."),
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
                  "Area Converter",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (converter.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.square_foot : Icons.history, size: 18),
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

  Widget _buildConverterView(AreaConverterModel converter) {
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

  Widget _buildInputSection(AreaConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.inputUnit, true),
        SizedBox(height: 4),
        _buildValueField(converter, true),
      ],
    );
  }

  Widget _buildOutputSection(AreaConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.outputUnit, false),
        SizedBox(height: 4),
        _buildValueField(converter, false),
      ],
    );
  }

  Widget _buildUnitDropdown(AreaConverterModel converter, String currentUnit, bool isInput) {
    final units = converter.availableUnits;

    return DropdownButton<String>(
      value: currentUnit,
      isExpanded: true,
      underline: Container(),
      items: units.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(
            areaUnits[unit] ?? unit,
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

  Widget _buildValueField(AreaConverterModel converter, bool isInput) {
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

  Widget _buildHistoryView(AreaConverterModel converter) {
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
        content: Text("Clear all area conversion history?"),
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
      context.read<AreaConverterModel>().clearHistory();
    }
  }
}