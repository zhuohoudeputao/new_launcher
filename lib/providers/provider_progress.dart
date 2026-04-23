import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProgressModel progressModel = ProgressModel();

MyProvider providerProgress = MyProvider(
    name: "Progress",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Track progress',
      keywords: 'progress track goal project percentage completion goal tracker',
      action: () {
        Global.infoModel.addInfo("AddProgress", "Add Progress",
            subtitle: "Tap to add a new progress to track",
            icon: Icon(Icons.trending_up),
            onTap: () => _showAddProgressDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await progressModel.init();
  Global.infoModel.addInfoWidget(
      "Progress",
      ChangeNotifierProvider.value(
          value: progressModel,
          builder: (context, child) => ProgressCard()),
      title: "Progress Tracker");
}

Future<void> _update() async {
  await progressModel.refresh();
}

void _showAddProgressDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddProgressDialog(),
  );
}

void _showEditProgressDialog(BuildContext context, int index, ProgressItem item) {
  showDialog(
    context: context,
    builder: (context) => EditProgressDialog(index: index, item: item),
  );
}

class ProgressItem {
  final String name;
  final int current;
  final int target;
  final DateTime createdAt;

  ProgressItem({
    required this.name,
    this.current = 0,
    this.target = 100,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now();

  double get percentage => target > 0 ? (current / target) * 100 : 0;
  bool get isComplete => current >= target;
  int get remaining => target - current;

  String toJson() {
    return jsonEncode({
      'name': name,
      'current': current,
      'target': target,
      'createdAt': createdAt.toIso8601String(),
    });
  }

  static ProgressItem fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ProgressItem(
      name: map['name'] as String,
      current: map['current'] as int,
      target: map['target'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ProgressItem copyWith({
    String? name,
    int? current,
    int? target,
    DateTime? createdAt,
  }) {
    return ProgressItem(
      name: name ?? this.name,
      current: current ?? this.current,
      target: target ?? this.target,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ProgressModel extends ChangeNotifier {
  static const int maxProgressItems = 15;
  static const String _storageKey = 'progress_items';

  List<ProgressItem> _items = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<ProgressItem> get items => _items;
  int get length => _items.length;
  int get completedCount => _items.where((p) => p.isComplete).length;
  double get averageProgress {
    if (_items.isEmpty) return 0;
    return _items.map((p) => p.percentage).reduce((a, b) => a + b) / _items.length;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final itemStrings = prefs.getStringList(_storageKey) ?? [];
    _items = itemStrings.map((s) => ProgressItem.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel
        .info("Progress initialized with ${_items.length} items", source: "Progress");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final itemStrings = _items.map((p) => p.toJson()).toList();
    await prefs.setStringList(_storageKey, itemStrings);
  }

  void addProgress(String name, int target) {
    if (_items.length >= maxProgressItems) {
      _items.removeAt(0);
    }
    _items.add(ProgressItem(name: name, target: target));
    Global.loggerModel.info("Added progress: $name (target: $target)", source: "Progress");
    _save();
    notifyListeners();
  }

  void updateProgress(int index, String name, int target) {
    if (index >= 0 && index < _items.length) {
      _items[index] = _items[index].copyWith(name: name, target: target);
      Global.loggerModel.info("Updated progress at index $index", source: "Progress");
      _save();
      notifyListeners();
    }
  }

  void updateCurrentValue(int index, int current) {
    if (index >= 0 && index < _items.length) {
      final cappedCurrent = current.clamp(0, _items[index].target);
      _items[index] = _items[index].copyWith(current: cappedCurrent);
      Global.loggerModel.info(
          "Updated progress ${_items[index].name}: $current/${_items[index].target}",
          source: "Progress");
      _save();
      notifyListeners();
    }
  }

  void incrementProgress(int index, int amount) {
    if (index >= 0 && index < _items.length) {
      final newCurrent = _items[index].current + amount;
      updateCurrentValue(index, newCurrent);
    }
  }

  void deleteProgress(int index) {
    if (index >= 0 && index < _items.length) {
      final name = _items[index].name;
      _items.removeAt(index);
      Global.loggerModel.info("Deleted progress: $name", source: "Progress");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearAllProgress() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared all progress items", source: "Progress");
    notifyListeners();
  }
}

class ProgressCard extends StatefulWidget {
  @override
  State<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<ProgressCard> {
  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressModel>();

    if (!progress.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 24),
              SizedBox(width: 12),
              Text("Progress Tracker: Loading..."),
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
                  Icon(Icons.trending_up, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Progress Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (progress.items.isNotEmpty)
                    Text(
                      "${progress.completedCount}/${progress.length} complete",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (progress.items.isEmpty)
                Text(
                  "No progress items. Tap + to add one!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ...progress.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildProgressItem(context, progress, index, item);
              }),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 18),
                    onPressed: () => _showAddProgressDialog(context),
                    tooltip: "Add progress",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (progress.items.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_sweep, size: 18),
                      onPressed: () => _showClearConfirmDialog(context, progress),
                      tooltip: "Clear all progress",
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

  Widget _buildProgressItem(
      BuildContext context, ProgressModel progress, int index, ProgressItem item) {
    final percentage = item.percentage;
    final progressColor = percentage >= 100
        ? Theme.of(context).colorScheme.primary
        : percentage >= 75
            ? Theme.of(context).colorScheme.tertiary
            : percentage >= 50
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onLongPress: () => _showEditProgressDialog(context, index, item),
        child: Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: progressColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${percentage.toInt()}%",
                        style: TextStyle(fontSize: 11, color: progressColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 6,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item.current}/${item.target}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (!item.isComplete)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, size: 16),
                            onPressed: () => progress.incrementProgress(index, -1),
                            style: IconButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              minimumSize: Size(24, 24),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(width: 4),
                          IconButton(
                            icon: Icon(Icons.add, size: 16),
                            onPressed: () => progress.incrementProgress(index, 1),
                            style: IconButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              minimumSize: Size(24, 24),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, ProgressModel progress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear all progress?"),
        content: Text("This will delete all ${progress.length} progress items permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              progress.clearAllProgress();
              Navigator.pop(context);
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }
}

class AddProgressDialog extends StatefulWidget {
  @override
  State<AddProgressDialog> createState() => _AddProgressDialogState();
}

class _AddProgressDialogState extends State<AddProgressDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController(text: "100");

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Progress"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Name",
              hintText: "e.g., Read 10 books, Walk 100km",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _targetController,
            decoration: InputDecoration(
              labelText: "Target",
              hintText: "e.g., 10, 100, 1000",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
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
            final name = _nameController.text.trim();
            final target = int.tryParse(_targetController.text.trim()) ?? 100;
            if (name.isNotEmpty && target > 0) {
              progressModel.addProgress(name, target);
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class EditProgressDialog extends StatefulWidget {
  final int index;
  final ProgressItem item;

  const EditProgressDialog({required this.index, required this.item});

  @override
  State<EditProgressDialog> createState() => _EditProgressDialogState();
}

class _EditProgressDialogState extends State<EditProgressDialog> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _targetController = TextEditingController(text: widget.item.target.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Progress"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _targetController,
            decoration: InputDecoration(
              labelText: "Target",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
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
            progressModel.deleteProgress(widget.index);
            Navigator.pop(context);
          },
          child: Text("Delete"),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final target = int.tryParse(_targetController.text.trim()) ?? 100;
            if (name.isNotEmpty && target > 0) {
              progressModel.updateProgress(widget.index, name, target);
              Navigator.pop(context);
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}