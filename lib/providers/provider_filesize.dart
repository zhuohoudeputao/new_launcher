import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

FileSizeConverterModel fileSizeConverterModel = FileSizeConverterModel();

MyProvider providerFileSizeConverter = MyProvider(
    name: "FileSizeConverter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'FileSize Converter',
      keywords: 'filesize size bytes kb mb gb tb pb converter file storage data',
      action: () => fileSizeConverterModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  fileSizeConverterModel.init();
  Global.infoModel.addInfoWidget(
      "FileSizeConverter",
      ChangeNotifierProvider.value(
          value: fileSizeConverterModel,
          builder: (context, child) => FileSizeConverterCard()),
      title: "FileSize Converter");
}

Future<void> _update() async {
  fileSizeConverterModel.refresh();
}

enum SizeUnit {
  bytes,
  kilobyte,
  megabyte,
  gigabyte,
  terabyte,
  petabyte,
}

class SizeUnitInfo {
  final String name;
  final String symbol;
  final double multiplier;

  const SizeUnitInfo({
    required this.name,
    required this.symbol,
    required this.multiplier,
  });
}

const Map<SizeUnit, SizeUnitInfo> sizeUnits = {
  SizeUnit.bytes: SizeUnitInfo(name: 'Bytes', symbol: 'B', multiplier: 1.0),
  SizeUnit.kilobyte: SizeUnitInfo(name: 'Kilobyte', symbol: 'KB', multiplier: 1024.0),
  SizeUnit.megabyte: SizeUnitInfo(name: 'Megabyte', symbol: 'MB', multiplier: 1024.0 * 1024.0),
  SizeUnit.gigabyte: SizeUnitInfo(name: 'Gigabyte', symbol: 'GB', multiplier: 1024.0 * 1024.0 * 1024.0),
  SizeUnit.terabyte: SizeUnitInfo(name: 'Terabyte', symbol: 'TB', multiplier: 1024.0 * 1024.0 * 1024.0 * 1024.0),
  SizeUnit.petabyte: SizeUnitInfo(name: 'Petabyte', symbol: 'PB', multiplier: 1024.0 * 1024.0 * 1024.0 * 1024.0 * 1024.0),
};

class ConversionHistoryEntry {
  final double inputValue;
  final SizeUnit inputUnit;
  final double outputValue;
  final SizeUnit outputUnit;
  final DateTime timestamp;

  ConversionHistoryEntry({
    required this.inputValue,
    required this.inputUnit,
    required this.outputValue,
    required this.outputUnit,
    required this.timestamp,
  });

  String get inputSymbol => sizeUnits[inputUnit]?.symbol ?? '';
  String get outputSymbol => sizeUnits[outputUnit]?.symbol ?? '';
}

class FileSizeConverterModel extends ChangeNotifier {
  SizeUnit _inputUnit = SizeUnit.megabyte;
  SizeUnit _outputUnit = SizeUnit.gigabyte;
  String _inputValue = '1';
  String _outputValue = '0.000977';
  bool _isInitialized = false;
  final List<ConversionHistoryEntry> _history = [];
  static const int maxHistory = 10;

  SizeUnit get inputUnit => _inputUnit;
  SizeUnit get outputUnit => _outputUnit;
  String get inputValue => _inputValue;
  String get outputValue => _outputValue;
  bool get isInitialized => _isInitialized;
  List<ConversionHistoryEntry> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;

  void init() {
    _isInitialized = true;
    _convert();
    Global.loggerModel.info("FileSizeConverter initialized", source: "FileSizeConverter");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("FileSizeConverter refreshed", source: "FileSizeConverter");
  }

  void setInputUnit(SizeUnit unit) {
    _inputUnit = unit;
    if (_inputUnit == _outputUnit) {
      final otherUnit = SizeUnit.values.firstWhere((u) => u != unit, orElse: () => unit);
      _outputUnit = otherUnit;
    }
    _convert();
    notifyListeners();
  }

  void setOutputUnit(SizeUnit unit) {
    _outputUnit = unit;
    if (_outputUnit == _inputUnit) {
      final otherUnit = SizeUnit.values.firstWhere((u) => u != unit, orElse: () => unit);
      _inputUnit = otherUnit;
    }
    _convert();
    notifyListeners();
  }

  void setInputValue(String value) {
    _inputValue = value;
    _convert();
    notifyListeners();
  }

  void swapUnits() {
    final temp = _inputUnit;
    _inputUnit = _outputUnit;
    _outputUnit = temp;

    final tempValue = _outputValue;
    _inputValue = tempValue;
    _outputValue = _inputValue;

    _convert();
    notifyListeners();
    Global.loggerModel.info("Units swapped", source: "FileSizeConverter");
  }

  void clear() {
    _inputValue = '0';
    _convert();
    notifyListeners();
    Global.loggerModel.info("FileSizeConverter cleared", source: "FileSizeConverter");
  }

  void _convert() {
    final input = double.tryParse(_inputValue);
    if (input == null) {
      _outputValue = '0';
      return;
    }

    final result = convertFileSize(input, _inputUnit, _outputUnit);
    _outputValue = _formatResult(result);
  }

  static double convertFileSize(double value, SizeUnit fromUnit, SizeUnit toUnit) {
    if (fromUnit == toUnit) return value;

    final bytesMultiplier = sizeUnits[fromUnit]?.multiplier ?? 1.0;
    final targetMultiplier = sizeUnits[toUnit]?.multiplier ?? 1.0;

    final bytes = value * bytesMultiplier;
    return bytes / targetMultiplier;
  }

  String _formatResult(double value) {
    if (value == value.toInt() && value.abs() < 1e10) {
      return value.toInt().toString();
    }

    if (value.abs() < 0.0001) {
      return value.toStringAsFixed(10);
    }

    if (value.abs() < 1) {
      return value.toStringAsFixed(6);
    }

    if (value.abs() < 100) {
      return value.toStringAsFixed(4);
    }

    String result = value.toStringAsFixed(2);
    result = result.replaceAll(RegExp(r'0+$'), '');
    result = result.replaceAll(RegExp(r'\.$'), '');
    return result;
  }

  void addToHistory() {
    final input = double.tryParse(_inputValue);
    if (input == null || input == 0) return;

    final output = double.tryParse(_outputValue);
    if (output == null) return;

    _history.insert(0, ConversionHistoryEntry(
      inputValue: input,
      inputUnit: _inputUnit,
      outputValue: output,
      outputUnit: _outputUnit,
      timestamp: DateTime.now(),
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }

    notifyListeners();
    Global.loggerModel.info("Conversion added to history", source: "FileSizeConverter");
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("FileSizeConverter history cleared", source: "FileSizeConverter");
  }

  void useHistoryEntry(ConversionHistoryEntry entry) {
    _inputUnit = entry.inputUnit;
    _outputUnit = entry.outputUnit;
    _inputValue = entry.inputValue.toString();
    _convert();
    notifyListeners();
  }

  String getHumanReadableSize(double bytes) {
    if (bytes <= 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    int unitIndex = 0;
    double size = bytes;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${_formatResult(size)} ${units[unitIndex]}';
  }
}

class FileSizeConverterCard extends StatefulWidget {
  @override
  State<FileSizeConverterCard> createState() => _FileSizeConverterCardState();
}

class _FileSizeConverterCardState extends State<FileSizeConverterCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final converter = context.watch<FileSizeConverterModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!converter.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.sd_card, size: 24),
              SizedBox(width: 12),
              Text("FileSize Converter: Loading..."),
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
                    Icon(Icons.sd_card, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "FileSize Converter",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (converter.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.sd_card : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Converter" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (converter.hasHistory)
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
            if (_showHistory) _buildHistoryView(converter)
            else _buildConverterView(converter),
          ],
        ),
      ),
    );
  }

  Widget _buildConverterView(FileSizeConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildConversionRow(converter),
        SizedBox(height: 8),
        _buildHumanReadable(converter),
      ],
    );
  }

  Widget _buildConversionRow(FileSizeConverterModel converter) {
    return Row(
      children: [
        Expanded(child: _buildInputSection(converter)),
        IconButton(
          icon: Icon(Icons.swap_horiz),
          onPressed: converter.swapUnits,
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(child: _buildOutputSection(converter)),
      ],
    );
  }

  Widget _buildInputSection(FileSizeConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.inputUnit, true),
        SizedBox(height: 4),
        _buildValueField(converter, true),
      ],
    );
  }

  Widget _buildOutputSection(FileSizeConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUnitDropdown(converter, converter.outputUnit, false),
        SizedBox(height: 4),
        _buildValueField(converter, false),
      ],
    );
  }

  Widget _buildUnitDropdown(FileSizeConverterModel converter, SizeUnit currentUnit, bool isInput) {
    return DropdownButton<SizeUnit>(
      value: currentUnit,
      isExpanded: true,
      underline: Container(),
      items: SizeUnit.values.map((unit) {
        final info = sizeUnits[unit];
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
          if (isInput) {
            converter.setInputUnit(value);
          } else {
            converter.setOutputUnit(value);
          }
        }
      },
    );
  }

  Widget _buildValueField(FileSizeConverterModel converter, bool isInput) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isInput) {
      return TextField(
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
        ),
        controller: TextEditingController(text: converter.inputValue),
        onChanged: (value) => converter.setInputValue(value),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Text(
          converter.outputValue,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildHumanReadable(FileSizeConverterModel converter) {
    final input = double.tryParse(converter.inputValue);
    if (input == null || input == 0) {
      return SizedBox.shrink();
    }

    final bytesMultiplier = sizeUnits[converter.inputUnit]?.multiplier ?? 1.0;
    final bytes = input * bytesMultiplier;
    final humanReadable = converter.getHumanReadableSize(bytes);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        SizedBox(width: 4),
        Text(
          '= $humanReadable',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(FileSizeConverterModel converter) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: converter.history.length,
        itemBuilder: (context, index) {
          final entry = converter.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text('${entry.inputValue} ${entry.inputSymbol}'),
            subtitle: Text(
              '= ${entry.outputValue} ${entry.outputSymbol}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              converter.useHistoryEntry(entry);
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
        content: Text("Clear all conversion history?"),
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
      context.read<FileSizeConverterModel>().clearHistory();
    }
  }
}