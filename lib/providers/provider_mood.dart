import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

MoodModel moodModel = MoodModel();

MyProvider providerMood = MyProvider(
    name: "Mood",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Log mood',
      keywords: 'mood emotion feeling happy sad track daily mental health',
      action: () {
        Global.infoModel.addInfo("LogMood", "Log Mood",
            subtitle: "Tap to log how you're feeling",
            icon: Icon(Icons.mood),
            onTap: () => _showMoodPicker(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await moodModel.init();
  Global.infoModel.addInfoWidget(
      "Mood",
      ChangeNotifierProvider.value(
          value: moodModel,
          builder: (context, child) => MoodCard()),
      title: "Mood Tracker");
}

Future<void> _update() async {
  await moodModel.refresh();
}

void _showMoodPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => MoodPickerSheet(),
  );
}

enum MoodLevel {
  verySad,
  sad,
  neutral,
  happy,
  veryHappy,
}

extension MoodLevelExtension on MoodLevel {
  String get emoji {
    switch (this) {
      case MoodLevel.verySad:
        return '😢';
      case MoodLevel.sad:
        return '😔';
      case MoodLevel.neutral:
        return '😐';
      case MoodLevel.happy:
        return '😊';
      case MoodLevel.veryHappy:
        return '😄';
    }
  }

  String get label {
    switch (this) {
      case MoodLevel.verySad:
        return 'Very Sad';
      case MoodLevel.sad:
        return 'Sad';
      case MoodLevel.neutral:
        return 'Neutral';
      case MoodLevel.happy:
        return 'Happy';
      case MoodLevel.veryHappy:
        return 'Very Happy';
    }
  }

  int get value {
    switch (this) {
      case MoodLevel.verySad:
        return 1;
      case MoodLevel.sad:
        return 2;
      case MoodLevel.neutral:
        return 3;
      case MoodLevel.happy:
        return 4;
      case MoodLevel.veryHappy:
        return 5;
    }
  }

  static MoodLevel fromValue(int value) {
    switch (value) {
      case 1:
        return MoodLevel.verySad;
      case 2:
        return MoodLevel.sad;
      case 3:
        return MoodLevel.neutral;
      case 4:
        return MoodLevel.happy;
      case 5:
        return MoodLevel.veryHappy;
      default:
        return MoodLevel.neutral;
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case MoodLevel.verySad:
        return Colors.red.shade400;
      case MoodLevel.sad:
        return Colors.orange.shade400;
      case MoodLevel.neutral:
        return Colors.grey.shade500;
      case MoodLevel.happy:
        return Colors.lightGreen.shade500;
      case MoodLevel.veryHappy:
        return Colors.green.shade500;
    }
  }
}

class MoodEntry {
  final DateTime date;
  final int moodValue;
  final String? note;

  MoodEntry({
    required this.date,
    required this.moodValue,
    this.note,
  });

  MoodLevel get mood => MoodLevelExtension.fromValue(moodValue);

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'moodValue': moodValue,
      'note': note,
    });
  }

  static MoodEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return MoodEntry(
      date: DateTime.parse(map['date'] as String),
      moodValue: map['moodValue'] as int,
      note: map['note'] as String?,
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}

class MoodModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  static const String _storageKey = 'mood_entries';

  List<MoodEntry> _history = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<MoodEntry> get history => _history;
  MoodEntry? get todayEntry {
    final todayKey = MoodEntry.getDayKey(DateTime.now());
    return _history.firstWhereOrNull((e) => MoodEntry.getDayKey(e.date) == todayKey);
  }
  MoodLevel? get todayMood => todayEntry?.mood;

  int get positiveStreak {
    int streak = 0;
    final sortedHistory = List<MoodEntry>.from(_history)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    for (final entry in sortedHistory) {
      if (entry.moodValue >= MoodLevel.neutral.value) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  MoodLevel get mostCommonMood {
    if (_history.isEmpty) return MoodLevel.neutral;
    
    final counts = <int, int>{};
    for (final entry in _history) {
      counts[entry.moodValue] = (counts[entry.moodValue] ?? 0) + 1;
    }
    
    int maxValue = 3;
    int maxCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxValue = entry.key;
      }
    }
    return MoodLevelExtension.fromValue(maxValue);
  }

  double get averageMood {
    if (_history.isEmpty) return 3.0;
    final sum = _history.fold<int>(0, (sum, e) => sum + e.moodValue);
    return sum / _history.length;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => MoodEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Mood initialized with ${_history.length} entries", source: "Mood");
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

  void logMood(MoodLevel mood, {String? note}) {
    final now = DateTime.now();
    final todayKey = MoodEntry.getDayKey(now);
    final existingIndex = _history.indexWhere((e) => MoodEntry.getDayKey(e.date) == todayKey);
    
    final newEntry = MoodEntry(
      date: now,
      moodValue: mood.value,
      note: note,
    );
    
    if (existingIndex >= 0) {
      _history[existingIndex] = newEntry;
      Global.loggerModel.info("Updated mood for today: ${mood.label}", source: "Mood");
    } else {
      _history.add(newEntry);
      Global.loggerModel.info("Logged mood: ${mood.label}", source: "Mood");
    }
    
    while (_history.length > maxHistoryDays) {
      _history.removeAt(0);
    }
    
    _save();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared mood history", source: "Mood");
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

class MoodCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodModel>();

    if (!mood.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.mood, size: 24),
              SizedBox(width: 12),
              Text("Mood Tracker: Loading..."),
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
                  Icon(Icons.mood, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Mood Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (mood.todayMood != null)
                    Text(
                      mood.todayMood!.emoji,
                      style: TextStyle(fontSize: 24),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (mood.todayMood != null) ...[
                Text(
                  "Today: ${mood.todayMood!.emoji} ${mood.todayMood!.label}",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
              ] else ...[
                Text(
                  "No mood logged today",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: mood.positiveStreak > 0
                        ? Colors.orange
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "${mood.positiveStreak} day streak",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    "Avg: ${mood.averageMood.toStringAsFixed(1)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.edit, size: 18),
                    label: Text(mood.todayMood != null ? "Update" : "Log"),
                    onPressed: () => _showMoodPicker(context),
                  ),
                  if (mood.history.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(Icons.history, size: 18),
                      label: Text("History"),
                      onPressed: () => _showHistoryDialog(context, mood),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, MoodModel mood) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mood History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: mood.history.length,
            itemBuilder: (context, index) {
              final entry = mood.history[mood.history.length - 1 - index];
              return ListTile(
                leading: Text(entry.mood.emoji, style: TextStyle(fontSize: 24)),
                title: Text(entry.mood.label),
                subtitle: Text(
                  "${entry.date.month}/${entry.date.day}",
                  style: TextStyle(fontSize: 12),
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
          if (mood.history.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showClearConfirmation(context, mood);
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

  void _showClearConfirmation(BuildContext context, MoodModel mood) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Are you sure you want to clear all mood history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              mood.clearHistory();
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

class MoodPickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "How are you feeling?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: MoodLevel.values.map((mood) {
              return GestureDetector(
                onTap: () {
                  moodModel.logMood(mood);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mood.getColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        mood.emoji,
                        style: TextStyle(fontSize: 36),
                      ),
                      SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}