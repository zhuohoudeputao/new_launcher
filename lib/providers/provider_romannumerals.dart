import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

RomanNumeralsModel romanNumeralsModel = RomanNumeralsModel();

MyProvider providerRomanNumerals = MyProvider(
    name: "RomanNumerals",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Roman Numerals Converter',
      keywords: 'roman numeral convert number latin I V X L C D M',
      action: () => romanNumeralsModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  romanNumeralsModel.init();
  Global.infoModel.addInfoWidget(
      "RomanNumerals",
      ChangeNotifierProvider.value(
          value: romanNumeralsModel,
          builder: (context, child) => RomanNumeralsCard()),
      title: "Roman Numerals Converter");
}

Future<void> _update() async {
  romanNumeralsModel.refresh();
}

enum ConversionMode { numberToRoman, romanToNumber }

class RomanNumeralsHistory {
  final String inputValue;
  final String outputValue;
  final ConversionMode mode;
  final DateTime timestamp;

  RomanNumeralsHistory({
    required this.inputValue,
    required this.outputValue,
    required this.mode,
    required this.timestamp,
  });
}

class RomanNumeralsModel extends ChangeNotifier {
  String _inputValue = '';
  ConversionMode _mode = ConversionMode.numberToRoman;
  List<RomanNumeralsHistory> _history = [];
  bool _isLoading = false;
  String _error = '';

  static const int maxHistoryLength = 10;
  static const int minNumber = 1;
  static const int maxNumber = 3999;

  String get inputValue => _inputValue;
  ConversionMode get mode => _mode;
  String get outputValue => _convert();
  List<RomanNumeralsHistory> get history => _history;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasHistory => _history.isNotEmpty;

  static const List<MapEntry<int, String>> romanSymbols = [
    MapEntry(1000, 'M'),
    MapEntry(900, 'CM'),
    MapEntry(500, 'D'),
    MapEntry(400, 'CD'),
    MapEntry(100, 'C'),
    MapEntry(90, 'XC'),
    MapEntry(50, 'L'),
    MapEntry(40, 'XL'),
    MapEntry(10, 'X'),
    MapEntry(9, 'IX'),
    MapEntry(5, 'V'),
    MapEntry(4, 'IV'),
    MapEntry(1, 'I'),
  ];

  void init() {
    Global.loggerModel.info("RomanNumerals initialized", source: "RomanNumerals");
    _isLoading = true;
    notifyListeners();
    _isLoading = false;
    notifyListeners();
  }

  void setInputValue(String value) {
    _inputValue = value;
    _error = '';
    notifyListeners();
  }

  void setMode(ConversionMode mode) {
    _mode = mode;
    _inputValue = '';
    _error = '';
    notifyListeners();
  }

  void swapMode() {
    String currentOutput = outputValue;
    String currentError = _error;
    
    if (_mode == ConversionMode.numberToRoman) {
      _mode = ConversionMode.romanToNumber;
    } else {
      _mode = ConversionMode.numberToRoman;
    }
    
    if (currentOutput.isNotEmpty && currentError.isEmpty) {
      _inputValue = currentOutput;
    } else {
      _inputValue = '';
    }
    _error = '';
    notifyListeners();
  }

  String _convert() {
    if (_inputValue.isEmpty) return '';
    _error = '';

    if (_mode == ConversionMode.numberToRoman) {
      return _numberToRoman(_inputValue);
    } else {
      return _romanToNumber(_inputValue);
    }
  }

  String _numberToRoman(String input) {
    int? number = int.tryParse(input);
    if (number == null) {
      _error = 'Invalid number';
      return '';
    }
    if (number < minNumber) {
      _error = 'Number must be >= 1';
      return '';
    }
    if (number > maxNumber) {
      _error = 'Number must be <= 3999';
      return '';
    }

    String result = '';
    int remaining = number;

    for (var entry in romanSymbols) {
      while (remaining >= entry.key) {
        result += entry.value;
        remaining -= entry.key;
      }
    }

    return result;
  }

  String _romanToNumber(String input) {
    String roman = input.toUpperCase().trim();
    if (roman.isEmpty) {
      _error = 'Invalid Roman numeral';
      return '';
    }

    for (int i = 0; i < roman.length; i++) {
      String c = roman[i];
      if (!_isValidRomanChar(c)) {
        _error = 'Invalid character: $c';
        return '';
      }
    }

    int result = 0;
    int i = 0;

    while (i < roman.length) {
      int value1 = _getRomanValue(roman[i]);
      
      if (i + 1 < roman.length) {
        int value2 = _getRomanValue(roman[i + 1]);
        
        if (value1 < value2) {
          if (!_isValidSubtraction(roman[i], roman[i + 1])) {
            _error = 'Invalid subtraction: ${roman[i]}${roman[i + 1]}';
            return '';
          }
          result += value2 - value1;
          i += 2;
        } else {
          result += value1;
          i++;
        }
      } else {
        result += value1;
        i++;
      }
    }

    String verification = _numberToRomanRaw(result);
    if (verification != roman) {
      _error = 'Not a valid Roman numeral';
      return '';
    }

    return result.toString();
  }

  bool _isValidRomanChar(String c) {
    return c == 'I' || c == 'V' || c == 'X' || c == 'L' || c == 'C' || c == 'D' || c == 'M';
  }

  int _getRomanValue(String c) {
    switch (c) {
      case 'I': return 1;
      case 'V': return 5;
      case 'X': return 10;
      case 'L': return 50;
      case 'C': return 100;
      case 'D': return 500;
      case 'M': return 1000;
      default: return 0;
    }
  }

  bool _isValidSubtraction(String smaller, String larger) {
    Set<String> canSubtractFromVOrX = {'I'};
    Set<String> canSubtractFromLOrC = {'X'};
    Set<String> canSubtractFromDOrM = {'C'};
    
    if (larger == 'V' || larger == 'X') {
      return canSubtractFromVOrX.contains(smaller);
    }
    if (larger == 'L' || larger == 'C') {
      return canSubtractFromLOrC.contains(smaller);
    }
    if (larger == 'D' || larger == 'M') {
      return canSubtractFromDOrM.contains(smaller);
    }
    return false;
  }

  String _numberToRomanRaw(int number) {
    if (number <= 0 || number > 3999) return '';
    
    String result = '';
    int remaining = number;

    for (var entry in romanSymbols) {
      while (remaining >= entry.key) {
        result += entry.value;
        remaining -= entry.key;
      }
    }

    return result;
  }

  void addToHistory() {
    String output = outputValue;
    if (_inputValue.isEmpty || _error.isNotEmpty || output.isEmpty) return;

    RomanNumeralsHistory entry = RomanNumeralsHistory(
      inputValue: _inputValue,
      outputValue: outputValue,
      mode: _mode,
      timestamp: DateTime.now(),
    );

    _history.insert(0, entry);
    if (_history.length > maxHistoryLength) {
      _history.removeLast();
    }
    Global.loggerModel.info("Conversion added to history", source: "RomanNumerals");
    notifyListeners();
  }

  void applyFromHistory(RomanNumeralsHistory entry) {
    _inputValue = entry.inputValue;
    _mode = entry.mode;
    _error = '';
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("History cleared", source: "RomanNumerals");
    notifyListeners();
  }

  void clearInput() {
    _inputValue = '';
    _error = '';
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  static String getModeLabel(ConversionMode mode) {
    return mode == ConversionMode.numberToRoman ? 'Number → Roman' : 'Roman → Number';
  }

  static String getModeIcon(ConversionMode mode) {
    return mode == ConversionMode.numberToRoman ? '123' : 'IV';
  }
}

class RomanNumeralsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RomanNumeralsModel>(
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
                    Text('Roman Numerals Converter',
                        style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      onPressed: () => model.swapMode(),
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Swap conversion direction',
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<ConversionMode>(
                  segments: [
                    ButtonSegment(
                      value: ConversionMode.numberToRoman,
                      label: Text('123→IV'),
                      icon: Icon(Icons.arrow_forward),
                    ),
                    ButtonSegment(
                      value: ConversionMode.romanToNumber,
                      label: Text('IV→123'),
                      icon: Icon(Icons.arrow_back),
                    ),
                  ],
                  selected: {model.mode},
                  onSelectionChanged: (Set<ConversionMode> selection) {
                    model.setMode(selection.first);
                  },
                ),
                const SizedBox(height: 12),
                _buildInputSection(context, model),
                const SizedBox(height: 8),
                _buildOutputSection(context, model),
                if (model.inputValue.isNotEmpty && model.error.isEmpty)
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

  Widget _buildInputSection(BuildContext context, RomanNumeralsModel model) {
    String hintText = model.mode == ConversionMode.numberToRoman
        ? 'Enter number (1-3999)'
        : 'Enter Roman numeral (I, V, X, L, C, D, M)';
    
    TextInputType inputType = model.mode == ConversionMode.numberToRoman
        ? TextInputType.number
        : TextInputType.text;

    return TextField(
      controller: TextEditingController(text: model.inputValue),
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: model.inputValue.isNotEmpty
            ? IconButton(
                onPressed: () => model.clearInput(),
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
              )
            : null,
        errorText: model.error.isNotEmpty ? model.error : null,
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      keyboardType: inputType,
      onChanged: (value) => model.setInputValue(value),
    );
  }

  Widget _buildOutputSection(BuildContext context, RomanNumeralsModel model) {
    String modeLabel = RomanNumeralsModel.getModeLabel(model.mode);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            modeLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            model.outputValue.isNotEmpty ? model.outputValue : '-',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: model.outputValue.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, RomanNumeralsModel model, RomanNumeralsHistory entry) {
    String modeIcon = RomanNumeralsModel.getModeIcon(entry.mode);
    
    return InkWell(
      onTap: () => model.applyFromHistory(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                modeIcon,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              entry.inputValue,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.arrow_forward, size: 16),
            ),
            Text(
              entry.outputValue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmationDialog(BuildContext context, RomanNumeralsModel model) {
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