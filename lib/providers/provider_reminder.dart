import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReminderModel reminderModel = ReminderModel();

MyProvider providerReminder = MyProvider(
    name: "Reminder",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Reminder',
      keywords: 'reminder alarm notify alert schedule time remind',
      action: () => reminderModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await reminderModel.init();
  Global.infoModel.addInfoWidget(
      "Reminder",
      ChangeNotifierProvider.value(
          value: reminderModel,
          builder: (context, child) => ReminderCard()),
      title: "Reminders");
}

Future<void> _update() async {
  reminderModel.refresh();
}

class ReminderEntry {
  final String id;
  final DateTime targetTime;
  final String message;
  bool notified;
  bool dismissed;

  ReminderEntry({
    required this.id,
    required this.targetTime,
    required this.message,
    this.notified = false,
    this.dismissed = false,
  });

  Duration get remaining => targetTime.difference(DateTime.now());
  
  bool get isExpired => remaining.isNegative || remaining.inSeconds == 0;
  
  bool get isActive => !dismissed && !isExpired;

  String get displayTime {
    final remaining = this.remaining;
    if (remaining.isNegative) return "Expired";
    
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    
    if (days > 0) {
      return "${days}d ${hours}h ${minutes}m";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else if (minutes > 0) {
      return "${minutes}m";
    } else {
      return "${remaining.inSeconds}s";
    }
  }

  String get targetTimeString {
    final hour = targetTime.hour.toString().padLeft(2, '0');
    final minute = targetTime.minute.toString().padLeft(2, '0');
    return "${hour}:${minute}";
  }

  String get targetDateString {
    final month = targetTime.month;
    final day = targetTime.day;
    return "$month/$day";
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetTime': targetTime.toIso8601String(),
    'message': message,
    'notified': notified,
    'dismissed': dismissed,
  };

  factory ReminderEntry.fromJson(Map<String, dynamic> json) => ReminderEntry(
    id: json['id'] ?? '',
    targetTime: DateTime.parse(json['targetTime']),
    message: json['message'] ?? '',
    notified: json['notified'] ?? false,
    dismissed: json['dismissed'] ?? false,
  );
}

class ReminderModel extends ChangeNotifier {
  final List<ReminderEntry> _reminders = [];
  static const int maxReminders = 10;
  Timer? _updateTimer;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  List<ReminderEntry> get reminders => List.unmodifiable(_reminders.where((r) => r.isActive).toList());
  List<ReminderEntry> get allReminders => List.unmodifiable(_reminders);
  int get length => reminders.length;
  int get totalLength => _reminders.length;
  bool get isInitialized => _isInitialized;
  bool get hasReminders => _reminders.any((r) => r.isActive);
  List<ReminderEntry> get expiredReminders => _reminders.where((r) => r.isExpired && !r.dismissed).toList();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadReminders();
    _startUpdateTimer();
    _isInitialized = true;
    Global.loggerModel.info("Reminder initialized", source: "Reminder");
    notifyListeners();
  }

  Future<void> _loadReminders() async {
    final saved = _prefs?.getStringList('reminders') ?? [];
    _reminders.clear();
    for (final jsonStr in saved) {
      try {
        final entry = ReminderEntry.fromJson(_decodeJson(jsonStr));
        _reminders.add(entry);
      } catch (e) {
        Global.loggerModel.warning("Failed to load reminder: $e", source: "Reminder");
      }
    }
    notifyListeners();
  }

  Map<String, dynamic> _decodeJson(String jsonStr) {
    return json.decode(jsonStr) as Map<String, dynamic>;
  }

  Future<void> _saveReminders() async {
    final jsonList = _reminders.map((r) => json.encode(r.toJson())).toList();
    await _prefs?.setStringList('reminders', jsonList);
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _checkExpiredReminders();
      notifyListeners();
    });
  }

  void _checkExpiredReminders() {
    for (final reminder in _reminders.where((r) => r.isExpired && !r.notified)) {
      reminder.notified = true;
      _showNotification(reminder);
    }
  }

  void _showNotification(ReminderEntry reminder) {
    final context = navigatorKey.currentContext;
    if (context != null && !reminder.dismissed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder: ${reminder.message}'),
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              dismissReminder(reminder.id);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
    Global.loggerModel.info("Reminder triggered: ${reminder.message}", source: "Reminder");
  }

  Future<void> addReminder(DateTime targetTime, String message) async {
    if (_reminders.length >= maxReminders) {
      final oldest = _reminders.last;
      _reminders.remove(oldest);
      Global.loggerModel.warning("Reminder limit reached, removed oldest", source: "Reminder");
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final entry = ReminderEntry(
      id: id,
      targetTime: targetTime,
      message: message,
    );

    _reminders.insert(0, entry);
    _reminders.sort((a, b) => a.targetTime.compareTo(b.targetTime));
    await _saveReminders();
    notifyListeners();
    Global.loggerModel.info("Reminder added: $message at ${entry.targetTimeString}", source: "Reminder");
  }

  Future<void> dismissReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _reminders[index].dismissed = true;
    await _saveReminders();
    notifyListeners();
    Global.loggerModel.info("Reminder dismissed", source: "Reminder");
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _saveReminders();
    notifyListeners();
    Global.loggerModel.info("Reminder deleted", source: "Reminder");
  }

  Future<void> clearAll() async {
    _reminders.clear();
    await _saveReminders();
    notifyListeners();
    Global.loggerModel.info("All reminders cleared", source: "Reminder");
  }

  Future<void> clearDismissed() async {
    _reminders.removeWhere((r) => r.dismissed);
    await _saveReminders();
    notifyListeners();
    Global.loggerModel.info("Dismissed reminders cleared", source: "Reminder");
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Reminder refreshed", source: "Reminder");
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

class ReminderCard extends StatefulWidget {
  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  @override
  Widget build(BuildContext context) {
    final reminder = context.watch<ReminderModel>();
    
    if (!reminder.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.notifications, size: 24),
              SizedBox(width: 12),
              Text("Reminders: Loading..."),
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
                Row(
                  children: [
                    Icon(Icons.notifications, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Reminders",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (reminder.hasReminders)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${reminder.length}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => _showAddReminderDialog(context),
                      tooltip: "Add reminder",
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (reminder.hasReminders)
                      IconButton(
                        icon: Icon(Icons.clear_all, size: 18),
                        onPressed: () => _showClearConfirmation(context),
                        tooltip: "Clear all",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (reminder.reminders.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    "No active reminders",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            if (reminder.reminders.isNotEmpty) ...[
              SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: reminder.reminders.length,
                itemBuilder: (context, index) {
                  final entry = reminder.reminders[index];
                  return _buildReminderItem(context, reminder, entry);
                },
              ),
            ],
            if (reminder.expiredReminders.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                "Expired:",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: reminder.expiredReminders.length,
                itemBuilder: (context, index) {
                  final entry = reminder.expiredReminders[index];
                  return _buildExpiredItem(context, reminder, entry);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(BuildContext context, ReminderModel model, ReminderEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = entry.remaining;
    final isUrgent = remaining.inMinutes < 5 && remaining.isNegative == false;
    
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isUrgent 
            ? colorScheme.errorContainer.withValues(alpha: 0.5)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.alarm,
            size: 20,
            color: isUrgent 
              ? colorScheme.error
              : colorScheme.primary,
          ),
        ),
      ),
      title: Text(
        entry.message,
        style: TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            entry.displayTime,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isUrgent 
                ? colorScheme.error
                : colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.schedule, size: 12, color: colorScheme.onSurfaceVariant),
          SizedBox(width: 4),
          Text(
            "${entry.targetDateString} ${entry.targetTimeString}",
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, size: 18),
        onPressed: () => model.deleteReminder(entry.id),
        tooltip: "Delete",
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildExpiredItem(BuildContext context, ReminderModel model, ReminderEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.notifications_active,
            size: 20,
            color: colorScheme.error,
          ),
        ),
      ),
      title: Text(
        entry.message,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.error,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        "Expired",
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.error,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.check, size: 18),
        onPressed: () => model.dismissReminder(entry.id),
        tooltip: "Dismiss",
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Reminders"),
        content: Text("This will delete all reminders."),
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
      context.read<ReminderModel>().clearAll();
    }
  }

  void _showAddReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(),
    );
  }
}

class AddReminderDialog extends StatefulWidget {
  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final TextEditingController _messageController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Reminder"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: "Reminder message",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: Icon(Icons.calendar_today, size: 18),
                  label: Text("${_selectedDate.month}/${_selectedDate.day}"),
                  onPressed: () => _selectDate(context),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  icon: Icon(Icons.access_time, size: 18),
                  label: Text(_selectedTime.format(context)),
                  onPressed: () => _selectTime(context),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => _addReminder(context),
          child: Text("Add"),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addReminder(BuildContext context) {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    final targetTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    context.read<ReminderModel>().addReminder(targetTime, message);
    Navigator.pop(context);
  }
}