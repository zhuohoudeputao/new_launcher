import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ExpenseModel expenseModel = ExpenseModel();

MyProvider providerExpense = MyProvider(
    name: "Expense",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Add expense',
      keywords: 'expense money spend cost budget track finance wallet',
      action: () {
        Global.infoModel.addInfo("AddExpense", "Add Expense",
            subtitle: "Track your spending",
            icon: Icon(Icons.attach_money),
            onTap: () => expenseModel.showAddDialog());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await expenseModel.init();
  Global.infoModel.addInfoWidget(
      "Expense",
      ChangeNotifierProvider.value(
          value: expenseModel,
          builder: (context, child) => ExpenseCard()),
      title: "Expense Tracker");
}

Future<void> _update() async {
  await expenseModel.refresh();
}

enum ExpenseCategory {
  food('Food', Icons.restaurant, '🍔'),
  transport('Transport', Icons.directions_car, '🚗'),
  entertainment('Entertainment', Icons.movie, '🎬'),
  shopping('Shopping', Icons.shopping_bag, '🛍️'),
  bills('Bills', Icons.receipt, '📄'),
  health('Health', Icons.local_hospital, '💊'),
  other('Other', Icons.more_horiz, '📦');

  final String label;
  final IconData icon;
  final String emoji;

  const ExpenseCategory(this.label, this.icon, this.emoji);
}

class ExpenseEntry {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String? description;
  final DateTime date;

  ExpenseEntry({
    required this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });

  String toJson() {
    return jsonEncode({
      'id': id,
      'amount': amount,
      'category': category.name,
      'description': description,
      'date': date.toIso8601String(),
    });
  }

  static ExpenseEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ExpenseEntry(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
    );
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

class ExpenseModel extends ChangeNotifier {
  static const int maxEntries = 100;
  static const String _storageKey = 'expense_entries';

  List<ExpenseEntry> _entries = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<ExpenseEntry> get entries => _entries;
  
  List<ExpenseEntry> get todayEntries {
    final today = DateTime.now();
    return _entries.where((e) => 
      e.date.year == today.year && 
      e.date.month == today.month && 
      e.date.day == today.day
    ).toList();
  }
  
  double get todayTotal {
    return todayEntries.fold(0.0, (sum, e) => sum + e.amount);
  }
  
  double get weekTotal {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _entries.where((e) => e.date.isAfter(startOfWeek) || e.date.isAtSameMomentAs(startOfWeek))
        .fold(0.0, (sum, e) => sum + e.amount);
  }
  
  double get monthTotal {
    final now = DateTime.now();
    return _entries.where((e) => 
      e.date.year == now.year && 
      e.date.month == now.month
    ).fold(0.0, (sum, e) => sum + e.amount);
  }
  
  Map<ExpenseCategory, double> get categoryTotals {
    final totals = <ExpenseCategory, double>{};
    for (var category in ExpenseCategory.values) {
      totals[category] = todayEntries
          .where((e) => e.category == category)
          .fold(0.0, (sum, e) => sum + e.amount);
    }
    return totals;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _entries = entryStrings.map((s) => ExpenseEntry.fromJson(s)).toList();
    _entries.sort((a, b) => b.date.compareTo(a.date));
    _isInitialized = true;
    Global.loggerModel.info("Expense initialized with ${_entries.length} entries", source: "Expense");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _entries.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void addExpense(double amount, ExpenseCategory category, {String? description}) {
    final entry = ExpenseEntry(
      id: ExpenseEntry.generateId(),
      amount: amount,
      category: category,
      description: description,
      date: DateTime.now(),
    );
    
    _entries.insert(0, entry);
    
    while (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    
    Global.loggerModel.info("Added expense: $amount for ${category.label}", source: "Expense");
    _save();
    notifyListeners();
  }

  void deleteExpense(String id) {
    _entries.removeWhere((e) => e.id == id);
    Global.loggerModel.info("Deleted expense: $id", source: "Expense");
    _save();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _entries.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared expense history", source: "Expense");
    notifyListeners();
  }

  void showAddDialog() {
    notifyListeners();
  }
}

class ExpenseCard extends StatefulWidget {
  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final expense = context.watch<ExpenseModel>();

    if (!expense.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.attach_money, size: 24),
              SizedBox(width: 12),
              Text("Expense Tracker: Loading..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_money, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Expense Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (expense.entries.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _showClearDialog(context, expense),
                      tooltip: "Clear all",
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalCard(context, "Today", expense.todayTotal),
                  _buildTotalCard(context, "Week", expense.weekTotal),
                  _buildTotalCard(context, "Month", expense.monthTotal),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddExpenseDialog(context, expense),
                      icon: Icon(Icons.add, size: 18),
                      label: Text("Add"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showHistory = !_showHistory),
                      icon: Icon(_showHistory ? Icons.keyboard_arrow_up : Icons.history, size: 18),
                      label: Text(_showHistory ? "Hide" : "History"),
                    ),
                  ),
                ],
              ),
              if (_showHistory && expense.entries.isNotEmpty) ...[
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 8),
                Text(
                  "Recent Expenses",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 8),
                ...expense.entries.take(10).map((entry) => _buildEntryTile(context, expense, entry)),
              ],
              if (_showHistory && expense.entries.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text("No expenses yet", style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, String label, double amount) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
        ),
        Text(
          "\$${amount.toStringAsFixed(2)}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEntryTile(BuildContext context, ExpenseModel expense, ExpenseEntry entry) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => expense.deleteExpense(entry.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Text(entry.category.emoji, style: TextStyle(fontSize: 20)),
        title: Text(
          entry.category.label,
          style: TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          entry.description ?? "${entry.date.month}/${entry.date.day}",
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
        ),
        trailing: Text(
          "\$${entry.amount.toStringAsFixed(2)}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, ExpenseModel expense) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.food;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Add Expense"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Amount",
                    prefixText: "\$ ",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.values.map((cat) => ChoiceChip(
                    label: Text("${cat.emoji} ${cat.label}"),
                    selected: selectedCategory == cat,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => selectedCategory = cat);
                      }
                    },
                  )).toList(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: "Note (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  expense.addExpense(
                    amount,
                    selectedCategory,
                    description: descriptionController.text.isNotEmpty 
                        ? descriptionController.text 
                        : null,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Expenses"),
        content: Text("Are you sure you want to delete all expense history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              expense.clearHistory();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text("Clear All"),
          ),
        ],
      ),
    );
  }
}