import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

SmartSuggestionsModel smartSuggestionsModel = SmartSuggestionsModel();

MyProvider providerSmartSuggestions = MyProvider(
    name: "SmartSuggestions",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'SmartSuggestions',
      keywords: 'suggestion smart learn predict recommend history pattern time',
      action: () => smartSuggestionsModel.requestFocus(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await smartSuggestionsModel.init();
  Global.infoModel.addInfoWidget(
      "SmartSuggestions",
      ChangeNotifierProvider.value(
          value: smartSuggestionsModel,
          builder: (context, child) => SmartSuggestionsCard()),
      title: "Smart Suggestions");
}

Future<void> _update() async {
  smartSuggestionsModel.refresh();
}

/// Represents a single action usage record
class ActionUsageEntry {
  final String actionName;
  final String? providerName;
  final DateTime timestamp;
  final int hour;
  final int dayOfWeek;

  ActionUsageEntry({
    required this.actionName,
    this.providerName,
    required this.timestamp,
    required this.hour,
    required this.dayOfWeek,
  });

  String toStorageString() {
    return '$actionName|${providerName ?? ""}|${timestamp.toIso8601String()}|$hour|$dayOfWeek';
  }

  static ActionUsageEntry? fromStorageString(String str) {
    try {
      final parts = str.split('|');
      if (parts.length != 5) return null;
      return ActionUsageEntry(
        actionName: parts[0],
        providerName: parts[1].isEmpty ? null : parts[1],
        timestamp: DateTime.parse(parts[2]),
        hour: int.parse(parts[3]),
        dayOfWeek: int.parse(parts[4]),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Time-of-day usage pattern for an action
class ActionPattern {
  final String actionName;
  final Map<int, int> hourlyUsage; // hour -> count
  final Map<int, int> dayOfWeekUsage; // dayOfWeek -> count
  int totalUsage;

  ActionPattern({
    required this.actionName,
    this.hourlyUsage = const {},
    this.dayOfWeekUsage = const {},
    this.totalUsage = 0,
  });

  /// Get usage probability for a specific hour
  double getProbabilityForHour(int hour) {
    if (totalUsage == 0) return 0.0;
    return (hourlyUsage[hour] ?? 0) / totalUsage;
  }

  /// Get usage probability for a specific day of week
  double getProbabilityForDayOfWeek(int dayOfWeek) {
    if (totalUsage == 0) return 0.0;
    return (dayOfWeekUsage[dayOfWeek] ?? 0) / totalUsage;
  }

  /// Combined probability for current time context
  double getCurrentProbability() {
    final now = DateTime.now();
    final hourProb = getProbabilityForHour(now.hour);
    final dayProb = getProbabilityForDayOfWeek(now.weekday);
    // Weight: hour pattern more important (70%), day pattern less (30%)
    return hourProb * 0.7 + dayProb * 0.3;
  }

  /// Peak usage hour
  int? getPeakHour() {
    if (hourlyUsage.isEmpty) return null;
    return hourlyUsage.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String formatPeakHour() {
    final peak = getPeakHour();
    if (peak == null) return "No data";
    if (peak < 12) return "${peak}am";
    if (peak == 12) return "12pm";
    return "${peak - 12}pm";
  }
}

class SmartSuggestionsModel extends ChangeNotifier {
  static const int maxHistoryEntries = 500;
  static const int minSuggestions = 3;
  static const int maxSuggestions = 8;
  static const double minProbabilityThreshold = 0.05;

  final List<ActionUsageEntry> _usageHistory = [];
  final Map<String, ActionPattern> _patterns = {};
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _focusRequested = false;
  bool _showHistory = false;

  List<ActionUsageEntry> get usageHistory => List.unmodifiable(_usageHistory);
  Map<String, ActionPattern> get patterns => Map.unmodifiable(_patterns);
  bool get isInitialized => _isInitialized;
  bool get shouldFocus => _focusRequested;
  bool get showHistory => _showHistory;
  bool get hasHistory => _usageHistory.isNotEmpty;

  /// Get suggested actions sorted by probability
  List<String> getSuggestions() {
    final suggestions = <String>[];
    
    // Calculate probabilities for all tracked actions
    final probabilities = <String, double>{};
    
    for (final pattern in _patterns.values) {
      final prob = pattern.getCurrentProbability();
      if (prob >= minProbabilityThreshold) {
        probabilities[pattern.actionName] = prob;
      }
    }
    
    // Sort by probability
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top suggestions
    for (final entry in sorted.take(maxSuggestions)) {
      suggestions.add(entry.key);
    }
    
    return suggestions;
  }

  /// Get suggestions for a specific hour
  List<String> getSuggestionsForHour(int hour) {
    final suggestions = <String>[];
    final probabilities = <String, double>{};
    
    for (final pattern in _patterns.values) {
      final prob = pattern.getProbabilityForHour(hour);
      if (prob >= minProbabilityThreshold) {
        probabilities[pattern.actionName] = prob;
      }
    }
    
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sorted.take(maxSuggestions)) {
      suggestions.add(entry.key);
    }
    
    return suggestions;
  }

  /// Record an action usage
  void recordActionUsage(String actionName, {String? providerName}) {
    final now = DateTime.now();
    final entry = ActionUsageEntry(
      actionName: actionName,
      providerName: providerName,
      timestamp: now,
      hour: now.hour,
      dayOfWeek: now.weekday,
    );
    
    _usageHistory.insert(0, entry);
    
    // Maintain max entries
    if (_usageHistory.length > maxHistoryEntries) {
      _usageHistory.removeRange(maxHistoryEntries, _usageHistory.length);
    }
    
    // Update pattern
    _updatePattern(entry);
    
    Global.loggerModel.info(
      "Recorded action usage: $actionName at hour ${now.hour}",
      source: "SmartSuggestions",
    );
    
    notifyListeners();
    _saveHistory();
  }

  void _updatePattern(ActionUsageEntry entry) {
    var pattern = _patterns[entry.actionName];
    
    if (pattern == null) {
      pattern = ActionPattern(
        actionName: entry.actionName,
        hourlyUsage: {},
        dayOfWeekUsage: {},
      );
    }
    
    // Create modifiable maps if needed (const {} is unmodifiable)
    if (pattern.hourlyUsage.isEmpty) {
      pattern.hourlyUsage.clear(); // This won't work on const, so we need a different approach
    }
    
    // Actually, we need to replace the const maps with modifiable ones
    // Check if the map is unmodifiable by trying a safe operation
    final hourlyMap = Map<int, int>.from(pattern.hourlyUsage);
    final dayOfWeekMap = Map<int, int>.from(pattern.dayOfWeekUsage);
    
    hourlyMap[entry.hour] = (hourlyMap[entry.hour] ?? 0) + 1;
    dayOfWeekMap[entry.dayOfWeek] = (dayOfWeekMap[entry.dayOfWeek] ?? 0) + 1;
    pattern.totalUsage++;
    
    // Create a new pattern with the updated maps
    final updatedPattern = ActionPattern(
      actionName: pattern.actionName,
      hourlyUsage: hourlyMap,
      dayOfWeekUsage: dayOfWeekMap,
      totalUsage: pattern.totalUsage,
    );
    
    _patterns[entry.actionName] = updatedPattern;
  }

  /// Get pattern for a specific action
  ActionPattern? getPatternForAction(String actionName) {
    return _patterns[actionName];
  }

  /// Get top used actions overall
  List<String> getTopActions(int count) {
    final sorted = _patterns.values.toList()
      ..sort((a, b) => b.totalUsage.compareTo(a.totalUsage));
    return sorted.take(count).map((p) => p.actionName).toList();
  }

  /// Get usage stats
  int get totalRecordedActions => _usageHistory.length;
  int get uniqueActions => _patterns.length;
  int get totalPatterns => _patterns.length;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadHistory();
    _isInitialized = true;
    Global.loggerModel.info(
      "SmartSuggestions initialized with ${_usageHistory.length} history entries, ${_patterns.length} patterns",
      source: "SmartSuggestions",
    );
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    final historyData = prefs.getStringList('SmartSuggestions.history') ?? [];
    
    for (final str in historyData) {
      final entry = ActionUsageEntry.fromStorageString(str);
      if (entry != null) {
        _usageHistory.add(entry);
        _updatePattern(entry);
      }
    }
    
    // Recalculate patterns from loaded history
    _rebuildPatterns();
  }

  void _rebuildPatterns() {
    _patterns.clear();
    for (final entry in _usageHistory) {
      _updatePattern(entry);
    }
  }

  Future<void> _saveHistory() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    try {
      final historyStrings = _usageHistory
          .map((e) => e.toStorageString())
          .toList();
      await prefs.setStringList('SmartSuggestions.history', historyStrings);
    } catch (e) {
      Global.loggerModel.error("Failed to save suggestions history: $e", source: "SmartSuggestions");
    }
  }

  void refresh() {
    notifyListeners();
  }

  void toggleHistory() {
    _showHistory = !_showHistory;
    notifyListeners();
  }

  void clearHistory() {
    _usageHistory.clear();
    _patterns.clear();
    notifyListeners();
    _saveHistory();
    Global.loggerModel.info("SmartSuggestions history cleared", source: "SmartSuggestions");
  }

  void requestFocus() {
    _focusRequested = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _focusRequested = false;
      notifyListeners();
    });
  }

  /// Format time ago for history entries
  String formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  /// Get hour label
  String getHourLabel(int hour) {
    if (hour == 0) return "12am";
    if (hour < 12) return "${hour}am";
    if (hour == 12) return "12pm";
    return "${hour - 12}pm";
  }

  /// Get day of week label
  String getDayOfWeekLabel(int dayOfWeek) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[dayOfWeek - 1];
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class SmartSuggestionsCard extends StatelessWidget {
  const SmartSuggestionsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SmartSuggestionsModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.psychology, size: 24),
              SizedBox(width: 12),
              Text("Smart Suggestions: Learning..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, size: 20, color: colorScheme.primary),
                      SizedBox(width: 8),
                      Text(
                        "Smart Suggestions",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(model.showHistory ? Icons.psychology : Icons.history, size: 18),
                        onPressed: () => model.toggleHistory(),
                        tooltip: model.showHistory ? "Suggestions" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (model.hasHistory)
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _showClearConfirmation(context),
                          tooltip: "Clear history",
                          style: IconButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (model.showHistory)
                _buildHistoryView(model, colorScheme)
              else
                _buildSuggestionsView(model, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsView(SmartSuggestionsModel model, ColorScheme colorScheme) {
    final suggestions = model.getSuggestions();
    final now = DateTime.now();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current time context
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 14, color: colorScheme.onSecondaryContainer),
              SizedBox(width: 4),
              Text(
                "Based on ${model.getHourLabel(now.hour)} patterns",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        
        if (suggestions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(Icons.lightbulb_outline, size: 32, color: colorScheme.onSurfaceVariant),
                SizedBox(height: 8),
                Text(
                  "Start using actions to build suggestions",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 4),
                Text(
                  "Suggestions improve as you use the launcher",
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Suggested for now:",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map((action) {
                  final pattern = model.getPatternForAction(action);
                  final peakHour = pattern?.formatPeakHour() ?? "";
                  
                  return ActionChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(action),
                        if (peakHour != "No data") ...[
                          SizedBox(width: 4),
                          Text(
                            peakHour,
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                    onPressed: () {
                      // Trigger the action through Global.actionModel
                      final actionMap = Global.actionModel.actionMap;
                      if (actionMap.containsKey(action)) {
                        actionMap[action]!.action();
                        model.recordActionUsage(action);
                      }
                    },
                    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                  );
                }).toList(),
              ),
            ],
          ),
        
        if (model.uniqueActions > 0) ...[
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                "Learned",
                "${model.uniqueActions}",
                Icons.school,
                colorScheme.primary,
              ),
              _buildStatItem(
                "Records",
                "${model.totalRecordedActions}",
                Icons.history,
                colorScheme.secondary,
              ),
              _buildStatItem(
                "Top Hour",
                model.getHourLabel(now.hour),
                Icons.access_time,
                colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryView(SmartSuggestionsModel model, ColorScheme colorScheme) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Usage History (${model.totalRecordedActions} records)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: model.usageHistory.length,
              addRepaintBoundaries: true,
              itemBuilder: (context, index) {
                final entry = model.usageHistory[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.touch_app, size: 20, color: colorScheme.primary),
                  title: Text(
                    entry.actionName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    "${model.getHourLabel(entry.hour)} | ${model.getDayOfWeekLabel(entry.dayOfWeek)}",
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                  trailing: Text(
                    model.formatTimeAgo(entry.timestamp),
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11)),
      ],
    );
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Learning History"),
        content: Text("This will delete all usage patterns. Suggestions will start fresh."),
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
      context.read<SmartSuggestionsModel>().clearHistory();
    }
  }
}