import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

WaterModel waterModel = WaterModel();

MyProvider providerWater = MyProvider(
    name: "Water",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Track water',
      keywords: 'water drink hydration glass cup intake track daily health',
      action: () {
        Global.infoModel.addInfo("AddWater", "Add Water",
            subtitle: "Tap to add a glass of water",
            icon: Icon(Icons.water_drop),
            onTap: () => waterModel.addGlass());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await waterModel.init();
  Global.infoModel.addInfoWidget(
      "Water",
      ChangeNotifierProvider.value(
          value: waterModel,
          builder: (context, child) => WaterCard()),
      title: "Water Tracker");
}

Future<void> _update() async {
  await waterModel.refresh();
}

class WaterEntry {
  final DateTime date;
  final int glasses;
  final int goal;

  WaterEntry({
    required this.date,
    required this.glasses,
    required this.goal,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'glasses': glasses,
      'goal': goal,
    });
  }

  static WaterEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return WaterEntry(
      date: DateTime.parse(map['date'] as String),
      glasses: map['glasses'] as int,
      goal: map['goal'] as int,
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}

class WaterModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  static const String _storageKey = 'water_entries';
  static const String _goalKey = 'water_goal';
  static const int defaultGoal = 8;

  List<WaterEntry> _history = [];
  int _dailyGoal = defaultGoal;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  int get dailyGoal => _dailyGoal;
  List<WaterEntry> get history => _history;
  int get todayGlasses => getTodayEntry()?.glasses ?? 0;
  double get progress => todayGlasses / _dailyGoal;
  bool get goalReached => todayGlasses >= _dailyGoal;

  WaterEntry? getTodayEntry() {
    final todayKey = WaterEntry.getDayKey(DateTime.now());
    return _history.firstWhereOrNull((e) => WaterEntry.getDayKey(e.date) == todayKey);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = prefs.getInt(_goalKey) ?? defaultGoal;
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => WaterEntry.fromJson(s)).toList();
    _isInitialized = true;
    _checkDailyReset();
    Global.loggerModel.info("Water initialized with ${_history.length} entries", source: "Water");
    notifyListeners();
  }

  Future<void> refresh() async {
    _checkDailyReset();
    notifyListeners();
  }

  void _checkDailyReset() {
    final today = DateTime.now();
    final todayKey = WaterEntry.getDayKey(today);
    
    if (_history.isEmpty || WaterEntry.getDayKey(_history.last.date) != todayKey) {
      _history.add(WaterEntry(
        date: today,
        glasses: 0,
        goal: _dailyGoal,
      ));
      
      while (_history.length > maxHistoryDays) {
        _history.removeAt(0);
      }
      _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
    await prefs.setInt(_goalKey, _dailyGoal);
  }

  void addGlass() {
    final todayEntry = getTodayEntry();
    if (todayEntry != null) {
      final index = _history.indexOf(todayEntry);
      if (index >= 0) {
        _history[index] = WaterEntry(
          date: todayEntry.date,
          glasses: todayEntry.glasses + 1,
          goal: todayEntry.goal,
        );
      }
    } else {
      _checkDailyReset();
      final newEntry = getTodayEntry();
      if (newEntry != null) {
        final index = _history.indexOf(newEntry);
        if (index >= 0) {
          _history[index] = WaterEntry(
            date: newEntry.date,
            glasses: 1,
            goal: newEntry.goal,
          );
        }
      }
    }
    Global.loggerModel.info("Added glass of water, total: $todayGlasses", source: "Water");
    _save();
    notifyListeners();
  }

  void removeGlass() {
    final todayEntry = getTodayEntry();
    if (todayEntry != null && todayEntry.glasses > 0) {
      final index = _history.indexOf(todayEntry);
      if (index >= 0) {
        _history[index] = WaterEntry(
          date: todayEntry.date,
          glasses: todayEntry.glasses - 1,
          goal: todayEntry.goal,
        );
      }
      Global.loggerModel.info("Removed glass of water, total: $todayGlasses", source: "Water");
      _save();
      notifyListeners();
    }
  }

  void setGoal(int goal) {
    if (goal > 0 && goal <= 20) {
      _dailyGoal = goal;
      final todayEntry = getTodayEntry();
      if (todayEntry != null) {
        final index = _history.indexOf(todayEntry);
        if (index >= 0) {
          _history[index] = WaterEntry(
            date: todayEntry.date,
            glasses: todayEntry.glasses,
            goal: goal,
          );
        }
      }
      Global.loggerModel.info("Set water goal to $goal glasses", source: "Water");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared water history", source: "Water");
    notifyListeners();
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool test(E element)) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class WaterCard extends StatefulWidget {
  @override
  State<WaterCard> createState() => _WaterCardState();
}

class _WaterCardState extends State<WaterCard> {
  @override
  Widget build(BuildContext context) {
    final water = context.watch<WaterModel>();

    if (!water.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.water_drop, size: 24),
              SizedBox(width: 12),
              Text("Water Tracker: Loading..."),
            ],
          ),
        ),
      );
    }

    final progressColor = water.goalReached
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.tertiary;

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
                  Icon(Icons.water_drop, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Water Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    "${water.todayGlasses}/${water.dailyGoal}",
                    style: TextStyle(
                      fontSize: 14,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: water.progress.clamp(0.0, 1.0),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: progressColor,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 20),
                    onPressed: water.todayGlasses > 0 ? () => water.removeGlass() : null,
                    tooltip: "Remove glass",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => water.addGlass(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          SizedBox(width: 4),
                          Text(
                            "Add Glass",
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, size: 18),
                    onPressed: () => _showGoalDialog(context, water),
                    tooltip: "Set goal",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              if (water.goalReached)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 4),
                      Text(
                        "Goal reached!",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WaterModel water) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Daily Goal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("How many glasses per day?"),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: water.dailyGoal > 1 ? () => water.setGoal(water.dailyGoal - 1) : null,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${water.dailyGoal}",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: water.dailyGoal < 20 ? () => water.setGoal(water.dailyGoal + 1) : null,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Done"),
          ),
        ],
      ),
    );
  }
}