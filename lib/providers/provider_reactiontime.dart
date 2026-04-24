import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

ReactionTimeModel reactionTimeModel = ReactionTimeModel();

MyProvider providerReactionTime = MyProvider(
    name: "ReactionTime",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'ReactionTime',
      keywords: 'reaction time reflex speed test tap quick fast response',
      action: () => reactionTimeModel.requestFocus(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  reactionTimeModel.init();
  Global.infoModel.addInfoWidget(
      "ReactionTime",
      ChangeNotifierProvider.value(
          value: reactionTimeModel,
          builder: (context, child) => ReactionTimeCard()),
      title: "ReactionTime");
}

Future<void> _update() async {
  reactionTimeModel.refresh();
}

class ReactionTimeModel extends ChangeNotifier {
  static const int maxHistory = 10;
  static const int minDelayMs = 1000;
  static const int maxDelayMs = 5000;

  ReactionState _state = ReactionState.waiting;
  int? _lastReactionTime;
  int? _bestTime;
  double? _averageTime;
  int _attemptCount = 0;
  final List<int> _history = [];
  Timer? _delayTimer;
  DateTime? _signalTime;
  bool _isInitialized = false;
  bool _focusRequested = false;

  ReactionState get state => _state;
  int? get lastReactionTime => _lastReactionTime;
  int? get bestTime => _bestTime;
  double? get averageTime => _averageTime;
  int get attemptCount => _attemptCount;
  List<int> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  bool get isInitialized => _isInitialized;
  bool get shouldFocus => _focusRequested;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("ReactionTime initialized", source: "ReactionTime");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void startTest() {
    if (_state == ReactionState.ready || _state == ReactionState.result) {
      _state = ReactionState.waiting;
      notifyListeners();

      final delayMs = minDelayMs + Random().nextInt(maxDelayMs - minDelayMs);
      _delayTimer = Timer(Duration(milliseconds: delayMs), () {
        _signalTime = DateTime.now();
        _state = ReactionState.go;
        Global.loggerModel.info("GO signal shown", source: "ReactionTime");
        notifyListeners();
      });
    } else if (_state == ReactionState.waiting) {
      _delayTimer?.cancel();
      _state = ReactionState.early;
      Global.loggerModel.warning("Too early! Reaction canceled", source: "ReactionTime");
      notifyListeners();
    } else if (_state == ReactionState.go) {
      final reactionTime = DateTime.now().difference(_signalTime!).inMilliseconds;
      _lastReactionTime = reactionTime;
      _attemptCount++;

      _addToHistory(reactionTime);

      if (_bestTime == null || reactionTime < _bestTime!) {
        _bestTime = reactionTime;
      }

      int total = 0;
      for (int time in _history) {
        total += time;
      }
      _averageTime = total / _history.length;

      _state = ReactionState.result;
      Global.loggerModel.info("Reaction time: $reactionTime ms", source: "ReactionTime");
      notifyListeners();
    } else if (_state == ReactionState.early) {
      _state = ReactionState.waiting;
      notifyListeners();
    }
  }

  void _addToHistory(int time) {
    _history.insert(0, time);
    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void reset() {
    _delayTimer?.cancel();
    _state = ReactionState.waiting;
    _lastReactionTime = null;
    _bestTime = null;
    _averageTime = null;
    _attemptCount = 0;
    _history.clear();
    _signalTime = null;
    Global.loggerModel.info("ReactionTime reset", source: "ReactionTime");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    if (_history.isEmpty) {
      _averageTime = null;
      _bestTime = null;
    }
    Global.loggerModel.info("ReactionTime history cleared", source: "ReactionTime");
    notifyListeners();
  }

  void requestFocus() {
    _focusRequested = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _focusRequested = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }
}

enum ReactionState {
  waiting,
  ready,
  go,
  result,
  early,
}

class ReactionTimeCard extends StatefulWidget {
  @override
  State<ReactionTimeCard> createState() => _ReactionTimeCardState();
}

class _ReactionTimeCardState extends State<ReactionTimeCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final reaction = context.watch<ReactionTimeModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!reaction.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.timer, size: 24),
              SizedBox(width: 12),
              Text("ReactionTime: Loading..."),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Reaction Time",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reaction.hasHistory)
                        IconButton(
                          icon: Icon(_showHistory ? Icons.timer : Icons.history, size: 18),
                          onPressed: () => setState(() => _showHistory = !_showHistory),
                          tooltip: _showHistory ? "Test" : "History",
                          style: IconButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (reaction.hasHistory)
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
              SizedBox(height: 12),
              if (_showHistory)
                _buildHistoryView(reaction)
              else
                _buildMainView(reaction),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(ReactionTimeModel reaction) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildReactionButton(reaction),
        SizedBox(height: 16),
        _buildStatsRow(reaction),
        if (reaction.state == ReactionState.early)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Too early! Try again.",
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (reaction.state == ReactionState.waiting)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Wait for green...",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (reaction.state == ReactionState.go)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "TAP NOW!",
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReactionButton(ReactionTimeModel reaction) {
    final colorScheme = Theme.of(context).colorScheme;

    Color buttonColor;
    Color textColor;
    String buttonText;

    switch (reaction.state) {
      case ReactionState.waiting:
        buttonColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        buttonText = "Wait...";
        break;
      case ReactionState.ready:
        buttonColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurface;
        buttonText = "Start";
        break;
      case ReactionState.go:
        buttonColor = colorScheme.primary;
        textColor = colorScheme.onPrimary;
        buttonText = "TAP!";
        break;
      case ReactionState.result:
        buttonColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        buttonText = "Start";
        break;
      case ReactionState.early:
        buttonColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        buttonText = "Try Again";
        break;
    }

    return GestureDetector(
      onTap: reaction.startTest,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: buttonColor,
          border: Border.all(
            color: reaction.state == ReactionState.go
                ? colorScheme.primary
                : colorScheme.outline,
            width: reaction.state == ReactionState.go ? 4 : 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reaction.state == ReactionState.result && reaction.lastReactionTime != null)
                Text(
                  "${reaction.lastReactionTime}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              if (reaction.state == ReactionState.result)
                Text(
                  "ms",
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              if (reaction.state != ReactionState.result)
                Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(ReactionTimeModel reaction) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          "Best",
          reaction.bestTime != null ? "${reaction.bestTime} ms" : "--",
          Icons.emoji_events,
          colorScheme.tertiary,
          colorScheme.onSurfaceVariant,
        ),
        _buildStatItem(
          "Avg",
          reaction.averageTime != null ? "${reaction.averageTime!.round()} ms" : "--",
          Icons.bar_chart,
          colorScheme.secondary,
          colorScheme.onSurfaceVariant,
        ),
        _buildStatItem(
          "Attempts",
          "${reaction.attemptCount}",
          Icons.repeat,
          colorScheme.primary,
          colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, Color labelColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(ReactionTimeModel reaction) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "History",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: reaction.history.length,
              itemBuilder: (context, index) {
                final time = reaction.history[index];
                final isBest = time == reaction.bestTime;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isBest ? Icons.emoji_events : Icons.timer,
                    size: 20,
                    color: isBest ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    "$time ms",
                    style: TextStyle(
                      fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                      color: isBest ? colorScheme.tertiary : colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text("#${reaction.history.length - index}"),
                );
              },
            ),
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
        content: Text("Clear all reaction time history?"),
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
      context.read<ReactionTimeModel>().clearHistory();
      setState(() => _showHistory = false);
    }
  }
}