import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

BmiModel bmiModel = BmiModel();

MyProvider providerBMI = MyProvider(
    name: "BMI",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Calculate BMI',
      keywords: 'bmi body mass index weight height health calculator metric imperial',
      action: () {
        Global.infoModel.addInfo("CalculateBMI", "BMI Calculator",
            subtitle: "Calculate your Body Mass Index",
            icon: Icon(Icons.monitor_weight),
            onTap: () => bmiModel.requestFocus());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await bmiModel.init();
  Global.infoModel.addInfoWidget(
      "BMI",
      ChangeNotifierProvider.value(
          value: bmiModel,
          builder: (context, child) => BmiCard()),
      title: "BMI Calculator");
}

Future<void> _update() async {
  await bmiModel.refresh();
}

class BmiEntry {
  final DateTime date;
  final double bmi;
  final double weight;
  final String unit;
  final double height;

  BmiEntry({
    required this.date,
    required this.bmi,
    required this.weight,
    required this.unit,
    required this.height,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'bmi': bmi,
      'weight': weight,
      'unit': unit,
      'height': height,
    });
  }

  static BmiEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return BmiEntry(
      date: DateTime.parse(map['date'] as String),
      bmi: (map['bmi'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      unit: map['unit'] as String,
      height: (map['height'] as num).toDouble(),
    );
  }
}

class BmiModel extends ChangeNotifier {
  static const int maxHistory = 10;
  static const String _storageKey = 'bmi_entries';
  static const String _unitKey = 'bmi_unit';
  static const String defaultUnit = 'metric';

  List<BmiEntry> _history = [];
  String _unit = defaultUnit;
  double _weight = 0;
  double _heightMetric = 0;
  int _heightFeet = 0;
  int _heightInches = 0;
  double? _calculatedBmi;
  bool _isInitialized = false;
  bool _focusInput = false;

  bool get isInitialized => _isInitialized;
  String get unit => _unit;
  double get weight => _weight;
  double get heightMetric => _heightMetric;
  int get heightFeet => _heightFeet;
  int get heightInches => _heightInches;
  double? get calculatedBmi => _calculatedBmi;
  List<BmiEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  bool get shouldFocus => _focusInput;

  String getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color getBmiColor(double bmi, BuildContext context) {
    if (bmi < 18.5) return Theme.of(context).colorScheme.tertiary;
    if (bmi < 25) return Theme.of(context).colorScheme.primary;
    if (bmi < 30) return Theme.of(context).colorScheme.secondary;
    return Theme.of(context).colorScheme.error;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _unit = prefs.getString(_unitKey) ?? defaultUnit;
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => BmiEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("BMI Calculator initialized with ${_history.length} entries", source: "BMI");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  void setUnit(String unit) {
    _unit = unit;
    _calculatedBmi = null;
    Global.loggerModel.info("BMI unit set to $unit", source: "BMI");
    _saveUnit();
    notifyListeners();
  }

  Future<void> _saveUnit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, _unit);
  }

  void setWeight(double weight) {
    _weight = weight;
    _calculateBmi();
    notifyListeners();
  }

  void setHeightMetric(double height) {
    _heightMetric = height;
    _calculateBmi();
    notifyListeners();
  }

  void setHeightFeet(int feet) {
    _heightFeet = feet;
    _calculateBmi();
    notifyListeners();
  }

  void setHeightInches(int inches) {
    _heightInches = inches;
    _calculateBmi();
    notifyListeners();
  }

  void _calculateBmi() {
    if (_unit == 'metric') {
      if (_weight > 0 && _heightMetric > 0) {
        double heightM = _heightMetric / 100;
        _calculatedBmi = _weight / (heightM * heightM);
      } else {
        _calculatedBmi = null;
      }
    } else {
      double totalInches = (_heightFeet * 12.0) + _heightInches;
      if (_weight > 0 && totalInches > 0) {
        _calculatedBmi = (_weight * 703) / (totalInches * totalInches);
      } else {
        _calculatedBmi = null;
      }
    }
  }

  void saveToHistory() {
    if (_calculatedBmi == null || _weight <= 0) return;

    double height = _unit == 'metric' ? _heightMetric : (_heightFeet * 12.0) + _heightInches;
    
    _history.insert(0, BmiEntry(
      date: DateTime.now(),
      bmi: _calculatedBmi!,
      weight: _weight,
      unit: _unit,
      height: height,
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }

    Global.loggerModel.info("BMI saved to history: ${_calculatedBmi!.toStringAsFixed(1)}", source: "BMI");
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void loadFromHistory(BmiEntry entry) {
    _unit = entry.unit;
    _weight = entry.weight;
    if (entry.unit == 'metric') {
      _heightMetric = entry.height;
    } else {
      _heightFeet = (entry.height / 12).floor();
      _heightInches = ((entry.height % 12).round()).clamp(0, 11);
    }
    _calculatedBmi = entry.bmi;
    Global.loggerModel.info("Loaded BMI from history", source: "BMI");
    _saveUnit();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("BMI history cleared", source: "BMI");
    _save();
    notifyListeners();
  }

  void clear() {
    _weight = 0;
    _heightMetric = 0;
    _heightFeet = 0;
    _heightInches = 0;
    _calculatedBmi = null;
    Global.loggerModel.info("BMI cleared", source: "BMI");
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

class BmiCard extends StatefulWidget {
  @override
  State<BmiCard> createState() => _BmiCardState();
}

class _BmiCardState extends State<BmiCard> {
  final _weightController = TextEditingController();
  final _heightMetricController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _weightFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onWeightChanged);
    _heightMetricController.addListener(_onHeightMetricChanged);
    _feetController.addListener(_onFeetChanged);
    _inchesController.addListener(_onInchesChanged);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightMetricController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  void _onWeightChanged() {
    final bmi = context.read<BmiModel>();
    final value = double.tryParse(_weightController.text) ?? 0;
    bmi.setWeight(value);
  }

  void _onHeightMetricChanged() {
    final bmi = context.read<BmiModel>();
    final value = double.tryParse(_heightMetricController.text) ?? 0;
    bmi.setHeightMetric(value);
  }

  void _onFeetChanged() {
    final bmi = context.read<BmiModel>();
    final value = int.tryParse(_feetController.text) ?? 0;
    bmi.setHeightFeet(value);
  }

  void _onInchesChanged() {
    final bmi = context.read<BmiModel>();
    final value = int.tryParse(_inchesController.text) ?? 0;
    bmi.setHeightInches(value);
  }

  @override
  Widget build(BuildContext context) {
    final bmi = context.watch<BmiModel>();

    if (!bmi.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.monitor_weight, size: 24),
              SizedBox(width: 12),
              Text("BMI Calculator: Loading..."),
            ],
          ),
        ),
      );
    }

    if (bmi.shouldFocus && !_weightFocusNode.hasFocus) {
      Future.delayed(Duration(milliseconds: 50), () {
        _weightFocusNode.requestFocus();
      });
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
                  Icon(Icons.monitor_weight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "BMI Calculator",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (bmi.calculatedBmi != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
color: bmi.getBmiColor(bmi.calculatedBmi!, context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bmi.getBmiCategory(bmi.calculatedBmi!),
                        style: TextStyle(
                          fontSize: 12,
                          color: bmi.getBmiColor(bmi.calculatedBmi!, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'metric',
                    label: Text('Metric'),
                    icon: Icon(Icons.straighten, size: 16),
                  ),
                  ButtonSegment(
                    value: 'imperial',
                    label: Text('Imperial'),
                    icon: Icon(Icons.height, size: 16),
                  ),
                ],
                selected: {bmi.unit},
                onSelectionChanged: (Set<String> newSelection) {
                  final newUnit = newSelection.first;
                  bmi.setUnit(newUnit);
                  _weightController.clear();
                  _heightMetricController.clear();
                  _feetController.clear();
                  _inchesController.clear();
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
              SizedBox(height: 12),
              if (bmi.unit == 'metric')
                _buildMetricInputs(context, bmi)
              else
                _buildImperialInputs(context, bmi),
              if (bmi.calculatedBmi != null)
                _buildBmiResult(context, bmi),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () {
                      bmi.clear();
                      _weightController.clear();
                      _heightMetricController.clear();
                      _feetController.clear();
                      _inchesController.clear();
                    },
                    tooltip: "Clear",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: bmi.calculatedBmi != null ? () => bmi.saveToHistory() : null,
                    icon: Icon(Icons.save, size: 18),
                    label: Text("Save"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (bmi.hasHistory)
                    IconButton(
                      icon: Icon(Icons.history, size: 20),
                      onPressed: () => _showHistoryDialog(context, bmi),
                      tooltip: "History",
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricInputs(BuildContext context, BmiModel bmi) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                focusNode: _weightFocusNode,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _heightMetricController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImperialInputs(BuildContext context, BmiModel bmi) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                focusNode: _weightFocusNode,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight (lb)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _feetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Feet',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _inchesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Inches',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBmiResult(BuildContext context, BmiModel bmi) {
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bmi.getBmiColor(bmi.calculatedBmi!, context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "BMI",
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  bmi.calculatedBmi!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: bmi.getBmiColor(bmi.calculatedBmi!, context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, BmiModel bmi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text("BMI History"),
            Spacer(),
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text("Clear History"),
                    content: Text("Clear all BMI history entries?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          bmi.clearHistory();
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: Text("Clear"),
                      ),
                    ],
                  ),
                );
              },
              tooltip: "Clear all",
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: bmi.history.length,
            itemBuilder: (context, index) {
              final entry = bmi.history[index];
              final dateStr = "${entry.date.day}/${entry.date.month}/${entry.date.year}";
              final weightStr = entry.unit == 'metric' 
                  ? "${entry.weight.toStringAsFixed(1)} kg"
                  : "${entry.weight.toStringAsFixed(1)} lb";
              final heightStr = entry.unit == 'metric'
                  ? "${entry.height.toStringAsFixed(1)} cm"
                  : "${(entry.height / 12).floor()}ft ${(entry.height % 12).round()}in";
              
              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bmi.getBmiColor(entry.bmi, context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      entry.bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: bmi.getBmiColor(entry.bmi, context),
                      ),
                    ),
                  ),
                ),
                title: Text("${entry.bmi.toStringAsFixed(1)} - ${bmi.getBmiCategory(entry.bmi)}"),
                subtitle: Text("$weightStr, $heightStr • $dateStr"),
                onTap: () {
                  bmi.loadFromHistory(entry);
                  if (entry.unit == 'metric') {
                    _weightController.text = entry.weight.toStringAsFixed(1);
                    _heightMetricController.text = entry.height.toStringAsFixed(1);
                    _feetController.clear();
                    _inchesController.clear();
                  } else {
                    _weightController.text = entry.weight.toStringAsFixed(1);
                    _heightMetricController.clear();
                    _feetController.text = ((entry.height / 12).floor()).toString();
                    _inchesController.text = ((entry.height % 12).round()).toString();
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }
}