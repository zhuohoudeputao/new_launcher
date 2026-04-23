import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

HabitModel habitModel = HabitModel();

MyProvider providerHabit = MyProvider(
    name: "Habit",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Track habit',
      keywords: 'habit track daily routine streak goal habit tracker',
      action: () {
        Global.infoModel.addInfo("AddHabit", "Add Habit",
            subtitle: "Tap to add a new habit to track",
            icon: Icon(Icons.track_changes),
            onTap: () => _showAddHabitDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await habitModel.init();
  Global.infoModel.addInfoWidget(
      "Habit",
      ChangeNotifierProvider.value(
          value: habitModel,
          builder: (context, child) => HabitCard()),
      title: "Habit Tracker");
}

Future<void> _update() async {
  await habitModel.refresh();
}

void _showAddHabitDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddHabitDialog(),
  );
}

void _showEditHabitDialog(BuildContext context, int index, HabitItem item) {
  showDialog(
    context: context,
    builder: (context) => EditHabitDialog(index: index, item: item),
  );
}

class HabitItem {
  final String name;
  final int streak;
  final int bestStreak;
  final Set<String> completedDates;
  final DateTime createdAt;

  HabitItem({
    required this.name,
    this.streak = 0,
    this.bestStreak = 0,
    Set<String>? completedDates,
    DateTime? createdAt,
  })  : completedDates = completedDates ?? {},
        createdAt = createdAt ?? DateTime.now();

  String get todayKey => _getDayKey(DateTime.now());

  bool isCompletedToday() => completedDates.contains(todayKey);

  int get totalDays => completedDates.length;

  static String _getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  String toJson() {
    return jsonEncode({
      'name': name,
      'streak': streak,
      'bestStreak': bestStreak,
      'completedDates': completedDates.toList(),
      'createdAt': createdAt.toIso8601String(),
    });
  }

  static HabitItem fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return HabitItem(
      name: map['name'] as String,
      streak: map['streak'] as int,
      bestStreak: map['bestStreak'] as int,
      completedDates: Set<String>.from(map['completedDates'] as List),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  HabitItem copyWith({
    String? name,
    int? streak,
    int? bestStreak,
    Set<String>? completedDates,
    DateTime? createdAt,
  }) {
    return HabitItem(
      name: name ?? this.name,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class HabitModel extends ChangeNotifier {
  static const int maxHabits = 10;
  static const String _storageKey = 'habit_items';

  List<HabitItem> _habits = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<HabitItem> get habits => _habits;
  int get length => _habits.length;
  int get completedTodayCount =>
      _habits.where((h) => h.isCompletedToday()).length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final habitStrings = prefs.getStringList(_storageKey) ?? [];
    _habits = habitStrings.map((s) => HabitItem.fromJson(s)).toList();
    _isInitialized = true;
    _checkDailyReset();
    Global.loggerModel
        .info("Habit initialized with ${_habits.length} habits", source: "Habit");
    notifyListeners();
  }

  Future<void> refresh() async {
    _checkDailyReset();
    notifyListeners();
  }

  void _checkDailyReset() {
    final today = DateTime.now();
    final todayKey = HabitItem._getDayKey(today);
    
    for (int i = 0; i < _habits.length; i++) {
      final habit = _habits[i];
      if (!habit.completedDates.contains(todayKey)) {
        final yesterday = today.subtract(Duration(days: 1));
        final yesterdayKey = HabitItem._getDayKey(yesterday);
        
        if (!habit.completedDates.contains(yesterdayKey) && habit.streak > 0) {
          _habits[i] = habit.copyWith(streak: 0);
        }
      }
    }
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final habitStrings = _habits.map((h) => h.toJson()).toList();
    await prefs.setStringList(_storageKey, habitStrings);
  }

  void addHabit(String name) {
    if (_habits.length >= maxHabits) {
      _habits.removeAt(0);
    }
    _habits.add(HabitItem(name: name));
    Global.loggerModel.info("Added habit: $name", source: "Habit");
    _save();
    notifyListeners();
  }

  void updateHabit(int index, String name) {
    if (index >= 0 && index < _habits.length) {
      _habits[index] = _habits[index].copyWith(name: name);
      Global.loggerModel.info("Updated habit at index $index", source: "Habit");
      _save();
      notifyListeners();
    }
  }

  void toggleHabit(int index) {
    if (index >= 0 && index < _habits.length) {
      final habit = _habits[index];
      final todayKey = habit.todayKey;
      Set<String> newDates = Set<String>.from(habit.completedDates);
      int newStreak = habit.streak;
      int newBestStreak = habit.bestStreak;

      if (newDates.contains(todayKey)) {
        newDates.remove(todayKey);
        newStreak = habit.streak > 0 ? habit.streak - 1 : 0;
      } else {
        newDates.add(todayKey);
        newStreak++;
        if (newStreak > newBestStreak) {
          newBestStreak = newStreak;
        }
      }

      _habits[index] = habit.copyWith(
        completedDates: newDates,
        streak: newStreak,
        bestStreak: newBestStreak,
      );
      Global.loggerModel.info(
          "Toggled habit ${habit.name}: ${newDates.contains(todayKey) ? 'completed' : 'uncompleted'}",
          source: "Habit");
      _save();
      notifyListeners();
    }
  }

  void deleteHabit(int index) {
    if (index >= 0 && index < _habits.length) {
      final name = _habits[index].name;
      _habits.removeAt(index);
      Global.loggerModel.info("Deleted habit: $name", source: "Habit");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearAllHabits() async {
    _habits.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared all habits", source: "Habit");
    notifyListeners();
  }
}

class HabitCard extends StatefulWidget {
  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitModel>();

    if (!habit.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.track_changes, size: 24),
              SizedBox(width: 12),
              Text("Habit Tracker: Loading..."),
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
                  Icon(Icons.track_changes, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Habit Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (habit.habits.isNotEmpty)
                    Text(
                      "${habit.completedTodayCount}/${habit.length} today",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (habit.habits.isEmpty)
                Text(
                  "No habits. Tap + to add one!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ...habit.habits.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildHabitItem(context, habit, index, item);
              }),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 18),
                    onPressed: () => _showAddHabitDialog(context),
                    tooltip: "Add habit",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (habit.habits.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_sweep, size: 18),
                      onPressed: () => _showClearConfirmDialog(context, habit),
                      tooltip: "Clear all habits",
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

  Widget _buildHabitItem(
      BuildContext context, HabitModel habit, int index, HabitItem item) {
    final isCompleted = item.isCompletedToday();
    final streakColor = item.streak >= 7
        ? Theme.of(context).colorScheme.primary
        : item.streak >= 3
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () => habit.toggleHabit(index),
        onLongPress: () => _showEditHabitDialog(context, index, item),
        child: Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                          : null,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: streakColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 12, color: streakColor),
                      SizedBox(width: 2),
                      Text(
                        "${item.streak}",
                        style: TextStyle(fontSize: 11, color: streakColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, HabitModel habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear all habits?"),
        content: Text("This will delete all ${habit.length} habits permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              habit.clearAllHabits();
              Navigator.pop(context);
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }
}

class AddHabitDialog extends StatefulWidget {
  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Habit"),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: "e.g., Exercise, Read, Meditate",
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              habitModel.addHabit(_controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class EditHabitDialog extends StatefulWidget {
  final int index;
  final HabitItem item;

  const EditHabitDialog({required this.index, required this.item});

  @override
  State<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<EditHabitDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Habit"),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: "Habit name",
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            habitModel.deleteHabit(widget.index);
            Navigator.pop(context);
          },
          child: Text("Delete"),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              habitModel.updateHabit(widget.index, _controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}