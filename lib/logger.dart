import 'package:flutter/material.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
  });

  String get levelString {
    switch (level) {
      case LogLevel.debug:
        return "DEBUG";
      case LogLevel.info:
        return "INFO";
      case LogLevel.warning:
        return "WARN";
      case LogLevel.error:
        return "ERROR";
    }
  }

  IconData get levelIcon {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
    }
  }
}

class LoggerModel extends ChangeNotifier {
  static final LoggerModel _instance = LoggerModel._internal();
  factory LoggerModel() => _instance;
  LoggerModel._internal();

  final List<LogEntry> _logs = [];
  static const int maxLogs = 1000;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void log(LogLevel level, String message, {String? source}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
    );

    _logs.add(entry);

    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }

    notifyListeners();

    debugPrint("[${entry.levelString}] ${entry.timestamp.toIso8601String()} - $message");
  }

  void debug(String message, {String? source}) {
    log(LogLevel.debug, message, source: source);
  }

  void info(String message, {String? source}) {
    log(LogLevel.info, message, source: source);
  }

  void warning(String message, {String? source}) {
    log(LogLevel.warning, message, source: source);
  }

  void error(String message, {String? source}) {
    log(LogLevel.error, message, source: source);
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }

  List<LogEntry> filterByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  List<LogEntry> filterBySource(String source) {
    return _logs.where((log) => log.source == source).toList();
  }

  List<LogEntry> search(String query) {
    return _logs
        .where((log) => log.message.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}