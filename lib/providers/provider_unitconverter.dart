import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

UnitConverterModel unitConverterModel = UnitConverterModel();

MyProvider providerUnitConverter = MyProvider(
    name: "UnitConverter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Unit Converter',
      keywords: 'convert unit temperature length weight mass distance cm m km inch foot mile celsius fahrenheit kg lb gram ounce',
      action: () => unitConverterModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  unitConverterModel.init();
  Global.infoModel.addInfoWidget(
      "UnitConverter",
      ChangeNotifierProvider.value(
          value: unitConverterModel,
          builder: (context, child) => UnitConverterCard()),
      title: "Unit Converter");
}

Future<void> _update() async {
  unitConverterModel.refresh();
}

enum ConversionCategory { temperature, length, weight }

class UnitType {
  final String name;
  final String symbol;
  final ConversionCategory category;
  
  const UnitType({
    required this.name,
    required this.symbol,
    required this.category,
  });
}

const Map<String, UnitType> unitTypes = {
  'celsius': UnitType(name: 'Celsius', symbol: '°C', category: ConversionCategory.temperature),
  'fahrenheit': UnitType(name: 'Fahrenheit', symbol: '°F', category: ConversionCategory.temperature),
  'kelvin': UnitType(name: 'Kelvin', symbol: 'K', category: ConversionCategory.temperature),
  'meter': UnitType(name: 'Meter', symbol: 'm', category: ConversionCategory.length),
  'kilometer': UnitType(name: 'Kilometer', symbol: 'km', category: ConversionCategory.length),
  'centimeter': UnitType(name: 'Centimeter', symbol: 'cm', category: ConversionCategory.length),
  'millimeter': UnitType(name: 'Millimeter', symbol: 'mm', category: ConversionCategory.length),
  'inch': UnitType(name: 'Inch', symbol: 'in', category: ConversionCategory.length),
  'foot': UnitType(name: 'Foot', symbol: 'ft', category: ConversionCategory.length),
  'mile': UnitType(name: 'Mile', symbol: 'mi', category: ConversionCategory.length),
  'yard': UnitType(name: 'Yard', symbol: 'yd', category: ConversionCategory.length),
  'kilogram': UnitType(name: 'Kilogram', symbol: 'kg', category: ConversionCategory.weight),
  'gram': UnitType(name: 'Gram', symbol: 'g', category: ConversionCategory.weight),
  'milligram': UnitType(name: 'Milligram', symbol: 'mg', category: ConversionCategory.weight),
  'pound': UnitType(name: 'Pound', symbol: 'lb', category: ConversionCategory.weight),
  'ounce': UnitType(name: 'Ounce', symbol: 'oz', category: ConversionCategory.weight),
};

List<String> getUnitsForCategory(ConversionCategory category) {
  return unitTypes.entries
      .where((e) => e.value.category == category)
      .map((e) => e.key)
      .toList();
}

class ConversionHistory {
  final double inputValue;
  final String inputUnit;
  final double outputValue;
  final String outputUnit;
  final ConversionCategory category;
  final DateTime timestamp;

  ConversionHistory({
    required this.inputValue,
    required this.inputUnit,
    required this.outputValue,
    required this.outputUnit,
    required this.category,
    required this.timestamp,
  });
  
  String get inputSymbol => unitTypes[inputUnit]?.symbol ?? inputUnit;
  String get outputSymbol => unitTypes[outputUnit]?.symbol ?? outputUnit;
}

class UnitConverterModel extends ChangeNotifier {
  ConversionCategory _selectedCategory = ConversionCategory.temperature;
  String _inputUnit = 'celsius';
  String _outputUnit = 'fahrenheit';
  String _inputValue = '0';
  String _outputValue = '32';
  bool _isInitialized = false;
  final List<ConversionHistory> _history = [];
  static const int maxHistory = 10;

  ConversionCategory get selectedCategory => _selectedCategory;
  String get inputUnit => _inputUnit;
  String get outputUnit => _outputUnit;
  String get inputValue => _inputValue;
  String get outputValue => _outputValue;
  bool get isInitialized => _isInitialized;
  List<ConversionHistory> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  
  List<String> get availableUnits => getUnitsForCategory(_selectedCategory);

  void init() {
    _isInitialized = true;
    _updateDefaultUnits();
    _convert();
    Global.loggerModel.info("UnitConverter initialized", source: "UnitConverter");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("UnitConverter refreshed", source: "UnitConverter");
  }

  void setCategory(ConversionCategory category) {
    _selectedCategory = category;
    _updateDefaultUnits();
    _convert();
    notifyListeners();
  }

  void _updateDefaultUnits() {
    final units = getUnitsForCategory(_selectedCategory);
    if (units.isNotEmpty) {
      _inputUnit = units[0];
      _outputUnit = units.length > 1 ? units[1] : units[0];
    }
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
    Global.loggerModel.info("Units swapped", source: "UnitConverter");
  }

  void clear() {
    _inputValue = '0';
    _convert();
    notifyListeners();
    Global.loggerModel.info("UnitConverter cleared", source: "UnitConverter");
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
    
    final fromCategory = unitTypes[fromUnit]?.category;
    final toCategory = unitTypes[toUnit]?.category;
    
    if (fromCategory != toCategory) {
      throw Exception('Cannot convert between different categories');
    }
    
    switch (fromCategory) {
      case ConversionCategory.temperature:
        return _convertTemperature(value, fromUnit, toUnit);
      case ConversionCategory.length:
        return _convertLength(value, fromUnit, toUnit);
      case ConversionCategory.weight:
        return _convertWeight(value, fromUnit, toUnit);
      default:
        return value;
    }
  }

  static double _convertTemperature(double value, String from, String to) {
    double celsius;
    
    switch (from) {
      case 'celsius':
        celsius = value;
        break;
      case 'fahrenheit':
        celsius = (value - 32) * 5 / 9;
        break;
      case 'kelvin':
        celsius = value - 273.15;
        break;
      default:
        celsius = value;
    }
    
    switch (to) {
      case 'celsius':
        return celsius;
      case 'fahrenheit':
        return celsius * 9 / 5 + 32;
      case 'kelvin':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  static double _convertLength(double value, String from, String to) {
    const metersPerUnit = {
      'meter': 1.0,
      'kilometer': 1000.0,
      'centimeter': 0.01,
      'millimeter': 0.001,
      'inch': 0.0254,
      'foot': 0.3048,
      'mile': 1609.344,
      'yard': 0.9144,
    };
    
    final meters = value * (metersPerUnit[from] ?? 1.0);
    return meters / (metersPerUnit[to] ?? 1.0);
  }

  static double _convertWeight(double value, String from, String to) {
    const gramsPerUnit = {
      'kilogram': 1000.0,
      'gram': 1.0,
      'milligram': 0.001,
      'pound': 453.592,
      'ounce': 28.3495,
    };
    
    final grams = value * (gramsPerUnit[from] ?? 1.0);
    return grams / (gramsPerUnit[to] ?? 1.0);
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
    
    _history.insert(0, ConversionHistory(
      inputValue: input,
      inputUnit: _inputUnit,
      outputValue: output,
      outputUnit: _outputUnit,
      category: _selectedCategory,
      timestamp: DateTime.now(),
    ));
    
    while (_history.length > maxHistory) {
      _history.removeLast();
    }
    
    notifyListeners();
    Global.loggerModel.info("Conversion added to history", source: "UnitConverter");
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("UnitConverter history cleared", source: "UnitConverter");
  }

  void useHistoryEntry(ConversionHistory entry) {
    _selectedCategory = entry.category;
    _inputUnit = entry.inputUnit;
    _outputUnit = entry.outputUnit;
    _inputValue = entry.inputValue.toString();
    _convert();
    notifyListeners();
  }
}

class UnitConverterCard extends StatefulWidget {
  @override
  State<UnitConverterCard> createState() => _UnitConverterCardState();
}

class _UnitConverterCardState extends State<UnitConverterCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final converter = context.watch<UnitConverterModel>();
    final colorScheme = Theme.of(context).colorScheme;
    
    if (!converter.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.swap_horiz, size: 24),
              SizedBox(width: 12),
              Text("Unit Converter: Loading..."),
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
                  "Unit Converter",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (converter.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.swap_horiz : Icons.history, size: 18),
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

  Widget _buildConverterView(UnitConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCategorySelector(converter),
        SizedBox(height: 12),
        _buildConversionRow(converter),
      ],
    );
  }

  Widget _buildCategorySelector(UnitConverterModel converter) {
    return SegmentedButton<ConversionCategory>(
      segments: [
        ButtonSegment(
          value: ConversionCategory.temperature,
          label: Text("Temp"),
          icon: Icon(Icons.thermostat, size: 16),
        ),
        ButtonSegment(
          value: ConversionCategory.length,
          label: Text("Length"),
          icon: Icon(Icons.straighten, size: 16),
        ),
        ButtonSegment(
          value: ConversionCategory.weight,
          label: Text("Weight"),
          icon: Icon(Icons.scale, size: 16),
        ),
      ],
      selected: {converter.selectedCategory},
      onSelectionChanged: (Set<ConversionCategory> newSelection) {
        converter.setCategory(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildConversionRow(UnitConverterModel converter) {
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

  Widget _buildInputSection(UnitConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.inputUnit, true),
        SizedBox(height: 4),
        _buildValueField(converter, true),
      ],
    );
  }

  Widget _buildOutputSection(UnitConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.outputUnit, false),
        SizedBox(height: 4),
        _buildValueField(converter, false),
      ],
    );
  }

  Widget _buildUnitDropdown(UnitConverterModel converter, String currentUnit, bool isInput) {
    final units = converter.availableUnits;
    
    return DropdownButton<String>(
      value: currentUnit,
      isExpanded: true,
      underline: Container(),
      items: units.map((unit) {
        final type = unitTypes[unit];
        return DropdownMenuItem(
          value: unit,
          child: Text(
            type?.symbol ?? unit,
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

  Widget _buildValueField(UnitConverterModel converter, bool isInput) {
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

  Widget _buildHistoryView(UnitConverterModel converter) {
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
        content: Text("Clear all conversion history?"),
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
      context.read<UnitConverterModel>().clearHistory();
    }
  }
}