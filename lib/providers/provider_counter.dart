import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

CounterModel counterModel = CounterModel();

MyProvider providerCounter = MyProvider(
    name: "Counter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Add counter',
      keywords: 'counter count tap tally number increment add track',
      action: () {
        Global.infoModel.addInfo("AddCounter", "Add Counter",
            subtitle: "Tap to add a new counter",
            icon: Icon(Icons.exposure_plus_1),
            onTap: () => _showAddCounterDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await counterModel.init();
  Global.infoModel.addInfoWidget(
      "Counter",
      ChangeNotifierProvider.value(
          value: counterModel,
          builder: (context, child) => CounterCard()),
      title: "Counter");
}

Future<void> _update() async {
  await counterModel.refresh();
}

void _showAddCounterDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddCounterDialog(),
  );
}

void _showEditCounterDialog(BuildContext context, int index, CounterItem item) {
  showDialog(
    context: context,
    builder: (context) => EditCounterDialog(index: index, item: item),
  );
}

class CounterItem {
  final String name;
  final int count;
  final int step;
  final DateTime createdAt;

  CounterItem({
    required this.name,
    this.count = 0,
    this.step = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String toJson() {
    return jsonEncode({
      'name': name,
      'count': count,
      'step': step,
      'createdAt': createdAt.toIso8601String(),
    });
  }

  static CounterItem fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return CounterItem(
      name: map['name'] as String,
      count: map['count'] as int,
      step: map['step'] as int? ?? 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  CounterItem copyWith({
    String? name,
    int? count,
    int? step,
    DateTime? createdAt,
  }) {
    return CounterItem(
      name: name ?? this.name,
      count: count ?? this.count,
      step: step ?? this.step,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CounterModel extends ChangeNotifier {
  static const int maxCounters = 15;
  static const String _storageKey = 'counter_items';

  List<CounterItem> _counters = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<CounterItem> get counters => _counters;
  int get length => _counters.length;
  int get totalCount => _counters.fold(0, (sum, c) => sum + c.count);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final counterStrings = prefs.getStringList(_storageKey) ?? [];
    _counters = counterStrings.map((s) => CounterItem.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel
        .info("Counter initialized with ${_counters.length} counters", source: "Counter");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final counterStrings = _counters.map((c) => c.toJson()).toList();
    await prefs.setStringList(_storageKey, counterStrings);
  }

  void addCounter(String name, int step) {
    if (_counters.length >= maxCounters) {
      _counters.removeAt(0);
    }
    _counters.add(CounterItem(name: name, step: step));
    Global.loggerModel.info("Added counter: $name (step: $step)", source: "Counter");
    _save();
    notifyListeners();
  }

  void updateCounter(int index, String name, int step) {
    if (index >= 0 && index < _counters.length) {
      _counters[index] = _counters[index].copyWith(name: name, step: step);
      Global.loggerModel.info("Updated counter at index $index", source: "Counter");
      _save();
      notifyListeners();
    }
  }

  void increment(int index) {
    if (index >= 0 && index < _counters.length) {
      final counter = _counters[index];
      _counters[index] = counter.copyWith(count: counter.count + counter.step);
      Global.loggerModel.info(
          "Incremented ${counter.name}: ${counter.count} -> ${counter.count + counter.step}",
          source: "Counter");
      _save();
      notifyListeners();
    }
  }

  void decrement(int index) {
    if (index >= 0 && index < _counters.length) {
      final counter = _counters[index];
      _counters[index] = counter.copyWith(count: counter.count - counter.step);
      Global.loggerModel.info(
          "Decremented ${counter.name}: ${counter.count} -> ${counter.count - counter.step}",
          source: "Counter");
      _save();
      notifyListeners();
    }
  }

  void resetCounter(int index) {
    if (index >= 0 && index < _counters.length) {
      final counter = _counters[index];
      _counters[index] = counter.copyWith(count: 0);
      Global.loggerModel.info("Reset counter ${counter.name} to 0", source: "Counter");
      _save();
      notifyListeners();
    }
  }

  void deleteCounter(int index) {
    if (index >= 0 && index < _counters.length) {
      final name = _counters[index].name;
      _counters.removeAt(index);
      Global.loggerModel.info("Deleted counter: $name", source: "Counter");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearAllCounters() async {
    _counters.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared all counters", source: "Counter");
    notifyListeners();
  }
}

class CounterCard extends StatefulWidget {
  @override
  State<CounterCard> createState() => _CounterCardState();
}

class _CounterCardState extends State<CounterCard> {
  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterModel>();

    if (!counter.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.exposure_plus_1, size: 24),
              SizedBox(width: 12),
              Text("Counter: Loading..."),
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
                  Icon(Icons.exposure_plus_1, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Counter",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (counter.counters.isNotEmpty)
                    Text(
                      "Total: ${counter.totalCount}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (counter.counters.isEmpty)
                Text(
                  "No counters. Tap + to add one!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ...counter.counters.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildCounterItem(context, counter, index, item);
              }),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 18),
                    onPressed: () => _showAddCounterDialog(context),
                    tooltip: "Add counter",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (counter.counters.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_sweep, size: 18),
                      onPressed: () => _showClearConfirmDialog(context, counter),
                      tooltip: "Clear all counters",
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterItem(
      BuildContext context, CounterModel counter, int index, CounterItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onLongPress: () => _showEditCounterDialog(context, index, item),
        child: Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        "Step: ${item.step}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove, size: 20),
                  onPressed: () => counter.decrement(index),
                  tooltip: "Decrement",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: Text(
                    "${item.count}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 20),
                  onPressed: () => counter.increment(index),
                  tooltip: "Increment",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 18),
                  onPressed: () => counter.resetCounter(index),
                  tooltip: "Reset",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, CounterModel counter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear all counters?"),
        content: Text("This will delete all ${counter.length} counters permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              counter.clearAllCounters();
              Navigator.pop(context);
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }
}

class AddCounterDialog extends StatefulWidget {
  @override
  State<AddCounterDialog> createState() => _AddCounterDialogState();
}

class _AddCounterDialogState extends State<AddCounterDialog> {
  final TextEditingController _nameController = TextEditingController();
  int _step = 1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Counter"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "e.g., Reps, Steps, Items",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text("Step: "),
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (_step > 1) {
                    setState(() => _step--);
                  }
                },
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text("${_step}", style: TextStyle(fontSize: 18)),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() => _step++);
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              counterModel.addCounter(_nameController.text.trim(), _step);
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class EditCounterDialog extends StatefulWidget {
  final int index;
  final CounterItem item;

  const EditCounterDialog({required this.index, required this.item});

  @override
  State<EditCounterDialog> createState() => _EditCounterDialogState();
}

class _EditCounterDialogState extends State<EditCounterDialog> {
  late TextEditingController _nameController;
  late int _step;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _step = widget.item.step;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Counter"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Counter name",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text("Step: "),
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (_step > 1) {
                    setState(() => _step--);
                  }
                },
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text("${_step}", style: TextStyle(fontSize: 18)),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() => _step++);
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            counterModel.deleteCounter(widget.index);
            Navigator.pop(context);
          },
          child: Text("Delete"),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              counterModel.updateCounter(widget.index, _nameController.text.trim(), _step);
              Navigator.pop(context);
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}