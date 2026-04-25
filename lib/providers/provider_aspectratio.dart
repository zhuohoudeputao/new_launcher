import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AspectRatioModel extends ChangeNotifier {
  int _width = 1920;
  int _height = 1080;
  int _targetWidth = 0;
  int _targetHeight = 0;
  int _selectedPresetIndex = 1;
  List<AspectRatioHistoryEntry> _history = [];
  bool _showHistory = false;

  int get width => _width;
  int get height => _height;
  int get targetWidth => _targetWidth;
  int get targetHeight => _targetHeight;
  int get selectedPresetIndex => _selectedPresetIndex;
  List<AspectRatioHistoryEntry> get history => _history;
  bool get showHistory => _showHistory;

  final List<AspectRatioPreset> presets = [
    AspectRatioPreset(name: '1:1', width: 1, height: 1),
    AspectRatioPreset(name: '4:3', width: 4, height: 3),
    AspectRatioPreset(name: '3:2', width: 3, height: 2),
    AspectRatioPreset(name: '16:9', width: 16, height: 9),
    AspectRatioPreset(name: '16:10', width: 16, height: 10),
    AspectRatioPreset(name: '21:9', width: 21, height: 9),
    AspectRatioPreset(name: '2:3', width: 2, height: 3),
    AspectRatioPreset(name: '3:4', width: 3, height: 4),
    AspectRatioPreset(name: '9:16', width: 9, height: 16),
    AspectRatioPreset(name: '10:16', width: 10, height: 16),
  ];

  AspectRatioModel() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final saved = await Global.getValue('aspectratio_history', '');
    if (saved.isNotEmpty) {
      final entries = saved.split('|');
      _history = entries.map((e) {
        final parts = e.split(',');
        return AspectRatioHistoryEntry(
          width: int.parse(parts[0]),
          height: int.parse(parts[1]),
          ratio: parts[2],
          timestamp: DateTime.parse(parts[3]),
        );
      }).toList();
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = _history.map((e) =>
        '${e.width},${e.height},${e.ratio},${e.timestamp.toIso8601String()}'
      ).join('|');
      await prefs.setString('aspectratio_history', entries);
    } catch (e) {
      Global.loggerModel.error('AspectRatio save history error: $e');
    }
  }

  void setWidth(int value) {
    _width = value;
    _calculateFromInputs();
    notifyListeners();
  }

  void setHeight(int value) {
    _height = value;
    _calculateFromInputs();
    notifyListeners();
  }

  void setTargetWidth(int value) {
    _targetWidth = value;
    if (_targetWidth > 0 && _selectedPresetIndex >= 0) {
      final preset = presets[_selectedPresetIndex];
      _targetHeight = (_targetWidth * preset.height / preset.width).round();
    }
    notifyListeners();
  }

  void setTargetHeight(int value) {
    _targetHeight = value;
    if (_targetHeight > 0 && _selectedPresetIndex >= 0) {
      final preset = presets[_selectedPresetIndex];
      _targetWidth = (_targetHeight * preset.width / preset.height).round();
    }
    notifyListeners();
  }

  void setSelectedPreset(int index) {
    _selectedPresetIndex = index;
    if (_targetWidth > 0) {
      final preset = presets[index];
      _targetHeight = (_targetWidth * preset.height / preset.width).round();
    } else if (_targetHeight > 0) {
      final preset = presets[index];
      _targetWidth = (_targetHeight * preset.width / preset.height).round();
    }
    notifyListeners();
  }

  void _calculateFromInputs() {
    if (_width > 0 && _height > 0) {
      addToHistory(_width, _height);
    }
  }

  int gcd(int a, int b) {
    while (b != 0) {
      final temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  String calculateRatio(int w, int h) {
    if (w <= 0 || h <= 0) return 'N/A';
    final g = gcd(w, h);
    final ratioW = w / g;
    final ratioH = h / g;
    return '${ratioW.toInt()}:${ratioH.toInt()}';
  }

  double calculateDecimalRatio(int w, int h) {
    if (h <= 0) return 0;
    return w / h;
  }

  void addToHistory(int w, int h) {
    final ratio = calculateRatio(w, h);
    final entry = AspectRatioHistoryEntry(
      width: w,
      height: h,
      ratio: ratio,
      timestamp: DateTime.now(),
    );
    _history.insert(0, entry);
    if (_history.length > 10) {
      _history.removeLast();
    }
    _saveHistory();
    notifyListeners();
  }

  void loadFromHistory(AspectRatioHistoryEntry entry) {
    _width = entry.width;
    _height = entry.height;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _saveHistory();
    notifyListeners();
  }

  void toggleHistory() {
    _showHistory = !_showHistory;
    notifyListeners();
  }

  void clearInputs() {
    _width = 1920;
    _height = 1080;
    _targetWidth = 0;
    _targetHeight = 0;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class AspectRatioPreset {
  final String name;
  final int width;
  final int height;

  AspectRatioPreset({
    required this.name,
    required this.width,
    required this.height,
  });
}

class AspectRatioHistoryEntry {
  final int width;
  final int height;
  final String ratio;
  final DateTime timestamp;

  AspectRatioHistoryEntry({
    required this.width,
    required this.height,
    required this.ratio,
    required this.timestamp,
  });
}

final AspectRatioModel aspectRatioModel = AspectRatioModel();

MyProvider providerAspectRatio = MyProvider(
  name: "AspectRatio",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "AspectRatio Calculator",
        keywords: "aspectratio, aspect, ratio, dimensions, width, height, calculate, calculator, image, video, resize, screen, resolution",
        action: () {
          Global.infoModel.addInfoWidget("AspectRatioCalculator", AspectRatioCalculatorCard(), title: "AspectRatio Calculator");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    Global.infoModel.addInfoWidget("AspectRatioCalculator", AspectRatioCalculatorCard(), title: "AspectRatio Calculator");
  },
  update: () {
    aspectRatioModel.refresh();
  },
);

class AspectRatioCalculatorCard extends StatefulWidget {
  @override
  State<AspectRatioCalculatorCard> createState() => _AspectRatioCalculatorCardState();
}

class _AspectRatioCalculatorCardState extends State<AspectRatioCalculatorCard> {
  final _widthController = TextEditingController(text: '1920');
  final _heightController = TextEditingController(text: '1080');
  final _targetWidthController = TextEditingController(text: '');
  final _targetHeightController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _widthController.text = aspectRatioModel.width.toString();
    _heightController.text = aspectRatioModel.height.toString();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _targetWidthController.dispose();
    _targetHeightController.dispose();
    super.dispose();
  }

  void _updateWidth(String value) {
    final num = int.tryParse(value) ?? 0;
    aspectRatioModel.setWidth(num);
    setState(() {});
  }

  void _updateHeight(String value) {
    final num = int.tryParse(value) ?? 0;
    aspectRatioModel.setHeight(num);
    setState(() {});
  }

  void _updateTargetWidth(String value) {
    final num = int.tryParse(value) ?? 0;
    aspectRatioModel.setTargetWidth(num);
    _targetHeightController.text = aspectRatioModel.targetHeight > 0 
      ? aspectRatioModel.targetHeight.toString() 
      : '';
    setState(() {});
  }

  void _updateTargetHeight(String value) {
    final num = int.tryParse(value) ?? 0;
    aspectRatioModel.setTargetHeight(num);
    _targetWidthController.text = aspectRatioModel.targetWidth > 0 
      ? aspectRatioModel.targetWidth.toString() 
      : '';
    setState(() {});
  }

  void _selectPreset(int index) {
    aspectRatioModel.setSelectedPreset(index);
    if (aspectRatioModel.targetWidth > 0) {
      _targetHeightController.text = aspectRatioModel.targetHeight.toString();
    } else if (aspectRatioModel.targetHeight > 0) {
      _targetWidthController.text = aspectRatioModel.targetWidth.toString();
    }
    setState(() {});
  }

  void _clearInputs() {
    aspectRatioModel.clearInputs();
    _widthController.text = '1920';
    _heightController.text = '1080';
    _targetWidthController.text = '';
    _targetHeightController.text = '';
    setState(() {});
  }

  void _toggleHistory() {
    aspectRatioModel.toggleHistory();
    setState(() {});
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = aspectRatioModel.calculateRatio(aspectRatioModel.width, aspectRatioModel.height);
    final decimal = aspectRatioModel.calculateDecimalRatio(aspectRatioModel.width, aspectRatioModel.height);
    
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.aspect_ratio, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AspectRatio Calculator',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputSection(context),
            const SizedBox(height: 12),
            _buildResultSection(context, ratio, decimal),
            const SizedBox(height: 12),
            _buildPresetSection(context),
            const SizedBox(height: 12),
            _buildTargetSection(context),
            const SizedBox(height: 16),
            _buildButtons(context),
            if (aspectRatioModel.showHistory) _buildHistorySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Dimensions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Width',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                controller: _widthController,
                onChanged: _updateWidth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                controller: _heightController,
                onChanged: _updateHeight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultSection(BuildContext context, String ratio, double decimal) {
    return Card.outlined(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text('Ratio', style: TextStyle(fontSize: 12)),
                Text(ratio, style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
              ],
            ),
            Column(
              children: [
                Text('Decimal', style: TextStyle(fontSize: 12)),
                Text(decimal.toStringAsFixed(3), style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Common Ratios',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: aspectRatioModel.presets.asMap().entries.map((entry) {
            final isSelected = aspectRatioModel.selectedPresetIndex == entry.key;
            return ActionChip(
              label: Text(entry.value.name),
              onPressed: () => _selectPreset(entry.key),
              side: isSelected
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTargetSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculate Target Dimensions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Width',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                controller: _targetWidthController,
                onChanged: _updateTargetWidth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Height',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                controller: _targetHeightController,
                onChanged: _updateTargetHeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${aspectRatioModel.presets[aspectRatioModel.selectedPresetIndex].name}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _clearInputs,
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Clear'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _toggleHistory,
          icon: Icon(
            aspectRatioModel.showHistory ? Icons.history : Icons.history_toggle_off,
            size: 18,
          ),
          label: Text(aspectRatioModel.showHistory ? 'Hide History' : 'History'),
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    if (aspectRatioModel.history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          'No history',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'History (${aspectRatioModel.history.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text('Are you sure you want to clear all history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          aspectRatioModel.clearHistory();
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...aspectRatioModel.history.map((entry) => ListTile(
          dense: true,
          leading: const Icon(Icons.aspect_ratio, size: 20),
          title: Text('${entry.width} × ${entry.height}'),
          subtitle: Text(entry.ratio),
          trailing: Text(
            _formatTimestamp(entry.timestamp),
            style: TextStyle(fontSize: 12),
          ),
          onTap: () {
            aspectRatioModel.loadFromHistory(entry);
            _widthController.text = entry.width.toString();
            _heightController.text = entry.height.toString();
            setState(() {});
          },
        )),
      ],
    );
  }
}