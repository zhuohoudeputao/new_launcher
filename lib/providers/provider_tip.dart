import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

TipModel tipModel = TipModel();

MyProvider providerTip = MyProvider(
    name: "Tip",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'TipCalculator',
      keywords: 'tip tipcalc calculator bill restaurant dining split',
      action: () => tipModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  tipModel.init();
  Global.infoModel.addInfoWidget(
      "TipCalculator",
      ChangeNotifierProvider.value(
          value: tipModel,
          builder: (context, child) => TipCard()),
      title: "Tip Calculator");
}

Future<void> _update() async {
  tipModel.refresh();
}

class TipCalculation {
  final double billAmount;
  final double tipPercentage;
  final int splitCount;
  final double tipAmount;
  final double totalAmount;
  final double perPerson;
  final double tipPerPerson;
  final DateTime timestamp;

  TipCalculation({
    required this.billAmount,
    required this.tipPercentage,
    required this.splitCount,
    required this.tipAmount,
    required this.totalAmount,
    required this.perPerson,
    required this.tipPerPerson,
    required this.timestamp,
  });
}

class TipModel extends ChangeNotifier {
  double _billAmount = 0;
  double _tipPercentage = 15;
  int _splitCount = 1;
  bool _isInitialized = false;
  final List<TipCalculation> _history = [];
  static const int maxHistory = 10;
  static const List<double> presetPercentages = [10, 15, 18, 20, 25];

  double get billAmount => _billAmount;
  double get tipPercentage => _tipPercentage;
  int get splitCount => _splitCount;
  bool get isInitialized => _isInitialized;
  List<TipCalculation> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  bool get isCustomPercentage => !presetPercentages.contains(_tipPercentage);

  double get tipAmount => _billAmount * _tipPercentage / 100;
  double get totalAmount => _billAmount + tipAmount;
  double get perPerson => totalAmount / _splitCount;
  double get tipPerPerson => tipAmount / _splitCount;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("Tip Calculator initialized", source: "Tip");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Tip Calculator refreshed", source: "Tip");
  }

  void setBillAmount(double amount) {
    _billAmount = amount;
    notifyListeners();
  }

  void setTipPercentage(double percentage) {
    _tipPercentage = percentage;
    notifyListeners();
  }

  void setSplitCount(int count) {
    _splitCount = count.clamp(1, 20);
    notifyListeners();
  }

  void incrementSplit() {
    if (_splitCount < 20) {
      _splitCount++;
      notifyListeners();
    }
  }

  void decrementSplit() {
    if (_splitCount > 1) {
      _splitCount--;
      notifyListeners();
    }
  }

  void clear() {
    _billAmount = 0;
    _tipPercentage = 15;
    _splitCount = 1;
    notifyListeners();
    Global.loggerModel.info("Tip Calculator cleared", source: "Tip");
  }

  void saveToHistory() {
    if (_billAmount <= 0) return;

    _history.insert(0, TipCalculation(
      billAmount: _billAmount,
      tipPercentage: _tipPercentage,
      splitCount: _splitCount,
      tipAmount: tipAmount,
      totalAmount: totalAmount,
      perPerson: perPerson,
      tipPerPerson: tipPerPerson,
      timestamp: DateTime.now(),
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }
    notifyListeners();
    Global.loggerModel.info("Tip calculation saved to history", source: "Tip");
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("Tip history cleared", source: "Tip");
  }

  String formatAmount(double amount) {
    if (amount == amount.round()) {
      return '\$${amount.round()}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }
}

class TipCard extends StatefulWidget {
  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  bool _showHistory = false;
  final TextEditingController _billController = TextEditingController();
  final TextEditingController _customTipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _billController.addListener(_onBillChanged);
    _customTipController.addListener(_onCustomTipChanged);
  }

  @override
  void dispose() {
    _billController.removeListener(_onBillChanged);
    _customTipController.removeListener(_onCustomTipChanged);
    _billController.dispose();
    _customTipController.dispose();
    super.dispose();
  }

  void _onBillChanged() {
    final value = double.tryParse(_billController.text);
    if (value != null) {
      context.read<TipModel>().setBillAmount(value);
    } else if (_billController.text.isEmpty) {
      context.read<TipModel>().setBillAmount(0);
    }
  }

  void _onCustomTipChanged() {
    final value = double.tryParse(_customTipController.text);
    if (value != null && value >= 0 && value <= 100) {
      context.read<TipModel>().setTipPercentage(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = context.watch<TipModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!tip.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.attach_money, size: 24),
              SizedBox(width: 12),
              Text("Tip Calculator: Loading..."),
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
                  "Tip Calculator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tip.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.calculate : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Calculator" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (tip.hasHistory)
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
            if (_showHistory) _buildHistoryView(tip)
            else _buildCalculatorView(tip),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorView(TipModel tip) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBillInput(tip),
        SizedBox(height: 12),
        _buildTipPercentageSelector(tip),
        SizedBox(height: 12),
        _buildSplitSelector(tip),
        SizedBox(height: 16),
        _buildResults(tip),
        SizedBox(height: 8),
        _buildActionButtons(tip),
      ],
    );
  }

  Widget _buildBillInput(TipModel tip) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _billController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: "Bill Amount",
        prefixText: "\$",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
      style: TextStyle(fontSize: 18),
    );
  }

  Widget _buildTipPercentageSelector(TipModel tip) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tip Percentage", style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        SizedBox(height: 8),
        SegmentedButton<double>(
          segments: TipModel.presetPercentages.map((p) =>
            ButtonSegment<double>(
              value: p,
              label: Text("${p}%"),
            )
          ).toList(),
          selected: tip.isCustomPercentage ? {} : {tip.tipPercentage},
          onSelectionChanged: (Set<double> newSelection) {
            if (newSelection.isNotEmpty) {
              context.read<TipModel>().setTipPercentage(newSelection.first);
              _customTipController.clear();
            }
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customTipController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Custom %",
                  suffixText: "%",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSplitSelector(TipModel tip) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Split Between", style: TextStyle(color: colorScheme.onSurfaceVariant)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: tip.splitCount > 1 ? () => tip.decrementSplit() : null,
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${tip.splitCount}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: tip.splitCount < 20 ? () => tip.incrementSplit() : null,
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResults(TipModel tip) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildResultRow("Tip", tip.formatAmount(tip.tipAmount)),
          SizedBox(height: 8),
          _buildResultRow("Total", tip.formatAmount(tip.totalAmount)),
          if (tip.splitCount > 1) ...[
            Divider(height: 16),
            _buildResultRow("Per Person", tip.formatAmount(tip.perPerson), isHighlight: true),
            SizedBox(height: 4),
            _buildResultRow("Tip Each", tip.formatAmount(tip.tipPerPerson)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlight = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isHighlight ? 20 : 16,
            color: isHighlight ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(TipModel tip) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: tip.billAmount > 0 ? () => tip.saveToHistory() : null,
          icon: Icon(Icons.save, size: 18),
          label: Text("Save"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            tip.clear();
            _billController.clear();
            _customTipController.clear();
          },
          icon: Icon(Icons.clear_all, size: 18),
          label: Text("Clear"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(TipModel tip) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: tip.history.length,
        itemBuilder: (context, index) {
          final entry = tip.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.attach_money, size: 20),
            title: Text("Bill: ${tip.formatAmount(entry.billAmount)}"),
            subtitle: Text(
              "Tip: ${tip.formatAmount(entry.tipAmount)} (${entry.tipPercentage}%)\n"
              "Split: ${entry.splitCount} → ${tip.formatAmount(entry.perPerson)}/person",
              style: TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
            onTap: () {
              context.read<TipModel>().setBillAmount(entry.billAmount);
              context.read<TipModel>().setTipPercentage(entry.tipPercentage);
              context.read<TipModel>().setSplitCount(entry.splitCount);
              _billController.text = entry.billAmount.toString();
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
        content: Text("Clear all tip calculation history?"),
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
      context.read<TipModel>().clearHistory();
    }
  }
}