import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

BiorhythmModel biorhythmModel = BiorhythmModel();

MyProvider providerBiorhythm = MyProvider(
  name: "Biorhythm",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Calculate Biorhythm',
      keywords: 'biorhythm cycle physical emotional intellectual rhythm birthdate',
      action: () {
        Global.infoModel.addInfo("CalculateBiorhythm", "Biorhythm Calculator",
            subtitle: "Calculate biorhythm cycles from birthdate",
            icon: Icon(Icons.waves),
            onTap: () => biorhythmModel.requestFocus());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await biorhythmModel.init();
  Global.infoModel.addInfoWidget(
    "Biorhythm",
    ChangeNotifierProvider.value(
      value: biorhythmModel,
      builder: (context, child) => BiorhythmCard(),
    ),
    title: "Biorhythm Calculator",
  );
}

Future<void> _update() async {
  await biorhythmModel.refresh();
}

class BiorhythmModel extends ChangeNotifier {
  static const int physicalCycle = 23;
  static const int emotionalCycle = 28;
  static const int intellectualCycle = 33;
  static const String _birthdateKey = 'biorhythm_birthdate';
  static const String _selectedDateKey = 'biorhythm_selected_date';

  DateTime? _birthdate;
  DateTime? _selectedDate;
  bool _isInitialized = false;
  bool _focusInput = false;

  bool get isInitialized => _isInitialized;
  DateTime? get birthdate => _birthdate;
  DateTime? get selectedDate => _selectedDate ?? DateTime.now();
  bool get shouldFocus => _focusInput;
  bool get hasBirthdate => _birthdate != null;

  double calculateCycleValue(DateTime birthdate, DateTime targetDate, int cycleLength) {
    int days = targetDate.difference(birthdate).inDays;
    double sineValue = sin(2 * pi * days / cycleLength);
    return sineValue;
  }

  double getPhysicalValue(DateTime birthdate, DateTime targetDate) {
    return calculateCycleValue(birthdate, targetDate, physicalCycle);
  }

  double getEmotionalValue(DateTime birthdate, DateTime targetDate) {
    return calculateCycleValue(birthdate, targetDate, emotionalCycle);
  }

  double getIntellectualValue(DateTime birthdate, DateTime targetDate) {
    return calculateCycleValue(birthdate, targetDate, intellectualCycle);
  }

  String getCycleStatus(double value) {
    if (value > 0.5) return "High";
    if (value > 0) return "Rising";
    if (value < -0.5) return "Low";
    if (value < 0) return "Falling";
    return "Critical";
  }

  String getCycleEmoji(double value) {
    if (value > 0.5) return "📈";
    if (value > 0) return "⬆️";
    if (value < -0.5) return "📉";
    if (value < 0) return "⬇️";
    return "⚠️";
  }

  int getDaysInCycle(DateTime birthdate, DateTime targetDate, int cycleLength) {
    int days = targetDate.difference(birthdate).inDays;
    return days % cycleLength;
  }

  DateTime getNextCriticalDay(DateTime birthdate, DateTime targetDate, int cycleLength) {
    int days = targetDate.difference(birthdate).inDays;
    int daysInCycle = days % cycleLength;
    int halfCycle = cycleLength ~/ 2;
    
    int daysToHalf = halfCycle - daysInCycle;
    if (daysToHalf < 0) daysToHalf += cycleLength;
    
    int daysToZero = cycleLength - daysInCycle;
    
    int daysToCritical = min(daysToHalf, daysToZero);
    return targetDate.add(Duration(days: daysToCritical));
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    final birthdateStr = prefs.getString(_birthdateKey);
    if (birthdateStr != null) {
      _birthdate = DateTime.parse(birthdateStr);
    }
    
    final selectedDateStr = prefs.getString(_selectedDateKey);
    if (selectedDateStr != null) {
      _selectedDate = DateTime.parse(selectedDateStr);
    }
    
    _isInitialized = true;
    Global.loggerModel.info("Biorhythm Calculator initialized", source: "Biorhythm");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  void setBirthdate(DateTime date) {
    _birthdate = date;
    Global.loggerModel.info("Birthdate set: ${date.toIso8601String()}", source: "Biorhythm");
    _saveBirthdate();
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    Global.loggerModel.info("Selected date set: ${date.toIso8601String()}", source: "Biorhythm");
    _saveSelectedDate();
    notifyListeners();
  }

  Future<void> _saveBirthdate() async {
    final prefs = await SharedPreferences.getInstance();
    if (_birthdate != null) {
      await prefs.setString(_birthdateKey, _birthdate!.toIso8601String());
    } else {
      await prefs.remove(_birthdateKey);
    }
  }

  Future<void> _saveSelectedDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedDate != null) {
      await prefs.setString(_selectedDateKey, _selectedDate!.toIso8601String());
    } else {
      await prefs.remove(_selectedDateKey);
    }
  }

  void resetSelectedDate() {
    _selectedDate = null;
    Global.loggerModel.info("Selected date reset to today", source: "Biorhythm");
    _saveSelectedDate();
    notifyListeners();
  }

  void clear() {
    _birthdate = null;
    _selectedDate = null;
    Global.loggerModel.info("Biorhythm cleared", source: "Biorhythm");
    _saveBirthdate();
    _saveSelectedDate();
    notifyListeners();
  }

  void requestFocus() {
    _focusInput = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _focusInput = false;
      notifyListeners();
    });
  }
}

class BiorhythmCard extends StatefulWidget {
  @override
  State<BiorhythmCard> createState() => _BiorhythmCardState();
}

class _BiorhythmCardState extends State<BiorhythmCard> {
  DateTime? _localBirthdate;
  DateTime _localSelectedDate = DateTime.now();
  final _birthdateFocusNode = FocusNode();
  final _selectedDateFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final model = context.read<BiorhythmModel>();
    _localBirthdate = model.birthdate;
    _localSelectedDate = model.selectedDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _birthdateFocusNode.dispose();
    _selectedDateFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    final model = context.read<BiorhythmModel>();
    final initialDate = _localBirthdate ?? model.birthdate ?? DateTime.now().subtract(Duration(days: 365 * 25));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _localBirthdate = picked;
      });
      model.setBirthdate(picked);
    }
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final model = context.read<BiorhythmModel>();
    final initialDate = _localSelectedDate;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        _localSelectedDate = picked;
      });
      model.setSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<BiorhythmModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.waves, size: 24),
              SizedBox(width: 12),
              Text("Biorhythm Calculator: Loading..."),
            ],
          ),
        ),
      );
    }

    if (model.shouldFocus && !_birthdateFocusNode.hasFocus) {
      Future.delayed(Duration(milliseconds: 50), () {
        _selectBirthdate(context);
      });
    }

    final displayBirthdate = _localBirthdate ?? model.birthdate;
    final displayTargetDate = _localSelectedDate;

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
                    Icon(Icons.waves, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Biorhythm Calculator",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.event, size: 18),
                      onPressed: () => _selectTargetDate(context),
                      tooltip: "Select target date",
                    ),
                    IconButton(
                      icon: Icon(Icons.cake, size: 18),
                      onPressed: () => _selectBirthdate(context),
                      tooltip: "Select birthdate",
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            if (displayBirthdate == null)
              _buildEmptyState(context)
            else
              _buildBiorhythmResult(context, model, displayBirthdate, displayTargetDate),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Target: ${displayTargetDate.day}/${displayTargetDate.month}/${displayTargetDate.year}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (displayBirthdate != null)
                  TextButton(
                    onPressed: () {
                      model.resetSelectedDate();
                      setState(() {
                        _localSelectedDate = DateTime.now();
                      });
                    },
                    child: Text("Today"),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.waves_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            SizedBox(height: 8),
            Text(
              "Select a birthdate to calculate biorhythms",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiorhythmResult(BuildContext context, BiorhythmModel model, DateTime birthdate, DateTime targetDate) {
    final physical = model.getPhysicalValue(birthdate, targetDate);
    final emotional = model.getEmotionalValue(birthdate, targetDate);
    final intellectual = model.getIntellectualValue(birthdate, targetDate);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCycleRow(context, "Physical", physical, 23, Icons.fitness_center, model, birthdate, targetDate),
        SizedBox(height: 8),
        _buildCycleRow(context, "Emotional", emotional, 28, Icons.favorite, model, birthdate, targetDate),
        SizedBox(height: 8),
        _buildCycleRow(context, "Intellectual", intellectual, 33, Icons.psychology, model, birthdate, targetDate),
        SizedBox(height: 12),
        _buildSummary(context, physical, emotional, intellectual),
      ],
    );
  }

  Widget _buildCycleRow(BuildContext context, String name, double value, int cycle, IconData icon, BiorhythmModel model, DateTime birthdate, DateTime targetDate) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = ((value + 1) / 2 * 100).round();
    final daysInCycle = model.getDaysInCycle(birthdate, targetDate, cycle);
    final status = model.getCycleStatus(value);
    final emoji = model.getCycleEmoji(value);
    
    Color cycleColor;
    if (value > 0.5) {
      cycleColor = colorScheme.primary;
    } else if (value > 0) {
      cycleColor = colorScheme.tertiary;
    } else if (value < -0.5) {
      cycleColor = colorScheme.error;
    } else {
      cycleColor = colorScheme.secondary;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cycleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cycleColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("$emoji $status", style: TextStyle(fontSize: 12)),
                  ],
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (value + 1) / 2,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(cycleColor),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Day $daysInCycle/$cycle",
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      "${percentage > 50 ? '+' : ''}${percentage - 50}%",
                      style: TextStyle(fontSize: 11, color: cycleColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, double physical, double emotional, double intellectual) {
    final colorScheme = Theme.of(context).colorScheme;
    
    double average = (physical + emotional + intellectual) / 3;
    String overallStatus;
    Color overallColor;
    
    if (average > 0.3) {
      overallStatus = "Overall: High Energy";
      overallColor = colorScheme.primary;
    } else if (average > 0) {
      overallStatus = "Overall: Balanced";
      overallColor = colorScheme.tertiary;
    } else if (average < -0.3) {
      overallStatus = "Overall: Low Energy";
      overallColor = colorScheme.error;
    } else {
      overallStatus = "Overall: Transitioning";
      overallColor = colorScheme.secondary;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: overallColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: overallColor),
          SizedBox(width: 8),
          Text(
            overallStatus,
            style: TextStyle(color: overallColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}