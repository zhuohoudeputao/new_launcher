import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

BloodPressureModel bloodPressureModel = BloodPressureModel();

MyProvider providerBloodPressure = MyProvider(
    name: "BloodPressure",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Log blood pressure',
      keywords: 'blood pressure bp systolic diastolic heart pulse log track health monitor',
      action: () {
        Global.infoModel.addInfo("LogBP", "Log Blood Pressure",
            subtitle: "Tap to log your blood pressure reading",
            icon: Icon(Icons.favorite),
            onTap: () => _showBPLogger(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await bloodPressureModel.init();
  Global.infoModel.addInfoWidget(
      "BloodPressure",
      ChangeNotifierProvider.value(
          value: bloodPressureModel,
          builder: (context, child) => BloodPressureCard()),
      title: "Blood Pressure");
}

Future<void> _update() async {
  await bloodPressureModel.refresh();
}

void _showBPLogger(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => BloodPressureLogDialog(),
  );
}

enum BPCategory {
  normal,
  elevated,
  highStage1,
  highStage2,
  crisis,
}

BPCategory getBPCategoryFromValues(int systolic, int diastolic) {
  if (systolic > 180 || diastolic > 120) {
    return BPCategory.crisis;
  }
  if (systolic >= 140 || diastolic >= 90) {
    return BPCategory.highStage2;
  }
  if (systolic >= 130 || diastolic >= 80) {
    return BPCategory.highStage1;
  }
  if (systolic >= 120 && diastolic < 80) {
    return BPCategory.elevated;
  }
  return BPCategory.normal;
}

extension BPCategoryExtension on BPCategory {
  String get label {
    switch (this) {
      case BPCategory.normal:
        return 'Normal';
      case BPCategory.elevated:
        return 'Elevated';
      case BPCategory.highStage1:
        return 'High Stage 1';
      case BPCategory.highStage2:
        return 'High Stage 2';
      case BPCategory.crisis:
        return 'Crisis';
    }
  }

  Color get color {
    // Use semantic colors derived from typical Material 3 palette
    switch (this) {
      case BPCategory.normal:
        return Color(0xFF4CAF50); // Green - healthy
      case BPCategory.elevated:
        return Color(0xFFFF9800); // Orange - caution
      case BPCategory.highStage1:
        return Color(0xFFFF5722); // Deep Orange - warning
      case BPCategory.highStage2:
        return Color(0xFFF44336); // Red - danger
      case BPCategory.crisis:
        return Color(0xFFB71C1C); // Dark Red - critical
    }
  }

  String get description {
    switch (this) {
      case BPCategory.normal:
        return '<120/<80 mmHg';
      case BPCategory.elevated:
        return '120-129/<80 mmHg';
      case BPCategory.highStage1:
        return '130-139/80-89 mmHg';
      case BPCategory.highStage2:
        return '≥140/≥90 mmHg';
      case BPCategory.crisis:
        return '>180/>120 mmHg';
    }
  }
}

class BloodPressureEntry {
  final DateTime date;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final String? notes;

  BloodPressureEntry({
    required this.date,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.notes,
  });

  BPCategory get category => getBPCategoryFromValues(systolic, diastolic);

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'notes': notes,
    });
  }

  static BloodPressureEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return BloodPressureEntry(
      date: DateTime.parse(map['date'] as String),
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      pulse: map['pulse'] as int?,
      notes: map['notes'] as String?,
    );
  }

  static String getDayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  String formatReading() {
    return "$systolic/$diastolic mmHg";
  }

  String formatWithPulse() {
    if (pulse != null) {
      return "$systolic/$diastolic mmHg, $pulse bpm";
    }
    return formatReading();
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

class BloodPressureModel extends ChangeNotifier {
  static const int maxHistoryEntries = 30;
  static const String _storageKey = 'blood_pressure_entries';
  static const String _targetKey = 'blood_pressure_target';

  List<BloodPressureEntry> _history = [];
  int _targetSystolic = 120;
  int _targetDiastolic = 80;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<BloodPressureEntry> get history => _history;
  int get targetSystolic => _targetSystolic;
  int get targetDiastolic => _targetDiastolic;

  BloodPressureEntry? get latestEntry {
    if (_history.isEmpty) return null;
    return _history.last;
  }

  bool get hasHistory => _history.isNotEmpty;

  int get entryCount => _history.length;

  int get averageSystolic {
    if (_history.isEmpty) return 0;
    final sum = _history.fold<int>(0, (sum, e) => sum + e.systolic);
    return sum ~/ _history.length;
  }

  int get averageDiastolic {
    if (_history.isEmpty) return 0;
    final sum = _history.fold<int>(0, (sum, e) => sum + e.diastolic);
    return sum ~/ _history.length;
  }

  int get averagePulse {
    if (_history.isEmpty) return 0;
    final entriesWithPulse = _history.where((e) => e.pulse != null).toList();
    if (entriesWithPulse.isEmpty) return 0;
    final sum = entriesWithPulse.fold<int>(0, (sum, e) => sum + e.pulse!);
    return sum ~/ entriesWithPulse.length;
  }

  int get minSystolic {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.systolic).reduce((a, b) => a < b ? a : b);
  }

  int get maxSystolic {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.systolic).reduce((a, b) => a > b ? a : b);
  }

  int get minDiastolic {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.diastolic).reduce((a, b) => a < b ? a : b);
  }

  int get maxDiastolic {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.diastolic).reduce((a, b) => a > b ? a : b);
  }

  BPCategory get averageCategory {
    if (_history.isEmpty) return BPCategory.normal;
    return getBPCategoryFromValues(averageSystolic, averageDiastolic);
  }

  int get normalReadings {
    return _history.where((e) => e.category == BPCategory.normal).length;
  }

  int get highReadings {
    return _history.where((e) =>
      e.category == BPCategory.highStage1 ||
      e.category == BPCategory.highStage2 ||
      e.category == BPCategory.crisis
    ).length;
  }

  double get normalPercentage {
    if (_history.isEmpty) return 0;
    return (normalReadings / _history.length) * 100;
  }

  int systolicChange() {
    if (_history.length < 2) return 0;
    final firstEntry = _history.first;
    final latestEntry = _history.last;
    return latestEntry.systolic - firstEntry.systolic;
  }

  int diastolicChange() {
    if (_history.length < 2) return 0;
    final firstEntry = _history.first;
    final latestEntry = _history.last;
    return latestEntry.diastolic - firstEntry.diastolic;
  }

  String get systolicChangeLabel {
    if (_history.length < 2) return "";
    final change = systolicChange();
    if (change > 0) return "+$change";
    if (change < 0) return "$change";
    return "0";
  }

  String get diastolicChangeLabel {
    if (_history.length < 2) return "";
    final change = diastolicChange();
    if (change > 0) return "+$change";
    if (change < 0) return "$change";
    return "0";
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => BloodPressureEntry.fromJson(s)).toList();
    _targetSystolic = prefs.getInt('${_targetKey}_systolic') ?? 120;
    _targetDiastolic = prefs.getInt('${_targetKey}_diastolic') ?? 80;
    _isInitialized = true;
    Global.loggerModel.info("Blood Pressure initialized with ${_history.length} entries", source: "BloodPressure");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
    await prefs.setInt('${_targetKey}_systolic', _targetSystolic);
    await prefs.setInt('${_targetKey}_diastolic', _targetDiastolic);
  }

  void setTarget(int systolic, int diastolic) {
    _targetSystolic = systolic;
    _targetDiastolic = diastolic;
    _save();
    notifyListeners();
    Global.loggerModel.info("Target BP set to $systolic/$diastolic", source: "BloodPressure");
  }

  void logReading(int systolic, int diastolic, {int? pulse, String? notes, DateTime? customDate}) {
    final date = customDate ?? DateTime.now();
    final dayKey = BloodPressureEntry.getDayKey(date);
    final existingIndex = _history.indexWhere((e) => BloodPressureEntry.getDayKey(e.date) == dayKey);

    final newEntry = BloodPressureEntry(
      date: date,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      notes: notes,
    );

    if (existingIndex >= 0) {
      _history[existingIndex] = newEntry;
      Global.loggerModel.info("Updated BP for ${date.month}/${date.day}: $systolic/$diastolic", source: "BloodPressure");
    } else {
      _history.add(newEntry);
      Global.loggerModel.info("Logged BP: $systolic/$diastolic", source: "BloodPressure");
    }

    final sortedHistory = List<BloodPressureEntry>.from(_history)
      ..sort((a, b) => a.date.compareTo(b.date));
    while (sortedHistory.length > maxHistoryEntries) {
      sortedHistory.removeAt(0);
    }
    _history = sortedHistory;

    _save();
    notifyListeners();
  }

  void deleteEntry(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _history.removeAt(index);
      Global.loggerModel.info("Deleted BP entry for ${entry.date.month}/${entry.date.day}", source: "BloodPressure");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared BP history", source: "BloodPressure");
    notifyListeners();
  }
}

class BloodPressureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BloodPressureModel>();

    if (!bp.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.favorite, size: 24),
              SizedBox(width: 12),
              Text("Blood Pressure: Loading..."),
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
                  Icon(Icons.favorite, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Blood Pressure",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (bp.latestEntry != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bp.latestEntry!.category.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bp.latestEntry!.formatReading(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: bp.latestEntry!.category.color,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (bp.latestEntry != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "${bp.latestEntry!.date.month}/${bp.latestEntry!.date.day}",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bp.latestEntry!.category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bp.latestEntry!.category.label,
                        style: TextStyle(fontSize: 11, color: bp.latestEntry!.category.color),
                      ),
                    ),
                    if (bp.hasHistory && bp.history.length >= 2) ...[
                      SizedBox(width: 12),
                      Icon(
                        bp.systolicChange() >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: bp.systolicChange() >= 0
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "${bp.systolicChangeLabel}/${bp.diastolicChangeLabel}",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
                if (bp.latestEntry!.pulse != null) ...[
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.monitor_heart,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Pulse: ${bp.latestEntry!.pulse} bpm",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 8),
              ] else ...[
                Text(
                  "No readings logged yet",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
              ],
              if (bp.hasHistory) ...[
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Avg: ${bp.averageSystolic}/${bp.averageDiastolic}",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bp.averageCategory.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bp.averageCategory.label,
                        style: TextStyle(fontSize: 11, color: bp.averageCategory.color),
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.percent,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "${bp.normalPercentage.toStringAsFixed(0)}% normal",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.add, size: 18),
                    label: Text("Log"),
                    onPressed: () => _showBPLogger(context),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.flag, size: 18),
                    label: Text("Target"),
                    onPressed: () => _showTargetDialog(context),
                  ),
                  if (bp.hasHistory)
                    TextButton.icon(
                      icon: Icon(Icons.history, size: 18),
                      label: Text("History"),
                      onPressed: () => _showHistoryDialog(context, bp),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTargetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BloodPressureTargetDialog(),
    );
  }

  void _showHistoryDialog(BuildContext context, BloodPressureModel bp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("BP History (${bp.entryCount} readings)"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: bp.history.length,
            itemBuilder: (context, index) {
              final entry = bp.history[bp.history.length - 1 - index];
              return ListTile(
                leading: Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: entry.category.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text(entry.formatReading()),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${entry.date.month}/${entry.date.day}/${entry.date.year}",
                      style: TextStyle(fontSize: 12),
                    ),
                    if (entry.pulse != null)
                      Text(
                        "Pulse: ${entry.pulse} bpm",
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, size: 20),
                  onPressed: () {
                    bp.deleteEntry(bp.history.length - 1 - index);
                    Navigator.pop(context);
                    _showHistoryDialog(context, bp);
                  },
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
          if (bp.hasHistory)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showClearConfirmation(context, bp);
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

  void _showClearConfirmation(BuildContext context, BloodPressureModel bp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Are you sure you want to clear all blood pressure history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              bp.clearHistory();
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

class BloodPressureLogDialog extends StatefulWidget {
  @override
  State<BloodPressureLogDialog> createState() => _BloodPressureLogDialogState();
}

class _BloodPressureLogDialogState extends State<BloodPressureLogDialog> {
  int _systolic = 120;
  int _diastolic = 80;
  int? _pulse;
  String? _notes;
  DateTime? _customDate;
  bool _useCustomDate = false;

  @override
  Widget build(BuildContext context) {
    final category = getBPCategoryFromValues(_systolic, _diastolic);

    return AlertDialog(
      title: Text("Log Blood Pressure"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _useCustomDate,
                  onChanged: (v) => setState(() => _useCustomDate = v ?? false),
                ),
                Text("Log for different date"),
              ],
            ),
            if (_useCustomDate) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Text("Date: "),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _customDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _customDate = picked);
                      }
                    },
                    child: Text(_customDate != null
                        ? "${_customDate!.month}/${_customDate!.day}"
                        : "Select"),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
            Text("Systolic (top number):", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter systolic",
                      suffixText: "mmHg",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0 && parsed <= 300) {
                        setState(() => _systolic = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text("Diastolic (bottom number):", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter diastolic",
                      suffixText: "mmHg",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0 && parsed <= 200) {
                        setState(() => _diastolic = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text("Pulse (optional):", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter pulse",
                      suffixText: "bpm",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0 && parsed <= 200) {
                        _pulse = parsed;
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: category.color),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$_systolic/$_diastolic: ${category.label}",
                      style: TextStyle(color: category.color),
                    ),
                  ),
                ],
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
        TextButton(
          onPressed: () {
            bloodPressureModel.logReading(
              _systolic,
              _diastolic,
              pulse: _pulse,
              notes: _notes,
              customDate: _useCustomDate ? _customDate : null,
            );
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}

class BloodPressureTargetDialog extends StatefulWidget {
  @override
  State<BloodPressureTargetDialog> createState() => _BloodPressureTargetDialogState();
}

class _BloodPressureTargetDialogState extends State<BloodPressureTargetDialog> {
  int _targetSystolic = 120;
  int _targetDiastolic = 80;

  @override
  void initState() {
    super.initState();
    _targetSystolic = bloodPressureModel.targetSystolic;
    _targetDiastolic = bloodPressureModel.targetDiastolic;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Set Target BP"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Target Systolic:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter target systolic",
                      suffixText: "mmHg",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0 && parsed <= 200) {
                        setState(() => _targetSystolic = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text("Target Diastolic:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter target diastolic",
                      suffixText: "mmHg",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0 && parsed <= 150) {
                        setState(() => _targetDiastolic = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: Text("120/80"),
                  onPressed: () => setState(() {
                    _targetSystolic = 120;
                    _targetDiastolic = 80;
                  }),
                  backgroundColor: _targetSystolic == 120 && _targetDiastolic == 80
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                ActionChip(
                  label: Text("110/70"),
                  onPressed: () => setState(() {
                    _targetSystolic = 110;
                    _targetDiastolic = 70;
                  }),
                  backgroundColor: _targetSystolic == 110 && _targetDiastolic == 70
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                ActionChip(
                  label: Text("130/85"),
                  onPressed: () => setState(() {
                    _targetSystolic = 130;
                    _targetDiastolic = 85;
                  }),
                  backgroundColor: _targetSystolic == 130 && _targetDiastolic == 85
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            bloodPressureModel.setTarget(_targetSystolic, _targetDiastolic);
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}