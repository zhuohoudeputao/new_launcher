/// Memory entry types for AI-powered launcher
/// These types represent the memory system categories

/// Categories of memory entries
enum MemoryCategory {
  HABIT,
  TASK,
  DATE,
  CONVERSATION,
  PREFERENCE,
}

/// Represents a single memory entry
class MemoryEntry {
  final MemoryCategory category;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? id;

  MemoryEntry({
    required this.category,
    required this.content,
    required this.timestamp,
    Map<String, dynamic>? metadata,
    this.id,
  }) : metadata = metadata ?? const {};

  factory MemoryEntry.fromJson(Map<String, dynamic> json) {
    return MemoryEntry(
      category: MemoryCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MemoryCategory.CONVERSATION,
      ),
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] ?? {},
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'id': id,
    };
  }

  /// Convert to storage string format (compatible with SharedPreferences)
  String toStorageString() {
    return '${category.name}|${content}|${timestamp.toIso8601String()}|${metadata.toString()}';
  }

  /// Parse from storage string format
  static MemoryEntry? fromStorageString(String str) {
    try {
      final parts = str.split('|');
      if (parts.length < 3) return null;
      return MemoryEntry(
        category: MemoryCategory.values.firstWhere(
          (e) => e.name == parts[0],
          orElse: () => MemoryCategory.CONVERSATION,
        ),
        content: parts[1],
        timestamp: DateTime.parse(parts[2]),
        metadata: parts.length > 3 ? _parseMetadata(parts[3]) : {},
      );
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> _parseMetadata(String str) {
    // Simple metadata parsing - can be enhanced later
    if (str.isEmpty || str == '{}') return {};
    try {
      // Basic format: {key: value}
      final result = <String, dynamic>{};
      final entries = str.replaceAll('{', '').replaceAll('}', '').split(',');
      for (final entry in entries) {
        final kv = entry.split(':');
        if (kv.length == 2) {
          result[kv[0].trim()] = kv[1].trim();
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }
}

/// Habit-specific metadata
class HabitMetadata {
  final int hour; // Hour of day (0-23)
  final int dayOfWeek; // Day of week (0-6, Monday=0)
  final int frequency; // How often this habit occurs
  final String? pattern; // Pattern description

  HabitMetadata({
    required this.hour,
    this.dayOfWeek = 0,
    this.frequency = 1,
    this.pattern,
  });

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'dayOfWeek': dayOfWeek,
      'frequency': frequency,
      'pattern': pattern,
    };
  }

  factory HabitMetadata.fromJson(Map<String, dynamic> json) {
    return HabitMetadata(
      hour: json['hour'] ?? 0,
      dayOfWeek: json['dayOfWeek'] ?? 0,
      frequency: json['frequency'] ?? 1,
      pattern: json['pattern'],
    );
  }
}

/// Task-specific metadata
class TaskMetadata {
  final DateTime? deadline;
  final String priority; // high, medium, low
  final String status; // pending, completed, cancelled
  final String? notes;

  TaskMetadata({
    this.deadline,
    this.priority = 'medium',
    this.status = 'pending',
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'deadline': deadline?.toIso8601String(),
      'priority': priority,
      'status': status,
      'notes': notes,
    };
  }

  factory TaskMetadata.fromJson(Map<String, dynamic> json) {
    return TaskMetadata(
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
    );
  }
}

/// Date-specific metadata (for important dates)
class DateMetadata {
  final String type; // birthday, anniversary, event, holiday
  final int? year; // Optional year for age calculation
  final bool recurring; // Does this repeat annually?
  final String? reminderDays; // Days before to remind

  DateMetadata({
    this.type = 'event',
    this.year,
    this.recurring = true,
    this.reminderDays = '7',
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'year': year,
      'recurring': recurring,
      'reminderDays': reminderDays,
    };
  }

  factory DateMetadata.fromJson(Map<String, dynamic> json) {
    return DateMetadata(
      type: json['type'] ?? 'event',
      year: json['year'],
      recurring: json['recurring'] ?? true,
      reminderDays: json['reminderDays'] ?? '7',
    );
  }
}