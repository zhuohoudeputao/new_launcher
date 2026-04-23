import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

SleepModel sleepModel = SleepModel();

MyProvider providerSleep = MyProvider(
    name: "Sleep",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Log sleep',
      keywords: 'sleep rest nap bed track night hours quality bedtime',
      action: () {
        Global.infoModel.addInfo("LogSleep", "Log Sleep",
            subtitle: "Tap to log your sleep duration and quality",
            icon: Icon(Icons.bedtime),
            onTap: () => _showSleepLogger(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await sleepModel.init();
  Global.infoModel.addInfoWidget(
      "Sleep",
      ChangeNotifierProvider.value(
          value: sleepModel,
          builder: (context, child) => SleepCard()),
      title: "Sleep Tracker");
}

Future<void> _update() async {
  await sleepModel.refresh();
}

void _showSleepLogger(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => SleepLogDialog(),
  );
}

enum SleepQuality {
  terrible,
  poor,
  fair,
  good,
  excellent,
}

extension SleepQualityExtension on SleepQuality {
  String get emoji {
    switch (this) {
      case SleepQuality.terrible:
        return '😫';
      case SleepQuality.poor:
        return '😴';
      case SleepQuality.fair:
        return '😐';
      case SleepQuality.good:
        return '😊';
      case SleepQuality.excellent:
        return '😄';
    }
  }

  String get label {
    switch (this) {
      case SleepQuality.terrible:
        return 'Terrible';
      case SleepQuality.poor:
        return 'Poor';
      case SleepQuality.fair:
        return 'Fair';
      case SleepQuality.good:
        return 'Good';
      case SleepQuality.excellent:
        return 'Excellent';
    }
  }

  int get value {
    switch (this) {
      case SleepQuality.terrible:
        return 1;
      case SleepQuality.poor:
        return 2;
      case SleepQuality.fair:
        return 3;
      case SleepQuality.good:
        return 4;
      case SleepQuality.excellent:
        return 5;
    }
  }

  static SleepQuality fromValue(int value) {
    switch (value) {
      case 1:
        return SleepQuality.terrible;
      case 2:
        return SleepQuality.poor;
      case 3:
        return SleepQuality.fair;
      case 4:
        return SleepQuality.good;
      case 5:
        return SleepQuality.excellent;
      default:
        return SleepQuality.fair;
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case SleepQuality.terrible:
        return Colors.red.shade400;
      case SleepQuality.poor:
        return Colors.orange.shade400;
      case SleepQuality.fair:
        return Colors.grey.shade500;
      case SleepQuality.good:
        return Colors.lightBlue.shade400;
      case SleepQuality.excellent:
        return Colors.blue.shade500;
    }
  }
}

class SleepEntry {
  final DateTime date;
  final double hours;
  final int qualityValue;
  final String? note;

  SleepEntry({
    required this.date,
    required this.hours,
    required this.qualityValue,
    this.note,
  });

  SleepQuality get quality => SleepQualityExtension.fromValue(qualityValue);

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'hours': hours,
      'qualityValue': qualityValue,
      'note': note,
    });
  }

  static SleepEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return SleepEntry(
      date: DateTime.parse(map['date'] as String),
      hours: (map['hours'] as num).toDouble(),
      qualityValue: map['qualityValue'] as int,
      note: map['note'] as String?,
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  String formatHours() {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) {
      return "${h}h";
    }
    return "${h}h ${m}m";
  }
}

class SleepModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  static const String _storageKey = 'sleep_entries';

  List<SleepEntry> _history = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<SleepEntry> get history => _history;
  SleepEntry? get lastNightEntry {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final yesterdayKey = SleepEntry.getDayKey(yesterday);
    return _history.firstWhereOrNull((e) => SleepEntry.getDayKey(e.date) == yesterdayKey);
  }
  SleepEntry? get todayEntry {
    final todayKey = SleepEntry.getDayKey(DateTime.now());
    return _history.firstWhereOrNull((e) => SleepEntry.getDayKey(e.date) == todayKey);
  }
  bool get hasHistory => _history.isNotEmpty;

  double get averageHours {
    if (_history.isEmpty) return 0;
    final sum = _history.fold<double>(0, (sum, e) => sum + e.hours);
    return sum / _history.length;
  }

  double get averageQuality {
    if (_history.isEmpty) return 0;
    final sum = _history.fold<int>(0, (sum, e) => sum + e.qualityValue);
    return sum / _history.length;
  }

  SleepQuality get averageQualityLevel {
    return SleepQualityExtension.fromValue(averageQuality.round());
  }

  int get nightsGoalMet {
    if (_history.isEmpty) return 0;
    return _history.where((e) => e.hours >= 7).length;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => SleepEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Sleep initialized with ${_history.length} entries", source: "Sleep");
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

  void logSleep(double hours, SleepQuality quality, {String? note, DateTime? customDate}) {
    final date = customDate ?? DateTime.now().subtract(Duration(days: 1));
    final dayKey = SleepEntry.getDayKey(date);
    final existingIndex = _history.indexWhere((e) => SleepEntry.getDayKey(e.date) == dayKey);

    final newEntry = SleepEntry(
      date: date,
      hours: hours,
      qualityValue: quality.value,
      note: note,
    );

    if (existingIndex >= 0) {
      _history[existingIndex] = newEntry;
      Global.loggerModel.info("Updated sleep for ${date.month}/${date.day}: ${hours}h, ${quality.label}", source: "Sleep");
    } else {
      _history.add(newEntry);
      Global.loggerModel.info("Logged sleep: ${hours}h, ${quality.label}", source: "Sleep");
    }

    final sortedHistory = List<SleepEntry>.from(_history)
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
      Global.loggerModel.info("Deleted sleep entry for ${entry.date.month}/${entry.date.day}", source: "Sleep");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared sleep history", source: "Sleep");
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

class SleepCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sleep = context.watch<SleepModel>();

    if (!sleep.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.bedtime, size: 24),
              SizedBox(width: 12),
              Text("Sleep Tracker: Loading..."),
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
                  Icon(Icons.bedtime, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Sleep Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (sleep.lastNightEntry != null)
                    Text(
                      sleep.lastNightEntry!.formatHours(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (sleep.lastNightEntry != null) ...[
                Row(
                  children: [
                    Text(
                      "Last night: ${sleep.lastNightEntry!.quality.emoji}",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(width: 8),
                    Text(
                      sleep.lastNightEntry!.quality.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: sleep.lastNightEntry!.quality.getColor(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ] else ...[
                Text(
                  "No sleep logged for last night",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
              ],
              if (sleep.hasHistory) ...[
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Avg: ${sleep.averageHours.toStringAsFixed(1)}h",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Quality: ${sleep.averageQuality.toStringAsFixed(1)}/5",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "${sleep.nightsGoalMet} nights ≥7h",
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
                    onPressed: () => _showSleepLogger(context),
                  ),
                  if (sleep.hasHistory)
                    TextButton.icon(
                      icon: Icon(Icons.history, size: 18),
                      label: Text("History"),
                      onPressed: () => _showHistoryDialog(context, sleep),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, SleepModel sleep) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Sleep History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: sleep.history.length,
            itemBuilder: (context, index) {
              final entry = sleep.history[sleep.history.length - 1 - index];
              return ListTile(
                leading: Text(entry.quality.emoji, style: TextStyle(fontSize: 24)),
                title: Text(entry.formatHours()),
                subtitle: Text(
                  "${entry.date.month}/${entry.date.day} - ${entry.quality.label}",
                  style: TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, size: 20),
                  onPressed: () {
                    sleep.deleteEntry(sleep.history.length - 1 - index);
                    Navigator.pop(context);
                    _showHistoryDialog(context, sleep);
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
          if (sleep.hasHistory)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showClearConfirmation(context, sleep);
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

  void _showClearConfirmation(BuildContext context, SleepModel sleep) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Are you sure you want to clear all sleep history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              sleep.clearHistory();
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

class SleepLogDialog extends StatefulWidget {
  @override
  State<SleepLogDialog> createState() => _SleepLogDialogState();
}

class _SleepLogDialogState extends State<SleepLogDialog> {
  double _hours = 7.0;
  SleepQuality _quality = SleepQuality.good;
  String? _note;
  DateTime? _customDate;
  bool _useCustomDate = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Log Sleep"),
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
                        initialDate: _customDate ?? DateTime.now().subtract(Duration(days: 1)),
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
            Text("Hours of sleep:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Slider(
              value: _hours,
              min: 0,
              max: 12,
              divisions: 24,
              label: "${_hours.toStringAsFixed(1)}h",
              onChanged: (v) => setState(() => _hours = v),
            ),
            SizedBox(height: 12),
            Text("Sleep quality:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: SleepQuality.values.map((q) {
                final isSelected = q == _quality;
                return GestureDetector(
                  onTap: () => setState(() => _quality = q),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? q.getColor(context).withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? q.getColor(context) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(q.emoji, style: TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
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
            sleepModel.logSleep(
              _hours,
              _quality,
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