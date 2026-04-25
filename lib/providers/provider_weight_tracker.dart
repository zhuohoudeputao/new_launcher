import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

WeightTrackerModel weightTrackerModel = WeightTrackerModel();

MyProvider providerWeightTracker = MyProvider(
    name: "WeightTracker",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Log weight',
      keywords: 'weight tracker body scale kg lb pound kilogram measure log track',
      action: () {
        Global.infoModel.addInfo("LogWeight", "Log Weight",
            subtitle: "Tap to log your body weight",
            icon: Icon(Icons.monitor_weight),
            onTap: () => _showWeightLogger(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await weightTrackerModel.init();
  Global.infoModel.addInfoWidget(
      "WeightTracker",
      ChangeNotifierProvider.value(
          value: weightTrackerModel,
          builder: (context, child) => WeightTrackerCard()),
      title: "Weight Tracker");
}

Future<void> _update() async {
  await weightTrackerModel.refresh();
}

void _showWeightLogger(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => WeightLogDialog(),
  );
}

enum WeightUnit {
  kg,
  lb,
}

extension WeightUnitExtension on WeightUnit {
  String get label {
    switch (this) {
      case WeightUnit.kg:
        return 'kg';
      case WeightUnit.lb:
        return 'lb';
    }
  }

  String get fullName {
    switch (this) {
      case WeightUnit.kg:
        return 'Kilograms';
      case WeightUnit.lb:
        return 'Pounds';
    }
  }

  double toKg(double value) {
    switch (this) {
      case WeightUnit.kg:
        return value;
      case WeightUnit.lb:
        return value * 0.45359237;
    }
  }

  double fromKg(double value) {
    switch (this) {
      case WeightUnit.kg:
        return value;
      case WeightUnit.lb:
        return value * 2.2046226218;
    }
  }
}

class WeightEntry {
  final DateTime date;
  final double weightKg;

  WeightEntry({
    required this.date,
    required this.weightKg,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'weightKg': weightKg,
    });
  }

  static WeightEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return WeightEntry(
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weightKg'] as num).toDouble(),
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  String formatWeight(WeightUnit unit) {
    final weight = unit.fromKg(weightKg);
    return "${weight.toStringAsFixed(1)} ${unit.label}";
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

class WeightTrackerModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  static const String _storageKey = 'weight_tracker_entries';
  static const String _goalKey = 'weight_tracker_goal';
  static const String _unitKey = 'weight_tracker_unit';

  List<WeightEntry> _history = [];
  double _goalWeightKg = 0;
  WeightUnit _unit = WeightUnit.kg;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<WeightEntry> get history => _history;
  WeightUnit get unit => _unit;
  double get goalWeightKg => _goalWeightKg;
  bool get hasGoal => _goalWeightKg > 0;

  WeightEntry? get todayEntry {
    final todayKey = WeightEntry.getDayKey(DateTime.now());
    return _history.firstWhereOrNull((e) => WeightEntry.getDayKey(e.date) == todayKey);
  }

  WeightEntry? get latestEntry {
    if (_history.isEmpty) return null;
    return _history.last;
  }

  bool get hasHistory => _history.isNotEmpty;

  double get currentWeightKg {
    return latestEntry?.weightKg ?? 0;
  }

  double get averageWeight {
    if (_history.isEmpty) return 0;
    final sum = _history.fold<double>(0, (sum, e) => sum + e.weightKg);
    return sum / _history.length;
  }

  double get minWeight {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
  }

  double get maxWeight {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
  }

  double get goalProgress {
    if (_history.isEmpty || !hasGoal) return 0;
    final firstEntry = _history.first;
    final latest = latestEntry!;
    if (firstEntry.weightKg == _goalWeightKg) return 100;
    if (firstEntry.weightKg < _goalWeightKg) {
      final progress = (latest.weightKg - firstEntry.weightKg) / (_goalWeightKg - firstEntry.weightKg);
      return (progress * 100).clamp(0, 100);
    } else {
      final progress = (firstEntry.weightKg - latest.weightKg) / (firstEntry.weightKg - _goalWeightKg);
      return (progress * 100).clamp(0, 100);
    }
  }

  double get weightChange {
    if (_history.length < 2) return 0;
    final firstEntry = _history.first;
    final latestEntry = _history.last;
    return latestEntry.weightKg - firstEntry.weightKg;
  }

  String get weightChangeLabel {
    if (_history.length < 2) return "";
    final change = weightChange;
    if (change > 0) {
      return "+${unit.fromKg(change).toStringAsFixed(1)} ${unit.label}";
    } else if (change < 0) {
      return "${unit.fromKg(change).toStringAsFixed(1)} ${unit.label}";
    }
    return "0 ${unit.label}";
  }

  int get daysLogged => _history.length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => WeightEntry.fromJson(s)).toList();
    _goalWeightKg = prefs.getDouble(_goalKey) ?? 0;
    final unitValue = prefs.getString(_unitKey) ?? 'kg';
    _unit = unitValue == 'lb' ? WeightUnit.lb : WeightUnit.kg;
    _isInitialized = true;
    Global.loggerModel.info("Weight Tracker initialized with ${_history.length} entries", source: "WeightTracker");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
    await prefs.setDouble(_goalKey, _goalWeightKg);
    await prefs.setString(_unitKey, _unit.label);
  }

  void setUnit(WeightUnit unit) {
    _unit = unit;
    _save();
    notifyListeners();
    Global.loggerModel.info("Weight unit set to ${unit.fullName}", source: "WeightTracker");
  }

  void setGoal(double goalWeight, WeightUnit unit) {
    _goalWeightKg = unit.toKg(goalWeight);
    _save();
    notifyListeners();
    Global.loggerModel.info("Goal weight set to ${goalWeight.toStringAsFixed(1)} ${unit.label}", source: "WeightTracker");
  }

  void clearGoal() {
    _goalWeightKg = 0;
    _save();
    notifyListeners();
    Global.loggerModel.info("Goal weight cleared", source: "WeightTracker");
  }

  void logWeight(double weight, WeightUnit unit, {DateTime? customDate}) {
    final date = customDate ?? DateTime.now();
    final weightKg = unit.toKg(weight);
    final dayKey = WeightEntry.getDayKey(date);
    final existingIndex = _history.indexWhere((e) => WeightEntry.getDayKey(e.date) == dayKey);

    final newEntry = WeightEntry(
      date: date,
      weightKg: weightKg,
    );

    if (existingIndex >= 0) {
      _history[existingIndex] = newEntry;
      Global.loggerModel.info("Updated weight for ${date.month}/${date.day}: ${weight.toStringAsFixed(1)} ${unit.label}", source: "WeightTracker");
    } else {
      _history.add(newEntry);
      Global.loggerModel.info("Logged weight: ${weight.toStringAsFixed(1)} ${unit.label}", source: "WeightTracker");
    }

    final sortedHistory = List<WeightEntry>.from(_history)
      ..sort((a, b) => a.date.compareTo(b.date));
    while (sortedHistory.length > maxHistoryDays) {
      sortedHistory.removeAt(0);
    }
    _history = sortedHistory;

    _save();
    notifyListeners();
  }

  void deleteEntry(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _history.removeAt(index);
      Global.loggerModel.info("Deleted weight entry for ${entry.date.month}/${entry.date.day}", source: "WeightTracker");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared weight history", source: "WeightTracker");
    notifyListeners();
  }
}

class WeightTrackerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weightTracker = context.watch<WeightTrackerModel>();

    if (!weightTracker.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.monitor_weight, size: 24),
              SizedBox(width: 12),
              Text("Weight Tracker: Loading..."),
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
                  Icon(Icons.monitor_weight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Weight Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (weightTracker.latestEntry != null)
                    Text(
                      weightTracker.latestEntry!.formatWeight(weightTracker.unit),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (weightTracker.latestEntry != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "${weightTracker.latestEntry!.date.month}/${weightTracker.latestEntry!.date.day}",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    if (weightTracker.hasHistory && weightTracker.history.length >= 2) ...[
                      SizedBox(width: 16),
                      Icon(
                        weightTracker.weightChange >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: weightTracker.weightChange >= 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.tertiary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        weightTracker.weightChangeLabel,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8),
              ] else ...[
                Text(
                  "No weight logged yet",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
              ],
              if (weightTracker.hasGoal) ...[
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Goal: ${weightTracker.unit.fromKg(weightTracker.goalWeightKg).toStringAsFixed(1)} ${weightTracker.unit.label}",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    if (weightTracker.hasHistory) ...[
                      SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: weightTracker.goalProgress / 100,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            weightTracker.goalProgress >= 100
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "${weightTracker.goalProgress.toStringAsFixed(0)}%",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8),
              ],
              if (weightTracker.hasHistory) ...[
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Avg: ${weightTracker.unit.fromKg(weightTracker.averageWeight).toStringAsFixed(1)} ${weightTracker.unit.label}",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Min: ${weightTracker.unit.fromKg(weightTracker.minWeight).toStringAsFixed(1)}",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Max: ${weightTracker.unit.fromKg(weightTracker.maxWeight).toStringAsFixed(1)}",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.add, size: 18),
                    label: Text("Log"),
                    onPressed: () => _showWeightLogger(context),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.flag, size: 18),
                    label: Text("Goal"),
                    onPressed: () => _showGoalDialog(context, weightTracker),
                  ),
                  if (weightTracker.hasHistory)
                    TextButton.icon(
                      icon: Icon(Icons.history, size: 18),
                      label: Text("History"),
                      onPressed: () => _showHistoryDialog(context, weightTracker),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WeightTrackerModel weightTracker) {
    showDialog(
      context: context,
      builder: (context) => WeightGoalDialog(),
    );
  }

  void _showHistoryDialog(BuildContext context, WeightTrackerModel weightTracker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Weight History (${weightTracker.daysLogged} days)"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: weightTracker.history.length,
            itemBuilder: (context, index) {
              final entry = weightTracker.history[weightTracker.history.length - 1 - index];
              return ListTile(
                leading: Icon(Icons.monitor_weight, color: Theme.of(context).colorScheme.primary),
                title: Text(entry.formatWeight(weightTracker.unit)),
                subtitle: Text(
                  "${entry.date.month}/${entry.date.day}/${entry.date.year}",
                  style: TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, size: 20),
                  onPressed: () {
                    weightTracker.deleteEntry(weightTracker.history.length - 1 - index);
                    Navigator.pop(context);
                    _showHistoryDialog(context, weightTracker);
                  },
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
          if (weightTracker.hasHistory)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showClearConfirmation(context, weightTracker);
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

  void _showClearConfirmation(BuildContext context, WeightTrackerModel weightTracker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Are you sure you want to clear all weight history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              weightTracker.clearHistory();
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

class WeightLogDialog extends StatefulWidget {
  @override
  State<WeightLogDialog> createState() => _WeightLogDialogState();
}

class _WeightLogDialogState extends State<WeightLogDialog> {
  double _weight = 70.0;
  DateTime? _customDate;
  bool _useCustomDate = false;

  @override
  Widget build(BuildContext context) {
    final weightTracker = weightTrackerModel;
    final unit = weightTracker.unit;

    return AlertDialog(
      title: Text("Log Weight"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _useCustomDate,
                  onChanged: (v) => setState(() => _useCustomDate = v ?? false),
                ),
                Text("Log for different date"),
              ],
            ),
            if (_useCustomDate) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Text("Date: "),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _customDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _customDate = picked);
                      }
                    },
                    child: Text(_customDate != null
                        ? "${_customDate!.month}/${_customDate!.day}"
                        : "Select"),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
            Text("Weight (${unit.label}):", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: "Enter weight",
                      suffixText: unit.label,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) {
                        _weight = parsed;
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionChip(
                  label: Text("kg"),
                  onPressed: () {
                    weightTracker.setUnit(WeightUnit.kg);
                    setState(() {});
                  },
                  backgroundColor: unit == WeightUnit.kg
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                SizedBox(width: 8),
                ActionChip(
                  label: Text("lb"),
                  onPressed: () {
                    weightTracker.setUnit(WeightUnit.lb);
                    setState(() {});
                  },
                  backgroundColor: unit == WeightUnit.lb
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
              ],
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
            weightTracker.logWeight(
              _weight,
              unit,
              customDate: _useCustomDate ? _customDate : null,
            );
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}

class WeightGoalDialog extends StatefulWidget {
  @override
  State<WeightGoalDialog> createState() => _WeightGoalDialogState();
}

class _WeightGoalDialogState extends State<WeightGoalDialog> {
  double _goalWeight = 65.0;
  bool _clearGoal = false;

  @override
  Widget build(BuildContext context) {
    final weightTracker = weightTrackerModel;
    final unit = weightTracker.unit;

    if (weightTracker.hasGoal) {
      _goalWeight = unit.fromKg(weightTracker.goalWeightKg);
    }

    return AlertDialog(
      title: Text("Set Goal Weight"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Goal weight (${unit.label}):", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: "Enter goal weight",
                      suffixText: unit.label,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) {
                        _goalWeight = parsed;
                        _clearGoal = false;
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionChip(
                  label: Text("kg"),
                  onPressed: () {
                    weightTracker.setUnit(WeightUnit.kg);
                    setState(() {});
                  },
                  backgroundColor: unit == WeightUnit.kg
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                SizedBox(width: 8),
                ActionChip(
                  label: Text("lb"),
                  onPressed: () {
                    weightTracker.setUnit(WeightUnit.lb);
                    setState(() {});
                  },
                  backgroundColor: unit == WeightUnit.lb
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
              ],
            ),
            if (weightTracker.hasGoal) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _clearGoal,
                    onChanged: (v) => setState(() => _clearGoal = v ?? false),
                  ),
                  Text("Clear goal"),
                ],
              ),
            ],
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
            if (_clearGoal) {
              weightTracker.clearGoal();
            } else {
              weightTracker.setGoal(_goalWeight, unit);
            }
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}