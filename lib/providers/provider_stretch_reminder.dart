import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StretchReminderModel extends ChangeNotifier {
  Timer? _timer;
  int _intervalMinutes = 30;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  int _todayStretches = 0;
  DateTime? _lastStretchTime;
  DateTime? _sessionStartTime;
  bool _isInitialized = false;

  int get intervalMinutes => _intervalMinutes;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isRunning => _isRunning;
  int get todayStretches => _todayStretches;
  DateTime? get lastStretchTime => _lastStretchTime;
  DateTime? get sessionStartTime => _sessionStartTime;
  bool get isInitialized => _isInitialized;

  void setElapsedSecondsForTest(int seconds) {
    _elapsedSeconds = seconds;
    notifyListeners();
  }

  String get formattedElapsed {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  double get progressPercent {
    if (_intervalMinutes <= 0) return 0;
    final targetSeconds = _intervalMinutes * 60;
    return (_elapsedSeconds / targetSeconds).clamp(0.0, 1.0);
  }

  bool get needsStretch {
    return _elapsedSeconds >= (_intervalMinutes * 60);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _intervalMinutes = prefs.getInt('StretchReminder.interval') ?? 30;
    _todayStretches = prefs.getInt('StretchReminder.todayStretches') ?? 0;
    
    final lastStretchStr = prefs.getString('StretchReminder.lastStretchTime');
    if (lastStretchStr != null) {
      _lastStretchTime = DateTime.tryParse(lastStretchStr);
    }
    
    final sessionStartStr = prefs.getString('StretchReminder.sessionStartTime');
    if (sessionStartStr != null) {
      _sessionStartTime = DateTime.tryParse(sessionStartStr);
      if (_sessionStartTime != null) {
        final now = DateTime.now();
        final elapsedSinceStart = now.difference(_sessionStartTime!).inSeconds;
        _elapsedSeconds = elapsedSinceStart;
      }
    }
    
    _checkDayReset();
    _isInitialized = true;
    Global.loggerModel.info("StretchReminder initialized with interval ${_intervalMinutes}m, ${_todayStretches} stretches today", source: "StretchReminder");
    notifyListeners();
  }

  void _checkDayReset() {
    if (_lastStretchTime != null) {
      final now = DateTime.now();
      if (now.year != _lastStretchTime!.year || 
          now.month != _lastStretchTime!.month || 
          now.day != _lastStretchTime!.day) {
        _todayStretches = 0;
        _saveTodayStretches();
      }
    }
  }

  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _sessionStartTime = DateTime.now();
    _saveSessionStartTime();
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
      
      if (_elapsedSeconds >= _intervalMinutes * 60) {
        Global.loggerModel.info("Stretch reminder triggered at ${_elapsedSeconds}s", source: "StretchReminder");
      }
    });
    
    Global.loggerModel.info("Stretch reminder timer started", source: "StretchReminder");
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    Global.loggerModel.info("Stretch reminder timer stopped", source: "StretchReminder");
    notifyListeners();
  }

  void reset() {
    _elapsedSeconds = 0;
    _todayStretches++;
    _lastStretchTime = DateTime.now();
    _sessionStartTime = DateTime.now();
    
    _saveTodayStretches();
    _saveLastStretchTime();
    _saveSessionStartTime();
    
    Global.loggerModel.info("Stretch completed! Total today: ${_todayStretches}", source: "StretchReminder");
    notifyListeners();
  }

  void setInterval(int minutes) {
    if (minutes < 5 || minutes > 120) return;
    _intervalMinutes = minutes;
    _saveInterval();
    Global.loggerModel.info("Stretch interval set to ${minutes} minutes", source: "StretchReminder");
    notifyListeners();
  }

  void skipStretch() {
    _elapsedSeconds = 0;
    _sessionStartTime = DateTime.now();
    _saveSessionStartTime();
    Global.loggerModel.info("Stretch skipped", source: "StretchReminder");
    notifyListeners();
  }

  void clearStats() {
    _todayStretches = 0;
    _lastStretchTime = null;
    _elapsedSeconds = 0;
    _sessionStartTime = null;
    _saveTodayStretches();
    _saveLastStretchTime();
    _saveSessionStartTime();
    Global.loggerModel.info("Stretch stats cleared", source: "StretchReminder");
    notifyListeners();
  }

  Future<void> _saveInterval() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('StretchReminder.interval', _intervalMinutes);
  }

  Future<void> _saveTodayStretches() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('StretchReminder.todayStretches', _todayStretches);
  }

  Future<void> _saveLastStretchTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastStretchTime != null) {
      prefs.setString('StretchReminder.lastStretchTime', _lastStretchTime!.toIso8601String());
    } else {
      prefs.remove('StretchReminder.lastStretchTime');
    }
  }

  Future<void> _saveSessionStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_sessionStartTime != null) {
      prefs.setString('StretchReminder.sessionStartTime', _sessionStartTime!.toIso8601String());
    } else {
      prefs.remove('StretchReminder.sessionStartTime');
    }
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

StretchReminderModel stretchReminderModel = StretchReminderModel();

class StretchReminderCard extends StatelessWidget {
  const StretchReminderCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<StretchReminderModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new, color: colorScheme.primary),
                SizedBox(width: 8),
                Text('Stretch Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                if (model.todayStretches > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${model.todayStretches} stretches today', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            SizedBox(height: 16),
            if (!model.isInitialized)
              Center(child: CircularProgressIndicator())
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    model.formattedElapsed,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: model.needsStretch ? colorScheme.error : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: model.progressPercent,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: model.needsStretch ? colorScheme.error : colorScheme.primary,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Interval: ${model.intervalMinutes}m', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  if (model.needsStretch)
                    Text('Time to stretch!', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold))
                  else
                    Text('${model.intervalMinutes - (model.elapsedSeconds ~/ 60)}m remaining', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
              if (model.needsStretch)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: colorScheme.error),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have been sitting for ${model.intervalMinutes}+ minutes. Stretch now!',
                            style: TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!model.isRunning)
                    ElevatedButton.icon(
                      icon: Icon(Icons.play_arrow),
                      label: Text('Start'),
                      onPressed: () => model.start(),
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
                    )
                  else ...[
                    ElevatedButton.icon(
                      icon: Icon(Icons.pause),
                      label: Text('Stop'),
                      onPressed: () => model.stop(),
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.check_circle),
                      label: Text('Stretched!'),
                      onPressed: () => model.reset(),
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [10, 15, 20, 30, 45, 60].map((minutes) => 
                  ActionChip(
                    label: Text('${minutes}m'),
                    onPressed: () => model.setInterval(minutes),
                    backgroundColor: model.intervalMinutes == minutes 
                        ? colorScheme.primaryContainer 
                        : colorScheme.surfaceContainerHighest,
                  )
                ).toList(),
              ),
              if (model.todayStretches > 0) ...[
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showClearStatsDialog(context),
                      child: Text('Clear Stats'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showClearStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Statistics'),
        content: Text('Are you sure you want to clear all stretch statistics?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              stretchReminderModel.clearStats();
              Navigator.pop(context);
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}

MyProvider providerStretchReminder = MyProvider(
  name: "StretchReminder",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Stretch Reminder",
        keywords: "stretch, reminder, health, fitness, break, sit, posture, exercise, move, standup",
        action: () {
          Global.infoModel.addInfoWidget("StretchReminderCard", StretchReminderCard(), title: "Stretch Reminder");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    stretchReminderModel.init();
    Global.infoModel.addInfoWidget("StretchReminderCard", StretchReminderCard(), title: "Stretch Reminder");
  },
  update: () {
    stretchReminderModel.refresh();
  },
);