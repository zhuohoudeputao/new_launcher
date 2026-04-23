import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

TimerModel timerModel = TimerModel();

MyProvider providerTimer = MyProvider(
    name: "Timer",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Timer',
      keywords: 'timer countdown alarm clock time countdown',
      action: () => timerModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  timerModel.init();
  Global.infoModel.addInfoWidget(
      "Timer",
      ChangeNotifierProvider.value(
          value: timerModel,
          builder: (context, child) => TimerCard()),
      title: "Quick Timer");
}

Future<void> _update() async {
  timerModel.refresh();
}

class TimerEntry {
  final String id;
  final int totalSeconds;
  int remainingSeconds;
  Timer? timer;
  bool isActive;
  final String label;

  TimerEntry({
    required this.id,
    required this.totalSeconds,
    this.remainingSeconds = 0,
    this.timer,
    this.isActive = true,
    this.label = '',
  });

  String get displayTime {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String get totalDisplayTime {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  double get progress => totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;
}

class TimerModel extends ChangeNotifier {
  final List<TimerEntry> _timers = [];
  static const int maxTimers = 5;
  bool _isInitialized = false;

  List<TimerEntry> get timers => List.unmodifiable(_timers);
  int get length => _timers.length;
  bool get isInitialized => _isInitialized;
  bool get hasTimers => _timers.any((t) => t.isActive);

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("Timer initialized", source: "Timer");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Timer refreshed", source: "Timer");
  }

  void addTimer(int seconds, {String label = ''}) {
    if (_timers.length >= maxTimers) {
      Global.loggerModel.warning("Timer limit reached (max: $maxTimers)", source: "Timer");
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final entry = TimerEntry(
      id: id,
      totalSeconds: seconds,
      remainingSeconds: seconds,
      label: label,
    );

    entry.timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (entry.remainingSeconds > 0) {
        entry.remainingSeconds--;
        notifyListeners();
      } else {
        _completeTimer(entry);
      }
    });

    _timers.insert(0, entry);
    notifyListeners();
    Global.loggerModel.info("Timer added: ${entry.totalDisplayTime}", source: "Timer");
  }

  void _completeTimer(TimerEntry entry) {
    entry.timer?.cancel();
    entry.isActive = false;
    notifyListeners();
    Global.loggerModel.info("Timer completed: ${entry.label.isNotEmpty ? entry.label : entry.totalDisplayTime}", source: "Timer");
    
    _showCompletionNotification(entry);
  }

  void _showCompletionNotification(TimerEntry entry) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Timer completed: ${entry.label.isNotEmpty ? entry.label : entry.totalDisplayTime}'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void cancelTimer(String id) {
    final entry = _timers.firstWhere((t) => t.id == id, orElse: () => _timers.first);
    entry.timer?.cancel();
    _timers.removeWhere((t) => t.id == id);
    notifyListeners();
    Global.loggerModel.info("Timer cancelled", source: "Timer");
  }

  void pauseTimer(String id) {
    final entry = _timers.firstWhere((t) => t.id == id, orElse: () => _timers.first);
    if (entry.isActive && entry.timer != null) {
      entry.timer!.cancel();
      entry.isActive = false;
      notifyListeners();
      Global.loggerModel.info("Timer paused", source: "Timer");
    }
  }

  void resumeTimer(String id) {
    final entry = _timers.firstWhere((t) => t.id == id, orElse: () => _timers.first);
    if (!entry.isActive && entry.remainingSeconds > 0) {
      entry.timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (entry.remainingSeconds > 0) {
          entry.remainingSeconds--;
          notifyListeners();
        } else {
          _completeTimer(entry);
        }
      });
      entry.isActive = true;
      notifyListeners();
      Global.loggerModel.info("Timer resumed", source: "Timer");
    }
  }

  void clearAllTimers() {
    for (final entry in _timers) {
      entry.timer?.cancel();
    }
    _timers.clear();
    notifyListeners();
    Global.loggerModel.info("All timers cleared", source: "Timer");
  }

  void addQuickTimer(int minutes) {
    addTimer(minutes * 60, label: '${minutes}m');
  }
}

class TimerCard extends StatefulWidget {
  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  final List<int> _quickMinutes = [1, 5, 10, 15, 30];
  int? _selectedMinutes;

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerModel>();
    
    if (!timer.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.timer, size: 24),
              SizedBox(width: 12),
              Text("Timer: Loading..."),
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
                  "Quick Timer",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (timer.hasTimers)
                  IconButton(
                    icon: Icon(Icons.clear_all, size: 18),
                    onPressed: () => _showClearConfirmation(context),
                    tooltip: "Clear all timers",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickMinutes.map((minutes) => 
                ActionChip(
                  label: Text('${minutes}m'),
                  avatar: Icon(Icons.timer_outlined, size: 16),
                  onPressed: () => timer.addQuickTimer(minutes),
                ),
              ).toList(),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Custom minutes',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (value) {
                      final mins = int.tryParse(value);
                      if (mins != null && mins > 0) {
                        timer.addQuickTimer(mins);
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _showAddTimerDialog(context),
                  tooltip: "Add custom timer",
                ),
              ],
            ),
            if (timer.timers.isNotEmpty) ...[
              SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: timer.timers.length,
                itemBuilder: (context, index) {
                  final entry = timer.timers[index];
                  return _buildTimerItem(context, timer, entry);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerItem(BuildContext context, TimerModel model, TimerEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressColor = entry.isActive 
      ? colorScheme.primary
      : colorScheme.onSurfaceVariant;
    
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          value: entry.progress,
          strokeWidth: 3,
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: progressColor,
        ),
      ),
      title: Text(
        entry.displayTime,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: entry.isActive ? null : colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        entry.label.isNotEmpty ? entry.label : entry.totalDisplayTime,
        style: TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.isActive)
            IconButton(
              icon: Icon(Icons.pause, size: 16),
              onPressed: () => model.pauseTimer(entry.id),
              tooltip: "Pause",
            )
          else if (entry.remainingSeconds > 0)
            IconButton(
              icon: Icon(Icons.play_arrow, size: 16),
              onPressed: () => model.resumeTimer(entry.id),
              tooltip: "Resume",
            ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: () => model.cancelTimer(entry.id),
            tooltip: "Cancel",
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Timers"),
        content: Text("This will cancel all active timers."),
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
      context.read<TimerModel>().clearAllTimers();
    }
  }

  void _showAddTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTimerDialog(),
    );
  }
}

class AddTimerDialog extends StatefulWidget {
  @override
  State<AddTimerDialog> createState() => _AddTimerDialogState();
}

class _AddTimerDialogState extends State<AddTimerDialog> {
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  
  @override
  void dispose() {
    _minutesController.dispose();
    _labelController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Timer"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Minutes",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: "Label (optional)",
              border: OutlineInputBorder(),
            ),
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
            final mins = int.tryParse(_minutesController.text);
            if (mins != null && mins > 0) {
              context.read<TimerModel>().addTimer(
                mins * 60,
                label: _labelController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: Text("Start"),
        ),
      ],
    );
  }
}