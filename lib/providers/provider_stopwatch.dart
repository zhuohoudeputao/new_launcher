import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

StopwatchModel stopwatchModel = StopwatchModel();

MyProvider providerStopwatch = MyProvider(
    name: "Stopwatch",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Stopwatch',
      keywords: 'stopwatch stopwatch lap elapsed time clock',
      action: () => stopwatchModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  stopwatchModel.init();
  Global.infoModel.addInfoWidget(
      "Stopwatch",
      ChangeNotifierProvider.value(
          value: stopwatchModel,
          builder: (context, child) => StopwatchCard()),
      title: "Stopwatch");
}

Future<void> _update() async {
  stopwatchModel.refresh();
}

class LapEntry {
  final int lapNumber;
  final int elapsedMilliseconds;
  final int lapMilliseconds;
  final DateTime timestamp;

  LapEntry({
    required this.lapNumber,
    required this.elapsedMilliseconds,
    required this.lapMilliseconds,
    required this.timestamp,
  });

  String get elapsedDisplay {
    return _formatTime(elapsedMilliseconds);
  }

  String get lapDisplay {
    return _formatTime(lapMilliseconds);
  }

  static String _formatTime(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final ms = (milliseconds % 1000) ~/ 10;
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }
}

class StopwatchModel extends ChangeNotifier {
  int _elapsedMilliseconds = 0;
  int _lastLapMilliseconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isInitialized = false;
  final List<LapEntry> _laps = [];
  static const int maxLaps = 20;

  int get elapsedMilliseconds => _elapsedMilliseconds;
  bool get isRunning => _isRunning;
  bool get isInitialized => _isInitialized;
  List<LapEntry> get laps => List.unmodifiable(_laps);
  bool get hasLaps => _laps.isNotEmpty;
  bool get isStarted => _elapsedMilliseconds > 0 || _isRunning;

  String get displayTime {
    final totalSeconds = _elapsedMilliseconds ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final ms = (_elapsedMilliseconds % 1000) ~/ 10;
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("Stopwatch initialized", source: "Stopwatch");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Stopwatch refreshed", source: "Stopwatch");
  }

  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      _elapsedMilliseconds += 50;
      notifyListeners();
    });
    
    Global.loggerModel.info("Stopwatch started", source: "Stopwatch");
    notifyListeners();
  }

  void pause() {
    if (!_isRunning) return;
    
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    
    Global.loggerModel.info("Stopwatch paused at ${displayTime}", source: "Stopwatch");
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _elapsedMilliseconds = 0;
    _lastLapMilliseconds = 0;
    _isRunning = false;
    _laps.clear();
    
    Global.loggerModel.info("Stopwatch reset", source: "Stopwatch");
    notifyListeners();
  }

  void lap() {
    if (!_isRunning && _elapsedMilliseconds == 0) return;
    
    if (_laps.length >= maxLaps) {
      Global.loggerModel.warning("Lap limit reached (max: $maxLaps)", source: "Stopwatch");
      return;
    }
    
    final lapMilliseconds = _elapsedMilliseconds - _lastLapMilliseconds;
    final entry = LapEntry(
      lapNumber: _laps.length + 1,
      elapsedMilliseconds: _elapsedMilliseconds,
      lapMilliseconds: lapMilliseconds,
      timestamp: DateTime.now(),
    );
    
    _laps.insert(0, entry);
    _lastLapMilliseconds = _elapsedMilliseconds;
    
    Global.loggerModel.info("Lap ${entry.lapNumber} recorded: ${entry.lapDisplay}", source: "Stopwatch");
    notifyListeners();
  }

  void clearLaps() {
    _laps.clear();
    _lastLapMilliseconds = _elapsedMilliseconds;
    
    Global.loggerModel.info("Laps cleared", source: "Stopwatch");
    notifyListeners();
  }
}

class StopwatchCard extends StatefulWidget {
  @override
  State<StopwatchCard> createState() => _StopwatchCardState();
}

class _StopwatchCardState extends State<StopwatchCard> {
  bool _showLaps = false;

  @override
  Widget build(BuildContext context) {
    final stopwatch = context.watch<StopwatchModel>();
    final colorScheme = Theme.of(context).colorScheme;
    
    if (!stopwatch.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 24),
              SizedBox(width: 12),
              Text("Stopwatch: Loading..."),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Stopwatch",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stopwatch.hasLaps)
                      IconButton(
                        icon: Icon(_showLaps ? Icons.timer_outlined : Icons.list, size: 18),
                        onPressed: () => setState(() => _showLaps = !_showLaps),
                        tooltip: _showLaps ? "Stopwatch" : "Laps",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (stopwatch.isStarted)
                      IconButton(
                        icon: Icon(Icons.refresh, size: 18),
                        onPressed: () => _showResetConfirmation(context),
                        tooltip: "Reset",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (_showLaps) _buildLapsView(stopwatch)
            else _buildStopwatchView(stopwatch),
          ],
        ),
      ),
    );
  }

  Widget _buildStopwatchView(StopwatchModel stopwatch) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            stopwatch.displayTime,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (stopwatch.isRunning)
              ElevatedButton.icon(
                icon: Icon(Icons.pause, size: 18),
                label: Text("Pause"),
                onPressed: stopwatch.pause,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                ),
              )
            else if (stopwatch.isStarted)
              ElevatedButton.icon(
                icon: Icon(Icons.play_arrow, size: 18),
                label: Text("Resume"),
                onPressed: stopwatch.start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                ),
              )
            else
              ElevatedButton.icon(
                icon: Icon(Icons.play_arrow, size: 18),
                label: Text("Start"),
                onPressed: stopwatch.start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                ),
              ),
            ElevatedButton.icon(
              icon: Icon(Icons.flag, size: 18),
              label: Text("Lap"),
              onPressed: stopwatch.isRunning || stopwatch.isStarted ? stopwatch.lap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLapsView(StopwatchModel stopwatch) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: stopwatch.laps.length,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final lap = stopwatch.laps[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Text(
              "#${lap.lapNumber}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              lap.lapDisplay,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              lap.elapsedDisplay,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showResetConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reset Stopwatch"),
        content: Text("This will reset the stopwatch and clear all laps."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Reset"),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      context.read<StopwatchModel>().reset();
    }
  }
}