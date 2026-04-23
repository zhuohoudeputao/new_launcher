import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

CountdownModel countdownModel = CountdownModel();

MyProvider providerCountdown = MyProvider(
  name: "Countdown",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Add Countdown',
      keywords: 'countdown deadline birthday event date add',
      action: () {
        Global.infoModel.addInfo("AddCountdown", "Add Countdown",
            subtitle: "Tap to add a countdown to an important date",
            icon: Icon(Icons.event_available),
            onTap: () => _showAddCountdownDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await countdownModel.init();
  Global.infoModel.addInfoWidget(
    "Countdown",
    ChangeNotifierProvider.value(
      value: countdownModel,
      builder: (context, child) => CountdownCard(),
    ),
    title: "Countdowns",
  );
}

Future<void> _update() async {
  await countdownModel.refresh();
}

void _showAddCountdownDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddCountdownDialog(),
  );
}

void _showEditCountdownDialog(BuildContext context, int index, CountdownEntry entry) {
  showDialog(
    context: context,
    builder: (context) => EditCountdownDialog(index: index, entry: entry),
  );
}

class CountdownEntry {
  final String name;
  final DateTime targetDate;
  final DateTime createdAt;

  CountdownEntry({
    required this.name,
    required this.targetDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'targetDate': targetDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory CountdownEntry.fromJson(Map<String, dynamic> json) => CountdownEntry(
    name: json['name'] as String,
    targetDate: DateTime.parse(json['targetDate'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class CountdownModel extends ChangeNotifier {
  List<CountdownEntry> _countdowns = [];
  static const int maxCountdowns = 10;
  static const String _countdownsKey = 'Countdown.List';
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  Timer? _timer;
  bool _disposed = false;

  List<CountdownEntry> get countdowns => List.unmodifiable(_countdowns);
  int get length => _countdowns.length;
  bool get isInitialized => _isInitialized;
  bool get hasCountdowns => _countdowns.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCountdowns();
    _startTimer();
    _isInitialized = true;
    Global.loggerModel.info("Countdown initialized with ${_countdowns.length} countdowns", source: "Countdown");
    notifyListeners();
  }

  Future<void> _loadCountdowns() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final countdownsJson = prefs.getStringList(_countdownsKey);
    if (countdownsJson != null) {
      try {
        _countdowns = countdownsJson
            .map((json) => CountdownEntry.fromJson(
                Map<String, dynamic>.from(
                    json.split('|').asMap().entries.map((e) {
                      final parts = json.split('|');
                      return {'name': parts[0], 'targetDate': parts[1], 'createdAt': parts[2]};
                    }).first,
                ),
            ))
            .toList();
      } catch (e) {
        _countdowns = countdownsJson.map((jsonStr) {
          final parts = jsonStr.split('|');
          return CountdownEntry(
            name: parts[0],
            targetDate: DateTime.parse(parts[1]),
            createdAt: DateTime.parse(parts[2]),
          );
        }).toList();
      }
    }
  }

  Future<void> _saveCountdowns() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final countdownsJson = _countdowns.map((c) =>
        '${c.name}|${c.targetDate.toIso8601String()}|${c.createdAt.toIso8601String()}'
      ).toList();
      await prefs.setStringList(_countdownsKey, countdownsJson);
      Global.loggerModel.info("Saved ${_countdowns.length} countdowns", source: "Countdown");
    } catch (e) {
      Global.loggerModel.error("Failed to save countdowns: $e", source: "Countdown");
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final now = DateTime.now();
    final initialDelay = 60 - now.second;

    Timer(Duration(seconds: initialDelay), () {
      if (_disposed) return;
      notifyListeners();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (_disposed) return;
        notifyListeners();
      });
    });
  }

  Future<void> refresh() async {
    await _loadCountdowns();
    notifyListeners();
    Global.loggerModel.info("Countdown refreshed", source: "Countdown");
  }

  void addCountdown(String name, DateTime targetDate) {
    if (name.trim().isEmpty) return;

    final entry = CountdownEntry(
      name: name.trim(),
      targetDate: targetDate,
      createdAt: DateTime.now(),
    );

    _countdowns.insert(0, entry);

    if (_countdowns.length > maxCountdowns) {
      _countdowns.removeLast();
    }

    notifyListeners();
    _saveCountdowns();
    Global.loggerModel.info("Added countdown: $name", source: "Countdown");
  }

  void updateCountdown(int index, String name, DateTime targetDate) {
    if (index < 0 || index >= _countdowns.length) return;
    if (name.trim().isEmpty) {
      deleteCountdown(index);
      return;
    }

    _countdowns[index] = CountdownEntry(
      name: name.trim(),
      targetDate: targetDate,
      createdAt: _countdowns[index].createdAt,
    );
    notifyListeners();
    _saveCountdowns();
    Global.loggerModel.info("Updated countdown at index $index", source: "Countdown");
  }

  void deleteCountdown(int index) {
    if (index < 0 || index >= _countdowns.length) return;

    final removedName = _countdowns[index].name;
    _countdowns.removeAt(index);
    notifyListeners();
    _saveCountdowns();
    Global.loggerModel.info("Deleted countdown: $removedName", source: "Countdown");
  }

  void clearAllCountdowns() {
    _countdowns.clear();
    notifyListeners();
    _saveCountdowns();
    Global.loggerModel.info("Cleared all countdowns", source: "Countdown");
  }

  Duration getRemainingTime(CountdownEntry entry) {
    final now = DateTime.now();
    final remaining = entry.targetDate.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isExpired(CountdownEntry entry) {
    return entry.targetDate.isBefore(DateTime.now());
  }

  String formatRemainingTime(CountdownEntry entry) {
    final remaining = getRemainingTime(entry);
    
    if (remaining == Duration.zero) {
      return "Expired";
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    if (days > 0) {
      return "${days}d ${hours}h";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }

  String formatDetailedRemainingTime(CountdownEntry entry) {
    final remaining = getRemainingTime(entry);
    
    if (remaining == Duration.zero) {
      return "Event has passed";
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (days > 365) {
      final years = days ~/ 365;
      final remainingDays = days % 365;
      return "${years}y ${remainingDays}d";
    } else if (days > 0) {
      return "${days} days, ${hours}h ${minutes}m";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else {
      return "${minutes}m ${seconds}s";
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class CountdownCard extends StatefulWidget {
  @override
  State<CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<CountdownCard> {
  @override
  Widget build(BuildContext context) {
    final countdowns = context.watch<CountdownModel>();

    if (!countdowns.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.timer, size: 24),
              SizedBox(width: 12),
              Text("Countdowns: Loading..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Countdowns",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (countdowns.hasCountdowns)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearConfirmation(context),
                        tooltip: "Clear all countdowns",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => _showAddCountdownDialog(context),
                      tooltip: "Add countdown",
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (!countdowns.hasCountdowns)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No countdowns. Tap + to add one.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: countdowns.length,
                itemBuilder: (context, index) {
                  final entry = countdowns.countdowns[index];
                  return _buildCountdownItem(context, index, entry, countdowns);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownItem(BuildContext context, int index, CountdownEntry entry, CountdownModel model) {
    final remaining = model.formatRemainingTime(entry);
    final detailed = model.formatDetailedRemainingTime(entry);
    final isExpired = model.isExpired(entry);
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon = Icons.event;
    Color iconColor = colorScheme.primary;
    
    if (isExpired) {
      icon = Icons.event_available;
      iconColor = colorScheme.onSurfaceVariant;
    } else if (entry.targetDate.difference(DateTime.now()).inDays < 7) {
      icon = Icons.event_busy;
      iconColor = colorScheme.error;
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(
        entry.name,
        style: TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        isExpired ? "Expired on ${_formatDate(entry.targetDate)}" : detailed,
        style: TextStyle(fontSize: 11),
      ),
      trailing: Text(
        remaining,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isExpired ? colorScheme.onSurfaceVariant : colorScheme.primary,
        ),
      ),
      onTap: () => _showEditCountdownDialog(context, index, entry),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Countdowns"),
        content: Text("This will delete all countdowns. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Clear"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<CountdownModel>().clearAllCountdowns();
    }
  }
}

class AddCountdownDialog extends StatefulWidget {
  @override
  State<AddCountdownDialog> createState() => _AddCountdownDialogState();
}

class _AddCountdownDialogState extends State<AddCountdownDialog> {
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  bool _showTimePicker = false;
  TimeOfDay _selectedTime = TimeOfDay(hour: 0, minute: 0);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Countdown"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Event name (e.g., Birthday)",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Target Date"),
              subtitle: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text("Include Time"),
              subtitle: Text(_showTimePicker 
                ? "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}"
                : "Not set"),
              trailing: Switch(
                value: _showTimePicker,
                onChanged: (value) {
                  setState(() {
                    _showTimePicker = value;
                    if (value) {
                      _selectTime(context);
                    } else {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                      );
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              context.read<CountdownModel>().addCountdown(_nameController.text, _selectedDate);
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class EditCountdownDialog extends StatefulWidget {
  final int index;
  final CountdownEntry entry;

  const EditCountdownDialog({
    required this.index,
    required this.entry,
  });

  @override
  State<EditCountdownDialog> createState() => _EditCountdownDialogState();
}

class _EditCountdownDialogState extends State<EditCountdownDialog> {
  late TextEditingController _nameController;
  late DateTime _selectedDate;
  bool _showTimePicker = false;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry.name);
    _selectedDate = widget.entry.targetDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.entry.targetDate);
    _showTimePicker = widget.entry.targetDate.hour != 0 || widget.entry.targetDate.minute != 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Countdown"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Event name",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Target Date"),
              subtitle: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text("Include Time"),
              subtitle: Text(_showTimePicker 
                ? "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}"
                : "Not set"),
              trailing: Switch(
                value: _showTimePicker,
                onChanged: (value) {
                  setState(() {
                    _showTimePicker = value;
                    if (value) {
                      _selectTime(context);
                    } else {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                      );
                      _selectedTime = TimeOfDay(hour: 0, minute: 0);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            context.read<CountdownModel>().deleteCountdown(widget.index);
            Navigator.pop(context);
          },
          tooltip: "Delete",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
        FilledButton(
          onPressed: () {
            context.read<CountdownModel>().updateCountdown(widget.index, _nameController.text, _selectedDate);
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}