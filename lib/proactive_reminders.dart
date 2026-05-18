import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/memory_system.dart';
import 'package:new_launcher/types/memory_types.dart';

class ProactiveReminders extends ChangeNotifier {
  static const int checkIntervalSeconds = 60;
  
  Timer? _checkTimer;
  final MemorySystem _memory;
  
  List<String> _activeReminders = [];
  
  List<String> get activeReminders => List.unmodifiable(_activeReminders);
  
  ProactiveReminders({required MemorySystem memory}) : _memory = memory;
  
  void start() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      Duration(seconds: checkIntervalSeconds),
      (_) => _checkReminders(),
    );
  }
  
  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
  
  void _checkReminders() {
    final now = DateTime.now();
    _activeReminders.clear();
    
    _checkHabits(now);
    _checkTasks(now);
    _checkDates(now);
    
    if (_activeReminders.isNotEmpty) {
      notifyListeners();
    }
  }
  
  void _checkHabits(DateTime now) {
    final habits = _memory.getHabitsByTime(now.hour);
    for (final habit in habits) {
      final metadata = HabitMetadata.fromJson(habit.metadata);
      if (metadata.frequency >= 3) {
        _activeReminders.add('You usually ${habit.content} at this time');
      }
    }
  }
  
  void _checkTasks(DateTime now) {
    final pendingTasks = _memory.getPendingTasks();
    for (final task in pendingTasks) {
      final metadata = TaskMetadata.fromJson(task.metadata);
      if (metadata.deadline != null) {
        final diff = metadata.deadline!.difference(now);
        if (diff.inHours <= 24 && diff.inHours > 0) {
          _activeReminders.add('Task "${task.content}" due in ${_formatDuration(diff)}');
        }
      }
    }
  }
  
  void _checkDates(DateTime now) {
    final upcomingDates = _memory.getDueDates(within: Duration(days: 7));
    for (final date in upcomingDates) {
      final metadata = DateMetadata.fromJson(date.metadata);
      DateTime nextOccurrence = DateTime(now.year, date.timestamp.month, date.timestamp.day);
      if (nextOccurrence.isBefore(now) && metadata.recurring) {
        nextOccurrence = DateTime(now.year + 1, date.timestamp.month, date.timestamp.day);
      }
      
      final diff = nextOccurrence.difference(now);
      if (diff.inDays <= 7 && diff.inDays >= 0) {
        if (diff.inDays == 0) {
          _activeReminders.add('${date.content} is today!');
        } else if (diff.inDays == 1) {
          _activeReminders.add('${date.content} is tomorrow');
        } else {
          _activeReminders.add('${date.content} in ${diff.inDays} days');
        }
      }
    }
  }
  
  String _formatDuration(Duration diff) {
    if (diff.inHours < 1) {
      return '${diff.inMinutes} minutes';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours';
    } else {
      return '${diff.inDays} days';
    }
  }
  
  void dismissReminder(String reminder) {
    _activeReminders.remove(reminder);
    notifyListeners();
  }
  
  void clearAll() {
    _activeReminders.clear();
    notifyListeners();
  }
}

ProactiveReminders? proactiveReminders;

void initProactiveReminders(MemorySystem memory) {
  proactiveReminders = ProactiveReminders(memory: memory);
  proactiveReminders!.start();
}