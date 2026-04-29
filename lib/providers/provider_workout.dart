import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

WorkoutModel workoutModel = WorkoutModel();

MyProvider providerWorkout = MyProvider(
    name: "Workout",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Log workout',
      keywords: 'workout exercise gym fitness run cycle swim yoga walk training log',
      action: () {
        Global.infoModel.addInfo("LogWorkout", "Log Workout",
            subtitle: "Tap to log your exercise session",
            icon: Icon(Icons.fitness_center),
            onTap: () => _showWorkoutLogger(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await workoutModel.init();
  Global.infoModel.addInfoWidget(
      "Workout",
      ChangeNotifierProvider.value(
          value: workoutModel,
          builder: (context, child) => WorkoutCard()),
      title: "Workout Log");
}

Future<void> _update() async {
  await workoutModel.refresh();
}

void _showWorkoutLogger(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => WorkoutLogDialog(),
  );
}

enum WorkoutType {
  running,
  cycling,
  weights,
  yoga,
  swimming,
  walking,
  hiit,
  other,
}

extension WorkoutTypeExtension on WorkoutType {
  String get emoji {
    switch (this) {
      case WorkoutType.running:
        return '🏃';
      case WorkoutType.cycling:
        return '🚴';
      case WorkoutType.weights:
        return '🏋️';
      case WorkoutType.yoga:
        return '🧘';
      case WorkoutType.swimming:
        return '🏊';
      case WorkoutType.walking:
        return '🚶';
      case WorkoutType.hiit:
        return '⚡';
      case WorkoutType.other:
        return '💪';
    }
  }

  String get label {
    switch (this) {
      case WorkoutType.running:
        return 'Running';
      case WorkoutType.cycling:
        return 'Cycling';
      case WorkoutType.weights:
        return 'Weights';
      case WorkoutType.yoga:
        return 'Yoga';
      case WorkoutType.swimming:
        return 'Swimming';
      case WorkoutType.walking:
        return 'Walking';
      case WorkoutType.hiit:
        return 'HIIT';
      case WorkoutType.other:
        return 'Other';
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case WorkoutType.running:
        return Colors.red.shade400;
      case WorkoutType.cycling:
        return Colors.green.shade400;
      case WorkoutType.weights:
        return Colors.orange.shade400;
      case WorkoutType.yoga:
        return Colors.purple.shade400;
      case WorkoutType.swimming:
        return Colors.blue.shade400;
      case WorkoutType.walking:
        return Colors.teal.shade400;
      case WorkoutType.hiit:
        return Colors.yellow.shade700;
      case WorkoutType.other:
        return Colors.grey.shade500;
    }
  }

  static WorkoutType fromString(String value) {
    switch (value) {
      case 'running':
        return WorkoutType.running;
      case 'cycling':
        return WorkoutType.cycling;
      case 'weights':
        return WorkoutType.weights;
      case 'yoga':
        return WorkoutType.yoga;
      case 'swimming':
        return WorkoutType.swimming;
      case 'walking':
        return WorkoutType.walking;
      case 'hiit':
        return WorkoutType.hiit;
      default:
        return WorkoutType.other;
    }
  }
}

class WorkoutEntry {
  final DateTime date;
  final WorkoutType type;
  final int durationMinutes;
  final String? note;

  WorkoutEntry({
    required this.date,
    required this.type,
    required this.durationMinutes,
    this.note,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'durationMinutes': durationMinutes,
      'note': note,
    });
  }

  static WorkoutEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return WorkoutEntry(
      date: DateTime.parse(map['date'] as String),
      type: WorkoutTypeExtension.fromString(map['type'] as String),
      durationMinutes: map['durationMinutes'] as int,
      note: map['note'] as String?,
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  String formatDuration() {
    if (durationMinutes >= 60) {
      final h = durationMinutes ~/ 60;
      final m = durationMinutes % 60;
      if (m == 0) {
        return "${h}h";
      }
      return "${h}h ${m}m";
    }
    return "${durationMinutes}m";
  }
}

class WorkoutModel extends ChangeNotifier {
  static const int maxHistoryEntries = 100;
  static const String _storageKey = 'workout_entries';

  List<WorkoutEntry> _history = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<WorkoutEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  int get totalEntries => _history.length;

  int get totalMinutes {
    return _history.fold<int>(0, (sum, e) => sum + e.durationMinutes);
  }

  int get thisWeekMinutes {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEntries = _history.where((e) => e.date.isAfter(weekStart));
    return weekEntries.fold<int>(0, (sum, e) => sum + e.durationMinutes);
  }

  int get thisMonthMinutes {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEntries = _history.where((e) => e.date.isAfter(monthStart));
    return monthEntries.fold<int>(0, (sum, e) => sum + e.durationMinutes);
  }

  int get thisWeekSessions {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _history.where((e) => e.date.isAfter(weekStart)).length;
  }

  int get thisMonthSessions {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _history.where((e) => e.date.isAfter(monthStart)).length;
  }

  Map<WorkoutType, int> getTypeCounts() {
    final counts = <WorkoutType, int>{};
    for (final entry in _history) {
      counts[entry.type] = (counts[entry.type] ?? 0) + 1;
    }
    return counts;
  }

  WorkoutEntry? get lastEntry {
    if (_history.isEmpty) return null;
    return _history.last;
  }

  String formatTotalMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes / 60;
      final m = minutes % 60;
      if (m == 0) {
        return "${h.floor()}h";
      }
      return "${h.floor()}h ${m}m";
    }
    return "${minutes}m";
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => WorkoutEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Workout initialized with ${_history.length} entries", source: "Workout");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void logWorkout(WorkoutType type, int durationMinutes, {String? note, DateTime? customDate}) {
    final date = customDate ?? DateTime.now();
    
    final newEntry = WorkoutEntry(
      date: date,
      type: type,
      durationMinutes: durationMinutes,
      note: note,
    );

    _history.add(newEntry);
    
    final sortedHistory = List<WorkoutEntry>.from(_history)
      ..sort((a, b) => a.date.compareTo(b.date));
    while (sortedHistory.length > maxHistoryEntries) {
      sortedHistory.removeAt(0);
    }
    _history = sortedHistory;

    Global.loggerModel.info("Logged workout: ${type.label} ${durationMinutes}m", source: "Workout");
    _save();
    notifyListeners();
  }

  void deleteEntry(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _history.removeAt(index);
      Global.loggerModel.info("Deleted workout entry ${entry.type.label} for ${entry.date.month}/${entry.date.day}", source: "Workout");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared workout history", source: "Workout");
    notifyListeners();
  }
}

class WorkoutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutModel>();

    if (!workout.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.fitness_center, size: 24),
              SizedBox(width: 12),
              Text("Workout Log: Loading..."),
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
                  Icon(Icons.fitness_center, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Workout Log",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (workout.lastEntry != null)
                    Text(
                      workout.lastEntry!.formatDuration(),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (workout.lastEntry != null) ...[
                Row(
                  children: [
                    Text(
                      "Last: ${workout.lastEntry!.type.emoji}",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(width: 8),
                    Text(
                      workout.lastEntry!.type.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: workout.lastEntry!.type.getColor(context),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "${workout.lastEntry!.date.month}/${workout.lastEntry!.date.day}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ] else ...[
                Text(
                  "No workouts logged yet",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
              ],
              if (workout.hasHistory) ...[
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Week: ${workout.formatTotalMinutes(workout.thisWeekMinutes)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Month: ${workout.formatTotalMinutes(workout.thisMonthMinutes)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Total: ${workout.formatTotalMinutes(workout.totalMinutes)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.event,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "${workout.totalEntries} sessions",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                    onPressed: () => _showWorkoutLogger(context),
                  ),
                  if (workout.hasHistory)
                    TextButton.icon(
                      icon: Icon(Icons.history, size: 18),
                      label: Text("History"),
                      onPressed: () => _showHistoryDialog(context, workout),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, WorkoutModel workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Workout History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: workout.history.length,
            addRepaintBoundaries: true,
            itemBuilder: (context, index) {
              final entry = workout.history[workout.history.length - 1 - index];
              return ListTile(
                leading: Text(entry.type.emoji, style: TextStyle(fontSize: 24)),
                title: Text("${entry.type.label} - ${entry.formatDuration()}"),
                subtitle: Text(
                  "${entry.date.month}/${entry.date.day}${entry.note != null ? ' - ${entry.note}' : ''}",
                  style: TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, size: 20),
                  onPressed: () {
                    workout.deleteEntry(workout.history.length - 1 - index);
                    Navigator.pop(context);
                    _showHistoryDialog(context, workout);
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
          if (workout.hasHistory)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showClearConfirmation(context, workout);
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

  void _showClearConfirmation(BuildContext context, WorkoutModel workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Are you sure you want to clear all workout history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              workout.clearHistory();
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

class WorkoutLogDialog extends StatefulWidget {
  @override
  State<WorkoutLogDialog> createState() => _WorkoutLogDialogState();
}

class _WorkoutLogDialogState extends State<WorkoutLogDialog> {
  WorkoutType _type = WorkoutType.running;
  int _duration = 30;
  String? _note;
  DateTime? _customDate;
  bool _useCustomDate = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Log Workout"),
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
            Text("Workout type:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WorkoutType.values.map((t) {
                final isSelected = t == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? t.getColor(context).withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? t.getColor(context) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.emoji, style: TextStyle(fontSize: 18)),
                        SizedBox(width: 4),
                        Text(t.label, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text("Duration (minutes):", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Slider(
              value: _duration.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              label: "${_duration}m",
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: "Note (optional)",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _note = v.isEmpty ? null : v,
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
            workoutModel.logWorkout(
              _type,
              _duration,
              note: _note,
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