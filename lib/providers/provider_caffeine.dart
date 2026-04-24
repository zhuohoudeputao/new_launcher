import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

CaffeineModel caffeineModel = CaffeineModel();

MyProvider providerCaffeine = MyProvider(
    name: "Caffeine",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Track caffeine',
      keywords: 'caffeine coffee tea energy drink cola beverage intake track daily health',
      action: () {
        Global.infoModel.addInfo("AddCaffeine", "Add Caffeine",
            subtitle: "Tap to add caffeine intake",
            icon: Icon(Icons.local_cafe),
            onTap: () => caffeineModel.addQuickDrink('coffee'));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await caffeineModel.init();
  Global.infoModel.addInfoWidget(
      "Caffeine",
      ChangeNotifierProvider.value(
          value: caffeineModel,
          builder: (context, child) => CaffeineCard()),
      title: "Caffeine Tracker");
}

Future<void> _update() async {
  await caffeineModel.refresh();
}

class CaffeineEntry {
  final DateTime date;
  final int amountMg;
  final int limit;
  final String drinkType;

  CaffeineEntry({
    required this.date,
    required this.amountMg,
    required this.limit,
    this.drinkType = '',
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'amountMg': amountMg,
      'limit': limit,
      'drinkType': drinkType,
    });
  }

  static CaffeineEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return CaffeineEntry(
      date: DateTime.parse(map['date'] as String),
      amountMg: map['amountMg'] as int,
      limit: map['limit'] as int,
      drinkType: map['drinkType'] as String? ?? '',
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}

class DailyCaffeineSummary {
  final DateTime date;
  final int totalMg;
  final int limit;

  DailyCaffeineSummary({
    required this.date,
    required this.totalMg,
    required this.limit,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'totalMg': totalMg,
      'limit': limit,
    });
  }

  static DailyCaffeineSummary fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return DailyCaffeineSummary(
      date: DateTime.parse(map['date'] as String),
      totalMg: map['totalMg'] as int,
      limit: map['limit'] as int,
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}

class DrinkOption {
  final String name;
  final int caffeineMg;
  final String icon;

  DrinkOption({
    required this.name,
    required this.caffeineMg,
    required this.icon,
  });
}

class CaffeineModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  static const String _storageKey = 'caffeine_entries';
  static const String _summaryKey = 'caffeine_daily_summaries';
  static const String _limitKey = 'caffeine_limit';
  static const int defaultLimit = 400;

  static final List<DrinkOption> drinkOptions = [
    DrinkOption(name: 'Coffee (8oz)', caffeineMg: 95, icon: '☕'),
    DrinkOption(name: 'Espresso', caffeineMg: 64, icon: '☕'),
    DrinkOption(name: 'Tea (8oz)', caffeineMg: 26, icon: '🍵'),
    DrinkOption(name: 'Green Tea', caffeineMg: 28, icon: '🍵'),
    DrinkOption(name: 'Energy Drink', caffeineMg: 80, icon: '⚡'),
    DrinkOption(name: 'Cola (12oz)', caffeineMg: 35, icon: '🥤'),
    DrinkOption(name: 'Diet Cola', caffeineMg: 46, icon: '🥤'),
    DrinkOption(name: 'Chocolate Bar', caffeineMg: 12, icon: '🍫'),
  ];

  List<CaffeineEntry> _entries = [];
  List<DailyCaffeineSummary> _dailySummaries = [];
  int _dailyLimit = defaultLimit;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  int get dailyLimit => _dailyLimit;
  List<DailyCaffeineSummary> get history => _dailySummaries;
  int get todayMg => getTodaySummary()?.totalMg ?? 0;
  double get progress => todayMg / _dailyLimit;
  bool get limitReached => todayMg >= _dailyLimit;
  bool get overLimit => todayMg > _dailyLimit;

  DailyCaffeineSummary? getTodaySummary() {
    final todayKey = DailyCaffeineSummary.getDayKey(DateTime.now());
    return _dailySummaries.firstWhereOrNull((e) => DailyCaffeineSummary.getDayKey(e.date) == todayKey);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyLimit = prefs.getInt(_limitKey) ?? defaultLimit;
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _entries = entryStrings.map((s) => CaffeineEntry.fromJson(s)).toList();
    final summaryStrings = prefs.getStringList(_summaryKey) ?? [];
    _dailySummaries = summaryStrings.map((s) => DailyCaffeineSummary.fromJson(s)).toList();
    _isInitialized = true;
    _checkDailyReset();
    Global.loggerModel.info("Caffeine initialized with ${_dailySummaries.length} daily summaries", source: "Caffeine");
    notifyListeners();
  }

  Future<void> refresh() async {
    _checkDailyReset();
    notifyListeners();
  }

  void _checkDailyReset() {
    final today = DateTime.now();
    final todayKey = DailyCaffeineSummary.getDayKey(today);
    
    if (_dailySummaries.isEmpty || DailyCaffeineSummary.getDayKey(_dailySummaries.last.date) != todayKey) {
      _dailySummaries.add(DailyCaffeineSummary(
        date: today,
        totalMg: 0,
        limit: _dailyLimit,
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
    await prefs.setInt(_limitKey, _dailyLimit);
  }

  void addQuickDrink(String drinkType) {
    final drink = drinkOptions.firstWhereOrNull((d) => d.name.toLowerCase().contains(drinkType.toLowerCase()));
    if (drink != null) {
      addCaffeine(drink.caffeineMg, drink.name);
    } else {
      addCaffeine(95, 'Coffee');
    }
  }

  void addCaffeine(int amountMg, String drinkType) {
    final today = DateTime.now();
    _entries.add(CaffeineEntry(
      date: today,
      amountMg: amountMg,
      limit: _dailyLimit,
      drinkType: drinkType,
    ));
    
    final todaySummary = getTodaySummary();
    if (todaySummary != null) {
      final index = _dailySummaries.indexOf(todaySummary);
      if (index >= 0) {
        _dailySummaries[index] = DailyCaffeineSummary(
          date: todaySummary.date,
          totalMg: todaySummary.totalMg + amountMg,
          limit: todaySummary.limit,
        );
      }
    }
    
    Global.loggerModel.info("Added $amountMg mg caffeine ($drinkType), total: $todayMg mg", source: "Caffeine");
    _save();
    notifyListeners();
  }

  void removeLastEntry() {
    if (_entries.isNotEmpty) {
      final lastEntry = _entries.last;
      final todayKey = CaffeineEntry.getDayKey(DateTime.now());
      
      if (CaffeineEntry.getDayKey(lastEntry.date) == todayKey) {
        _entries.removeLast();
        
        final todaySummary = getTodaySummary();
        if (todaySummary != null) {
          final index = _dailySummaries.indexOf(todaySummary);
          if (index >= 0) {
            final newTotal = todaySummary.totalMg - lastEntry.amountMg;
            _dailySummaries[index] = DailyCaffeineSummary(
              date: todaySummary.date,
              totalMg: newTotal.clamp(0, double.maxFinite.toInt()),
              limit: todaySummary.limit,
            );
          }
        }
        Global.loggerModel.info("Removed caffeine entry, total: $todayMg mg", source: "Caffeine");
        _save();
        notifyListeners();
      }
    }
  }

  void setLimit(int limit) {
    if (limit > 0 && limit <= 1000) {
      _dailyLimit = limit;
      final todaySummary = getTodaySummary();
      if (todaySummary != null) {
        final index = _dailySummaries.indexOf(todaySummary);
        if (index >= 0) {
          _dailySummaries[index] = DailyCaffeineSummary(
            date: todaySummary.date,
            totalMg: todaySummary.totalMg,
            limit: limit,
          );
        }
      }
      Global.loggerModel.info("Set caffeine limit to $limit mg", source: "Caffeine");
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
    Global.loggerModel.info("Cleared caffeine history", source: "Caffeine");
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

class CaffeineCard extends StatefulWidget {
  @override
  State<CaffeineCard> createState() => _CaffeineCardState();
}

class _CaffeineCardState extends State<CaffeineCard> {
  @override
  Widget build(BuildContext context) {
    final caffeine = context.watch<CaffeineModel>();

    if (!caffeine.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.local_cafe, size: 24),
              SizedBox(width: 12),
              Text("Caffeine Tracker: Loading..."),
            ],
          ),
        ),
      );
    }

    final progressColor = caffeine.overLimit
        ? Theme.of(context).colorScheme.error
        : caffeine.limitReached
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
                  Icon(Icons.local_cafe, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Caffeine Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    "${caffeine.todayMg}/${caffeine.dailyLimit} mg",
                    style: TextStyle(
                      fontSize: 14,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: caffeine.progress.clamp(0.0, 1.5),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: progressColor,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              if (caffeine.overLimit)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "Over recommended limit!",
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
                children: CaffeineModel.drinkOptions.map((drink) {
                  return ActionChip(
                    avatar: Text(drink.icon, style: TextStyle(fontSize: 14)),
                    label: Text("${drink.caffeineMg} mg"),
                    onPressed: () => caffeine.addCaffeine(drink.caffeineMg, drink.name),
                  );
                }).toList(),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 20),
                    onPressed: caffeine.todayMg > 0 ? () => caffeine.removeLastEntry() : null,
                    tooltip: "Remove last",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCustomAddDialog(context, caffeine),
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
                    onPressed: () => _showLimitDialog(context, caffeine),
                    tooltip: "Set limit",
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

  void _showCustomAddDialog(BuildContext context, CaffeineModel caffeine) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Custom Amount"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter caffeine amount in mg:"),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g., 100",
                suffixText: "mg",
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
                caffeine.addCaffeine(amount, 'Custom');
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showLimitDialog(BuildContext context, CaffeineModel caffeine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Daily Limit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Maximum caffeine per day (mg):"),
            SizedBox(height: 8),
            Text(
              "Recommended: 400 mg",
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
                  onPressed: caffeine.dailyLimit > 50 ? () => caffeine.setLimit(caffeine.dailyLimit - 50) : null,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${caffeine.dailyLimit}",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: caffeine.dailyLimit < 1000 ? () => caffeine.setLimit(caffeine.dailyLimit + 50) : null,
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