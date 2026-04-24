import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

IntervalTimerModel intervalTimerModel = IntervalTimerModel();

MyProvider providerIntervalTimer = MyProvider(
    name: "IntervalTimer",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Interval timer',
      keywords: 'interval timer hiit tabata workout circuit training',
      action: () {
        Global.infoModel.addInfo("IntervalTimer", "Interval Timer",
            subtitle: "HIIT/Tabata workout timer",
            icon: Icon(Icons.timer),
            onTap: () {});
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  Global.infoModel.addInfoWidget(
      "IntervalTimer",
      ChangeNotifierProvider.value(
          value: intervalTimerModel,
          builder: (context, child) => IntervalTimerCard()),
      title: "Interval Timer");
}

Future<void> _update() async {
  intervalTimerModel.notifyListeners();
}

enum IntervalPhase { work, rest }

class IntervalTimerModel extends ChangeNotifier {
  int workDuration = 30;
  int restDuration = 10;
  int sets = 4;
  int currentSet = 1;
  IntervalPhase currentPhase = IntervalPhase.work;
  int remainingSeconds = 30;
  bool isRunning = false;
  bool isPaused = false;
  Timer? _timer;
  int totalElapsedSeconds = 0;

  bool get isActive => isRunning && !isPaused;
  int get totalDuration => (workDuration + restDuration) * sets;
  double get progress => totalElapsedSeconds / totalDuration;
  bool get isWorkPhase => currentPhase == IntervalPhase.work;

  List<IntervalPreset> presets = [
    IntervalPreset(name: "Tabata", work: 20, rest: 10, sets: 8),
    IntervalPreset(name: "HIIT 30/10", work: 30, rest: 10, sets: 8),
    IntervalPreset(name: "HIIT 45/15", work: 45, rest: 15, sets: 6),
    IntervalPreset(name: "Circuit", work: 60, rest: 30, sets: 5),
    IntervalPreset(name: "EMOM", work: 60, rest: 0, sets: 10),
  ];

  void applyPreset(IntervalPreset preset) {
    stop();
    workDuration = preset.work;
    restDuration = preset.rest;
    sets = preset.sets;
    resetToStart();
    notifyListeners();
  }

  void setWorkDuration(int seconds) {
    if (seconds >= 5 && seconds <= 300) {
      workDuration = seconds;
      if (!isRunning) remainingSeconds = workDuration;
      notifyListeners();
    }
  }

  void setRestDuration(int seconds) {
    if (seconds >= 0 && seconds <= 120) {
      restDuration = seconds;
      notifyListeners();
    }
  }

  void setSets(int count) {
    if (count >= 1 && count <= 20) {
      sets = count;
      notifyListeners();
    }
  }

  void resetToStart() {
    currentSet = 1;
    currentPhase = IntervalPhase.work;
    remainingSeconds = workDuration;
    totalElapsedSeconds = 0;
    isRunning = false;
    isPaused = false;
    notifyListeners();
  }

  void start() {
    if (isRunning && isPaused) {
      isPaused = false;
      _startTimer();
      notifyListeners();
      return;
    }
    if (!isRunning) {
      isRunning = true;
      isPaused = false;
      _resetToRunning();
      _startTimer();
      Global.loggerModel.info("Interval timer started: ${workDuration}s work, ${restDuration}s rest, $sets sets", source: "IntervalTimer");
      notifyListeners();
    }
  }

  void _resetToRunning() {
    currentSet = 1;
    currentPhase = IntervalPhase.work;
    remainingSeconds = workDuration;
    totalElapsedSeconds = 0;
    isPaused = false;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isPaused) {
        remainingSeconds--;
        totalElapsedSeconds++;
        if (remainingSeconds <= 0) {
          _advancePhase();
        }
        notifyListeners();
      }
    });
  }

  void _advancePhase() {
    if (currentPhase == IntervalPhase.work && restDuration > 0) {
      currentPhase = IntervalPhase.rest;
      remainingSeconds = restDuration;
      Global.loggerModel.info("Work phase complete, rest phase started", source: "IntervalTimer");
    } else {
      currentSet++;
      if (currentSet > sets) {
        complete();
        return;
      }
      currentPhase = IntervalPhase.work;
      remainingSeconds = workDuration;
      Global.loggerModel.info("Set $currentSet started", source: "IntervalTimer");
    }
  }

  void pause() {
    if (isRunning && !isPaused) {
      isPaused = true;
      _timer?.cancel();
      Global.loggerModel.info("Interval timer paused", source: "IntervalTimer");
      notifyListeners();
    }
  }

  void resume() {
    if (isRunning && isPaused) {
      isPaused = false;
      _startTimer();
      Global.loggerModel.info("Interval timer resumed", source: "IntervalTimer");
      notifyListeners();
    }
  }

  void stop() {
    _timer?.cancel();
    isRunning = false;
    isPaused = false;
    resetToStart();
    Global.loggerModel.info("Interval timer stopped", source: "IntervalTimer");
    notifyListeners();
  }

  void complete() {
    _timer?.cancel();
    isRunning = false;
    isPaused = false;
    Global.loggerModel.info("Interval timer completed: $sets sets", source: "IntervalTimer");
    notifyListeners();
  }

  void skipPhase() {
    if (isRunning) {
      remainingSeconds = 0;
      _advancePhase();
      Global.loggerModel.info("Phase skipped", source: "IntervalTimer");
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class IntervalPreset {
  final String name;
  final int work;
  final int rest;
  final int sets;

  IntervalPreset({
    required this.name,
    required this.work,
    required this.rest,
    required this.sets,
  });
}

class IntervalTimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final timer = context.watch<IntervalTimerModel>();

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
                  Icon(Icons.timer, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Interval Timer",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (timer.isRunning)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: timer.isWorkPhase
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        timer.isPaused ? "Paused" : (timer.isWorkPhase ? "WORK" : "REST"),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: timer.isWorkPhase
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              if (timer.isRunning) ...[
                _buildRunningDisplay(context, timer),
              ] else ...[
                _buildSetupDisplay(context, timer),
              ],
              SizedBox(height: 12),
              _buildControls(context, timer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunningDisplay(BuildContext context, IntervalTimerModel timer) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: timer.remainingSeconds / (timer.isWorkPhase ? timer.workDuration : timer.restDuration),
                strokeWidth: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: timer.isWorkPhase
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            Column(
              children: [
                Text(
                  _formatTime(timer.remainingSeconds),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: timer.isWorkPhase
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  "Set ${timer.currentSet}/${timer.sets}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),
        LinearProgressIndicator(
          value: timer.progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        SizedBox(height: 4),
        Text(
          "Total: ${_formatTime(timer.totalElapsedSeconds)} / ${_formatTime(timer.totalDuration)}",
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSetupDisplay(BuildContext context, IntervalTimerModel timer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Presets:",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timer.presets.map((preset) => ActionChip(
            label: Text(preset.name),
            onPressed: () => timer.applyPreset(preset),
          )).toList(),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Work", style: TextStyle(fontSize: 12)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 18),
                        onPressed: () => timer.setWorkDuration(timer.workDuration - 5),
                      ),
                      Text("${timer.workDuration}s", style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add, size: 18),
                        onPressed: () => timer.setWorkDuration(timer.workDuration + 5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rest", style: TextStyle(fontSize: 12)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 18),
                        onPressed: () => timer.setRestDuration(timer.restDuration - 5),
                      ),
                      Text("${timer.restDuration}s", style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add, size: 18),
                        onPressed: () => timer.setRestDuration(timer.restDuration + 5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sets", style: TextStyle(fontSize: 12)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 18),
                        onPressed: () => timer.setSets(timer.sets - 1),
                      ),
                      Text("${timer.sets}", style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add, size: 18),
                        onPressed: () => timer.setSets(timer.sets + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          "Total time: ${_formatTime(timer.totalDuration)}",
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, IntervalTimerModel timer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!timer.isRunning)
          ElevatedButton.icon(
            icon: Icon(Icons.play_arrow, size: 18),
            label: Text("Start"),
            onPressed: () => timer.start(),
          ),
        if (timer.isRunning && !timer.isPaused)
          ElevatedButton.icon(
            icon: Icon(Icons.pause, size: 18),
            label: Text("Pause"),
            onPressed: () => timer.pause(),
          ),
        if (timer.isRunning && timer.isPaused)
          ElevatedButton.icon(
            icon: Icon(Icons.play_arrow, size: 18),
            label: Text("Resume"),
            onPressed: () => timer.resume(),
          ),
        if (timer.isRunning)
          TextButton.icon(
            icon: Icon(Icons.skip_next, size: 18),
            label: Text("Skip"),
            onPressed: () => timer.skipPhase(),
          ),
        if (timer.isRunning)
          TextButton.icon(
            icon: Icon(Icons.stop, size: 18),
            label: Text("Stop"),
            onPressed: () => timer.stop(),
          ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return "${mins}:${secs.toString().padLeft(2, '0')}";
  }
}