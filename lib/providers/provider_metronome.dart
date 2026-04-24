import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

MetronomeModel metronomeModel = MetronomeModel();

MyProvider providerMetronome = MyProvider(
    name: "Metronome",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Metronome',
      keywords: 'metronome beat bpm tempo rhythm music tap pulse',
      action: () => metronomeModel.requestFocus(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  metronomeModel.init();
  Global.infoModel.addInfoWidget(
      "Metronome",
      ChangeNotifierProvider.value(
          value: metronomeModel,
          builder: (context, child) => MetronomeCard()),
      title: "Metronome");
}

Future<void> _update() async {
  metronomeModel.refresh();
}

class MetronomeModel extends ChangeNotifier {
  static const int minBpm = 20;
  static const int maxBpm = 300;
  static const int defaultBpm = 120;
  static const List<int> presetBpm = [60, 80, 100, 120, 140, 160, 180];
  static const List<int> timeSignatureOptions = [2, 3, 4, 6, 8];
  static const int defaultTimeSignature = 4;
  static const int maxHistory = 10;

  int _bpm = defaultBpm;
  int _timeSignature = defaultTimeSignature;
  bool _isRunning = false;
  int _currentBeat = 0;
  bool _showBeat = false;
  bool _isInitialized = false;
  Timer? _timer;
  Timer? _beatFlashTimer;
  final List<int> _history = [];
  final List<DateTime> _tapTimes = [];
  bool _focusRequested = false;

  int get bpm => _bpm;
  int get timeSignature => _timeSignature;
  bool get isRunning => _isRunning;
  int get currentBeat => _currentBeat;
  bool get showBeat => _showBeat;
  bool get isInitialized => _isInitialized;
  bool get isAccentBeat => _currentBeat == 1;
  List<int> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  bool get shouldFocus => _focusRequested;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("Metronome initialized", source: "Metronome");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setBpm(int bpm) {
    _bpm = bpm.clamp(minBpm, maxBpm);
    if (_isRunning) {
      _restartTimer();
    }
    Global.loggerModel.info("BPM set to $_bpm", source: "Metronome");
    notifyListeners();
  }

  void incrementBpm(int step) {
    setBpm(_bpm + step);
  }

  void decrementBpm(int step) {
    setBpm(_bpm - step);
  }

  void setTimeSignature(int beats) {
    if (timeSignatureOptions.contains(beats)) {
      _timeSignature = beats;
      _currentBeat = 0;
      Global.loggerModel.info("Time signature set to $_timeSignature", source: "Metronome");
      notifyListeners();
    }
  }

  void tapTempo() {
    final now = DateTime.now();
    _tapTimes.add(now);

    if (_tapTimes.length > 4) {
      _tapTimes.removeAt(0);
    }

    if (_tapTimes.length >= 2) {
      double avgInterval = 0;
      for (int i = 1; i < _tapTimes.length; i++) {
        avgInterval += _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds;
      }
      avgInterval /= (_tapTimes.length - 1);

      if (avgInterval > 0 && avgInterval < 3000) {
        int calculatedBpm = (60000 / avgInterval).round().clamp(minBpm, maxBpm);
        setBpm(calculatedBpm);
        Global.loggerModel.info("Tap tempo calculated: $calculatedBpm BPM", source: "Metronome");
      }
    }
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _currentBeat = 1;
    _flashBeat();
    _startTimer();
    Global.loggerModel.info("Metronome started at $_bpm BPM", source: "Metronome");
    notifyListeners();
  }

  void pause() {
    if (!_isRunning) return;
    _isRunning = false;
    _timer?.cancel();
    _beatFlashTimer?.cancel();
    _showBeat = false;
    Global.loggerModel.info("Metronome paused", source: "Metronome");
    notifyListeners();
  }

  void stop() {
    pause();
    _currentBeat = 0;
    Global.loggerModel.info("Metronome stopped", source: "Metronome");
    notifyListeners();
  }

  void toggle() {
    if (_isRunning) {
      pause();
    } else {
      start();
    }
  }

  void _startTimer() {
    final intervalMs = (60000 / _bpm).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _tick();
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }

  void _tick() {
    _currentBeat++;
    if (_currentBeat > _timeSignature) {
      _currentBeat = 1;
    }
    _flashBeat();
    notifyListeners();
  }

  void _flashBeat() {
    _showBeat = true;
    notifyListeners();

    _beatFlashTimer?.cancel();
    final flashDurationMs = (60000 / _bpm / 3).round().clamp(50, 200);
    _beatFlashTimer = Timer(Duration(milliseconds: flashDurationMs), () {
      _showBeat = false;
      notifyListeners();
    });
  }

  void saveToHistory() {
    if (_history.contains(_bpm)) {
      _history.remove(_bpm);
    }
    _history.insert(0, _bpm);

    while (_history.length > maxHistory) {
      _history.removeLast();
    }
    Global.loggerModel.info("BPM $_bpm saved to history", source: "Metronome");
    notifyListeners();
  }

  void loadFromHistory(int bpm) {
    setBpm(bpm);
    Global.loggerModel.info("Loaded BPM $bpm from history", source: "Metronome");
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("Metronome history cleared", source: "Metronome");
    notifyListeners();
  }

  void clearTapTimes() {
    _tapTimes.clear();
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
    _timer?.cancel();
    _beatFlashTimer?.cancel();
    super.dispose();
  }
}

class MetronomeCard extends StatefulWidget {
  @override
  State<MetronomeCard> createState() => _MetronomeCardState();
}

class _MetronomeCardState extends State<MetronomeCard> {
  final TextEditingController _bpmController = TextEditingController();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _bpmController.text = metronomeModel.bpm.toString();
    metronomeModel.addListener(_onModelChanged);
  }

  @override
  void dispose() {
    metronomeModel.removeListener(_onModelChanged);
    _bpmController.dispose();
    super.dispose();
  }

  void _onModelChanged() {
    if (_bpmController.text != metronomeModel.bpm.toString()) {
      _bpmController.text = metronomeModel.bpm.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final metro = context.watch<MetronomeModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!metro.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.music_note, size: 24),
              SizedBox(width: 12),
              Text("Metronome: Loading..."),
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
                      Icon(Icons.music_note, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Metronome",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (metro.hasHistory)
                        IconButton(
                          icon: Icon(_showHistory ? Icons.music_note : Icons.history, size: 18),
                          onPressed: () => setState(() => _showHistory = !_showHistory),
                          tooltip: _showHistory ? "Metronome" : "History",
                          style: IconButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (metro.hasHistory)
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
                _buildHistoryView(metro)
              else
                _buildMainView(metro),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(MetronomeModel metro) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBeatIndicator(metro),
        SizedBox(height: 16),
        _buildBpmControls(metro),
        SizedBox(height: 12),
        _buildTimeSignatureSelector(metro),
        SizedBox(height: 16),
        _buildPlayControls(metro),
      ],
    );
  }

  Widget _buildBeatIndicator(MetronomeModel metro) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: metro.showBeat
            ? (metro.isAccentBeat
                ? colorScheme.primary
                : colorScheme.secondary)
            : colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: metro.isAccentBeat ? colorScheme.primary : colorScheme.outline,
          width: metro.isAccentBeat ? 3 : 1,
        ),
      ),
      child: Center(
        child: metro.isRunning
            ? Text(
                "${metro.currentBeat}",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: metro.showBeat
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              )
            : Icon(
                Icons.music_note,
                size: 32,
                color: colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }

  Widget _buildBpmControls(MetronomeModel metro) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove, size: 24),
              onPressed: () => metro.decrementBpm(10),
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              width: 100,
              child: TextField(
                controller: _bpmController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: "BPM",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                onSubmitted: (value) {
                  final bpm = int.tryParse(value);
                  if (bpm != null) {
                    metro.setBpm(bpm);
                  } else {
                    _bpmController.text = metro.bpm.toString();
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, size: 24),
              onPressed: () => metro.incrementBpm(10),
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: MetronomeModel.presetBpm.map((bpm) => ActionChip(
            label: Text("$bpm"),
            onPressed: () => metro.setBpm(bpm),
            backgroundColor: metro.bpm == bpm
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            labelStyle: TextStyle(
              color: metro.bpm == bpm
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSignatureSelector(MetronomeModel metro) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(
          "Time: ",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: MetronomeModel.timeSignatureOptions.map((t) =>
              ButtonSegment<int>(
                value: t,
                label: Text("$t/4"),
              )
            ).toList(),
            selected: {metro.timeSignature},
            onSelectionChanged: (Set<int> newSelection) {
              if (newSelection.isNotEmpty) {
                metro.setTimeSignature(newSelection.first);
              }
            },
style: ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayControls(MetronomeModel metro) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.fiber_manual_record, size: 24),
          onPressed: () {
            metro.clearTapTimes();
            metro.tapTempo();
          },
          tooltip: "Tap Tempo",
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.tertiary,
            backgroundColor: colorScheme.tertiaryContainer,
          ),
        ),
        FloatingActionButton(
          heroTag: "metronome_play",
          onPressed: metro.toggle,
          child: Icon(
            metro.isRunning ? Icons.pause : Icons.play_arrow,
            size: 28,
          ),
          backgroundColor: metro.isRunning
              ? colorScheme.secondaryContainer
              : colorScheme.primaryContainer,
          foregroundColor: metro.isRunning
              ? colorScheme.onSecondaryContainer
              : colorScheme.onPrimaryContainer,
        ),
        IconButton(
          icon: Icon(Icons.stop, size: 24),
          onPressed: metro.isRunning ? () => metro.stop() : null,
          tooltip: "Stop",
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(MetronomeModel metro) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: metro.history.length,
        itemBuilder: (context, index) {
          final bpm = metro.history[index];
          return ListTile(
            dense: true,
            leading: Icon(Icons.music_note, size: 20),
            title: Text("$bpm BPM"),
            trailing: IconButton(
              icon: Icon(Icons.refresh, size: 18),
              onPressed: () {
                metro.loadFromHistory(bpm);
                setState(() => _showHistory = false);
              },
              tooltip: "Use this BPM",
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
            onTap: () {
              metro.loadFromHistory(bpm);
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
        content: Text("Clear all BPM history?"),
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
      context.read<MetronomeModel>().clearHistory();
    }
  }
}