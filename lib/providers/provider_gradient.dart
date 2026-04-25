import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

GradientModel gradientModel = GradientModel();

MyProvider providerGradient = MyProvider(
    name: "Gradient",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Gradient Generator',
      keywords: 'gradient linear radial colors css flutter design background',
      action: () {
        gradientModel.generateGradient();
        Global.infoModel.addInfoWidget(
            "GradientAction",
            ChangeNotifierProvider.value(
                value: gradientModel,
                builder: (context, child) => _GradientActionCard()),
            title: "Gradient Generator");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  gradientModel.init();
  Global.infoModel.addInfoWidget(
      "Gradient",
      ChangeNotifierProvider.value(
          value: gradientModel,
          builder: (context, child) => GradientCard()),
      title: "Gradient Generator");
}

Future<void> _update() async {
  gradientModel.refresh();
}

class _GradientActionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gradient = context.watch<GradientModel>();
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.gradient, size: 20),
            SizedBox(width: 8),
            Text("Generated ${gradient.gradientType} gradient"),
            SizedBox(width: 8),
            Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                gradient: gradient.currentGradient,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum GradientType {
  linear,
  radial,
}

enum GradientDirection {
  horizontal,
  vertical,
  diagonalUp,
  diagonalDown,
  radialCenter,
}

class GradientModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;
  
  GradientType _gradientType = GradientType.linear;
  GradientDirection _gradientDirection = GradientDirection.horizontal;
  List<Color> _colors = [Colors.blue, Colors.purple];
  LinearGradient? _currentLinearGradient;
  RadialGradient? _currentRadialGradient;
  List<GradientHistoryEntry> _history = [];
  
  bool get isInitialized => _isInitialized;
  GradientType get gradientType => _gradientType;
  GradientDirection get gradientDirection => _gradientDirection;
  List<Color> get colors => List.unmodifiable(_colors);
  Gradient get currentGradient {
    if (_gradientType == GradientType.linear) {
      return _currentLinearGradient ?? LinearGradient(colors: _colors);
    } else {
      return _currentRadialGradient ?? RadialGradient(colors: _colors);
    }
  }
  List<GradientHistoryEntry> get history => List.unmodifiable(_history);
  
  static const List<GradientType> availableTypes = GradientType.values;
  static const List<GradientDirection> availableDirections = GradientDirection.values;
  
  static String getGradientTypeName(GradientType type) {
    switch (type) {
      case GradientType.linear:
        return "Linear";
      case GradientType.radial:
        return "Radial";
    }
  }
  
  static String getGradientDirectionName(GradientDirection dir) {
    switch (dir) {
      case GradientDirection.horizontal:
        return "Horizontal";
      case GradientDirection.vertical:
        return "Vertical";
      case GradientDirection.diagonalUp:
        return "Diagonal Up";
      case GradientDirection.diagonalDown:
        return "Diagonal Down";
      case GradientDirection.radialCenter:
        return "Center";
    }
  }

  void init() {
    _isInitialized = true;
    _colors = [_generateRandomColor(), _generateRandomColor()];
    generateGradient();
    Global.loggerModel.info("Gradient initialized", source: "Gradient");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  Color _generateRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
      1.0,
    );
  }
  
  void setGradientType(GradientType type) {
    _gradientType = type;
    if (type == GradientType.radial) {
      _gradientDirection = GradientDirection.radialCenter;
    } else if (_gradientDirection == GradientDirection.radialCenter) {
      _gradientDirection = GradientDirection.horizontal;
    }
    generateGradient();
    Global.loggerModel.info("Gradient type set to: ${getGradientTypeName(type)}", source: "Gradient");
  }
  
  void setGradientDirection(GradientDirection dir) {
    if (_gradientType == GradientType.radial && dir != GradientDirection.radialCenter) {
      return;
    }
    _gradientDirection = dir;
    generateGradient();
    Global.loggerModel.info("Gradient direction set to: ${getGradientDirectionName(dir)}", source: "Gradient");
  }
  
  void setColor(int index, Color color) {
    if (index >= 0 && index < _colors.length) {
      _colors[index] = color;
      generateGradient();
      Global.loggerModel.info("Color $index set", source: "Gradient");
    }
  }
  
  void addColor() {
    if (_colors.length < 5) {
      _colors.add(_generateRandomColor());
      generateGradient();
      Global.loggerModel.info("Added color, now ${_colors.length} colors", source: "Gradient");
    }
  }
  
  void removeColor(int index) {
    if (_colors.length > 2 && index >= 0 && index < _colors.length) {
      _colors.removeAt(index);
      generateGradient();
      Global.loggerModel.info("Removed color $index, now ${_colors.length} colors", source: "Gradient");
    }
  }
  
  void generateGradient() {
    if (_gradientType == GradientType.linear) {
      _currentLinearGradient = _createLinearGradient();
      _currentRadialGradient = null;
    } else {
      _currentRadialGradient = _createRadialGradient();
      _currentLinearGradient = null;
    }
    
    final entry = GradientHistoryEntry(
      gradientType: _gradientType,
      gradientDirection: _gradientDirection,
      colors: List.from(_colors),
      timestamp: DateTime.now(),
    );
    _history.insert(0, entry);
    if (_history.length > 10) {
      _history.removeLast();
    }
    
    notifyListeners();
    Global.loggerModel.info("Generated ${getGradientTypeName(_gradientType)} gradient", source: "Gradient");
  }
  
  LinearGradient _createLinearGradient() {
    Alignment begin;
    Alignment end;
    
    switch (_gradientDirection) {
      case GradientDirection.horizontal:
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        break;
      case GradientDirection.vertical:
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        break;
      case GradientDirection.diagonalUp:
        begin = Alignment.bottomLeft;
        end = Alignment.topRight;
        break;
      case GradientDirection.diagonalDown:
        begin = Alignment.topLeft;
        end = Alignment.bottomRight;
        break;
      case GradientDirection.radialCenter:
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        break;
    }
    
    return LinearGradient(
      begin: begin,
      end: end,
      colors: _colors,
    );
  }
  
  RadialGradient _createRadialGradient() {
    return RadialGradient(
      colors: _colors,
    );
  }
  
  void generateRandomGradient() {
    final numColors = 2 + _random.nextInt(3);
    _colors = [];
    for (int i = 0; i < numColors; i++) {
      _colors.add(_generateRandomColor());
    }
    generateGradient();
  }
  
  String colorToHex(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return "#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}${g.toRadixString(16).padLeft(2, '0').toUpperCase()}${b.toRadixString(16).padLeft(2, '0').toUpperCase()}";
  }
  
  String getCssGradient() {
    final hexColors = _colors.map(colorToHex).toList();
    
    if (_gradientType == GradientType.radial) {
      return "background: radial-gradient(circle, ${hexColors.join(', ')});";
    }
    
    String direction;
    switch (_gradientDirection) {
      case GradientDirection.horizontal:
        direction = "to right";
        break;
      case GradientDirection.vertical:
        direction = "to bottom";
        break;
      case GradientDirection.diagonalUp:
        direction = "to top right";
        break;
      case GradientDirection.diagonalDown:
        direction = "to bottom right";
        break;
      case GradientDirection.radialCenter:
        direction = "to right";
        break;
    }
    
    return "background: linear-gradient($direction, ${hexColors.join(', ')});";
  }
  
  String getFlutterGradient() {
    final hexColors = _colors.map(colorToHex).toList();
    final colorStrings = hexColors.map((hex) => 'Color(0x${hex.substring(1)}FF)').toList();
    
    if (_gradientType == GradientType.radial) {
      return "RadialGradient(colors: [${colorStrings.join(', ')}])";
    }
    
    String begin;
    String end;
    switch (_gradientDirection) {
      case GradientDirection.horizontal:
        begin = "Alignment.centerLeft";
        end = "Alignment.centerRight";
        break;
      case GradientDirection.vertical:
        begin = "Alignment.topCenter";
        end = "Alignment.bottomCenter";
        break;
      case GradientDirection.diagonalUp:
        begin = "Alignment.bottomLeft";
        end = "Alignment.topRight";
        break;
      case GradientDirection.diagonalDown:
        begin = "Alignment.topLeft";
        end = "Alignment.bottomRight";
        break;
      case GradientDirection.radialCenter:
        begin = "Alignment.centerLeft";
        end = "Alignment.centerRight";
        break;
    }
    
    return "LinearGradient(begin: $begin, end: $end, colors: [${colorStrings.join(', ')}])";
  }
  
  void copyCssToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: getCssGradient()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied CSS: ${getCssGradient()}"),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void copyFlutterToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: getFlutterGradient()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied Flutter code"),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void useHistoryEntry(GradientHistoryEntry entry) {
    _gradientType = entry.gradientType;
    _gradientDirection = entry.gradientDirection;
    _colors = List.from(entry.colors);
    generateGradient();
    Global.loggerModel.info("Using history entry", source: "Gradient");
  }
  
  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("Gradient history cleared", source: "Gradient");
  }
}

class GradientHistoryEntry {
  final GradientType gradientType;
  final GradientDirection gradientDirection;
  final List<Color> colors;
  final DateTime timestamp;
  
  GradientHistoryEntry({
    required this.gradientType,
    required this.gradientDirection,
    required this.colors,
    required this.timestamp,
  });
  
  String getFormattedTime() {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return "just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${diff.inDays}d ago";
    }
  }
}

class GradientCard extends StatefulWidget {
  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard> {
  bool _showHistory = false;
  bool _showCode = false;
  
  @override
  Widget build(BuildContext context) {
    final gradient = context.watch<GradientModel>();
    
    if (!gradient.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.gradient, size: 24),
              SizedBox(width: 12),
              Text("Gradient: Loading..."),
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
            _buildHeader(context),
            SizedBox(height: 12),
            _buildTypeSelector(context, gradient),
            SizedBox(height: 8),
            if (gradient.gradientType == GradientType.linear)
              _buildDirectionSelector(context, gradient),
            SizedBox(height: 12),
            _buildGradientPreview(context, gradient),
            SizedBox(height: 12),
            _buildColorList(context, gradient),
            SizedBox(height: 8),
            _buildColorActions(context, gradient),
            SizedBox(height: 12),
            _buildActionButtons(context, gradient),
            if (_showCode) ...[
              SizedBox(height: 12),
              _buildCodeSection(context, gradient),
            ],
            if (_showHistory && gradient.history.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildHistorySection(context, gradient),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.gradient, size: 20),
        SizedBox(width: 8),
        Text(
          "Gradient Generator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Spacer(),
        TextButton(
          onPressed: () => setState(() => _showCode = !_showCode),
          child: Text(_showCode ? "Hide Code" : "Code"),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (gradientModel.history.isNotEmpty)
          TextButton(
            onPressed: () => setState(() => _showHistory = !_showHistory),
            child: Text(_showHistory ? "Hide History" : "History"),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }
  
  Widget _buildTypeSelector(BuildContext context, GradientModel gradient) {
    return SegmentedButton<GradientType>(
      segments: GradientType.values.map((type) => 
        ButtonSegment(
          value: type,
          label: Text(GradientModel.getGradientTypeName(type), style: TextStyle(fontSize: 12)),
        )
      ).toList(),
      selected: {gradient.gradientType},
      onSelectionChanged: (Set<GradientType> newSelection) {
        gradient.setGradientType(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
  
  Widget _buildDirectionSelector(BuildContext context, GradientModel gradient) {
    final directions = [
      GradientDirection.horizontal,
      GradientDirection.vertical,
      GradientDirection.diagonalUp,
      GradientDirection.diagonalDown,
    ];
    
    return SegmentedButton<GradientDirection>(
      segments: directions.map((dir) => 
        ButtonSegment(
          value: dir,
          label: Text(GradientModel.getGradientDirectionName(dir), style: TextStyle(fontSize: 11)),
        )
      ).toList(),
      selected: {gradient.gradientDirection},
      onSelectionChanged: (Set<GradientDirection> newSelection) {
        gradient.setGradientDirection(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
  
  Widget _buildGradientPreview(BuildContext context, GradientModel gradient) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: gradient.currentGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
  
  Widget _buildColorList(BuildContext context, GradientModel gradient) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: gradient.colors.asMap().entries.map((entry) {
        final index = entry.key;
        final color = entry.value;
        return GestureDetector(
          onTap: () => _showColorPicker(context, gradient, index),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Stack(
              children: [
                if (gradient.colors.length > 2)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => gradient.removeColor(index),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 10, color: Theme.of(context).colorScheme.onError),
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: _getContrastColor(color),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildColorActions(BuildContext context, GradientModel gradient) {
    return Row(
      children: [
        if (gradient.colors.length < 5)
          ActionChip(
            avatar: Icon(Icons.add, size: 16),
            label: Text("Add Color"),
            onPressed: () => gradient.addColor(),
          ),
        Spacer(),
        Text(
          "${gradient.colors.length} colors",
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(BuildContext context, GradientModel gradient) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => gradient.generateRandomGradient(),
            icon: Icon(Icons.refresh, size: 18),
            label: Text("Random"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.code, size: 18),
          onPressed: () => gradient.copyCssToClipboard(context),
          tooltip: "Copy CSS",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        IconButton(
          icon: Icon(Icons.flutter_dash, size: 18),
          onPressed: () => gradient.copyFlutterToClipboard(context),
          tooltip: "Copy Flutter",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (gradient.history.isNotEmpty) ...[
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18),
            onPressed: () => _showClearHistoryDialog(context, gradient),
            tooltip: "Clear history",
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildCodeSection(BuildContext context, GradientModel gradient) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("CSS:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            SelectableText(
              gradient.getCssGradient(),
              style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
            SizedBox(height: 8),
            Text("Flutter:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            SelectableText(
              gradient.getFlutterGradient(),
              style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistorySection(BuildContext context, GradientModel gradient) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("History", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...gradient.history.map((entry) => 
              GestureDetector(
                onTap: () => gradient.useHistoryEntry(entry),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        GradientModel.getGradientTypeName(entry.gradientType),
                        style: TextStyle(fontSize: 11),
                      ),
                      SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: entry.gradientType == GradientType.linear
                              ? LinearGradient(colors: entry.colors)
                              : RadialGradient(colors: entry.colors),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Spacer(),
                      Text(
                        entry.getFormattedTime(),
                        style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showColorPicker(BuildContext context, GradientModel gradient, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Color ${index + 1}"),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
            Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
            Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
            Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
            Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
            Colors.white,
          ].map((color) => GestureDetector(
            onTap: () {
              gradient.setColor(index, color);
              Navigator.pop(context);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              gradient.setColor(index, gradientModel._generateRandomColor());
              Navigator.pop(context);
            },
            child: Text("Random"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }
  
  void _showClearHistoryDialog(BuildContext context, GradientModel gradient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Delete all gradient history entries?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              gradient.clearHistory();
              Navigator.pop(context);
            },
            child: Text("Clear"),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getContrastColor(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final luminance = (r * 0.299 + g * 0.587 + b * 0.114) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}