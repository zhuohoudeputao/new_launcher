import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

BandwidthCalculatorModel bandwidthCalculatorModel = BandwidthCalculatorModel();

MyProvider providerBandwidthCalculator = MyProvider(
    name: "BandwidthCalculator",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Bandwidth Calculator',
      keywords: 'bandwidth download upload speed time calculate network transfer',
      action: () => bandwidthCalculatorModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  bandwidthCalculatorModel.init();
  Global.infoModel.addInfoWidget(
      "BandwidthCalculator",
      ChangeNotifierProvider.value(
          value: bandwidthCalculatorModel,
          builder: (context, child) => BandwidthCalculatorCard()),
      title: "Bandwidth Calculator");
}

Future<void> _update() async {
  bandwidthCalculatorModel.refresh();
}

enum BandwidthSizeUnit {
  bytes,
  kilobyte,
  megabyte,
  gigabyte,
  terabyte,
}

enum BandwidthSpeedUnit {
  bps,
  Kbps,
  Mbps,
  Gbps,
}

class BandwidthSizeUnitInfo {
  final String name;
  final String symbol;
  final double multiplier;

  const BandwidthSizeUnitInfo({
    required this.name,
    required this.symbol,
    required this.multiplier,
  });
}

class BandwidthSpeedUnitInfo {
  final String name;
  final String symbol;
  final double multiplier;

  const BandwidthSpeedUnitInfo({
    required this.name,
    required this.symbol,
    required this.multiplier,
  });
}

const Map<BandwidthSizeUnit, BandwidthSizeUnitInfo> bandwidthSizeUnits = {
  BandwidthSizeUnit.bytes: BandwidthSizeUnitInfo(name: 'Bytes', symbol: 'B', multiplier: 1.0),
  BandwidthSizeUnit.kilobyte: BandwidthSizeUnitInfo(name: 'Kilobyte', symbol: 'KB', multiplier: 1024.0),
  BandwidthSizeUnit.megabyte: BandwidthSizeUnitInfo(name: 'Megabyte', symbol: 'MB', multiplier: 1024.0 * 1024.0),
  BandwidthSizeUnit.gigabyte: BandwidthSizeUnitInfo(name: 'Gigabyte', symbol: 'GB', multiplier: 1024.0 * 1024.0 * 1024.0),
  BandwidthSizeUnit.terabyte: BandwidthSizeUnitInfo(name: 'Terabyte', symbol: 'TB', multiplier: 1024.0 * 1024.0 * 1024.0 * 1024.0),
};

const Map<BandwidthSpeedUnit, BandwidthSpeedUnitInfo> bandwidthSpeedUnits = {
  BandwidthSpeedUnit.bps: BandwidthSpeedUnitInfo(name: 'Bits/s', symbol: 'bps', multiplier: 1.0),
  BandwidthSpeedUnit.Kbps: BandwidthSpeedUnitInfo(name: 'Kilobits/s', symbol: 'Kbps', multiplier: 1000.0),
  BandwidthSpeedUnit.Mbps: BandwidthSpeedUnitInfo(name: 'Megabits/s', symbol: 'Mbps', multiplier: 1000000.0),
  BandwidthSpeedUnit.Gbps: BandwidthSpeedUnitInfo(name: 'Gigabits/s', symbol: 'Gbps', multiplier: 1000000000.0),
};

enum CalculationMode {
  timeFromSizeSpeed,
  speedFromSizeTime,
  sizeFromSpeedTime,
}

class BandwidthHistoryEntry {
  final CalculationMode mode;
  final double fileSize;
  final BandwidthSizeUnit sizeUnit;
  final double speed;
  final BandwidthSpeedUnit speedUnit;
  final double timeSeconds;
  final String resultText;
  final DateTime timestamp;

  BandwidthHistoryEntry({
    required this.mode,
    required this.fileSize,
    required this.sizeUnit,
    required this.speed,
    required this.speedUnit,
    required this.timeSeconds,
    required this.resultText,
    required this.timestamp,
  });

  String get sizeSymbol => bandwidthSizeUnits[sizeUnit]?.symbol ?? '';
  String get speedSymbol => bandwidthSpeedUnits[speedUnit]?.symbol ?? '';
}

class BandwidthCalculatorModel extends ChangeNotifier {
  CalculationMode _mode = CalculationMode.timeFromSizeSpeed;
  BandwidthSizeUnit _sizeUnit = BandwidthSizeUnit.megabyte;
  BandwidthSpeedUnit _speedUnit = BandwidthSpeedUnit.Mbps;
  String _fileSize = '100';
  String _speed = '100';
  String _timeMinutes = '10';
  String _result = '';
  bool _isInitialized = false;
  final List<BandwidthHistoryEntry> _history = [];
  static const int maxHistory = 10;

  CalculationMode get mode => _mode;
  BandwidthSizeUnit get sizeUnit => _sizeUnit;
  BandwidthSpeedUnit get speedUnit => _speedUnit;
  String get fileSize => _fileSize;
  String get speed => _speed;
  String get timeMinutes => _timeMinutes;
  String get result => _result;
  bool get isInitialized => _isInitialized;
  List<BandwidthHistoryEntry> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;

  void init() {
    _isInitialized = true;
    _calculate();
    Global.loggerModel.info("BandwidthCalculator initialized", source: "BandwidthCalculator");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("BandwidthCalculator refreshed", source: "BandwidthCalculator");
  }

  void setMode(CalculationMode mode) {
    _mode = mode;
    _calculate();
    notifyListeners();
  }

  void setSizeUnit(BandwidthSizeUnit unit) {
    _sizeUnit = unit;
    _calculate();
    notifyListeners();
  }

  void setSpeedUnit(BandwidthSpeedUnit unit) {
    _speedUnit = unit;
    _calculate();
    notifyListeners();
  }

  void setFileSize(String value) {
    _fileSize = value;
    _calculate();
    notifyListeners();
  }

  void setSpeed(String value) {
    _speed = value;
    _calculate();
    notifyListeners();
  }

  void setTimeMinutes(String value) {
    _timeMinutes = value;
    _calculate();
    notifyListeners();
  }

  void clear() {
    _fileSize = '0';
    _speed = '0';
    _timeMinutes = '0';
    _result = '';
    notifyListeners();
    Global.loggerModel.info("BandwidthCalculator cleared", source: "BandwidthCalculator");
  }

  void _calculate() {
    switch (_mode) {
      case CalculationMode.timeFromSizeSpeed:
        _calculateTimeFromSizeSpeed();
        break;
      case CalculationMode.speedFromSizeTime:
        _calculateSpeedFromSizeTime();
        break;
      case CalculationMode.sizeFromSpeedTime:
        _calculateSizeFromSpeedTime();
        break;
    }
  }

  void _calculateTimeFromSizeSpeed() {
    final size = double.tryParse(_fileSize);
    final speedVal = double.tryParse(_speed);
    if (size == null || speedVal == null || speedVal <= 0) {
      _result = 'Invalid input';
      return;
    }

    final bytesMultiplier = bandwidthSizeUnits[_sizeUnit]?.multiplier ?? 1.0;
    final bitsMultiplier = bandwidthSpeedUnits[_speedUnit]?.multiplier ?? 1.0;

    final totalBytes = size * bytesMultiplier;
    final totalBits = totalBytes * 8;
    final bitsPerSecond = speedVal * bitsMultiplier;
    final seconds = totalBits / bitsPerSecond;

    _result = _formatTime(seconds);
  }

  void _calculateSpeedFromSizeTime() {
    final size = double.tryParse(_fileSize);
    final timeMin = double.tryParse(_timeMinutes);
    if (size == null || timeMin == null || timeMin <= 0) {
      _result = 'Invalid input';
      return;
    }

    final bytesMultiplier = bandwidthSizeUnits[_sizeUnit]?.multiplier ?? 1.0;
    final totalBytes = size * bytesMultiplier;
    final totalBits = totalBytes * 8;
    final seconds = timeMin * 60;
    final bitsPerSecond = totalBits / seconds;

    final mbps = bitsPerSecond / 1000000.0;
    final kbps = bitsPerSecond / 1000.0;

    if (mbps >= 1) {
      _result = '${_formatNumber(mbps)} Mbps';
    } else {
      _result = '${_formatNumber(kbps)} Kbps';
    }
  }

  void _calculateSizeFromSpeedTime() {
    final speedVal = double.tryParse(_speed);
    final timeMin = double.tryParse(_timeMinutes);
    if (speedVal == null || timeMin == null || timeMin <= 0) {
      _result = 'Invalid input';
      return;
    }

    final bitsMultiplier = bandwidthSpeedUnits[_speedUnit]?.multiplier ?? 1.0;
    final bitsPerSecond = speedVal * bitsMultiplier;
    final seconds = timeMin * 60;
    final totalBits = bitsPerSecond * seconds;
    final totalBytes = totalBits / 8;

    _result = _formatSize(totalBytes);
  }

  String _formatTime(double seconds) {
    if (seconds < 1) {
      final ms = seconds * 1000;
      return '${_formatNumber(ms)} ms';
    }

    if (seconds < 60) {
      return '${_formatNumber(seconds)} seconds';
    }

    final minutes = seconds / 60;
    if (minutes < 60) {
      return '${_formatNumber(minutes)} minutes';
    }

    final hours = minutes / 60;
    if (hours < 24) {
      return '${_formatNumber(hours)} hours';
    }

    final days = hours / 24;
    return '${_formatNumber(days)} days';
  }

  String _formatSize(double bytes) {
    if (bytes < 1024) {
      return '${_formatNumber(bytes)} B';
    }

    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${_formatNumber(kb)} KB';
    }

    final mb = kb / 1024;
    if (mb < 1024) {
      return '${_formatNumber(mb)} MB';
    }

    final gb = mb / 1024;
    if (gb < 1024) {
      return '${_formatNumber(gb)} GB';
    }

    final tb = gb / 1024;
    return '${_formatNumber(tb)} TB';
  }

  String _formatNumber(double value) {
    if (value == value.toInt() && value.abs() < 1e10) {
      return value.toInt().toString();
    }

    if (value.abs() < 0.01) {
      return value.toStringAsFixed(4);
    }

    if (value.abs() < 100) {
      return value.toStringAsFixed(2);
    }

    String result = value.toStringAsFixed(1);
    result = result.replaceAll(RegExp(r'0+$'), '');
    result = result.replaceAll(RegExp(r'\.$'), '');
    return result;
  }

  void addToHistory() {
    final size = double.tryParse(_fileSize);
    final speedVal = double.tryParse(_speed);
    final timeMin = double.tryParse(_timeMinutes);

    if (size == null || size == 0 || _result.isEmpty || _result == 'Invalid input') {
      return;
    }

    double timeSeconds = 0;
    switch (_mode) {
      case CalculationMode.timeFromSizeSpeed:
        if (speedVal == null || speedVal <= 0) return;
        final bytesMultiplier = bandwidthSizeUnits[_sizeUnit]?.multiplier ?? 1.0;
        final bitsMultiplier = bandwidthSpeedUnits[_speedUnit]?.multiplier ?? 1.0;
        final totalBytes = size * bytesMultiplier;
        final totalBits = totalBytes * 8;
        final bitsPerSecond = speedVal * bitsMultiplier;
        timeSeconds = totalBits / bitsPerSecond;
        break;
      case CalculationMode.speedFromSizeTime:
        if (timeMin == null || timeMin <= 0) return;
        timeSeconds = timeMin * 60;
        break;
      case CalculationMode.sizeFromSpeedTime:
        if (speedVal == null || timeMin == null || speedVal <= 0 || timeMin <= 0) return;
        timeSeconds = timeMin * 60;
        break;
    }

    _history.insert(0, BandwidthHistoryEntry(
      mode: _mode,
      fileSize: size,
      sizeUnit: _sizeUnit,
      speed: speedVal ?? 0,
      speedUnit: _speedUnit,
      timeSeconds: timeSeconds,
      resultText: _result,
      timestamp: DateTime.now(),
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }

    notifyListeners();
    Global.loggerModel.info("Bandwidth calculation added to history", source: "BandwidthCalculator");
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("BandwidthCalculator history cleared", source: "BandwidthCalculator");
  }

  void useHistoryEntry(BandwidthHistoryEntry entry) {
    _mode = entry.mode;
    _sizeUnit = entry.sizeUnit;
    _speedUnit = entry.speedUnit;
    _fileSize = entry.fileSize.toString();

    switch (entry.mode) {
      case CalculationMode.timeFromSizeSpeed:
        _speed = entry.speed.toString();
        break;
      case CalculationMode.speedFromSizeTime:
        _timeMinutes = (entry.timeSeconds / 60).toString();
        break;
      case CalculationMode.sizeFromSpeedTime:
        _speed = entry.speed.toString();
        _timeMinutes = (entry.timeSeconds / 60).toString();
        break;
    }

    _calculate();
    notifyListeners();
  }
}

class BandwidthCalculatorCard extends StatefulWidget {
  @override
  State<BandwidthCalculatorCard> createState() => _BandwidthCalculatorCardState();
}

class _BandwidthCalculatorCardState extends State<BandwidthCalculatorCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final calculator = context.watch<BandwidthCalculatorModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!calculator.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.network_check, size: 24),
              SizedBox(width: 12),
              Text("Bandwidth Calculator: Loading..."),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.network_check, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Bandwidth Calculator",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (calculator.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.network_check : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Calculator" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (calculator.hasHistory)
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
            if (_showHistory) _buildHistoryView(calculator)
            else _buildCalculatorView(calculator),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorView(BandwidthCalculatorModel calculator) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeSelector(calculator),
        SizedBox(height: 12),
        _buildInputSection(calculator),
        SizedBox(height: 12),
        _buildResultSection(calculator),
      ],
    );
  }

  Widget _buildModeSelector(BandwidthCalculatorModel calculator) {
    return SegmentedButton<CalculationMode>(
      segments: [
        ButtonSegment(
          value: CalculationMode.timeFromSizeSpeed,
          label: Text('Time', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.timer, size: 18),
        ),
        ButtonSegment(
          value: CalculationMode.speedFromSizeTime,
          label: Text('Speed', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.speed, size: 18),
        ),
        ButtonSegment(
          value: CalculationMode.sizeFromSpeedTime,
          label: Text('Size', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.sd_card, size: 18),
        ),
      ],
      selected: {calculator.mode},
      onSelectionChanged: (Set<CalculationMode> newSelection) {
        calculator.setMode(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildInputSection(BandwidthCalculatorModel calculator) {
    switch (calculator.mode) {
      case CalculationMode.timeFromSizeSpeed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildFileSizeInput(calculator),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildSpeedInput(calculator),
                ),
              ],
            ),
          ],
        );
      case CalculationMode.speedFromSizeTime:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildFileSizeInput(calculator),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildTimeInput(calculator),
                ),
              ],
            ),
          ],
        );
      case CalculationMode.sizeFromSpeedTime:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSpeedInput(calculator),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildTimeInput(calculator),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildFileSizeInput(BandwidthCalculatorModel calculator) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('File Size', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                controller: TextEditingController(text: calculator.fileSize),
                onChanged: (value) => calculator.setFileSize(value),
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: _buildSizeUnitDropdown(calculator),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeUnitDropdown(BandwidthCalculatorModel calculator) {
    return DropdownButton<BandwidthSizeUnit>(
      value: calculator.sizeUnit,
      isExpanded: true,
      underline: Container(),
      items: BandwidthSizeUnit.values.map((unit) {
        final info = bandwidthSizeUnits[unit];
        return DropdownMenuItem(
          value: unit,
          child: Text(
            info?.symbol ?? unit.name,
            style: TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          calculator.setSizeUnit(value);
        }
      },
    );
  }

  Widget _buildSpeedInput(BandwidthCalculatorModel calculator) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Speed', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                controller: TextEditingController(text: calculator.speed),
                onChanged: (value) => calculator.setSpeed(value),
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: _buildSpeedUnitDropdown(calculator),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedUnitDropdown(BandwidthCalculatorModel calculator) {
    return DropdownButton<BandwidthSpeedUnit>(
      value: calculator.speedUnit,
      isExpanded: true,
      underline: Container(),
      items: BandwidthSpeedUnit.values.map((unit) {
        final info = bandwidthSpeedUnits[unit];
        return DropdownMenuItem(
          value: unit,
          child: Text(
            info?.symbol ?? unit.name,
            style: TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          calculator.setSpeedUnit(value);
        }
      },
    );
  }

  Widget _buildTimeInput(BandwidthCalculatorModel calculator) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time (minutes)', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        SizedBox(height: 4),
        TextField(
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
          controller: TextEditingController(text: calculator.timeMinutes),
          onChanged: (value) => calculator.setTimeMinutes(value),
        ),
      ],
    );
  }

  Widget _buildResultSection(BandwidthCalculatorModel calculator) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calculate, size: 20, color: colorScheme.onPrimaryContainer),
          SizedBox(width: 8),
          Text(
            calculator.result.isEmpty ? 'Enter values' : calculator.result,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(BandwidthCalculatorModel calculator) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: calculator.history.length,
        itemBuilder: (context, index) {
          final entry = calculator.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(_getHistoryTitle(entry)),
            subtitle: Text(
              entry.resultText,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              calculator.useHistoryEntry(entry);
              setState(() => _showHistory = false);
            },
          );
        },
      ),
    );
  }

  String _getHistoryTitle(BandwidthHistoryEntry entry) {
    switch (entry.mode) {
      case CalculationMode.timeFromSizeSpeed:
        return '${entry.fileSize} ${entry.sizeSymbol} @ ${entry.speed} ${entry.speedSymbol}';
      case CalculationMode.speedFromSizeTime:
        return '${entry.fileSize} ${entry.sizeSymbol} in ${(entry.timeSeconds / 60).toStringAsFixed(1)} min';
      case CalculationMode.sizeFromSpeedTime:
        return '${entry.speed} ${entry.speedSymbol} for ${(entry.timeSeconds / 60).toStringAsFixed(1)} min';
    }
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all bandwidth calculation history?"),
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
      context.read<BandwidthCalculatorModel>().clearHistory();
    }
  }
}