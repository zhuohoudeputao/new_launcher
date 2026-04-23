import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

PomodoroModel pomodoroModel = PomodoroModel();

MyProvider providerPomodoro = MyProvider(
  name: "Pomodoro",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Pomodoro Timer',
      keywords: 'pomodoro timer productivity work break focus session',
      action: () {
        Global.infoModel.addInfo("PomodoroTimer", "Pomodoro Timer",
            subtitle: "Start a productivity session",
            icon: Icon(Icons.timer),
            onTap: () {});
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await pomodoroModel.init();
  Global.infoModel.addInfoWidget(
    "Pomodoro",
    ChangeNotifierProvider.value(
      value: pomodoroModel,
      builder: (context, child) => PomodoroCard(),
    ),
    title: "Pomodoro Timer",
  );
}

Future<void> _update() async {
  await pomodoroModel.refresh();
}

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroSession {
  final DateTime startTime;
  final PomodoroPhase phase;
  final int durationMinutes;

  PomodoroSession({
    required this.startTime,
    required this.phase,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'phase': phase.index,
    'durationMinutes': durationMinutes,
  };

  factory PomodoroSession.fromJson(Map<String, dynamic> json) => PomodoroSession(
    startTime: DateTime.parse(json['startTime'] as String),
    phase: PomodoroPhase.values[json['phase'] as int],
    durationMinutes: json['durationMinutes'] as int,
  );
}

class PomodoroModel extends ChangeNotifier {
  static const int defaultWorkDuration = 25;
  static const int defaultShortBreakDuration = 5;
  static const int defaultLongBreakDuration = 15;
  static const int sessionsBeforeLongBreak = 4;

  int workDuration = defaultWorkDuration;
  int shortBreakDuration = defaultShortBreakDuration;
  int longBreakDuration = defaultLongBreakDuration;

  int completedSessions = 0;
  PomodoroPhase currentPhase = PomodoroPhase.work;
  bool isRunning = false;
  bool isPaused = false;
  int remainingSeconds = 0;

  List<PomodoroSession> _sessionHistory = [];
  static const int maxHistoryEntries = 20;
  static const String _historyKey = 'Pomodoro.History';
  static const String _settingsKey = 'Pomodoro.Settings';
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  Timer? _timer;
  bool _disposed = false;

  List<PomodoroSession> get sessionHistory => List.unmodifiable(_sessionHistory);
  int get historyLength => _sessionHistory.length;
  bool get isInitialized => _isInitialized;
  bool get hasHistory => _sessionHistory.isNotEmpty;
  int get currentPhaseDuration {
    switch (currentPhase) {
      case PomodoroPhase.work:
        return workDuration;
      case PomodoroPhase.shortBreak:
        return shortBreakDuration;
      case PomodoroPhase.longBreak:
        return longBreakDuration;
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    await _loadHistory();
    remainingSeconds = workDuration * 60;
    _isInitialized = true;
    Global.loggerModel.info("Pomodoro initialized", source: "Pomodoro");
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        final parts = settingsJson.split(',');
        if (parts.length == 3) {
          workDuration = int.tryParse(parts[0]) ?? defaultWorkDuration;
          shortBreakDuration = int.tryParse(parts[1]) ?? defaultShortBreakDuration;
          longBreakDuration = int.tryParse(parts[2]) ?? defaultLongBreakDuration;
        }
      } catch (e) {
        Global.loggerModel.error("Failed to load settings: $e", source: "Pomodoro");
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final settingsJson = '$workDuration,$shortBreakDuration,$longBreakDuration';
      await prefs.setString(_settingsKey, settingsJson);
      Global.loggerModel.info("Saved settings", source: "Pomodoro");
    } catch (e) {
      Global.loggerModel.error("Failed to save settings: $e", source: "Pomodoro");
    }
  }

  Future<void> _loadHistory() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final historyJson = prefs.getStringList(_historyKey);
    if (historyJson != null) {
      try {
        _sessionHistory = historyJson.map((json) {
          final parts = json.split('|');
          return PomodoroSession(
            startTime: DateTime.parse(parts[0]),
            phase: PomodoroPhase.values[int.parse(parts[1])],
            durationMinutes: int.parse(parts[2]),
          );
        }).toList();
      } catch (e) {
        _sessionHistory = [];
        Global.loggerModel.error("Failed to load history: $e", source: "Pomodoro");
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final historyJson = _sessionHistory.map((s) =>
        '${s.startTime.toIso8601String()}|${s.phase.index}|${s.durationMinutes}'
      ).toList();
      await prefs.setStringList(_historyKey, historyJson);
      Global.loggerModel.info("Saved ${_sessionHistory.length} session history", source: "Pomodoro");
    } catch (e) {
      Global.loggerModel.error("Failed to save history: $e", source: "Pomodoro");
    }
  }

  Future<void> refresh() async {
    await _loadSettings();
    await _loadHistory();
    notifyListeners();
    Global.loggerModel.info("Pomodoro refreshed", source: "Pomodoro");
  }

  void start() {
    if (isRunning) return;
    isRunning = true;
    isPaused = false;
    _startTimer();
    Global.loggerModel.info("Pomodoro started: ${currentPhase.name}", source: "Pomodoro");
    notifyListeners();
  }

  void pause() {
    if (!isRunning || isPaused) return;
    isPaused = true;
    _timer?.cancel();
    Global.loggerModel.info("Pomodoro paused", source: "Pomodoro");
    notifyListeners();
  }

  void resume() {
    if (!isRunning || !isPaused) return;
    isPaused = false;
    _startTimer();
    Global.loggerModel.info("Pomodoro resumed", source: "Pomodoro");
    notifyListeners();
  }

  void stop() {
    isRunning = false;
    isPaused = false;
    _timer?.cancel();
    remainingSeconds = currentPhaseDuration * 60;
    Global.loggerModel.info("Pomodoro stopped", source: "Pomodoro");
    notifyListeners();
  }

  void skip() {
    _timer?.cancel();
    _transitionToNextPhase();
    Global.loggerModel.info("Pomodoro skipped", source: "Pomodoro");
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) return;
      if (isPaused) return;

      remainingSeconds--;
      notifyListeners();

      if (remainingSeconds <= 0) {
        _timer?.cancel();
        _completePhase();
      }
    });
  }

  void _completePhase() {
    final session = PomodoroSession(
      startTime: DateTime.now(),
      phase: currentPhase,
      durationMinutes: currentPhaseDuration,
    );

    _sessionHistory.insert(0, session);
    if (_sessionHistory.length > maxHistoryEntries) {
      _sessionHistory.removeLast();
    }

    if (currentPhase == PomodoroPhase.work) {
      completedSessions++;
      _saveHistory();
    }

    _transitionToNextPhase();
    Global.loggerModel.info("Phase completed: ${currentPhase.name}", source: "Pomodoro");
  }

  void _transitionToNextPhase() {
    if (currentPhase == PomodoroPhase.work) {
      if (completedSessions % sessionsBeforeLongBreak == 0) {
        currentPhase = PomodoroPhase.longBreak;
        remainingSeconds = longBreakDuration * 60;
      } else {
        currentPhase = PomodoroPhase.shortBreak;
        remainingSeconds = shortBreakDuration * 60;
      }
    } else {
      currentPhase = PomodoroPhase.work;
      remainingSeconds = workDuration * 60;
    }

    if (isRunning && !isPaused) {
      _startTimer();
    }
    notifyListeners();
  }

  void resetCompletedSessions() {
    completedSessions = 0;
    Global.loggerModel.info("Completed sessions reset", source: "Pomodoro");
    notifyListeners();
  }

  void clearHistory() {
    _sessionHistory.clear();
    _saveHistory();
    Global.loggerModel.info("History cleared", source: "Pomodoro");
    notifyListeners();
  }

  void addTestSession(PomodoroSession session) {
    _sessionHistory.insert(0, session);
    if (_sessionHistory.length > maxHistoryEntries) {
      _sessionHistory.removeLast();
    }
    notifyListeners();
  }

  void updateSettings(int work, int shortBreak, int longBreak) {
    workDuration = work;
    shortBreakDuration = shortBreak;
    longBreakDuration = longBreak;
    if (!isRunning) {
      remainingSeconds = currentPhaseDuration * 60;
    }
    _saveSettings();
    Global.loggerModel.info("Settings updated: $work/$shortBreak/$longBreak", source: "Pomodoro");
    notifyListeners();
  }

  String formatTime() {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double getProgress() {
    final totalSeconds = currentPhaseDuration * 60;
    if (totalSeconds <= 0) return 0;
    return (totalSeconds - remainingSeconds) / totalSeconds;
  }

  String getPhaseLabel() {
    switch (currentPhase) {
      case PomodoroPhase.work:
        return "Work";
      case PomodoroPhase.shortBreak:
        return "Short Break";
      case PomodoroPhase.longBreak:
        return "Long Break";
    }
  }

  IconData getPhaseIcon() {
    switch (currentPhase) {
      case PomodoroPhase.work:
        return Icons.work;
      case PomodoroPhase.shortBreak:
        return Icons.coffee;
      case PomodoroPhase.longBreak:
        return Icons.weekend;
    }
  }

  Color getPhaseColor(ColorScheme colorScheme) {
    switch (currentPhase) {
      case PomodoroPhase.work:
        return colorScheme.primary;
      case PomodoroPhase.shortBreak:
        return colorScheme.tertiary;
      case PomodoroPhase.longBreak:
        return colorScheme.secondary;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class PomodoroCard extends StatefulWidget {
  @override
  State<PomodoroCard> createState() => _PomodoroCardState();
}

class _PomodoroCardState extends State<PomodoroCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!pomodoro.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.timer, size: 24),
              SizedBox(width: 12),
              Text("Pomodoro: Loading..."),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(pomodoro.getPhaseIcon(), size: 20, color: pomodoro.getPhaseColor(colorScheme)),
                    SizedBox(width: 8),
                    Text(
                      pomodoro.getPhaseLabel(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pomodoro.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.timer : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Show timer" : "Show history",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, size: 18),
                      onPressed: () => _showSettingsDialog(context),
                      tooltip: "Settings",
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_showHistory)
              _buildHistoryView(context, pomodoro)
            else
              _buildTimerView(context, pomodoro),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerView(BuildContext context, PomodoroModel pomodoro) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 12),
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: pomodoro.getProgress(),
                strokeWidth: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: pomodoro.getPhaseColor(colorScheme),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pomodoro.formatTime(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "#${pomodoro.completedSessions}",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!pomodoro.isRunning)
              ElevatedButton.icon(
                onPressed: pomodoro.start,
                icon: Icon(Icons.play_arrow, size: 18),
                label: Text("Start"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pomodoro.getPhaseColor(colorScheme),
                  foregroundColor: colorScheme.onPrimary,
                ),
              )
            else if (pomodoro.isPaused)
              ElevatedButton.icon(
                onPressed: pomodoro.resume,
                icon: Icon(Icons.play_arrow, size: 18),
                label: Text("Resume"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pomodoro.getPhaseColor(colorScheme),
                  foregroundColor: colorScheme.onPrimary,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: pomodoro.pause,
                icon: Icon(Icons.pause, size: 18),
                label: Text("Pause"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  foregroundColor: colorScheme.onSurface,
                ),
              ),
            SizedBox(width: 8),
            IconButton(
              onPressed: pomodoro.skip,
              icon: Icon(Icons.skip_next, size: 18),
              tooltip: "Skip",
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              onPressed: pomodoro.isRunning ? pomodoro.stop : pomodoro.resetCompletedSessions,
              icon: Icon(Icons.refresh, size: 18),
              tooltip: pomodoro.isRunning ? "Stop" : "Reset sessions",
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryView(BuildContext context, PomodoroModel pomodoro) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Session History",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 16),
              onPressed: () => _showClearHistoryConfirmation(context),
              tooltip: "Clear history",
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        if (pomodoro.sessionHistory.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "No completed sessions yet.",
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: pomodoro.historyLength,
            itemBuilder: (context, index) {
              final session = pomodoro.sessionHistory[index];
              return _buildHistoryItem(context, session, colorScheme);
            },
          ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, PomodoroSession session, ColorScheme colorScheme) {
    IconData icon;
    Color color;

    switch (session.phase) {
      case PomodoroPhase.work:
        icon = Icons.work;
        color = colorScheme.primary;
        break;
      case PomodoroPhase.shortBreak:
        icon = Icons.coffee;
        color = colorScheme.tertiary;
        break;
      case PomodoroPhase.longBreak:
        icon = Icons.weekend;
        color = colorScheme.secondary;
        break;
    }

    final timeStr = "${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}";

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 16, color: color),
      title: Text(
        "${session.phase.name} - ${session.durationMinutes}m",
        style: TextStyle(fontSize: 12),
      ),
      subtitle: Text(
        timeStr,
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    final pomodoro = context.read<PomodoroModel>();
    int work = pomodoro.workDuration;
    int shortBreak = pomodoro.shortBreakDuration;
    int longBreak = pomodoro.longBreakDuration;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Pomodoro Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.work),
                title: Text("Work Duration"),
                trailing: Text("${work} min"),
                onTap: () async {
                  final value = await _showDurationPicker(context, work, 1, 60);
                  if (value != null) setState(() => work = value);
                },
              ),
              ListTile(
                leading: Icon(Icons.coffee),
                title: Text("Short Break"),
                trailing: Text("${shortBreak} min"),
                onTap: () async {
                  final value = await _showDurationPicker(context, shortBreak, 1, 15);
                  if (value != null) setState(() => shortBreak = value);
                },
              ),
              ListTile(
                leading: Icon(Icons.weekend),
                title: Text("Long Break"),
                trailing: Text("${longBreak} min"),
                onTap: () async {
                  final value = await _showDurationPicker(context, longBreak, 5, 30);
                  if (value != null) setState(() => longBreak = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                context.read<PomodoroModel>().updateSettings(work, shortBreak, longBreak);
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _showDurationPicker(BuildContext context, int current, int min, int max) async {
    int selected = current;

    return await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Duration"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: selected.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: "${selected} min",
                onChanged: (value) => setState(() => selected = value.round()),
              ),
              Text("${selected} minutes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text("Select"),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("This will delete all session history. This action cannot be undone."),
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
      context.read<PomodoroModel>().clearHistory();
    }
  }
}