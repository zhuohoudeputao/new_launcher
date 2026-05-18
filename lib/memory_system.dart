/// Memory System for AI-powered launcher
/// Tracks user habits, tasks, important dates, conversations, and preferences

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_launcher/types/memory_types.dart';

/// Memory System - manages all memory categories
class MemorySystem extends ChangeNotifier {
  static const int maxConversations = 500;
  static const int maxTasks = 100;
  static const int maxHabits = 50;
  static const int maxDates = 30;
  static const int maxPreferences = 20;
  
  final SharedPreferences _prefs;
  
  // Memory storage
  final List<MemoryEntry> _conversations = [];
  final List<MemoryEntry> _tasks = [];
  final List<MemoryEntry> _habits = [];
  final List<MemoryEntry> _dates = [];
  final List<MemoryEntry> _preferences = [];
  
  // Keys for SharedPreferences
  static const String _conversationsKey = 'Memory.Conversations';
  static const String _tasksKey = 'Memory.Tasks';
  static const String _habitsKey = 'Memory.Habits';
  static const String _datesKey = 'Memory.Dates';
  static const String _preferencesKey = 'Memory.Preferences';
  
  MemorySystem({required SharedPreferences prefs}) : _prefs = prefs {
    _loadFromStorage();
  }
  
  // Getters
  List<MemoryEntry> get conversations => List.unmodifiable(_conversations);
  List<MemoryEntry> get tasks => List.unmodifiable(_tasks);
  List<MemoryEntry> get habits => List.unmodifiable(_habits);
  List<MemoryEntry> get dates => List.unmodifiable(_dates);
  List<MemoryEntry> get preferences => List.unmodifiable(_preferences);
  
  int get conversationCount => _conversations.length;
  int get taskCount => _tasks.length;
  int get habitCount => _habits.length;
  int get dateCount => _dates.length;
  int get preferenceCount => _preferences.length;
  
  // Load from SharedPreferences
  void _loadFromStorage() {
    _loadCategory(_conversationsKey, _conversations);
    _loadCategory(_tasksKey, _tasks);
    _loadCategory(_habitsKey, _habits);
    _loadCategory(_datesKey, _dates);
    _loadCategory(_preferencesKey, _preferences);
  }
  
  void _loadCategory(String key, List<MemoryEntry> list) {
    final stored = _prefs.getStringList(key) ?? [];
    for (final str in stored) {
      final entry = MemoryEntry.fromStorageString(str);
      if (entry != null) {
        list.add(entry);
      }
    }
  }
  
  // Save to SharedPreferences
  Future<void> _saveCategory(String key, List<MemoryEntry> list) async {
    final stored = list.map((e) => e.toStorageString()).toList();
    await _prefs.setStringList(key, stored);
  }
  
  // Add entries with limit enforcement
  Future<void> addConversation(String query, String response) async {
    final entry = MemoryEntry(
      category: MemoryCategory.CONVERSATION,
      content: '$query|$response',
      timestamp: DateTime.now(),
      metadata: {'query': query, 'response': response},
    );
    
    _conversations.add(entry);
    
    // Enforce limit
    while (_conversations.length > maxConversations) {
      _conversations.removeAt(0);
    }
    
    await _saveCategory(_conversationsKey, _conversations);
    notifyListeners();
  }
  
  Future<void> addTask(String task, DateTime? deadline, String priority) async {
    final entry = MemoryEntry(
      category: MemoryCategory.TASK,
      content: task,
      timestamp: DateTime.now(),
      metadata: TaskMetadata(
        deadline: deadline,
        priority: priority,
        status: 'pending',
      ).toJson(),
    );
    
    _tasks.add(entry);
    
    // Enforce limit
    while (_tasks.length > maxTasks) {
      _tasks.removeAt(0);
    }
    
    await _saveCategory(_tasksKey, _tasks);
    notifyListeners();
  }
  
  Future<void> addHabit(String habit, int hour, int dayOfWeek) async {
    final entry = MemoryEntry(
      category: MemoryCategory.HABIT,
      content: habit,
      timestamp: DateTime.now(),
      metadata: HabitMetadata(
        hour: hour,
        dayOfWeek: dayOfWeek,
        frequency: 1,
      ).toJson(),
    );
    
    // Check if habit already exists
    final existing = _habits.where((h) => h.content == habit).firstOrNull;
    if (existing != null) {
      // Update frequency
      final metadata = HabitMetadata.fromJson(existing.metadata);
      existing.metadata['frequency'] = metadata.frequency + 1;
    } else {
      _habits.add(entry);
      
      // Enforce limit
      while (_habits.length > maxHabits) {
        _habits.removeAt(0);
      }
    }
    
    await _saveCategory(_habitsKey, _habits);
    notifyListeners();
  }
  
  Future<void> addImportantDate(String name, DateTime date, String type, bool recurring) async {
    final entry = MemoryEntry(
      category: MemoryCategory.DATE,
      content: name,
      timestamp: DateTime.now(),
      metadata: DateMetadata(
        type: type,
        year: date.year,
        recurring: recurring,
      ).toJson(),
    );
    
    _dates.add(entry);
    
    // Enforce limit
    while (_dates.length > maxDates) {
      _dates.removeAt(0);
    }
    
    await _saveCategory(_datesKey, _dates);
    notifyListeners();
  }
  
  Future<void> addPreference(String key, String value) async {
    final entry = MemoryEntry(
      category: MemoryCategory.PREFERENCE,
      content: '$key=$value',
      timestamp: DateTime.now(),
      metadata: {'key': key, 'value': value},
    );
    
    // Check if preference already exists
    final existingIndex = _preferences.indexWhere((p) => p.content.startsWith('$key='));
    if (existingIndex >= 0) {
      // Replace with updated entry
      _preferences[existingIndex] = MemoryEntry(
        category: MemoryCategory.PREFERENCE,
        content: '$key=$value',
        timestamp: DateTime.now(),
        metadata: {'key': key, 'value': value},
      );
    } else {
      _preferences.add(entry);
      
      // Enforce limit
      while (_preferences.length > maxPreferences) {
        _preferences.removeAt(0);
      }
    }
    
    await _saveCategory(_preferencesKey, _preferences);
    notifyListeners();
  }
  
  // Update operations
  Future<void> updateTaskStatus(String task, String status) async {
    final entry = _tasks.where((t) => t.content == task).firstOrNull;
    if (entry != null) {
      entry.metadata['status'] = status;
      await _saveCategory(_tasksKey, _tasks);
      notifyListeners();
    }
  }
  
  // Delete operations
  Future<void> deleteEntry(MemoryCategory category, String content) async {
    switch (category) {
      case MemoryCategory.CONVERSATION:
        _conversations.removeWhere((e) => e.content == content);
        await _saveCategory(_conversationsKey, _conversations);
        break;
      case MemoryCategory.TASK:
        _tasks.removeWhere((e) => e.content == content);
        await _saveCategory(_tasksKey, _tasks);
        break;
      case MemoryCategory.HABIT:
        _habits.removeWhere((e) => e.content == content);
        await _saveCategory(_habitsKey, _habits);
        break;
      case MemoryCategory.DATE:
        _dates.removeWhere((e) => e.content == content);
        await _saveCategory(_datesKey, _dates);
        break;
      case MemoryCategory.PREFERENCE:
        _preferences.removeWhere((e) => e.content == content);
        await _saveCategory(_preferencesKey, _preferences);
        break;
    }
    notifyListeners();
  }
  
  Future<void> clearCategory(MemoryCategory category) async {
    switch (category) {
      case MemoryCategory.CONVERSATION:
        _conversations.clear();
        await _saveCategory(_conversationsKey, _conversations);
        break;
      case MemoryCategory.TASK:
        _tasks.clear();
        await _saveCategory(_tasksKey, _tasks);
        break;
      case MemoryCategory.HABIT:
        _habits.clear();
        await _saveCategory(_habitsKey, _habits);
        break;
      case MemoryCategory.DATE:
        _dates.clear();
        await _saveCategory(_datesKey, _dates);
        break;
      case MemoryCategory.PREFERENCE:
        _preferences.clear();
        await _saveCategory(_preferencesKey, _preferences);
        break;
    }
    notifyListeners();
  }
  
  // Retrieval operations
  List<MemoryEntry> getHabitsByTime(int hour) {
    return _habits.where((h) {
      final metadata = HabitMetadata.fromJson(h.metadata);
      return metadata.hour == hour;
    }).toList();
  }
  
  List<MemoryEntry> getTasksByDate(DateTime date) {
    return _tasks.where((t) {
      final metadata = TaskMetadata.fromJson(t.metadata);
      if (metadata.deadline == null) return false;
      return metadata.deadline!.year == date.year &&
             metadata.deadline!.month == date.month &&
             metadata.deadline!.day == date.day;
    }).toList();
  }
  
  List<MemoryEntry> getDueDates({Duration? within}) {
    final now = DateTime.now();
    final threshold = within != null ? now.add(within) : now.add(Duration(days: 30));
    
    return _dates.where((d) {
      final metadata = DateMetadata.fromJson(d.metadata);
      // Calculate next occurrence
      final nextOccurrence = DateTime(
        now.year,
        d.timestamp.month,
        d.timestamp.day,
      );
      if (nextOccurrence.isBefore(now) && metadata.recurring) {
        // Next year if recurring
        return DateTime(now.year + 1, d.timestamp.month, d.timestamp.day)
            .isBefore(threshold);
      }
      return nextOccurrence.isBefore(threshold);
    }).toList();
  }
  
  List<MemoryEntry> getPendingTasks() {
    return _tasks.where((t) {
      final metadata = TaskMetadata.fromJson(t.metadata);
      return metadata.status == 'pending';
    }).toList();
  }
  
  // Search across all categories
  List<MemoryEntry> searchMemory(String query) {
    final queryLower = query.toLowerCase();
    final results = <MemoryEntry>[];
    
    for (final entry in [..._conversations, ..._tasks, ..._habits, ..._dates, ..._preferences]) {
      if (entry.content.toLowerCase().contains(queryLower)) {
        results.add(entry);
      }
    }
    
    return results;
  }
  
  // Get recent conversations for context
  List<Map<String, String>> getRecentConversations({int limit = 5}) {
    final recent = _conversations.reversed.take(limit);
    return recent.map((e) {
      final parts = e.content.split('|');
      return {
        'query': parts.isNotEmpty ? parts[0] : '',
        'response': parts.length > 1 ? parts[1] : '',
      };
    }).toList();
  }
  
  // Get top habits for context
  List<String> getTopHabits({int limit = 3}) {
    final sorted = List<MemoryEntry>.from(_habits);
    sorted.sort((a, b) {
      final aFreq = HabitMetadata.fromJson(a.metadata).frequency;
      final bFreq = HabitMetadata.fromJson(b.metadata).frequency;
      return bFreq.compareTo(aFreq);
    });
    return sorted.take(limit).map((e) => e.content).toList();
  }
  
  // Get preference value
  String? getPreference(String key) {
    final entry = _preferences.where((p) => p.content.startsWith('$key=')).firstOrNull;
    if (entry != null) {
      return entry.metadata['value'] as String?;
    }
    return null;
  }
}

/// Global Memory System instance
MemorySystem? memorySystem;

/// Initialize Memory System
Future<void> initMemorySystem(SharedPreferences prefs) async {
  memorySystem = MemorySystem(prefs: prefs);
}