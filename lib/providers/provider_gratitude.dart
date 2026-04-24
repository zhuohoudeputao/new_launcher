import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

GratitudeModel gratitudeModel = GratitudeModel();

MyProvider providerGratitude = MyProvider(
    name: "Gratitude",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Add gratitude',
      keywords: 'gratitude grateful thanks thankful appreciation journal daily positive',
      action: () {
        Global.infoModel.addInfo("AddGratitude", "Add Gratitude",
            subtitle: "Tap to record what you're grateful for",
            icon: Icon(Icons.favorite),
            onTap: () => _showGratitudeInputDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await gratitudeModel.init();
  Global.infoModel.addInfoWidget(
      "Gratitude",
      ChangeNotifierProvider.value(
          value: gratitudeModel,
          builder: (context, child) => GratitudeCard()),
      title: "Gratitude Journal");
}

Future<void> _update() async {
  await gratitudeModel.refresh();
}

void _showGratitudeInputDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => GratitudeInputDialog(),
  );
}

class GratitudeEntry {
  final DateTime date;
  final String text;

  GratitudeEntry({
    required this.date,
    required this.text,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'text': text,
    });
  }

  static GratitudeEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return GratitudeEntry(
      date: DateTime.parse(map['date'] as String),
      text: map['text'] as String,
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}

class GratitudeDay {
  final DateTime date;
  final List<GratitudeEntry> entries;

  GratitudeDay({
    required this.date,
    required this.entries,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  static GratitudeDay fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return GratitudeDay(
      date: DateTime.parse(map['date'] as String),
      entries: (map['entries'] as List).map((e) => GratitudeEntry.fromJson(e as String)).toList(),
    );
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

class GratitudeModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  static const int maxEntriesPerDay = 5;
  static const String _storageKey = 'gratitude_days';

  List<GratitudeDay> _history = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<GratitudeDay> get history => _history;
  
  GratitudeDay? get todayDay {
    final todayKey = GratitudeEntry.getDayKey(DateTime.now());
    return _history.firstWhereOrNull((d) => GratitudeEntry.getDayKey(d.date) == todayKey);
  }
  
  List<GratitudeEntry> get todayEntries => todayDay?.entries ?? [];
  int get todayCount => todayEntries.length;

  int get streak {
    int streak = 0;
    final sortedHistory = List<GratitudeDay>.from(_history)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final today = DateTime.now();
    final todayKey = GratitudeEntry.getDayKey(today);
    
    bool hasToday = sortedHistory.any((d) => GratitudeEntry.getDayKey(d.date) == todayKey);
    
    if (hasToday) {
      streak = 1;
      for (int i = 1; i < sortedHistory.length; i++) {
        final prevDate = sortedHistory[i].date;
        final prevKey = GratitudeEntry.getDayKey(prevDate);
        final expectedPrevKey = GratitudeEntry.getDayKey(today.subtract(Duration(days: i)));
        
        if (prevKey == expectedPrevKey) {
          streak++;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }

  int get totalEntries {
    return _history.fold<int>(0, (sum, day) => sum + day.entries.length);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dayStrings = prefs.getStringList(_storageKey) ?? [];
    _history = dayStrings.map((s) => GratitudeDay.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Gratitude initialized with ${_history.length} days", source: "Gratitude");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final dayStrings = _history.map((d) => d.toJson()).toList();
    await prefs.setStringList(_storageKey, dayStrings);
  }

  void addEntry(String text) {
    if (text.trim().isEmpty) return;
    
    final now = DateTime.now();
    final todayKey = GratitudeEntry.getDayKey(now);
    final existingDayIndex = _history.indexWhere((d) => GratitudeEntry.getDayKey(d.date) == todayKey);
    
    final newEntry = GratitudeEntry(date: now, text: text.trim());
    
    if (existingDayIndex >= 0) {
      final existingDay = _history[existingDayIndex];
      if (existingDay.entries.length >= maxEntriesPerDay) {
        Global.loggerModel.warning("Max entries per day reached", source: "Gratitude");
        return;
      }
      _history[existingDayIndex] = GratitudeDay(
        date: existingDay.date,
        entries: [...existingDay.entries, newEntry],
      );
      Global.loggerModel.info("Added gratitude entry for today", source: "Gratitude");
    } else {
      _history.add(GratitudeDay(date: now, entries: [newEntry]));
      Global.loggerModel.info("Created new gratitude day", source: "Gratitude");
    }
    
    while (_history.length > maxHistoryDays) {
      _history.removeAt(0);
    }
    
    _save();
    notifyListeners();
  }

  void removeEntry(GratitudeEntry entry) {
    final entryKey = GratitudeEntry.getDayKey(entry.date);
    final dayIndex = _history.indexWhere((d) => GratitudeEntry.getDayKey(d.date) == entryKey);
    
    if (dayIndex >= 0) {
      final day = _history[dayIndex];
      final updatedEntries = day.entries.where((e) => e != entry).toList();
      
      if (updatedEntries.isEmpty) {
        _history.removeAt(dayIndex);
        Global.loggerModel.info("Removed empty gratitude day", source: "Gratitude");
      } else {
        _history[dayIndex] = GratitudeDay(date: day.date, entries: updatedEntries);
        Global.loggerModel.info("Removed gratitude entry", source: "Gratitude");
      }
      
      _save();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared gratitude history", source: "Gratitude");
    notifyListeners();
  }
}

class GratitudeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gratitude = context.watch<GratitudeModel>();

    if (!gratitude.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.favorite, size: 24),
              SizedBox(width: 12),
              Text("Gratitude Journal: Loading..."),
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
                  Icon(Icons.favorite, size: 20, color: Colors.pink),
                  SizedBox(width: 8),
                  Text(
                    "Gratitude Journal",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: gratitude.streak > 0 ? Colors.orange : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "${gratitude.streak}",
                    style: TextStyle(
                      fontSize: 12,
                      color: gratitude.streak > 0 ? Colors.orange : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (gratitude.todayEntries.isNotEmpty) ...[
                ...gratitude.todayEntries.map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite_border, size: 16, color: Colors.pink.shade300),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.text,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
                SizedBox(height: 8),
              ] else ...[
                Text(
                  "No gratitude logged today",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
              ],
              if (gratitude.todayCount < GratitudeModel.maxEntriesPerDay)
                Text(
                  "${gratitude.todayCount}/${GratitudeModel.maxEntriesPerDay} entries today",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (gratitude.todayCount < GratitudeModel.maxEntriesPerDay)
                    TextButton.icon(
                      icon: Icon(Icons.add, size: 18),
                      label: Text("Add"),
                      onPressed: () => _showGratitudeInputDialog(context),
                    ),
                  if (gratitude.history.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(Icons.history, size: 18),
                      label: Text("History"),
                      onPressed: () => _showHistoryDialog(context, gratitude),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, GratitudeModel gratitude) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Gratitude History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: gratitude.history.length,
            itemBuilder: (context, index) {
              final day = gratitude.history[gratitude.history.length - 1 - index];
              return ExpansionTile(
                title: Text("${day.date.month}/${day.date.day}"),
                subtitle: Text("${day.entries.length} entries"),
                children: day.entries.map((entry) => ListTile(
                  leading: Icon(Icons.favorite_border, size: 16, color: Colors.pink.shade300),
                  title: Text(entry.text),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, size: 18),
                    onPressed: () {
                      gratitude.removeEntry(entry);
                      if (gratitude.history.isEmpty) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                )).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
          if (gratitude.history.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showClearConfirmation(context, gratitude);
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

  void _showClearConfirmation(BuildContext context, GratitudeModel gratitude) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Are you sure you want to clear all gratitude history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              gratitude.clearHistory();
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

class GratitudeInputDialog extends StatefulWidget {
  @override
  State<GratitudeInputDialog> createState() => _GratitudeInputDialogState();
}

class _GratitudeInputDialogState extends State<GratitudeInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Gratitude"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "What are you grateful for today?",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "e.g., My family, Good health, A sunny day...",
              border: OutlineInputBorder(),
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
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              gratitudeModel.addEntry(text);
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}