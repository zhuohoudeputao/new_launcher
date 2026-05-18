import 'package:new_launcher/memory_system.dart';
import 'package:new_launcher/providers/provider_app.dart';
import 'package:new_launcher/providers/provider_weather.dart';
import 'package:new_launcher/data.dart';

class ContextBuilder {
  final MemorySystem? _memory;
  
  ContextBuilder({MemorySystem? memory}) : _memory = memory;
  
  Map<String, dynamic> buildFullContext() {
    final now = DateTime.now();
    
    return {
      'apps': _getInstalledApps(),
      'location': _getLocation(),
      'time': now.toIso8601String(),
      'hour': now.hour,
      'day_of_week': now.weekday,
      'recent_queries': _getRecentQueries(),
      'top_habits': _getTopHabits(),
      'pending_tasks': _getPendingTasks(),
      'upcoming_dates': _getUpcomingDates(),
      'preferences': _getPreferences(),
    };
  }
  
  List<String> _getInstalledApps() {
    try {
      return allAppsModel.apps.map((app) => app.appName).toList();
    } catch (e) {
      return [];
    }
  }
  
  String _getLocation() {
    try {
      return 'unknown'; // Location from weather provider
    } catch (e) {
      return 'unknown';
    }
  }
  
  List<String> _getRecentQueries() {
    if (_memory == null) return [];
    
    final conversations = _memory!.getRecentConversations(limit: 5);
    return conversations.map((c) => c['query'] ?? '').toList();
  }
  
  List<String> _getTopHabits() {
    if (_memory == null) return [];
    return _memory!.getTopHabits(limit: 3);
  }
  
  List<String> _getPendingTasks() {
    if (_memory == null) return [];
    
    final tasks = _memory!.getPendingTasks();
    return tasks.map((t) => t.content).toList();
  }
  
  List<String> _getUpcomingDates() {
    if (_memory == null) return [];
    
    final dates = _memory!.getDueDates(within: Duration(days: 7));
    return dates.map((d) => d.content).toList();
  }
  
  Map<String, String> _getPreferences() {
    if (_memory == null) return {};
    
    final prefs = <String, String>{};
    for (final entry in _memory!.preferences) {
      final parts = entry.content.split('=');
      if (parts.length == 2) {
        prefs[parts[0]] = parts[1];
      }
    }
    return prefs;
  }
}

ContextBuilder? contextBuilder;

void initContextBuilder(MemorySystem? memory) {
  contextBuilder = ContextBuilder(memory: memory);
}