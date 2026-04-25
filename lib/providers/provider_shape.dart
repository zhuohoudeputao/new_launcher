import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

ShapeModel shapeModel = ShapeModel();

MyProvider providerShape = MyProvider(
    name: "Shape",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'ShapeCalculator',
      keywords: 'shape geometry circle rectangle triangle sphere cylinder cone area perimeter volume surface diagonal radius diameter',
      action: () => shapeModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await shapeModel.init();
  Global.infoModel.addInfoWidget(
      "ShapeCalculator",
      ChangeNotifierProvider.value(
          value: shapeModel,
          builder: (context, child) => ShapeCard()),
      title: "Shape Calculator");
}

Future<void> _update() async {
  shapeModel.refresh();
}

class ShapeHistoryEntry {
  final DateTime date;
  final String shapeType;
  final Map<String, double> inputs;
  final Map<String, double> results;

  ShapeHistoryEntry({
    required this.date,
    required this.shapeType,
    required this.inputs,
    required this.results,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'shapeType': shapeType,
      'inputs': inputs,
      'results': results,
    });
  }

  static ShapeHistoryEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final inputsMap = (map['inputs'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    final resultsMap = (map['results'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    return ShapeHistoryEntry(
      date: DateTime.parse(map['date'] as String),
      shapeType: map['shapeType'] as String,
      inputs: inputsMap,
      results: resultsMap,
    );
  }

  String get displayText {
    switch (shapeType) {
      case 'circle':
        final r = inputs['radius'] ?? 0;
        return 'Circle (r=$r): A=${_format(results['area']!)}, C=${_format(results['circumference']!)}';
      case 'rectangle':
        final w = inputs['width'] ?? 0;
        final h = inputs['height'] ?? 0;
        return 'Rectangle ($w×$h): A=${_format(results['area']!)}, P=${_format(results['perimeter']!)}, D=${_format(results['diagonal']!)}';
      case 'triangle':
        final b = inputs['base'] ?? 0;
        final h = inputs['height'] ?? 0;
        return 'Triangle (b=$b, h=$h): A=${_format(results['area']!)}';
      case 'sphere':
        final r = inputs['radius'] ?? 0;
        return 'Sphere (r=$r): V=${_format(results['volume']!)}, SA=${_format(results['surfaceArea']!)}';
      case 'cylinder':
        final r = inputs['radius'] ?? 0;
        final h = inputs['height'] ?? 0;
        return 'Cylinder (r=$r, h=$h): V=${_format(results['volume']!)}, SA=${_format(results['surfaceArea']!)}';
      case 'cone':
        final r = inputs['radius'] ?? 0;
        final h = inputs['height'] ?? 0;
        return 'Cone (r=$r, h=$h): V=${_format(results['volume']!)}, SA=${_format(results['surfaceArea']!)}';
      default:
        return '';
    }
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }
}

class ShapeModel extends ChangeNotifier {
  static const int maxHistory = 10;
  static const String _storageKey = 'shape_history';

  List<ShapeHistoryEntry> _history = [];
  String _shapeType = 'circle';
  Map<String, double> _inputs = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  String get shapeType => _shapeType;
  List<ShapeHistoryEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  Map<String, double> get inputs => _inputs;

  Map<String, double> get results {
    switch (_shapeType) {
      case 'circle':
        return _calculateCircle();
      case 'rectangle':
        return _calculateRectangle();
      case 'triangle':
        return _calculateTriangle();
      case 'sphere':
        return _calculateSphere();
      case 'cylinder':
        return _calculateCylinder();
      case 'cone':
        return _calculateCone();
      default:
        return {};
    }
  }

  Map<String, double> _calculateCircle() {
    final radius = _inputs['radius'] ?? 0;
    if (radius <= 0) return {};
    
    return {
      'diameter': 2 * radius,
      'circumference': 2 * pi * radius,
      'area': pi * radius * radius,
    };
  }

  Map<String, double> _calculateRectangle() {
    final width = _inputs['width'] ?? 0;
    final height = _inputs['height'] ?? 0;
    if (width <= 0 || height <= 0) return {};
    
    return {
      'area': width * height,
      'perimeter': 2 * (width + height),
      'diagonal': sqrt(width * width + height * height),
    };
  }

  Map<String, double> _calculateTriangle() {
    final base = _inputs['base'] ?? 0;
    final height = _inputs['height'] ?? 0;
    if (base <= 0 || height <= 0) return {};
    
    return {
      'area': 0.5 * base * height,
    };
  }

  Map<String, double> _calculateSphere() {
    final radius = _inputs['radius'] ?? 0;
    if (radius <= 0) return {};
    
    return {
      'diameter': 2 * radius,
      'surfaceArea': 4 * pi * radius * radius,
      'volume': (4 / 3) * pi * radius * radius * radius,
    };
  }

  Map<String, double> _calculateCylinder() {
    final radius = _inputs['radius'] ?? 0;
    final height = _inputs['height'] ?? 0;
    if (radius <= 0 || height <= 0) return {};
    
    return {
      'volume': pi * radius * radius * height,
      'surfaceArea': 2 * pi * radius * (radius + height),
    };
  }

  Map<String, double> _calculateCone() {
    final radius = _inputs['radius'] ?? 0;
    final height = _inputs['height'] ?? 0;
    if (radius <= 0 || height <= 0) return {};
    
    final slant = sqrt(radius * radius + height * height);
    return {
      'volume': (1 / 3) * pi * radius * radius * height,
      'surfaceArea': pi * radius * (radius + slant),
    };
  }

  String get shapeName {
    switch (_shapeType) {
      case 'circle':
        return 'Circle';
      case 'rectangle':
        return 'Rectangle';
      case 'triangle':
        return 'Triangle';
      case 'sphere':
        return 'Sphere';
      case 'cylinder':
        return 'Cylinder';
      case 'cone':
        return 'Cone';
      default:
        return '';
    }
  }

  String get shapeIcon {
    switch (_shapeType) {
      case 'circle':
        return '⭕';
      case 'rectangle':
        return '⬛';
      case 'triangle':
        return '🔺';
      case 'sphere':
        return '🔮';
      case 'cylinder':
        return '🛢️';
      case 'cone':
        return '📐';
      default:
        return '';
    }
  }

  List<String> get inputLabels {
    switch (_shapeType) {
      case 'circle':
        return ['radius'];
      case 'rectangle':
        return ['width', 'height'];
      case 'triangle':
        return ['base', 'height'];
      case 'sphere':
        return ['radius'];
      case 'cylinder':
        return ['radius', 'height'];
      case 'cone':
        return ['radius', 'height'];
      default:
        return [];
    }
  }

  List<String> get resultLabels {
    switch (_shapeType) {
      case 'circle':
        return ['Diameter', 'Circumference', 'Area'];
      case 'rectangle':
        return ['Area', 'Perimeter', 'Diagonal'];
      case 'triangle':
        return ['Area'];
      case 'sphere':
        return ['Diameter', 'Surface Area', 'Volume'];
      case 'cylinder':
        return ['Volume', 'Surface Area'];
      case 'cone':
        return ['Volume', 'Surface Area'];
      default:
        return [];
    }
  }

  List<String> get resultKeys {
    switch (_shapeType) {
      case 'circle':
        return ['diameter', 'circumference', 'area'];
      case 'rectangle':
        return ['area', 'perimeter', 'diagonal'];
      case 'triangle':
        return ['area'];
      case 'sphere':
        return ['diameter', 'surfaceArea', 'volume'];
      case 'cylinder':
        return ['volume', 'surfaceArea'];
      case 'cone':
        return ['volume', 'surfaceArea'];
      default:
        return [];
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => ShapeHistoryEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Shape Calculator initialized with ${_history.length} entries", source: "Shape");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Shape Calculator refreshed", source: "Shape");
  }

  void setShapeType(String type) {
    _shapeType = type;
    _inputs = {};
    notifyListeners();
  }

  void setInput(String key, double value) {
    _inputs[key] = value;
    notifyListeners();
  }

  void clear() {
    _inputs = {};
    notifyListeners();
    Global.loggerModel.info("Shape Calculator cleared", source: "Shape");
  }

  bool hasValidInput() {
    for (final label in inputLabels) {
      if ((_inputs[label] ?? 0) <= 0) return false;
    }
    return true;
  }

  void saveToHistory() {
    if (!hasValidInput()) return;
    if (results.isEmpty) return;

    _history.insert(0, ShapeHistoryEntry(
      date: DateTime.now(),
      shapeType: _shapeType,
      inputs: Map.from(_inputs),
      results: Map.from(results),
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }
    _save();
    notifyListeners();
    Global.loggerModel.info("Shape calculation saved to history", source: "Shape");
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void loadFromHistory(ShapeHistoryEntry entry) {
    _shapeType = entry.shapeType;
    _inputs = Map.from(entry.inputs);
    notifyListeners();
    Global.loggerModel.info("Loaded shape from history", source: "Shape");
  }

  void clearHistory() {
    _history.clear();
    _save();
    notifyListeners();
    Global.loggerModel.info("Shape history cleared", source: "Shape");
  }
}

class ShapeCard extends StatefulWidget {
  @override
  State<ShapeCard> createState() => _ShapeCardState();
}

class _ShapeCardState extends State<ShapeCard> {
  bool _showHistory = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final label in ['radius', 'width', 'height', 'base']) {
      _controllers[label] = TextEditingController();
      _controllers[label]!.addListener(_onInputChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.removeListener(_onInputChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _onInputChanged() {
    final model = context.read<ShapeModel>();
    for (final label in model.inputLabels) {
      final value = double.tryParse(_controllers[label]?.text ?? '');
      if (value != null) {
        model.setInput(label, value);
      } else if ((_controllers[label]?.text ?? '').isEmpty) {
        model.setInput(label, 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shape = context.watch<ShapeModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!shape.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.category, size: 24),
              SizedBox(width: 12),
              Text("Shape Calculator: Loading..."),
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
                Text(
                  "Shape Calculator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (shape.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.calculate : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Calculator" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (shape.hasHistory)
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
            if (_showHistory) _buildHistoryView(shape)
            else _buildCalculatorView(shape),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorView(ShapeModel shape) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildShapeSelector(shape),
        SizedBox(height: 8),
        _buildInputs(shape),
        SizedBox(height: 12),
        if (shape.hasValidInput()) _buildResults(shape),
        SizedBox(height: 8),
        _buildActionButtons(shape),
      ],
    );
  }

  Widget _buildShapeSelector(ShapeModel shape) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'circle', label: Text('Circle')),
        ButtonSegment(value: 'rectangle', label: Text('Rect')),
        ButtonSegment(value: 'triangle', label: Text('Tri')),
        ButtonSegment(value: 'sphere', label: Text('Sphere')),
        ButtonSegment(value: 'cylinder', label: Text('Cyl')),
        ButtonSegment(value: 'cone', label: Text('Cone')),
      ],
      selected: {shape.shapeType},
      onSelectionChanged: (Set<String> selection) {
        context.read<ShapeModel>().setShapeType(selection.first);
        for (final controller in _controllers.values) {
          controller.clear();
        }
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildInputs(ShapeModel shape) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: shape.inputLabels.map((label) {
        return Padding(
          padding: EdgeInsets.only(bottom: shape.inputLabels.length > 1 && shape.inputLabels.last != label ? 8 : 0),
          child: TextField(
            controller: _controllers[label],
            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: _getInputLabel(shape.shapeType, label),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              suffixText: shape.shapeType == 'circle' || shape.shapeType == 'sphere' || 
                          shape.shapeType == 'cylinder' || shape.shapeType == 'cone' ||
                          shape.shapeType == 'triangle' ? '' : '',
            ),
            style: TextStyle(fontSize: 18),
          ),
        );
      }).toList(),
    );
  }

  String _getInputLabel(String shapeType, String label) {
    switch (shapeType) {
      case 'circle':
        return 'Radius';
      case 'rectangle':
        return label == 'width' ? 'Width' : 'Height';
      case 'triangle':
        return label == 'base' ? 'Base' : 'Height';
      case 'sphere':
        return 'Radius';
      case 'cylinder':
        return label == 'radius' ? 'Radius' : 'Height';
      case 'cone':
        return label == 'radius' ? 'Radius' : 'Height';
      default:
        return label;
    }
  }

  Widget _buildResults(ShapeModel shape) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(shape.shapeIcon, style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                shape.shapeName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: shape.resultLabels.asMap().entries.map((entry) {
              final idx = entry.key;
              final label = entry.value;
              final key = shape.resultKeys[idx];
              final value = shape.results[key] ?? 0;
              
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatResult(value),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatResult(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    if (value.abs() < 0.01) return value.toStringAsExponential(2);
    if (value.abs() > 10000) return value.toStringAsExponential(2);
    return value.toStringAsFixed(2);
  }

  Widget _buildActionButtons(ShapeModel shape) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: shape.hasValidInput() ? () => shape.saveToHistory() : null,
          icon: Icon(Icons.save, size: 18),
          label: Text("Save"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            shape.clear();
            for (final controller in _controllers.values) {
              controller.clear();
            }
          },
          icon: Icon(Icons.clear_all, size: 18),
          label: Text("Clear"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(ShapeModel shape) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: shape.history.length,
        itemBuilder: (context, index) {
          final entry = shape.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.category, size: 20),
            title: Text(
              entry.displayText,
              style: TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatDate(entry.date),
              style: TextStyle(fontSize: 10),
            ),
            onTap: () {
              context.read<ShapeModel>().loadFromHistory(entry);
              for (final label in entry.inputs.keys) {
                if (_controllers.containsKey(label)) {
                  _controllers[label]!.text = entry.inputs[label].toString();
                }
              }
              setState(() => _showHistory = false);
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all shape calculation history?"),
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
      context.read<ShapeModel>().clearHistory();
    }
  }
}