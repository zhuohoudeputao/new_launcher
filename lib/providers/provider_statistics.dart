import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

StatisticsModel statisticsModel = StatisticsModel();

MyProvider providerStatisticsCalculator = MyProvider(
    name: "Statistics",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Statistics Calculator',
      keywords: 'statistics mean median mode stddev variance average calculator math',
      action: () {
        Global.infoModel.addInfo(
            "Statistics",
            "Statistics Calculator",
            subtitle: "Calculate statistics from numbers",
            icon: Icon(Icons.analytics),
            onTap: () => statisticsModel.calculate());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  statisticsModel.init();
  Global.infoModel.addInfoWidget(
      "Statistics",
      ChangeNotifierProvider.value(
          value: statisticsModel,
          builder: (context, child) => StatisticsCard()),
      title: "Statistics Calculator");
}

Future<void> _update() async {
  statisticsModel.refresh();
}

class StatisticsModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputNumbers = "";
  double? _mean;
  double? _median;
  List<double>? _mode;
  double? _stdDev;
  double? _variance;
  double? _min;
  double? _max;
  double? _range;
  double? _sum;
  int? _count;
  String _error = "";
  List<String> _history = [];
  
  bool get isInitialized => _isInitialized;
  String get inputNumbers => _inputNumbers;
  double? get mean => _mean;
  double? get median => _median;
  List<double>? get mode => _mode;
  double? get stdDev => _stdDev;
  double? get variance => _variance;
  double? get min => _min;
  double? get max => _max;
  double? get range => _range;
  double? get sum => _sum;
  int? get count => _count;
  String get error => _error;
  List<String> get history => _history;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("Statistics initialized", source: "Statistics");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setInputNumbers(String input) {
    _inputNumbers = input;
    _error = "";
    notifyListeners();
  }

  void calculate() {
    _error = "";
    _mean = null;
    _median = null;
    _mode = null;
    _stdDev = null;
    _variance = null;
    _min = null;
    _max = null;
    _range = null;
    _sum = null;
    _count = null;
    
    if (_inputNumbers.trim().isEmpty) {
      _error = "Enter numbers separated by commas or spaces";
      notifyListeners();
      return;
    }
    
    List<double> numbers = [];
    String cleanedInput = _inputNumbers.replaceAll(',', ' ');
    List<String> parts = cleanedInput.split(RegExp(r'\s+'));
    
    for (String part in parts) {
      if (part.trim().isEmpty) continue;
      double? num = double.tryParse(part.trim());
      if (num == null) {
        _error = "Invalid number: ${part.trim()}";
        notifyListeners();
        return;
      }
      numbers.add(num);
    }
    
    if (numbers.isEmpty) {
      _error = "No valid numbers found";
      notifyListeners();
      return;
    }
    
    _count = numbers.length;
    _sum = numbers.reduce((a, b) => a + b);
    _mean = _sum! / _count!;
    
    List<double> sorted = List.from(numbers);
    sorted.sort();
    _min = sorted.first;
    _max = sorted.last;
    _range = _max! - _min!;
    
    int midIndex = _count! ~/ 2;
    if (_count! % 2 == 0) {
      _median = (sorted[midIndex - 1] + sorted[midIndex]) / 2;
    } else {
      _median = sorted[midIndex];
    }
    
    Map<double, int> frequency = {};
    for (double num in numbers) {
      frequency[num] = (frequency[num] ?? 0) + 1;
    }
    int maxFreq = frequency.values.reduce((a, b) => a > b ? a : b);
    _mode = frequency.entries
        .where((e) => e.value == maxFreq)
        .map((e) => e.key)
        .toList();
    _mode!.sort();
    
    double sumSquaredDiff = 0;
    for (double num in numbers) {
      sumSquaredDiff += pow(num - _mean!, 2);
    }
    _variance = sumSquaredDiff / _count!;
    _stdDev = sqrt(_variance!);
    
    String historyEntry = _formatHistoryEntry(numbers);
    if (_history.length >= 10) {
      _history.removeAt(0);
    }
    _history.add(historyEntry);
    
    Global.loggerModel.info("Statistics calculated for ${_count} numbers", source: "Statistics");
    notifyListeners();
  }

  String _formatHistoryEntry(List<double> numbers) {
    String numsStr = numbers.length <= 5 
        ? numbers.map((n) => n.toStringAsFixed(2)).join(', ')
        : "${numbers.take(3).map((n) => n.toStringAsFixed(2)).join(', ')}... (${numbers.length} numbers)";
    return "$numsStr | Mean: ${_mean!.toStringAsFixed(2)}";
  }

  void loadFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      String entry = _history[index];
      List<String> parts = entry.split(' | ');
      if (parts.isNotEmpty) {
        String numsPart = parts[0];
        if (numsPart.contains('...')) {
          String countMatch = RegExp(r'\((\d+) numbers\)').firstMatch(numsPart)?.group(1) ?? '';
          if (countMatch.isNotEmpty) {
            numsPart = numsPart.replaceAll('...', '').replaceAll('($countMatch numbers)', '').trim();
          }
        }
        _inputNumbers = numsPart;
        calculate();
      }
    }
  }

  void clearHistory() {
    _history = [];
    notifyListeners();
    Global.loggerModel.info("Statistics history cleared", source: "Statistics");
  }

  void clearInput() {
    _inputNumbers = "";
    _error = "";
    _mean = null;
    _median = null;
    _mode = null;
    _stdDev = null;
    _variance = null;
    _min = null;
    _max = null;
    _range = null;
    _sum = null;
    _count = null;
    notifyListeners();
  }

  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String formatNumber(double? value) {
    if (value == null) return "-";
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(4);
  }

  String formatMode(List<double>? values) {
    if (values == null || values.isEmpty) return "-";
    if (values.length == 1) {
      return formatNumber(values.first);
    }
    return values.map((v) => formatNumber(v)).join(', ');
  }
}

class StatisticsCard extends StatefulWidget {
  @override
  State<StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<StatisticsCard> {
  final TextEditingController _inputController = TextEditingController();
  bool _showHistory = false;
  
  @override
  void initState() {
    super.initState();
    _inputController.text = statisticsModel.inputNumbers;
  }
  
  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsModel>();
    
    if (!stats.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.analytics, size: 24),
              SizedBox(width: 12),
              Text("Statistics: Loading..."),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, size: 20),
                SizedBox(width: 8),
                Text(
                  "Statistics Calculator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (stats.history.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _showHistory = !_showHistory);
                    },
                    child: Text(_showHistory ? "Hide" : "History"),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (_showHistory && stats.history.isNotEmpty)
              _buildHistorySection(context, stats),
            if (!_showHistory) ...[
              _buildInputSection(context, stats),
              if (stats.error.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    stats.error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (stats.count != null && stats.error.isEmpty)
                _buildResultsSection(context, stats),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputSection(BuildContext context, StatisticsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter numbers (comma or space separated):",
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _inputController,
          decoration: InputDecoration(
            hintText: "e.g., 1, 2, 3, 4, 5",
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_inputController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _inputController.clear();
                      stats.setInputNumbers("");
                    },
                    tooltip: "Clear input",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.calculate, size: 18),
                  onPressed: () {
                    stats.setInputNumbers(_inputController.text);
                    stats.calculate();
                  },
                  tooltip: "Calculate",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          keyboardType: TextInputType.text,
          style: TextStyle(fontSize: 14),
          onChanged: (value) => stats.setInputNumbers(value),
          onSubmitted: (value) {
            stats.setInputNumbers(value);
            stats.calculate();
          },
        ),
      ],
    );
  }
  
  Widget _buildResultsSection(BuildContext context, StatisticsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Text("Results (${stats.count} numbers):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatChip(context, "Count", "${stats.count}", Icons.list),
            _buildStatChip(context, "Sum", stats.formatNumber(stats.sum), Icons.add),
            _buildStatChip(context, "Min", stats.formatNumber(stats.min), Icons.arrow_downward),
            _buildStatChip(context, "Max", stats.formatNumber(stats.max), Icons.arrow_upward),
            _buildStatChip(context, "Range", stats.formatNumber(stats.range), Icons.compare_arrows),
            _buildStatChip(context, "Mean", stats.formatNumber(stats.mean), Icons.bar_chart),
            _buildStatChip(context, "Median", stats.formatNumber(stats.median), Icons.vertical_align_center),
            _buildStatChip(context, "Mode", stats.formatMode(stats.mode), Icons.filter_list),
            _buildStatChip(context, "Variance", stats.formatNumber(stats.variance), Icons.show_chart),
            _buildStatChip(context, "Std Dev", stats.formatNumber(stats.stdDev), Icons.trending_up),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: () {
                String allStats = "Count: ${stats.count}\n"
                    "Sum: ${stats.formatNumber(stats.sum)}\n"
                    "Min: ${stats.formatNumber(stats.min)}\n"
                    "Max: ${stats.formatNumber(stats.max)}\n"
                    "Range: ${stats.formatNumber(stats.range)}\n"
                    "Mean: ${stats.formatNumber(stats.mean)}\n"
                    "Median: ${stats.formatNumber(stats.median)}\n"
                    "Mode: ${stats.formatMode(stats.mode)}\n"
                    "Variance: ${stats.formatNumber(stats.variance)}\n"
                    "Std Dev: ${stats.formatNumber(stats.stdDev)}";
                stats.copyToClipboard(allStats, context);
              },
              child: Text("Copy all"),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 4),
          Text("$label:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
  
  Widget _buildHistorySection(BuildContext context, StatisticsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("History (${stats.history.length}):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Spacer(),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Clear History"),
                    content: Text("Clear all ${stats.history.length} history entries?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          stats.clearHistory();
                          Navigator.pop(context);
                          setState(() => _showHistory = false);
                        },
                        child: Text("Clear"),
                      ),
                    ],
                  ),
                );
              },
              child: Text("Clear"),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(maxHeight: 150),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: stats.history.length,
            itemBuilder: (context, index) {
              final reversedIndex = stats.history.length - 1 - index;
              return ListTile(
                dense: true,
                title: Text(
                  stats.history[reversedIndex],
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  stats.loadFromHistory(reversedIndex);
                  _inputController.text = stats.inputNumbers;
                  setState(() => _showHistory = false);
                },
                trailing: Icon(Icons.restore, size: 16, color: Theme.of(context).colorScheme.primary),
              );
            },
          ),
        ),
      ],
    );
  }
}