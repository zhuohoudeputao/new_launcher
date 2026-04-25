import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

PaceModel paceModel = PaceModel();

MyProvider providerPace = MyProvider(
    name: "Pace",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'PaceCalculator',
      keywords: 'pace run running calculator time distance speed marathon race',
      action: () => paceModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await paceModel.init();
  Global.infoModel.addInfoWidget(
      "PaceCalculator",
      ChangeNotifierProvider.value(
          value: paceModel,
          builder: (context, child) => PaceCard()),
      title: "Pace Calculator");
}

Future<void> _update() async {
  paceModel.refresh();
}

class PaceHistoryEntry {
  final DateTime date;
  final String mode;
  final double distance;
  final int timeMinutes;
  final int timeSeconds;
  final String unit;
  final String result;

  PaceHistoryEntry({
    required this.date,
    required this.mode,
    required this.distance,
    required this.timeMinutes,
    required this.timeSeconds,
    required this.unit,
    required this.result,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'mode': mode,
      'distance': distance,
      'timeMinutes': timeMinutes,
      'timeSeconds': timeSeconds,
      'unit': unit,
      'result': result,
    });
  }

  static PaceHistoryEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return PaceHistoryEntry(
      date: DateTime.parse(map['date'] as String),
      mode: map['mode'] as String,
      distance: (map['distance'] as num).toDouble(),
      timeMinutes: map['timeMinutes'] as int,
      timeSeconds: map['timeSeconds'] as int,
      unit: map['unit'] as String,
      result: map['result'] as String,
    );
  }
}

class PaceModel extends ChangeNotifier {
  static const int maxHistory = 10;
  static const String _storageKey = 'pace_history';

  List<PaceHistoryEntry> _history = [];
  String _mode = 'pace';
  double _distance = 5.0;
  int _timeMinutes = 25;
  int _timeSeconds = 0;
  String _unit = 'km';
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  String get mode => _mode;
  double get distance => _distance;
  int get timeMinutes => _timeMinutes;
  int get timeSeconds => _timeSeconds;
  String get unit => _unit;
  List<PaceHistoryEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;

  static const List<Map<String, dynamic>> raceDistances = [
    {'name': '5K', 'km': 5.0, 'mi': 3.10686},
    {'name': '10K', 'km': 10.0, 'mi': 6.21371},
    {'name': 'Half Marathon', 'km': 21.0975, 'mi': 13.1094},
    {'name': 'Marathon', 'km': 42.195, 'mi': 26.2188},
  ];

  int get totalSeconds => _timeMinutes * 60 + _timeSeconds;

  String get result {
    if (_distance <= 0) return 'Invalid distance';
    if (totalSeconds <= 0 && _mode != 'distance') return 'Invalid time';

    switch (_mode) {
      case 'pace':
        final paceSeconds = totalSeconds / _distance;
        final paceMin = paceSeconds ~/ 60;
        final paceSec = (paceSeconds % 60).round();
        return '${paceMin}:${paceSec.toString().padLeft(2, '0')} min/${_unit}';
      case 'time':
        final totalPaceSeconds = totalSeconds;
        final totalTimeSeconds = _distance * totalPaceSeconds;
        final hours = totalTimeSeconds ~/ 3600;
        final minutes = (totalTimeSeconds % 3600) ~/ 60;
        final seconds = (totalTimeSeconds % 60).round();
        if (hours > 0) {
          return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        }
        return '${minutes}:${seconds.toString().padLeft(2, '0')}';
      case 'distance':
        final totalPaceSeconds = totalSeconds;
        final dist = totalSeconds / totalPaceSeconds;
        return '${dist.toStringAsFixed(2)} ${_unit}';
      default:
        return '';
    }
  }

  String get modeLabel {
    switch (_mode) {
      case 'pace':
        return 'Calculate Pace';
      case 'time':
        return 'Calculate Time';
      case 'distance':
        return 'Calculate Distance';
      default:
        return '';
    }
  }

  String get inputLabel1 {
    switch (_mode) {
      case 'pace':
        return 'Distance (${_unit})';
      case 'time':
        return 'Distance (${_unit})';
      case 'distance':
        return 'Pace (min/${_unit})';
      default:
        return '';
    }
  }

  String get inputLabel2 {
    switch (_mode) {
      case 'pace':
        return 'Time';
      case 'time':
        return 'Pace (min/${_unit})';
      case 'distance':
        return 'Time';
      default:
        return '';
    }
  }

  List<String> get predictedTimes {
    if (_mode != 'pace' || _distance <= 0 || totalSeconds <= 0) return [];

    final paceSecondsPerKm = _unit == 'km'
        ? totalSeconds / _distance
        : totalSeconds / (_distance * 1.60934);

    return raceDistances.map((race) {
      final raceKm = race['km'] as double;
      final predictedSeconds = raceKm * paceSecondsPerKm;
      final hours = predictedSeconds ~/ 3600;
      final minutes = (predictedSeconds % 3600) ~/ 60;
      final seconds = (predictedSeconds % 60).round();
      final timeStr = hours > 0
          ? '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
          : '${minutes}:${seconds.toString().padLeft(2, '0')}';
      return '${race['name']}: ${timeStr}';
    }).toList();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => PaceHistoryEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Pace Calculator initialized with ${_history.length} entries", source: "Pace");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Pace Calculator refreshed", source: "Pace");
  }

  void setMode(String mode) {
    _mode = mode;
    notifyListeners();
  }

  void setDistance(double value) {
    _distance = value;
    notifyListeners();
  }

  void setTimeMinutes(int value) {
    _timeMinutes = value;
    notifyListeners();
  }

  void setTimeSeconds(int value) {
    _timeSeconds = value;
    notifyListeners();
  }

  void setUnit(String unit) {
    _unit = unit;
    notifyListeners();
  }

  void clear() {
    _distance = 5.0;
    _timeMinutes = 25;
    _timeSeconds = 0;
    _unit = 'km';
    notifyListeners();
    Global.loggerModel.info("Pace Calculator cleared", source: "Pace");
  }

  void saveToHistory() {
    if (_distance <= 0) return;
    if (totalSeconds <= 0 && _mode != 'distance') return;

    _history.insert(0, PaceHistoryEntry(
      date: DateTime.now(),
      mode: _mode,
      distance: _distance,
      timeMinutes: _timeMinutes,
      timeSeconds: _timeSeconds,
      unit: _unit,
      result: result,
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }
    _save();
    notifyListeners();
    Global.loggerModel.info("Pace calculation saved to history", source: "Pace");
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void loadFromHistory(PaceHistoryEntry entry) {
    _mode = entry.mode;
    _distance = entry.distance;
    _timeMinutes = entry.timeMinutes;
    _timeSeconds = entry.timeSeconds;
    _unit = entry.unit;
    notifyListeners();
    Global.loggerModel.info("Loaded pace from history", source: "Pace");
  }

  void clearHistory() {
    _history.clear();
    _save();
    notifyListeners();
    Global.loggerModel.info("Pace history cleared", source: "Pace");
  }
}

class PaceCard extends StatefulWidget {
  @override
  State<PaceCard> createState() => _PaceCardState();
}

class _PaceCardState extends State<PaceCard> {
  bool _showHistory = false;
  bool _showPredictions = false;
  final TextEditingController _distanceController = TextEditingController(text: '5.0');
  final TextEditingController _minutesController = TextEditingController(text: '25');
  final TextEditingController _secondsController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _distanceController.addListener(_onDistanceChanged);
    _minutesController.addListener(_onMinutesChanged);
    _secondsController.addListener(_onSecondsChanged);
  }

  @override
  void dispose() {
    _distanceController.removeListener(_onDistanceChanged);
    _minutesController.removeListener(_onMinutesChanged);
    _secondsController.removeListener(_onSecondsChanged);
    _distanceController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _onDistanceChanged() {
    final value = double.tryParse(_distanceController.text);
    if (value != null) {
      context.read<PaceModel>().setDistance(value);
    } else if (_distanceController.text.isEmpty) {
      context.read<PaceModel>().setDistance(0);
    }
  }

  void _onMinutesChanged() {
    final value = int.tryParse(_minutesController.text);
    if (value != null) {
      context.read<PaceModel>().setTimeMinutes(value);
    } else if (_minutesController.text.isEmpty) {
      context.read<PaceModel>().setTimeMinutes(0);
    }
  }

  void _onSecondsChanged() {
    final value = int.tryParse(_secondsController.text);
    if (value != null && value < 60) {
      context.read<PaceModel>().setTimeSeconds(value);
    } else if (_secondsController.text.isEmpty) {
      context.read<PaceModel>().setTimeSeconds(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pace = context.watch<PaceModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!pace.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.timer, size: 24),
              SizedBox(width: 12),
              Text("Pace Calculator: Loading..."),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pace Calculator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pace.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.timer : Icons.history, size: 18),
                        onPressed: () => setState(() {
                          _showHistory = !_showHistory;
                          if (_showHistory) _showPredictions = false;
                        }),
                        tooltip: _showHistory ? "Calculator" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (pace.hasHistory)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearHistoryConfirmation(context),
                        tooltip: "Clear history",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (_showHistory) _buildHistoryView(pace)
            else _buildCalculatorView(pace),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorView(PaceModel pace) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeSelector(pace),
        SizedBox(height: 8),
        _buildUnitSelector(pace),
        SizedBox(height: 8),
        _buildInputs(pace),
        SizedBox(height: 12),
        _buildResult(pace),
        if (pace.mode == 'pace' && pace.predictedTimes.isNotEmpty && _showPredictions)
          _buildPredictions(pace),
        if (pace.mode == 'pace' && pace.distance > 0 && pace.totalSeconds > 0)
          _buildPredictionsToggle(),
        SizedBox(height: 8),
        _buildActionButtons(pace),
      ],
    );
  }

  Widget _buildModeSelector(PaceModel pace) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'pace', label: Text('Pace')),
        ButtonSegment(value: 'time', label: Text('Time')),
        ButtonSegment(value: 'distance', label: Text('Distance')),
      ],
      selected: {pace.mode},
      onSelectionChanged: (Set<String> selection) {
        context.read<PaceModel>().setMode(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildUnitSelector(PaceModel pace) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'km', label: Text('km')),
        ButtonSegment(value: 'mi', label: Text('mile')),
      ],
      selected: {pace.unit},
      onSelectionChanged: (Set<String> selection) {
        context.read<PaceModel>().setUnit(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildInputs(PaceModel pace) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _distanceController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: pace.inputLabel1,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _secondsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Seconds',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult(PaceModel pace) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pace.modeLabel,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            pace.result,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: pace.result.contains('Invalid') ? colorScheme.error : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsToggle() {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text('Race Predictions'),
      selected: _showPredictions,
      onSelected: (selected) => setState(() => _showPredictions = selected),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildPredictions(PaceModel pace) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Predicted Race Times',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          ...pace.predictedTimes.map((time) => Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Text(
              time,
              style: TextStyle(fontSize: 12),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PaceModel pace) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: pace.distance > 0 && pace.totalSeconds > 0 ? () => pace.saveToHistory() : null,
          icon: Icon(Icons.save, size: 18),
          label: Text("Save"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            pace.clear();
            _distanceController.text = '5.0';
            _minutesController.text = '25';
            _secondsController.text = '0';
          },
          icon: Icon(Icons.clear_all, size: 18),
          label: Text("Clear"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(PaceModel pace) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: pace.history.length,
        itemBuilder: (context, index) {
          final entry = pace.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.timer, size: 20),
            title: Text('${entry.mode}: ${entry.result}'),
            subtitle: Text(
              '${entry.distance} ${entry.unit}, ${entry.timeMinutes}:${entry.timeSeconds.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              context.read<PaceModel>().loadFromHistory(entry);
              _distanceController.text = entry.distance.toString();
              _minutesController.text = entry.timeMinutes.toString();
              _secondsController.text = entry.timeSeconds.toString();
              setState(() => _showHistory = false);
            },
          );
        },
      ),
    );
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all pace calculation history?"),
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
      context.read<PaceModel>().clearHistory();
      setState(() => _showHistory = false);
    }
  }
}