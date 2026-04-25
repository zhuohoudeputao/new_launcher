import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

CalorieModel calorieModel = CalorieModel();

MyProvider providerCalorie = MyProvider(
    name: "Calorie",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Track calories',
      keywords: 'calorie calories food eat meal intake track daily health nutrition diet',
      action: () {
        Global.infoModel.addInfo("AddCalorie", "Add Calories",
            subtitle: "Tap to log a meal",
            icon: Icon(Icons.restaurant),
            onTap: () => calorieModel.addQuickFood('apple'));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await calorieModel.init();
  Global.infoModel.addInfoWidget(
      "Calorie",
      ChangeNotifierProvider.value(
          value: calorieModel,
          builder: (context, child) => CalorieCard()),
      title: "Calorie Tracker");
}

Future<void> _update() async {
  await calorieModel.refresh();
}

class CalorieEntry {
  final DateTime date;
  final int amountCal;
  final int goal;
  final String foodType;

  CalorieEntry({
    required this.date,
    required this.amountCal,
    required this.goal,
    this.foodType = '',
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'amountCal': amountCal,
      'goal': goal,
      'foodType': foodType,
    });
  }

  static CalorieEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return CalorieEntry(
      date: DateTime.parse(map['date'] as String),
      amountCal: map['amountCal'] as int,
      goal: map['goal'] as int,
      foodType: map['foodType'] as String? ?? '',
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}

class DailyCalorieSummary {
  final DateTime date;
  final int totalCal;
  final int goal;

  DailyCalorieSummary({
    required this.date,
    required this.totalCal,
    required this.goal,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'totalCal': totalCal,
      'goal': goal,
    });
  }

  static DailyCalorieSummary fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return DailyCalorieSummary(
      date: DateTime.parse(map['date'] as String),
      totalCal: map['totalCal'] as int,
      goal: map['goal'] as int,
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}

class FoodOption {
  final String name;
  final int calories;
  final String icon;

  FoodOption({
    required this.name,
    required this.calories,
    required this.icon,
  });
}

class CalorieModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  static const String _storageKey = 'calorie_entries';
  static const String _summaryKey = 'calorie_daily_summaries';
  static const String _goalKey = 'calorie_goal';
  static const int defaultGoal = 2000;

  static final List<FoodOption> foodOptions = [
    FoodOption(name: 'Apple', calories: 95, icon: '🍎'),
    FoodOption(name: 'Banana', calories: 105, icon: '🍌'),
    FoodOption(name: 'Egg', calories: 78, icon: '🥚'),
    FoodOption(name: 'Toast', calories: 75, icon: '🍞'),
    FoodOption(name: 'Coffee', calories: 5, icon: '☕'),
    FoodOption(name: 'Salad', calories: 150, icon: '🥗'),
    FoodOption(name: 'Sandwich', calories: 350, icon: '🥪'),
    FoodOption(name: 'Pizza Slice', calories: 285, icon: '🍕'),
    FoodOption(name: 'Burger', calories: 500, icon: '🍔'),
    FoodOption(name: 'Rice (1 cup)', calories: 200, icon: '🍚'),
    FoodOption(name: 'Chicken Breast', calories: 165, icon: '🍗'),
    FoodOption(name: 'Soup', calories: 100, icon: '🥣'),
  ];

  List<CalorieEntry> _entries = [];
  List<DailyCalorieSummary> _dailySummaries = [];
  int _dailyGoal = defaultGoal;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  int get dailyGoal => _dailyGoal;
  List<DailyCalorieSummary> get history => _dailySummaries;
  int get todayCal => getTodaySummary()?.totalCal ?? 0;
  double get progress => todayCal / _dailyGoal;
  bool get goalReached => todayCal >= _dailyGoal;
  bool get overGoal => todayCal > _dailyGoal;
  int get remainingCal => _dailyGoal - todayCal;

  DailyCalorieSummary? getTodaySummary() {
    final todayKey = DailyCalorieSummary.getDayKey(DateTime.now());
    return _dailySummaries.firstWhereOrNull((e) => DailyCalorieSummary.getDayKey(e.date) == todayKey);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = prefs.getInt(_goalKey) ?? defaultGoal;
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _entries = entryStrings.map((s) => CalorieEntry.fromJson(s)).toList();
    final summaryStrings = prefs.getStringList(_summaryKey) ?? [];
    _dailySummaries = summaryStrings.map((s) => DailyCalorieSummary.fromJson(s)).toList();
    _isInitialized = true;
    _checkDailyReset();
    Global.loggerModel.info("Calorie initialized with ${_dailySummaries.length} daily summaries", source: "Calorie");
    notifyListeners();
  }

  Future<void> refresh() async {
    _checkDailyReset();
    notifyListeners();
  }

  void _checkDailyReset() {
    final today = DateTime.now();
    final todayKey = DailyCalorieSummary.getDayKey(today);
    
    if (_dailySummaries.isEmpty || DailyCalorieSummary.getDayKey(_dailySummaries.last.date) != todayKey) {
      _dailySummaries.add(DailyCalorieSummary(
        date: today,
        totalCal: 0,
        goal: _dailyGoal,
      ));
      
      while (_dailySummaries.length > maxHistoryDays) {
        _dailySummaries.removeAt(0);
      }
      _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _entries.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
    final summaryStrings = _dailySummaries.map((e) => e.toJson()).toList();
    await prefs.setStringList(_summaryKey, summaryStrings);
    await prefs.setInt(_goalKey, _dailyGoal);
  }

  void addQuickFood(String foodType) {
    final food = foodOptions.firstWhereOrNull((f) => f.name.toLowerCase().contains(foodType.toLowerCase()));
    if (food != null) {
      addCalorie(food.calories, food.name);
    } else {
      addCalorie(100, 'Food');
    }
  }

  void addCalorie(int amountCal, String foodType) {
    final today = DateTime.now();
    _entries.add(CalorieEntry(
      date: today,
      amountCal: amountCal,
      goal: _dailyGoal,
      foodType: foodType,
    ));
    
    final todaySummary = getTodaySummary();
    if (todaySummary != null) {
      final index = _dailySummaries.indexOf(todaySummary);
      if (index >= 0) {
        _dailySummaries[index] = DailyCalorieSummary(
          date: todaySummary.date,
          totalCal: todaySummary.totalCal + amountCal,
          goal: todaySummary.goal,
        );
      }
    }
    
    Global.loggerModel.info("Added $amountCal cal ($foodType), total: $todayCal cal", source: "Calorie");
    _save();
    notifyListeners();
  }

  void removeLastEntry() {
    if (_entries.isNotEmpty) {
      final lastEntry = _entries.last;
      final todayKey = CalorieEntry.getDayKey(DateTime.now());
      
      if (CalorieEntry.getDayKey(lastEntry.date) == todayKey) {
        _entries.removeLast();
        
        final todaySummary = getTodaySummary();
        if (todaySummary != null) {
          final index = _dailySummaries.indexOf(todaySummary);
          if (index >= 0) {
            final newTotal = todaySummary.totalCal - lastEntry.amountCal;
            _dailySummaries[index] = DailyCalorieSummary(
              date: todaySummary.date,
              totalCal: newTotal.clamp(0, double.maxFinite.toInt()),
              goal: todaySummary.goal,
            );
          }
        }
        Global.loggerModel.info("Removed calorie entry, total: $todayCal cal", source: "Calorie");
        _save();
        notifyListeners();
      }
    }
  }

  void setGoal(int goal) {
    if (goal > 0 && goal <= 5000) {
      _dailyGoal = goal;
      final todaySummary = getTodaySummary();
      if (todaySummary != null) {
        final index = _dailySummaries.indexOf(todaySummary);
        if (index >= 0) {
          _dailySummaries[index] = DailyCalorieSummary(
            date: todaySummary.date,
            totalCal: todaySummary.totalCal,
            goal: goal,
          );
        }
      }
      Global.loggerModel.info("Set calorie goal to $goal cal", source: "Calorie");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _entries.clear();
    _dailySummaries.clear();
    _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_summaryKey);
    Global.loggerModel.info("Cleared calorie history", source: "Calorie");
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

class CalorieCard extends StatefulWidget {
  @override
  State<CalorieCard> createState() => _CalorieCardState();
}

class _CalorieCardState extends State<CalorieCard> {
  @override
  Widget build(BuildContext context) {
    final calorie = context.watch<CalorieModel>();

    if (!calorie.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.restaurant, size: 24),
              SizedBox(width: 12),
              Text("Calorie Tracker: Loading..."),
            ],
          ),
        ),
      );
    }

    final progressColor = calorie.overGoal
        ? Theme.of(context).colorScheme.error
        : calorie.goalReached
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
                  Icon(Icons.restaurant, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Calorie Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    "${calorie.todayCal}/${calorie.dailyGoal} cal",
                    style: TextStyle(
                      fontSize: 14,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (!calorie.overGoal)
                Text(
                  "Remaining: ${calorie.remainingCal} cal",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: calorie.progress.clamp(0.0, 1.5),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: progressColor,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              if (calorie.overGoal)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "Over daily goal!",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CalorieModel.foodOptions.map((food) {
                  return ActionChip(
                    avatar: Text(food.icon, style: TextStyle(fontSize: 14)),
                    label: Text("${food.calories} cal"),
                    onPressed: () => calorie.addCalorie(food.calories, food.name),
                  );
                }).toList(),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 20),
                    onPressed: calorie.todayCal > 0 ? () => calorie.removeLastEntry() : null,
                    tooltip: "Remove last",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCustomAddDialog(context, calorie),
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
                            "Custom",
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, size: 18),
                    onPressed: () => _showGoalDialog(context, calorie),
                    tooltip: "Set goal",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
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

  void _showCustomAddDialog(BuildContext context, CalorieModel calorie) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Custom Calories"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter calorie amount:"),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g., 300",
                suffixText: "cal",
              ),
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
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                calorie.addCalorie(amount, 'Custom');
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context, CalorieModel calorie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Daily Goal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Maximum calories per day:"),
            SizedBox(height: 8),
            Text(
              "Typical: 2000 cal",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: calorie.dailyGoal > 100 ? () => calorie.setGoal(calorie.dailyGoal - 100) : null,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${calorie.dailyGoal}",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: calorie.dailyGoal < 5000 ? () => calorie.setGoal(calorie.dailyGoal + 100) : null,
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