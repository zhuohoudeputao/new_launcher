# Metronome Provider Implementation

## Overview

The Metronome provider provides a visual beat indicator for musicians, offering configurable BPM, time signature support, and tap tempo functionality.

## Features

- Configurable BPM (20-300, default 120)
- Visual beat indicator with accent highlight for first beat
- Start/pause/stop controls
- Tap tempo feature (tap to set BPM)
- Preset BPM options (60, 80, 100, 120, 140, 160, 180)
- Time signature support (2/4, 3/4, 4/4, 6/4, 8/4)
- BPM history (up to 10 entries)
- Circular beat indicator with current beat number display

## Implementation Details

### Provider Structure

```dart
MyProvider providerMetronome = MyProvider(
    name: "Metronome",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Model: MetronomeModel

The `MetronomeModel` class extends `ChangeNotifier` and manages the metronome state.

#### Key Properties

- `_bpm`: Current BPM setting (20-300 range)
- `_timeSignature`: Number of beats per measure (2, 3, 4, 6, 8)
- `_isRunning`: Whether the metronome is playing
- `_currentBeat`: Current beat number in the measure
- `_showBeat`: Visual flash indicator
- `_history`: List of recently used BPMs

#### Constants

```dart
static const int minBpm = 20;
static const int maxBpm = 300;
static const int defaultBpm = 120;
static const List<int> presetBpm = [60, 80, 100, 120, 140, 160, 180];
static const List<int> timeSignatureOptions = [2, 3, 4, 6, 8];
static const int defaultTimeSignature = 4;
static const int maxHistory = 10;
```

#### Methods

- `setBpm(int bpm)`: Set BPM with clamping to valid range
- `incrementBpm(int step)`: Increase BPM by step
- `decrementBpm(int step)`: Decrease BPM by step
- `setTimeSignature(int beats)`: Set time signature (must be valid option)
- `tapTempo()`: Calculate BPM from tap timing
- `start()`: Start the metronome
- `pause()`: Pause without resetting beat count
- `stop()`: Stop and reset beat count to 0
- `toggle()`: Toggle between running and paused
- `saveToHistory()`: Save current BPM to history
- `loadFromHistory(int bpm)`: Load BPM from history
- `clearHistory()`: Clear all BPM history

### Timer Management

The metronome uses `Timer.periodic` for beat timing:

```dart
void _startTimer() {
  final intervalMs = (60000 / _bpm).round();
  _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
    _tick();
  });
}
```

### Visual Beat Flash

Beat flash duration is calculated relative to BPM:

```dart
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
```

### Tap Tempo Algorithm

The tap tempo feature stores up to 4 tap times and calculates average interval:

```dart
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
    }
  }
}
```

## UI Components

### MetronomeCard

The main widget displays the metronome interface:

#### Beat Indicator

A circular container showing the current beat number with visual flash effect:

```dart
Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: metro.showBeat
        ? (metro.isAccentBeat ? colorScheme.primary : colorScheme.secondary)
        : colorScheme.surfaceContainerHighest,
  ),
  child: Center(
    child: Text("${metro.currentBeat}", ...),
  ),
)
```

#### BPM Controls

- +/- buttons for fine adjustment
- Text field for direct input
- ActionChip presets for quick selection

#### Time Signature Selector

```dart
SegmentedButton<int>(
  segments: [2, 3, 4, 6, 8].map((t) =>
    ButtonSegment<int>(value: t, label: Text("$t/4"))
  ).toList(),
  selected: {metro.timeSignature},
  onSelectionChanged: (Set<int> newSelection) { ... },
)
```

#### Play Controls

- Tap tempo button (circular record icon)
- Play/pause FloatingActionButton
- Stop button

## Keywords

The provider responds to these keywords:
- metronome
- beat
- bpm
- tempo
- rhythm
- music
- tap
- pulse

## Material 3 Components Used

- `Card.filled` for card container
- `SegmentedButton` for time signature selection
- `ActionChip` for BPM presets
- `FloatingActionButton` for play/pause control
- `IconButton` for tap tempo and stop controls

## Testing

34 tests cover the Metronome provider:
- Model initialization
- BPM operations (set, increment, decrement, clamping)
- Time signature operations
- Start/pause/stop/toggle functionality
- History operations (save, load, clear)
- Tap tempo functionality
- Widget rendering tests

## Memory Management

The model properly cancels timers in `dispose()`:

```dart
@override
void dispose() {
  _timer?.cancel();
  _beatFlashTimer?.cancel();
  super.dispose();
}
```

## Performance Considerations

- Timer interval recalculated on BPM change while running
- Visual flash duration clamped between 50-200ms
- Beat indicator state managed via `notifyListeners()`