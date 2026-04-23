import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

MeditationModel meditationModel = MeditationModel();

MyProvider providerMeditation = MyProvider(
    name: "Meditation",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Meditation',
      keywords: 'meditation meditate relax breath calm focus zen mindfulness',
      action: () {
        Global.infoModel.addInfo("StartMeditation", "Start Meditation",
            subtitle: "Begin a meditation session",
            icon: Icon(Icons.self_improvement),
            onTap: () => _showMeditationDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await meditationModel.init();
  Global.infoModel.addInfoWidget(
      "Meditation",
      ChangeNotifierProvider.value(
          value: meditationModel,
          builder: (context, child) => MeditationCard()),
      title: "Meditation Timer");
}

Future<void> _update() async {
  meditationModel.notifyListeners();
}

void _showMeditationDialog(BuildContext context) {
  meditationModel.startMeditation(5);
}

enum MeditationState { idle, running, paused, completed }

enum BreathingPhase { inhale, hold, exhale, rest }

class MeditationSession {
  final int durationMinutes;
  final DateTime completedAt;
  final String? breathingPattern;

  MeditationSession({
    required this.durationMinutes,
    required this.completedAt,
    this.breathingPattern,
  });

  String toJson() {
    return jsonEncode({
      'durationMinutes': durationMinutes,
      'completedAt': completedAt.toIso8601String(),
      'breathingPattern': breathingPattern,
    });
  }

  static MeditationSession fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return MeditationSession(
      durationMinutes: map['durationMinutes'] as int,
      completedAt: DateTime.parse(map['completedAt'] as String),
      breathingPattern: map['breathingPattern'] as String?,
    );
  }
}

class MeditationModel extends ChangeNotifier {
  static const int maxHistory = 20;
  static const String _historyKey = 'meditation_history';
  static const String _totalMinutesKey = 'meditation_total_minutes';

  MeditationState _state = MeditationState.idle;
  int _durationMinutes = 5;
  int _remainingSeconds = 0;
  Timer? _timer;
  List<MeditationSession> _history = [];
  int _totalMinutes = 0;
  bool _isInitialized = false;

  BreathingPhase _breathingPhase = BreathingPhase.inhale;
  int _breathingCount = 0;
  Timer? _breathingTimer;
  bool _breathingEnabled = false;

  BreathingPhase get breathingPhase => _breathingPhase;
  bool get breathingEnabled => _breathingEnabled;
  int get breathingCount => _breathingCount;

  MeditationState get state => _state;
  int get durationMinutes => _durationMinutes;
  int get remainingSeconds => _remainingSeconds;
  List<MeditationSession> get history => _history;
  int get totalMinutes => _totalMinutes;
  bool get isInitialized => _isInitialized;
  int get sessionCount => _history.length;

  double get progress {
    if (_durationMinutes == 0) return 0;
    final totalSeconds = _durationMinutes * 60;
    return (totalSeconds - _remainingSeconds) / totalSeconds;
  }

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get breathingPhaseText {
    switch (_breathingPhase) {
      case BreathingPhase.inhale:
        return 'Inhale';
      case BreathingPhase.hold:
        return 'Hold';
      case BreathingPhase.exhale:
        return 'Exhale';
      case BreathingPhase.rest:
        return 'Rest';
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStrings = prefs.getStringList(_historyKey) ?? [];
    _history = historyStrings.map((s) => MeditationSession.fromJson(s)).toList();
    _totalMinutes = prefs.getInt(_totalMinutesKey) ?? 0;
    _isInitialized = true;
    Global.loggerModel
        .info("Meditation initialized with ${_history.length} sessions", source: "Meditation");
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStrings = _history.map((s) => s.toJson()).toList();
    await prefs.setStringList(_historyKey, historyStrings);
    await prefs.setInt(_totalMinutesKey, _totalMinutes);
  }

  void setBreathingEnabled(bool enabled) {
    _breathingEnabled = enabled;
    notifyListeners();
  }

  void startMeditation(int minutes) {
    _durationMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _state = MeditationState.running;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeMeditation();
      }
    });
    
    if (_breathingEnabled) {
      _startBreathingGuide();
    }
    
    Global.loggerModel.info("Started meditation for $minutes minutes", source: "Meditation");
    notifyListeners();
  }

  void _startBreathingGuide() {
    _breathingCount = 0;
    _breathingPhase = BreathingPhase.inhale;
    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      _breathingCount++;
      switch (_breathingPhase) {
        case BreathingPhase.inhale:
          _breathingPhase = BreathingPhase.hold;
          break;
        case BreathingPhase.hold:
          _breathingPhase = BreathingPhase.exhale;
          break;
        case BreathingPhase.exhale:
          _breathingPhase = BreathingPhase.rest;
          break;
        case BreathingPhase.rest:
          _breathingPhase = BreathingPhase.inhale;
          break;
      }
      notifyListeners();
    });
  }

  void pauseMeditation() {
    _state = MeditationState.paused;
    _timer?.cancel();
    _breathingTimer?.cancel();
    Global.loggerModel.info("Paused meditation", source: "Meditation");
    notifyListeners();
  }

  void resumeMeditation() {
    _state = MeditationState.running;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeMeditation();
      }
    });
    
    if (_breathingEnabled) {
      _startBreathingGuide();
    }
    
    Global.loggerModel.info("Resumed meditation", source: "Meditation");
    notifyListeners();
  }

  void cancelMeditation() {
    _state = MeditationState.idle;
    _timer?.cancel();
    _breathingTimer?.cancel();
    _remainingSeconds = 0;
    _breathingCount = 0;
    Global.loggerModel.info("Cancelled meditation", source: "Meditation");
    notifyListeners();
  }

  void _completeMeditation() {
    _state = MeditationState.completed;
    _timer?.cancel();
    _breathingTimer?.cancel();
    
    final session = MeditationSession(
      durationMinutes: _durationMinutes,
      completedAt: DateTime.now(),
      breathingPattern: _breathingEnabled ? '4-4-4-4' : null,
    );
    
    _history.insert(0, session);
    if (_history.length > maxHistory) {
      _history.removeLast();
    }
    _totalMinutes += _durationMinutes;
    _save();
    
    Global.loggerModel
        .info("Completed meditation session: $_durationMinutes minutes", source: "Meditation");
    notifyListeners();
  }

  void reset() {
    _state = MeditationState.idle;
    _timer?.cancel();
    _breathingTimer?.cancel();
    _remainingSeconds = 0;
    _breathingCount = 0;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    _totalMinutes = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await prefs.remove(_totalMinutesKey);
    Global.loggerModel.info("Cleared meditation history", source: "Meditation");
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingTimer?.cancel();
    super.dispose();
  }
}

class MeditationCard extends StatefulWidget {
  @override
  State<MeditationCard> createState() => _MeditationCardState();
}

class _MeditationCardState extends State<MeditationCard> {
  final List<int> _presetDurations = [1, 3, 5, 10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    final meditation = context.watch<MeditationModel>();

    if (!meditation.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.self_improvement, size: 24),
              SizedBox(width: 12),
              Text("Meditation: Loading..."),
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
              children: [
                Icon(Icons.self_improvement, size: 20),
                SizedBox(width: 8),
                Text(
                  "Meditation Timer",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (meditation.totalMinutes > 0)
                  Text(
                    "${meditation.totalMinutes} min total",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            _buildMeditationContent(context, meditation),
          ],
        ),
      ),
    );
  }

  Widget _buildMeditationContent(BuildContext context, MeditationModel meditation) {
    switch (meditation.state) {
      case MeditationState.idle:
        return _buildIdleContent(context, meditation);
      case MeditationState.running:
      case MeditationState.paused:
        return _buildRunningContent(context, meditation);
      case MeditationState.completed:
        return _buildCompletedContent(context, meditation);
    }
  }

  Widget _buildIdleContent(BuildContext context, MeditationModel meditation) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select duration:",
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetDurations.map((duration) {
            return ActionChip(
              label: Text("${duration}m"),
              onPressed: () => meditation.startMeditation(duration),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            );
          }).toList(),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(
              meditation.breathingEnabled ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => meditation.setBreathingEnabled(!meditation.breathingEnabled),
              child: Text(
                "Breathing guide (4-4-4-4)",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        if (meditation.sessionCount > 0) ...[
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                "${meditation.sessionCount} sessions",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () => _showHistoryDialog(context, meditation),
                child: Text("History"),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRunningContent(BuildContext context, MeditationModel meditation) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: meditation.progress,
                strokeWidth: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    meditation.formattedTime,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (meditation.breathingEnabled) ...[
                    SizedBox(height: 4),
                    Text(
                      meditation.breathingPhaseText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.stop, size: 28),
              onPressed: () => meditation.cancelMeditation(),
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(width: 16),
            IconButton(
              icon: Icon(
                meditation.state == MeditationState.paused ? Icons.play_arrow : Icons.pause,
                size: 32,
              ),
              onPressed: () {
                if (meditation.state == MeditationState.paused) {
                  meditation.resumeMeditation();
                } else {
                  meditation.pauseMeditation();
                }
              },
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedContent(BuildContext context, MeditationModel meditation) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: 12),
        Text(
          "Session Complete!",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "${meditation.durationMinutes} minutes",
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => meditation.reset(),
          child: Text("New Session"),
        ),
      ],
    );
  }

  void _showHistoryDialog(BuildContext context, MeditationModel meditation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Meditation History"),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: meditation.history.isEmpty
              ? Center(child: Text("No sessions yet"))
              : ListView.builder(
                  itemCount: meditation.history.length,
                  itemBuilder: (context, index) {
                    final session = meditation.history[index];
                    final timeAgo = _formatTimeAgo(session.completedAt);
                    return ListTile(
                      leading: Icon(Icons.self_improvement),
                      title: Text("${session.durationMinutes} minutes"),
                      subtitle: Text(timeAgo),
                      trailing: session.breathingPattern != null
                          ? Icon(Icons.air, size: 16)
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
          if (meditation.history.isNotEmpty)
            TextButton(
              onPressed: () {
                meditation.clearHistory();
                Navigator.pop(context);
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";
    return "${dateTime.month}/${dateTime.day}";
  }
}