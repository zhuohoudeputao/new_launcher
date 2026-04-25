import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

BitwiseModel bitwiseModel = BitwiseModel();

MyProvider providerBitwise = MyProvider(
    name: "Bitwise",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Bitwise Calculator',
      keywords: 'bitwise bit and or xor not shift calculator binary logic',
      action: () => bitwiseModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  bitwiseModel.init();
  Global.infoModel.addInfoWidget(
      "Bitwise",
      ChangeNotifierProvider.value(
          value: bitwiseModel,
          builder: (context, child) => BitwiseCard()),
      title: "Bitwise Calculator");
}

Future<void> _update() async {
  bitwiseModel.refresh();
}

enum BitwiseOperation { and, or, xor, not, leftShift, rightShift }

class BitwiseOperationType {
  final String name;
  final String symbol;
  final BitwiseOperation operation;
  final bool requiresTwoInputs;

  const BitwiseOperationType({
    required this.name,
    required this.symbol,
    required this.operation,
    required this.requiresTwoInputs,
  });
}

const Map<String, BitwiseOperationType> bitwiseOperations = {
  'and': BitwiseOperationType(name: 'AND', symbol: '&', operation: BitwiseOperation.and, requiresTwoInputs: true),
  'or': BitwiseOperationType(name: 'OR', symbol: '|', operation: BitwiseOperation.or, requiresTwoInputs: true),
  'xor': BitwiseOperationType(name: 'XOR', symbol: '^', operation: BitwiseOperation.xor, requiresTwoInputs: true),
  'not': BitwiseOperationType(name: 'NOT', symbol: '~', operation: BitwiseOperation.not, requiresTwoInputs: false),
  'leftShift': BitwiseOperationType(name: 'Left Shift', symbol: '<<', operation: BitwiseOperation.leftShift, requiresTwoInputs: true),
  'rightShift': BitwiseOperationType(name: 'Right Shift', symbol: '>>', operation: BitwiseOperation.rightShift, requiresTwoInputs: true),
};

List<String> getAllOperations() {
  return bitwiseOperations.keys.toList();
}

class BitwiseHistory {
  final int input1;
  final int? input2;
  final String operation;
  final int result;
  final DateTime timestamp;

  BitwiseHistory({
    required this.input1,
    this.input2,
    required this.operation,
    required this.result,
    required this.timestamp,
  });

  String get operationSymbol => bitwiseOperations[operation]?.symbol ?? operation;
  String get operationName => bitwiseOperations[operation]?.name ?? operation;
  String get resultBinary => result == 0 ? '0' : result.toRadixString(2);
  
  String get expression {
    if (input2 != null) {
      return '$input1 $operationSymbol $input2 = $result';
    } else {
      return '$operationSymbol $input1 = $result';
    }
  }
}

class BitwiseModel extends ChangeNotifier {
  int _input1 = 0;
  int _input2 = 0;
  String _operation = 'and';
  List<BitwiseHistory> _history = [];
  bool _isLoading = false;

  static const int maxHistoryLength = 10;

  int get input1 => _input1;
  int get input2 => _input2;
  String get operation => _operation;
  int get result => _calculate();
  String get input1Binary => _toBinary(_input1);
  String get input2Binary => _toBinary(_input2);
  String get resultBinary => _toBinary(result);
  String get input1Hex => _toHex(_input1);
  String get input2Hex => _toHex(_input2);
  String get resultHex => _toHex(result);
  List<BitwiseHistory> get history => _history;
  bool get isLoading => _isLoading;
  bool get requiresTwoInputs => bitwiseOperations[_operation]?.requiresTwoInputs ?? true;

  void init() {
    _isLoading = true;
    notifyListeners();
    _isLoading = false;
    notifyListeners();
  }

  void setInput1(int value) {
    _input1 = value;
    notifyListeners();
  }

  void setInput2(int value) {
    _input2 = value;
    notifyListeners();
  }

  void setOperation(String op) {
    _operation = op;
    notifyListeners();
  }

  String _toBinary(int value) {
    if (value == 0) return '0';
    String binary = value.toRadixString(2);
    return binary;
  }

  String _toHex(int value) {
    return value.toRadixString(16).toUpperCase();
  }

  int _calculate() {
    BitwiseOperationType? opType = bitwiseOperations[_operation];
    if (opType == null) return 0;

    switch (opType.operation) {
      case BitwiseOperation.and:
        return _input1 & _input2;
      case BitwiseOperation.or:
        return _input1 | _input2;
      case BitwiseOperation.xor:
        return _input1 ^ _input2;
      case BitwiseOperation.not:
        return ~_input1;
      case BitwiseOperation.leftShift:
        return _input1 << _input2;
      case BitwiseOperation.rightShift:
        return _input1 >> _input2;
    }
  }

  void addToHistory() {
    int? secondInput = requiresTwoInputs ? _input2 : null;
    
    BitwiseHistory entry = BitwiseHistory(
      input1: _input1,
      input2: secondInput,
      operation: _operation,
      result: result,
      timestamp: DateTime.now(),
    );
    
    _history.insert(0, entry);
    if (_history.length > maxHistoryLength) {
      _history.removeLast();
    }
    notifyListeners();
  }

  void applyFromHistory(BitwiseHistory entry) {
    _input1 = entry.input1;
    _input2 = entry.input2 ?? 0;
    _operation = entry.operation;
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

class BitwiseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BitwiseModel>(
      builder: (context, model, child) {
        return Card.filled(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bitwise Calculator',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildOperationSelector(context, model),
                const SizedBox(height: 12),
                _buildInputFields(context, model),
                const SizedBox(height: 12),
                _buildResultSection(context, model),
                if (model.input1 != 0 || (model.requiresTwoInputs && model.input2 != 0))
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

  Widget _buildOperationSelector(BuildContext context, BitwiseModel model) {
    return SegmentedButton<String>(
      segments: getAllOperations().map((op) {
        return ButtonSegment(
          value: op,
          label: Text(bitwiseOperations[op]?.symbol ?? op),
        );
      }).toList(),
      selected: {model.operation},
      onSelectionChanged: (Set<String> newSelection) {
        model.setOperation(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildInputFields(BuildContext context, BitwiseModel model) {
    return Column(
      children: [
        _buildInputRow(context, model, 'Input 1', model.input1, model.input1Binary, model.input1Hex, (value) => model.setInput1(value)),
        if (model.requiresTwoInputs) ...[
          const SizedBox(height: 8),
          _buildInputRow(context, model, 'Input 2', model.input2, model.input2Binary, model.input2Hex, (value) => model.setInput2(value)),
        ],
      ],
    );
  }

  Widget _buildInputRow(BuildContext context, BitwiseModel model, String label, int value, String binary, String hex, Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          flex: 2,
          child: TextField(
            controller: TextEditingController(text: value.toString()),
            decoration: const InputDecoration(
              labelText: 'DEC',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.numberWithOptions(signed: true),
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: (text) {
              int? newValue = int.tryParse(text);
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: TextEditingController(text: binary),
            decoration: const InputDecoration(
              labelText: 'BIN',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: (text) {
              String sanitized = text.replaceAll(RegExp(r'[^01]'), '');
              if (sanitized.isNotEmpty) {
                int? newValue = int.tryParse(sanitized, radix: 2);
                if (newValue != null) {
                  onChanged(newValue);
                }
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: TextEditingController(text: hex),
            decoration: const InputDecoration(
              labelText: 'HEX',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.text,
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: (text) {
              String sanitized = text.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
              if (sanitized.isNotEmpty) {
                int? newValue = int.tryParse(sanitized, radix: 16);
                if (newValue != null) {
                  onChanged(newValue);
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(BuildContext context, BitwiseModel model) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Result', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildResultItem(context, 'DEC', model.result.toString()),
              const SizedBox(width: 12),
              _buildResultItem(context, 'BIN', model.resultBinary),
              const SizedBox(width: 12),
              _buildResultItem(context, 'HEX', model.resultHex),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          )),
          SelectableText(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, BitwiseModel model, BitwiseHistory entry) {
    return InkWell(
      onTap: () => model.applyFromHistory(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Text(
              entry.expression,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              entry.resultBinary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmationDialog(BuildContext context, BitwiseModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all calculation history?'),
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