import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

LoanModel loanModel = LoanModel();

MyProvider providerLoan = MyProvider(
    name: "Loan",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'LoanCalculator',
      keywords: 'loan calculator mortgage payment interest amortization finance',
      action: () => loanModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await loanModel.init();
  Global.infoModel.addInfoWidget(
      "LoanCalculator",
      ChangeNotifierProvider.value(
          value: loanModel,
          builder: (context, child) => LoanCard()),
      title: "Loan Calculator");
}

Future<void> _update() async {
  loanModel.refresh();
}

class LoanEntry {
  final DateTime date;
  final double principal;
  final double annualRate;
  final int termYears;
  final double monthlyPayment;
  final double totalInterest;
  final double totalPayment;

  LoanEntry({
    required this.date,
    required this.principal,
    required this.annualRate,
    required this.termYears,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalPayment,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'principal': principal,
      'annualRate': annualRate,
      'termYears': termYears,
      'monthlyPayment': monthlyPayment,
      'totalInterest': totalInterest,
      'totalPayment': totalPayment,
    });
  }

  static LoanEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return LoanEntry(
      date: DateTime.parse(map['date'] as String),
      principal: (map['principal'] as num).toDouble(),
      annualRate: (map['annualRate'] as num).toDouble(),
      termYears: map['termYears'] as int,
      monthlyPayment: (map['monthlyPayment'] as num).toDouble(),
      totalInterest: (map['totalInterest'] as num).toDouble(),
      totalPayment: (map['totalPayment'] as num).toDouble(),
    );
  }
}

class AmortizationEntry {
  final int month;
  final double payment;
  final double principal;
  final double interest;
  final double balance;

  AmortizationEntry({
    required this.month,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}

class LoanModel extends ChangeNotifier {
  static const int maxHistory = 10;
  static const String _storageKey = 'loan_entries';

  List<LoanEntry> _history = [];
  double _principal = 0;
  double _annualRate = 5.0;
  int _termYears = 30;
  bool _isInitialized = false;
  bool _showAmortization = false;

  bool get isInitialized => _isInitialized;
  double get principal => _principal;
  double get annualRate => _annualRate;
  int get termYears => _termYears;
  List<LoanEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  bool get showAmortization => _showAmortization;

  double get monthlyPayment {
    if (_principal <= 0 || _annualRate <= 0 || _termYears <= 0) return 0;
    double monthlyRate = _annualRate / 100 / 12;
    int numPayments = _termYears * 12;
    if (monthlyRate == 0) return _principal / numPayments;
    return _principal *
        (monthlyRate * pow(1 + monthlyRate, numPayments)) /
        (pow(1 + monthlyRate, numPayments) - 1);
  }

  double get totalPayment {
    return monthlyPayment * _termYears * 12;
  }

  double get totalInterest {
    return totalPayment - _principal;
  }

  double get interestPercentage {
    if (_principal <= 0) return 0;
    return (totalInterest / _principal) * 100;
  }

  List<AmortizationEntry> get amortizationSchedule {
    if (_principal <= 0 || _annualRate <= 0 || _termYears <= 0) return [];
    List<AmortizationEntry> schedule = [];
    double balance = _principal;
    double monthlyRate = _annualRate / 100 / 12;
    int numPayments = _termYears * 12;

    for (int month = 1; month <= numPayments; month++) {
      double interestPayment = balance * monthlyRate;
      double principalPayment = monthlyPayment - interestPayment;
      balance -= principalPayment;
      if (balance < 0) balance = 0;

      schedule.add(AmortizationEntry(
        month: month,
        payment: monthlyPayment,
        principal: principalPayment,
        interest: interestPayment,
        balance: balance,
      ));
    }
    return schedule;
  }

  double pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => LoanEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Loan Calculator initialized with ${_history.length} entries", source: "Loan");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Loan Calculator refreshed", source: "Loan");
  }

  void setPrincipal(double amount) {
    _principal = amount;
    notifyListeners();
  }

  void setAnnualRate(double rate) {
    _annualRate = rate.clamp(0.1, 30);
    notifyListeners();
  }

  void setTermYears(int years) {
    _termYears = years.clamp(1, 50);
    notifyListeners();
  }

  void toggleAmortization() {
    _showAmortization = !_showAmortization;
    notifyListeners();
  }

  void clear() {
    _principal = 0;
    _annualRate = 5.0;
    _termYears = 30;
    _showAmortization = false;
    notifyListeners();
    Global.loggerModel.info("Loan Calculator cleared", source: "Loan");
  }

  void saveToHistory() {
    if (_principal <= 0 || monthlyPayment <= 0) return;

    _history.insert(0, LoanEntry(
      date: DateTime.now(),
      principal: _principal,
      annualRate: _annualRate,
      termYears: _termYears,
      monthlyPayment: monthlyPayment,
      totalInterest: totalInterest,
      totalPayment: totalPayment,
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }
    _save();
    notifyListeners();
    Global.loggerModel.info("Loan calculation saved to history", source: "Loan");
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void loadFromHistory(LoanEntry entry) {
    _principal = entry.principal;
    _annualRate = entry.annualRate;
    _termYears = entry.termYears;
    notifyListeners();
    Global.loggerModel.info("Loaded loan from history", source: "Loan");
  }

  void clearHistory() {
    _history.clear();
    _save();
    notifyListeners();
    Global.loggerModel.info("Loan history cleared", source: "Loan");
  }

  String formatAmount(double amount) {
    if (amount == amount.round()) {
      return '\$${amount.round()}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }
}

class LoanCard extends StatefulWidget {
  @override
  State<LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<LoanCard> {
  bool _showHistory = false;
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _termController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _principalController.addListener(_onPrincipalChanged);
    _rateController.addListener(_onRateChanged);
    _termController.addListener(_onTermChanged);
  }

  @override
  void dispose() {
    _principalController.removeListener(_onPrincipalChanged);
    _rateController.removeListener(_onRateChanged);
    _termController.removeListener(_onTermChanged);
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _onPrincipalChanged() {
    final value = double.tryParse(_principalController.text);
    if (value != null) {
      context.read<LoanModel>().setPrincipal(value);
    } else if (_principalController.text.isEmpty) {
      context.read<LoanModel>().setPrincipal(0);
    }
  }

  void _onRateChanged() {
    final value = double.tryParse(_rateController.text);
    if (value != null) {
      context.read<LoanModel>().setAnnualRate(value);
    }
  }

  void _onTermChanged() {
    final value = int.tryParse(_termController.text);
    if (value != null) {
      context.read<LoanModel>().setTermYears(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = context.watch<LoanModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!loan.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.account_balance, size: 24),
              SizedBox(width: 12),
              Text("Loan Calculator: Loading..."),
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
                  "Loan Calculator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loan.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.calculate : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Calculator" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (loan.hasHistory)
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
            if (_showHistory) _buildHistoryView(loan)
            else _buildCalculatorView(loan),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorView(LoanModel loan) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInputs(loan),
        SizedBox(height: 12),
        if (loan.principal > 0) _buildResults(loan),
        if (loan.showAmortization && loan.principal > 0) _buildAmortizationTable(loan),
        SizedBox(height: 8),
        _buildActionButtons(loan),
      ],
    );
  }

  Widget _buildInputs(LoanModel loan) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _principalController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Principal Amount",
            prefixText: "\$",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _rateController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Interest Rate",
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
            SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _termController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Term",
                  suffixText: "years",
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

  Widget _buildResults(LoanModel loan) {
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
          _buildResultRow("Monthly Payment", loan.formatAmount(loan.monthlyPayment), isHighlight: true),
          SizedBox(height: 8),
          _buildResultRow("Total Payment", loan.formatAmount(loan.totalPayment)),
          SizedBox(height: 4),
          _buildResultRow("Total Interest", loan.formatAmount(loan.totalInterest)),
          SizedBox(height: 4),
          _buildResultRow("Interest vs Principal", "${loan.interestPercentage.toStringAsFixed(1)}%"),
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

  Widget _buildAmortizationTable(LoanModel loan) {
    final colorScheme = Theme.of(context).colorScheme;
    final schedule = loan.amortizationSchedule;
    final displaySchedule = schedule.length > 12 ? schedule.sublist(0, 12) : schedule;

    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Table(
          border: TableBorder.all(
            color: colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
              children: [
                _buildTableCell("#", isHeader: true),
                _buildTableCell("Principal", isHeader: true),
                _buildTableCell("Interest", isHeader: true),
                _buildTableCell("Balance", isHeader: true),
              ],
            ),
            ...displaySchedule.map((entry) => TableRow(
              children: [
                _buildTableCell("${entry.month}"),
                _buildTableCell(loan.formatAmount(entry.principal)),
                _buildTableCell(loan.formatAmount(entry.interest)),
                _buildTableCell(loan.formatAmount(entry.balance)),
              ],
            )),
            if (schedule.length > 12)
              TableRow(
                children: [
                  _buildTableCell("..."),
                  _buildTableCell("..."),
                  _buildTableCell("..."),
                  _buildTableCell("..."),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButtons(LoanModel loan) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (loan.principal > 0)
          TextButton.icon(
            onPressed: () => loan.toggleAmortization(),
            icon: Icon(Icons.table_chart, size: 16),
            label: Text(loan.showAmortization ? "Hide Table" : "Amortization"),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.secondary,
            ),
          ),
        ElevatedButton.icon(
          onPressed: loan.principal > 0 ? () => loan.saveToHistory() : null,
          icon: Icon(Icons.save, size: 18),
          label: Text("Save"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            loan.clear();
            _principalController.clear();
            _rateController.text = "5.0";
            _termController.text = "30";
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

  Widget _buildHistoryView(LoanModel loan) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: loan.history.length,
        itemBuilder: (context, index) {
          final entry = loan.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.account_balance, size: 20),
            title: Text("Principal: ${loan.formatAmount(entry.principal)}"),
            subtitle: Text(
              "Rate: ${entry.annualRate}% | ${entry.termYears}yr\n"
              "Monthly: ${loan.formatAmount(entry.monthlyPayment)}",
              style: TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
            onTap: () {
              context.read<LoanModel>().loadFromHistory(entry);
              _principalController.text = entry.principal.toString();
              _rateController.text = entry.annualRate.toString();
              _termController.text = entry.termYears.toString();
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
        content: Text("Clear all loan calculation history?"),
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
      context.read<LoanModel>().clearHistory();
    }
  }
}