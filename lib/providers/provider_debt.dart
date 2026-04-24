import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

DebtModel debtModel = DebtModel();

MyProvider providerDebt = MyProvider(
    name: "Debt",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Add debt',
      keywords: 'debt loan money owe borrow lend tracker owed',
      action: () {
        Global.infoModel.addInfo("AddDebt", "Add Debt",
            subtitle: "Tap to record a debt or loan",
            icon: Icon(Icons.account_balance_wallet),
            onTap: () => _showAddDebtDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await debtModel.init();
  Global.infoModel.addInfoWidget(
      "Debt",
      ChangeNotifierProvider.value(
          value: debtModel,
          builder: (context, child) => DebtCard()),
      title: "Debt Tracker");
}

Future<void> _update() async {
  await debtModel.refresh();
}

void _showAddDebtDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddDebtDialog(),
  );
}

class DebtEntry {
  final String id;
  final String personName;
  final double amount;
  final bool isOwedToMe;
  final DateTime date;
  final DateTime? dueDate;
  final String? description;
  final bool isPaid;

  DebtEntry({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isOwedToMe,
    required this.date,
    this.dueDate,
    this.description,
    this.isPaid = false,
  });

  String toJson() {
    return jsonEncode({
      'id': id,
      'personName': personName,
      'amount': amount,
      'isOwedToMe': isOwedToMe,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'description': description,
      'isPaid': isPaid,
    });
  }

  static DebtEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return DebtEntry(
      id: map['id'] as String,
      personName: map['personName'] as String,
      amount: (map['amount'] as num).toDouble(),
      isOwedToMe: map['isOwedToMe'] as bool,
      date: DateTime.parse(map['date'] as String),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      description: map['description'] as String?,
      isPaid: map['isPaid'] as bool? ?? false,
    );
  }

  bool isOverdue() {
    if (dueDate == null || isPaid) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  int daysUntilDue() {
    if (dueDate == null) return -1;
    return dueDate!.difference(DateTime.now()).inDays;
  }
}

class DebtModel extends ChangeNotifier {
  static const int maxEntries = 20;
  static const String _storageKey = 'debt_entries';

  List<DebtEntry> _entries = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<DebtEntry> get entries => _entries;
  
  List<DebtEntry> get unpaidEntries => _entries.where((e) => !e.isPaid).toList();
  List<DebtEntry> get paidEntries => _entries.where((e) => e.isPaid).toList();
  
  List<DebtEntry> get owedToMe => unpaidEntries.where((e) => e.isOwedToMe).toList();
  List<DebtEntry> get owedByMe => unpaidEntries.where((e) => !e.isOwedToMe).toList();
  
  double get totalOwedToMe => owedToMe.fold<double>(0, (sum, e) => sum + e.amount);
  double get totalOwedByMe => owedByMe.fold<double>(0, (sum, e) => sum + e.amount);
  double get netBalance => totalOwedToMe - totalOwedByMe;
  
  List<DebtEntry> get overdueEntries => unpaidEntries.where((e) => e.isOverdue()).toList();
  
  int get unpaidCount => unpaidEntries.length;
  int get paidCount => paidEntries.length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _entries = entryStrings.map((s) => DebtEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Debt initialized with ${_entries.length} entries", source: "Debt");
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

  void addEntry({
    required String personName,
    required double amount,
    required bool isOwedToMe,
    DateTime? dueDate,
    String? description,
  }) {
    if (personName.trim().isEmpty || amount <= 0) return;
    
    final entry = DebtEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      personName: personName.trim(),
      amount: amount,
      isOwedToMe: isOwedToMe,
      date: DateTime.now(),
      dueDate: dueDate,
      description: description?.trim(),
    );
    
    _entries.add(entry);
    
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    
    Global.loggerModel.info("Added debt entry: ${isOwedToMe ? 'owed to me' : 'owed by me'} ${amount} from/to ${personName}", source: "Debt");
    _save();
    notifyListeners();
  }

  void markAsPaid(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _entries[index] = DebtEntry(
        id: _entries[index].id,
        personName: _entries[index].personName,
        amount: _entries[index].amount,
        isOwedToMe: _entries[index].isOwedToMe,
        date: _entries[index].date,
        dueDate: _entries[index].dueDate,
        description: _entries[index].description,
        isPaid: true,
      );
      Global.loggerModel.info("Debt marked as paid", source: "Debt");
      _save();
      notifyListeners();
    }
  }

  void markAsUnpaid(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _entries[index] = DebtEntry(
        id: _entries[index].id,
        personName: _entries[index].personName,
        amount: _entries[index].amount,
        isOwedToMe: _entries[index].isOwedToMe,
        date: _entries[index].date,
        dueDate: _entries[index].dueDate,
        description: _entries[index].description,
        isPaid: false,
      );
      Global.loggerModel.info("Debt marked as unpaid", source: "Debt");
      _save();
      notifyListeners();
    }
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    Global.loggerModel.info("Deleted debt entry", source: "Debt");
    _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _entries.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared all debt entries", source: "Debt");
    notifyListeners();
  }
}

class DebtCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final debt = context.watch<DebtModel>();

    if (!debt.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet, size: 24),
              SizedBox(width: 12),
              Text("Debt Tracker: Loading..."),
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
                  Icon(Icons.account_balance_wallet, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Debt Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (debt.overdueEntries.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${debt.overdueEntries.length} overdue",
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        "Owed to Me",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "\$${debt.totalOwedToMe.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: debt.totalOwedToMe > 0 ? Colors.green : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Column(
                    children: [
                      Text(
                        "Owed by Me",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "\$${debt.totalOwedByMe.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: debt.totalOwedByMe > 0 ? Colors.red : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Column(
                    children: [
                      Text(
                        "Net Balance",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "\$${debt.netBalance.abs().toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: debt.netBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (debt.unpaidEntries.isNotEmpty) ...[
                Text(
                  "Unpaid Debts (${debt.unpaidCount})",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ...debt.unpaidEntries.take(5).map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        entry.isOwedToMe ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 16,
                        color: entry.isOwedToMe ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${entry.personName}",
                              style: TextStyle(fontSize: 14),
                            ),
                            if (entry.dueDate != null)
                              Text(
                                entry.isOverdue()
                                    ? "Overdue ${-entry.daysUntilDue()} days"
                                    : "Due in ${entry.daysUntilDue()} days",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: entry.isOverdue() ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        "\$${entry.amount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: entry.isOwedToMe ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                )),
                if (debt.unpaidEntries.length > 5)
                  Text(
                    "... and ${debt.unpaidEntries.length - 5} more",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                SizedBox(height: 8),
              ] else ...[
                Text(
                  "No unpaid debts",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.add, size: 18),
                    label: Text("Add"),
                    onPressed: () => _showAddDebtDialog(context),
                  ),
                  if (debt.entries.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(Icons.history, size: 18),
                      label: Text("History"),
                      onPressed: () => _showHistoryDialog(context, debt),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, DebtModel debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Debt History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: debt.entries.length,
            itemBuilder: (context, index) {
              final entry = debt.entries[debt.entries.length - 1 - index];
              return ListTile(
                leading: Icon(
                  entry.isOwedToMe ? Icons.arrow_downward : Icons.arrow_upward,
                  color: entry.isPaid ? Theme.of(context).colorScheme.onSurfaceVariant : (entry.isOwedToMe ? Colors.green : Colors.red),
                ),
                title: Text(
                  "${entry.personName} - \$${entry.amount.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: entry.isPaid ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                  ),
                ),
                subtitle: Text(
                  entry.isPaid
                      ? "Paid"
                      : (entry.isOverdue()
                          ? "Overdue ${-entry.daysUntilDue()} days"
                          : (entry.dueDate != null ? "Due in ${entry.daysUntilDue()} days" : "No due date")),
                  style: TextStyle(
                    color: entry.isPaid ? Theme.of(context).colorScheme.onSurfaceVariant : (entry.isOverdue() ? Theme.of(context).colorScheme.error : null),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!entry.isPaid)
                      IconButton(
                        icon: Icon(Icons.check, size: 18),
                        onPressed: () {
                          debt.markAsPaid(entry.id);
                        },
                      ),
                    if (entry.isPaid)
                      IconButton(
                        icon: Icon(Icons.undo, size: 18),
                        onPressed: () {
                          debt.markAsUnpaid(entry.id);
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 18),
                      onPressed: () {
                        debt.deleteEntry(entry.id);
                        if (debt.entries.isEmpty) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
          if (debt.entries.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showClearConfirmation(context, debt);
              },
              child: Text(
                "Clear All",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, DebtModel debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Debts"),
        content: Text("Are you sure you want to clear all debt entries?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              debt.clearAll();
              Navigator.pop(context);
            },
            child: Text(
              "Clear",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class AddDebtDialog extends StatefulWidget {
  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isOwedToMe = true;
  DateTime? _dueDate;

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Debt"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text("Owed to Me"),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: false,
                  label: Text("Owed by Me"),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_isOwedToMe},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isOwedToMe = newSelection.first;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _personController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Person Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Amount",
                prefixText: "\$",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate != null
                        ? "Due: ${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}"
                        : "No due date",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.date_range, size: 18),
                  label: Text(_dueDate != null ? "Change" : "Set Due Date"),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now().add(Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _dueDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Description (optional)",
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
        TextButton(
          onPressed: () {
            final person = _personController.text.trim();
            final amountText = _amountController.text.trim();
            final amount = double.tryParse(amountText);
            
            if (person.isNotEmpty && amount != null && amount > 0) {
              debtModel.addEntry(
                personName: person,
                amount: amount,
                isOwedToMe: _isOwedToMe,
                dueDate: _dueDate,
                description: _descriptionController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}