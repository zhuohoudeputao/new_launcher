import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

NumberBaseModel numberBaseModel = NumberBaseModel();

MyProvider providerNumberBase = MyProvider(
    name: "NumberBase",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Number Base Converter',
      keywords: 'convert number base binary octal decimal hex hexadecimal bin oct dec',
      action: () => numberBaseModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  numberBaseModel.init();
  Global.infoModel.addInfoWidget(
      "NumberBase",
      ChangeNotifierProvider.value(
          value: numberBaseModel,
          builder: (context, child) => NumberBaseCard()),
      title: "Number Base Converter");
}

Future<void> _update() async {
  numberBaseModel.refresh();
}

enum NumberBase { binary, octal, decimal, hexadecimal }

class NumberBaseType {
  final String name;
  final String suffix;
  final int radix;
  final NumberBase base;

  const NumberBaseType({
    required this.name,
    required this.suffix,
    required this.radix,
    required this.base,
  });
}

const Map<String, NumberBaseType> numberBaseTypes = {
  'binary': NumberBaseType(name: 'Binary', suffix: 'BIN', radix: 2, base: NumberBase.binary),
  'octal': NumberBaseType(name: 'Octal', suffix: 'OCT', radix: 8, base: NumberBase.octal),
  'decimal': NumberBaseType(name: 'Decimal', suffix: 'DEC', radix: 10, base: NumberBase.decimal),
  'hexadecimal': NumberBaseType(name: 'Hexadecimal', suffix: 'HEX', radix: 16, base: NumberBase.hexadecimal),
};

List<String> getAllBases() {
  return numberBaseTypes.keys.toList();
}

class NumberBaseHistory {
  final String inputValue;
  final String inputBase;
  final String outputValue;
  final String outputBase;
  final DateTime timestamp;

  NumberBaseHistory({
    required this.inputValue,
    required this.inputBase,
    required this.outputValue,
    required this.outputBase,
    required this.timestamp,
  });

  String get inputSuffix => numberBaseTypes[inputBase]?.suffix ?? inputBase;
  String get outputSuffix => numberBaseTypes[outputBase]?.suffix ?? outputBase;
}

class NumberBaseModel extends ChangeNotifier {
  String _inputValue = '';
  String _inputBase = 'decimal';
  String _outputBase = 'binary';
  List<NumberBaseHistory> _history = [];
  bool _isLoading = false;

  static const int maxHistoryLength = 10;

  String get inputValue => _inputValue;
  String get inputBase => _inputBase;
  String get outputBase => _outputBase;
  String get outputValue => _convert(_inputValue, _inputBase, _outputBase);
  List<NumberBaseHistory> get history => _history;
  bool get isLoading => _isLoading;

  void init() {
    _isLoading = true;
    notifyListeners();
    _isLoading = false;
    notifyListeners();
  }

  void setInputValue(String value) {
    String sanitized = _sanitizeInput(value, _inputBase);
    _inputValue = sanitized;
    notifyListeners();
  }

  void setInputBase(String base) {
    _inputBase = base;
    _inputValue = _sanitizeInput(_inputValue, base);
    notifyListeners();
  }

  void setOutputBase(String base) {
    _outputBase = base;
    notifyListeners();
  }

  void swapBases() {
    if (_inputBase == _outputBase) return;
    
    String currentOutput = outputValue;
    String temp = _inputBase;
    _inputBase = _outputBase;
    _outputBase = temp;
    
    _inputValue = _sanitizeInput(currentOutput, _inputBase);
    notifyListeners();
  }

  String _sanitizeInput(String value, String base) {
    int radix = numberBaseTypes[base]?.radix ?? 10;
    String result = '';
    
    for (int i = 0; i < value.length; i++) {
      String char = value[i].toUpperCase();
      if (_isValidDigit(char, radix)) {
        result += char;
      }
    }
    
    return result;
  }

  bool _isValidDigit(String char, int radix) {
    if (radix <= 10) {
      int digit = int.tryParse(char) ?? -1;
      return digit >= 0 && digit < radix;
    } else {
      int digit = int.tryParse(char) ?? -1;
      if (digit >= 0 && digit < radix) return true;
      if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 70) {
        int hexValue = char.codeUnitAt(0) - 55;
        return hexValue < radix;
      }
      return false;
    }
  }

  String _convert(String value, String inputBaseKey, String outputBaseKey) {
    if (value.isEmpty) return '';
    
    NumberBaseType? inputType = numberBaseTypes[inputBaseKey];
    NumberBaseType? outputType = numberBaseTypes[outputBaseKey];
    
    if (inputType == null || outputType == null) return '';
    
    try {
      int decimalValue = int.parse(value, radix: inputType.radix);
      String result = decimalValue.toRadixString(outputType.radix).toUpperCase();
      return result;
    } catch (e) {
      return '';
    }
  }

  void addToHistory() {
    if (_inputValue.isEmpty) return;
    
    NumberBaseHistory entry = NumberBaseHistory(
      inputValue: _inputValue,
      inputBase: _inputBase,
      outputValue: outputValue,
      outputBase: _outputBase,
      timestamp: DateTime.now(),
    );
    
    _history.insert(0, entry);
    if (_history.length > maxHistoryLength) {
      _history.removeLast();
    }
    notifyListeners();
  }

  void applyFromHistory(NumberBaseHistory entry) {
    _inputValue = entry.inputValue;
    _inputBase = entry.inputBase;
    _outputBase = entry.outputBase;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class NumberBaseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NumberBaseModel>(
      builder: (context, model, child) {
        return Card.filled(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Number Base Converter',
                        style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      onPressed: () => model.swapBases(),
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Swap bases',
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInputSection(context, model),
                const SizedBox(height: 8),
                _buildOutputSection(context, model),
                if (model.inputValue.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        model.addToHistory();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to history'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      child: const Text('Add to History'),
                    ),
                  ),
                if (model.history.isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('History',
                          style: Theme.of(context).textTheme.titleSmall),
                      TextButton(
                        onPressed: () => _showClearConfirmationDialog(context, model),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...model.history.map((entry) => _buildHistoryItem(context, model, entry)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection(BuildContext context, NumberBaseModel model) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButton<String>(
            value: model.inputBase,
            isExpanded: true,
            items: getAllBases().map((base) {
              return DropdownMenuItem(
                value: base,
                child: Text(numberBaseTypes[base]?.suffix ?? base),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) model.setInputBase(value);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: TextEditingController(text: model.inputValue),
            decoration: const InputDecoration(
              hintText: 'Enter number',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (value) => model.setInputValue(value),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputSection(BuildContext context, NumberBaseModel model) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButton<String>(
            value: model.outputBase,
            isExpanded: true,
            items: getAllBases().map((base) {
              return DropdownMenuItem(
                value: base,
                child: Text(numberBaseTypes[base]?.suffix ?? base),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) model.setOutputBase(value);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              model.outputValue.isNotEmpty ? model.outputValue : '-',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: model.outputValue.isNotEmpty
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, NumberBaseModel model, NumberBaseHistory entry) {
    return InkWell(
      onTap: () => model.applyFromHistory(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Text(
              '${entry.inputValue} ${entry.inputSuffix}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.arrow_forward, size: 16),
            ),
            Text(
              '${entry.outputValue} ${entry.outputSuffix}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmationDialog(BuildContext context, NumberBaseModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all conversion history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              model.clearHistory();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}