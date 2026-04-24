import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

TimestampModel timestampModel = TimestampModel();

MyProvider providerTimestamp = MyProvider(
    name: "Timestamp",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Timestamp Converter',
      keywords: 'timestamp unix datetime epoch time convert date',
      action: () => timestampModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  timestampModel.init();
  Global.infoModel.addInfoWidget(
      "Timestamp",
      ChangeNotifierProvider.value(
          value: timestampModel,
          builder: (context, child) => TimestampCard()),
      title: "Timestamp Converter");
}

Future<void> _update() async {
  timestampModel.refresh();
}

class TimestampHistory {
  final String inputValue;
  final String inputType;
  final String outputValue;
  final DateTime timestamp;

  TimestampHistory({
    required this.inputValue,
    required this.inputType,
    required this.outputValue,
    required this.timestamp,
  });
}

class TimestampModel extends ChangeNotifier {
  String _inputValue = '';
  String _inputType = 'timestamp';
  String _outputValue = '';
  List<TimestampHistory> _history = [];
  bool _isLoading = false;
  String? _error;

  static const int maxHistoryLength = 10;

  String get inputValue => _inputValue;
  String get inputType => _inputType;
  String get outputValue => _outputValue;
  List<TimestampHistory> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentTimestamp => DateTime.now().millisecondsSinceEpoch;

  void init() {
    _isLoading = true;
    notifyListeners();
    _isLoading = false;
    notifyListeners();
  }

  void setInputValue(String value) {
    _inputValue = value.trim();
    _error = null;
    _convert();
    notifyListeners();
  }

  void setInputType(String type) {
    _inputType = type;
    _error = null;
    _convert();
    notifyListeners();
  }

  void swapInputType() {
    if (_inputType == 'timestamp') {
      _inputType = 'datetime';
      if (_outputValue.isNotEmpty) {
        _inputValue = _outputValue;
      }
    } else {
      _inputType = 'timestamp';
      if (_outputValue.isNotEmpty) {
        _inputValue = _outputValue;
      }
    }
    _error = null;
    _convert();
    notifyListeners();
  }

  void _convert() {
    if (_inputValue.isEmpty) {
      _outputValue = '';
      return;
    }

    if (_inputType == 'timestamp') {
      _convertTimestampToDatetime();
    } else {
      _convertDatetimeToTimestamp();
    }
  }

  void _convertTimestampToDatetime() {
    try {
      int? timestamp = int.tryParse(_inputValue);
      if (timestamp == null) {
        _error = 'Invalid timestamp';
        _outputValue = '';
        return;
      }

      DateTime dateTime;
      if (timestamp > 1000000000000) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
      } else {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
      }

      _outputValue = _formatDateTime(dateTime);
      _error = null;
    } catch (e) {
      _error = 'Invalid timestamp';
      _outputValue = '';
    }
  }

  void _convertDatetimeToTimestamp() {
    try {
      DateTime? dateTime = DateTime.tryParse(_inputValue);
      if (dateTime == null) {
        _error = 'Invalid datetime format';
        _outputValue = '';
        return;
      }

      int timestamp = dateTime.toUtc().millisecondsSinceEpoch;
      _outputValue = timestamp.toString();
      _error = null;
    } catch (e) {
      _error = 'Invalid datetime format';
      _outputValue = '';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  void setCurrentTimestamp() {
    int ts = DateTime.now().millisecondsSinceEpoch;
    _inputType = 'timestamp';
    _inputValue = ts.toString();
    _error = null;
    _convert();
    notifyListeners();
  }

  void addToHistory() {
    if (_inputValue.isEmpty || _outputValue.isEmpty) return;

    TimestampHistory entry = TimestampHistory(
      inputValue: _inputValue,
      inputType: _inputType,
      outputValue: _outputValue,
      timestamp: DateTime.now(),
    );

    _history.insert(0, entry);
    if (_history.length > maxHistoryLength) {
      _history.removeLast();
    }
    notifyListeners();
  }

  void applyFromHistory(TimestampHistory entry) {
    _inputValue = entry.inputValue;
    _inputType = entry.inputType;
    _error = null;
    _convert();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void clearInput() {
    _inputValue = '';
    _outputValue = '';
    _error = null;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class TimestampCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TimestampModel>(
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
                    Text('Timestamp Converter',
                        style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => model.setCurrentTimestamp(),
                          icon: const Icon(Icons.schedule),
                          tooltip: 'Use current timestamp',
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => model.swapInputType(),
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: 'Swap timestamp/datetime',
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInputSection(context, model),
                const SizedBox(height: 8),
                _buildOutputSection(context, model),
                if (model.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      model.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (model.inputValue.isNotEmpty && model.outputValue.isNotEmpty)
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

  Widget _buildInputSection(BuildContext context, TimestampModel model) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'timestamp', label: Text('Timestamp')),
              ButtonSegment(value: 'datetime', label: Text('Datetime')),
            ],
            selected: {model.inputType},
            onSelectionChanged: (Set<String> newSelection) {
              model.setInputType(newSelection.first);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: TextEditingController(text: model.inputValue),
            decoration: InputDecoration(
              hintText: model.inputType == 'timestamp' 
                  ? 'Enter timestamp (ms or s)' 
                  : 'YYYY-MM-DD HH:MM:SS',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: model.inputValue.isNotEmpty
                  ? IconButton(
                      onPressed: () => model.clearInput(),
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'Clear',
                    )
                  : null,
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (value) => model.setInputValue(value),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputSection(BuildContext context, TimestampModel model) {
    String outputLabel = model.inputType == 'timestamp' ? 'Datetime' : 'Timestamp';
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            outputLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildHistoryItem(BuildContext context, TimestampModel model, TimestampHistory entry) {
    return InkWell(
      onTap: () => model.applyFromHistory(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmationDialog(BuildContext context, TimestampModel model) {
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