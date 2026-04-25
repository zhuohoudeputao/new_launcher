import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

PaletteModel paletteModel = PaletteModel();

MyProvider providerPalette = MyProvider(
    name: "Palette",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Color Palette',
      keywords: 'palette color scheme harmony complementary analogous triadic monochromatic tetradic split design',
      action: () {
        paletteModel.generatePalette();
        Global.infoModel.addInfoWidget(
            "PaletteAction",
            ChangeNotifierProvider.value(
                value: paletteModel,
                builder: (context, child) => _PaletteActionCard()),
            title: "Color Palette");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  paletteModel.init();
  Global.infoModel.addInfoWidget(
      "Palette",
      ChangeNotifierProvider.value(
          value: paletteModel,
          builder: (context, child) => PaletteCard()),
      title: "Color Palette Generator");
}

Future<void> _update() async {
  paletteModel.refresh();
}

class _PaletteActionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<PaletteModel>();
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.palette, size: 20),
            SizedBox(width: 8),
            Text("Generated ${palette.paletteType} palette"),
            SizedBox(width: 8),
            ...palette.currentPalette.take(4).map((c) => Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

enum PaletteType {
  complementary,
  analogous,
  triadic,
  splitComplementary,
  tetradic,
  monochromatic,
}

class PaletteModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;
  
  PaletteType _paletteType = PaletteType.complementary;
  List<Color> _currentPalette = [];
  List<PaletteHistoryEntry> _history = [];
  Color _baseColor = Colors.blue;
  
  bool get isInitialized => _isInitialized;
  PaletteType get paletteType => _paletteType;
  List<Color> get currentPalette => List.unmodifiable(_currentPalette);
  List<PaletteHistoryEntry> get history => List.unmodifiable(_history);
  Color get baseColor => _baseColor;
  
  static const List<PaletteType> availableTypes = PaletteType.values;
  
  static String getPaletteTypeName(PaletteType type) {
    switch (type) {
      case PaletteType.complementary:
        return "Complementary";
      case PaletteType.analogous:
        return "Analogous";
      case PaletteType.triadic:
        return "Triadic";
      case PaletteType.splitComplementary:
        return "Split Complementary";
      case PaletteType.tetradic:
        return "Tetradic";
      case PaletteType.monochromatic:
        return "Monochromatic";
    }
  }
  
  static String getPaletteDescription(PaletteType type) {
    switch (type) {
      case PaletteType.complementary:
        return "Two colors opposite on the color wheel";
      case PaletteType.analogous:
        return "Colors adjacent on the color wheel";
      case PaletteType.triadic:
        return "Three colors evenly spaced (120° apart)";
      case PaletteType.splitComplementary:
        return "Base color + two adjacent to its complement";
      case PaletteType.tetradic:
        return "Four colors forming a rectangle on the wheel";
      case PaletteType.monochromatic:
        return "Variations of a single color (shades/tints)";
    }
  }

  void init() {
    _isInitialized = true;
    _baseColor = _generateRandomColor();
    generatePalette();
    Global.loggerModel.info("Palette initialized", source: "Palette");
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
  
  HSVColor _toHSV(Color color) {
    return HSVColor.fromColor(color);
  }
  
  Color _fromHSV(HSVColor hsv) {
    return hsv.toColor();
  }
  
  void setPaletteType(PaletteType type) {
    _paletteType = type;
    generatePalette();
    Global.loggerModel.info("Palette type set to: ${getPaletteTypeName(type)}", source: "Palette");
  }
  
  void setBaseColor(Color color) {
    _baseColor = color;
    generatePalette();
    Global.loggerModel.info("Base color set", source: "Palette");
  }
  
  void generatePalette() {
    final baseHSV = _toHSV(_baseColor);
    List<Color> palette = [];
    
    switch (_paletteType) {
      case PaletteType.complementary:
        palette = _generateComplementary(baseHSV);
        break;
      case PaletteType.analogous:
        palette = _generateAnalogous(baseHSV);
        break;
      case PaletteType.triadic:
        palette = _generateTriadic(baseHSV);
        break;
      case PaletteType.splitComplementary:
        palette = _generateSplitComplementary(baseHSV);
        break;
      case PaletteType.tetradic:
        palette = _generateTetradic(baseHSV);
        break;
      case PaletteType.monochromatic:
        palette = _generateMonochromatic(baseHSV);
        break;
    }
    
    _currentPalette = palette;
    
    final entry = PaletteHistoryEntry(
      paletteType: _paletteType,
      colors: palette,
      baseColor: _baseColor,
      timestamp: DateTime.now(),
    );
    _history.insert(0, entry);
    if (_history.length > 10) {
      _history.removeLast();
    }
    
    notifyListeners();
    Global.loggerModel.info("Generated ${getPaletteTypeName(_paletteType)} palette", source: "Palette");
  }
  
  void generateRandomPalette() {
    _baseColor = _generateRandomColor();
    generatePalette();
  }
  
  List<Color> _generateComplementary(HSVColor baseHSV) {
    final complement = HSVColor.fromAHSV(
      1.0,
      (baseHSV.hue + 180) % 360,
      baseHSV.saturation,
      baseHSV.value,
    );
    return [
      _fromHSV(baseHSV),
      _fromHSV(complement),
    ];
  }
  
  List<Color> _generateAnalogous(HSVColor baseHSV) {
    return [
      _fromHSV(HSVColor.fromAHSV(1.0, (baseHSV.hue - 30) % 360, baseHSV.saturation, baseHSV.value)),
      _fromHSV(baseHSV),
      _fromHSV(HSVColor.fromAHSV(1.0, (baseHSV.hue + 30) % 360, baseHSV.saturation, baseHSV.value)),
    ];
  }
  
  List<Color> _generateTriadic(HSVColor baseHSV) {
    return [
      _fromHSV(baseHSV),
      _fromHSV(HSVColor.fromAHSV(1.0, (baseHSV.hue + 120) % 360, baseHSV.saturation, baseHSV.value)),
      _fromHSV(HSVColor.fromAHSV(1.0, (baseHSV.hue + 240) % 360, baseHSV.saturation, baseHSV.value)),
    ];
  }
  
  List<Color> _generateSplitComplementary(HSVColor baseHSV) {
    final complementHue = (baseHSV.hue + 180) % 360;
    return [
      _fromHSV(baseHSV),
      _fromHSV(HSVColor.fromAHSV(1.0, (complementHue - 30) % 360, baseHSV.saturation, baseHSV.value)),
      _fromHSV(HSVColor.fromAHSV(1.0, (complementHue + 30) % 360, baseHSV.saturation, baseHSV.value)),
    ];
  }
  
  List<Color> _generateTetradic(HSVColor baseHSV) {
    return [
      _fromHSV(baseHSV),
      _fromHSV(HSVColor.fromAHSV(1.0, (baseHSV.hue + 90) % 360, baseHSV.saturation, baseHSV.value)),
      _fromHSV(HSVColor.fromAHSV(1.0, (baseHSV.hue + 180) % 360, baseHSV.saturation, baseHSV.value)),
      _fromHSV(HSVColor.fromAHSV(1.0, (baseHSV.hue + 270) % 360, baseHSV.saturation, baseHSV.value)),
    ];
  }
  
  List<Color> _generateMonochromatic(HSVColor baseHSV) {
    return [
      _fromHSV(HSVColor.fromAHSV(1.0, baseHSV.hue, baseHSV.saturation, 0.2)),
      _fromHSV(HSVColor.fromAHSV(1.0, baseHSV.hue, baseHSV.saturation, 0.4)),
      _fromHSV(HSVColor.fromAHSV(1.0, baseHSV.hue, baseHSV.saturation, 0.6)),
      _fromHSV(HSVColor.fromAHSV(1.0, baseHSV.hue, baseHSV.saturation, 0.8)),
      _fromHSV(baseHSV),
    ];
  }
  
  String colorToHex(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return "#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}${g.toRadixString(16).padLeft(2, '0').toUpperCase()}${b.toRadixString(16).padLeft(2, '0').toUpperCase()}";
  }
  
  void copyPaletteToClipboard(BuildContext context) {
    final hexColors = _currentPalette.map(colorToHex).join(", ");
    Clipboard.setData(ClipboardData(text: hexColors));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied: $hexColors"),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void copyColorToClipboard(Color color, BuildContext context) {
    final hex = colorToHex(color);
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied: $hex"),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void useHistoryEntry(PaletteHistoryEntry entry) {
    _paletteType = entry.paletteType;
    _baseColor = entry.baseColor;
    _currentPalette = List.from(entry.colors);
    notifyListeners();
    Global.loggerModel.info("Using history entry", source: "Palette");
  }
  
  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("Palette history cleared", source: "Palette");
  }
}

class PaletteHistoryEntry {
  final PaletteType paletteType;
  final List<Color> colors;
  final Color baseColor;
  final DateTime timestamp;
  
  PaletteHistoryEntry({
    required this.paletteType,
    required this.colors,
    required this.baseColor,
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

class PaletteCard extends StatefulWidget {
  @override
  State<PaletteCard> createState() => _PaletteCardState();
}

class _PaletteCardState extends State<PaletteCard> {
  bool _showHistory = false;
  
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<PaletteModel>();
    
    if (!palette.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.palette, size: 24),
              SizedBox(width: 12),
              Text("Palette: Loading..."),
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
            _buildTypeSelector(context, palette),
            SizedBox(height: 12),
            _buildPalettePreview(context, palette),
            SizedBox(height: 8),
            _buildPaletteInfo(context, palette),
            SizedBox(height: 12),
            _buildBaseColorSelector(context, palette),
            SizedBox(height: 8),
            _buildActionButtons(context, palette),
            if (_showHistory && palette.history.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildHistorySection(context, palette),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.palette, size: 20),
        SizedBox(width: 8),
        Text(
          "Color Palette Generator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Spacer(),
        if (paletteModel.history.isNotEmpty)
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
  
  Widget _buildTypeSelector(BuildContext context, PaletteModel palette) {
    return SegmentedButton<PaletteType>(
      segments: PaletteType.values.map((type) => 
        ButtonSegment(
          value: type,
          label: Text(PaletteModel.getPaletteTypeName(type), style: TextStyle(fontSize: 11)),
        )
      ).toList(),
      selected: {palette.paletteType},
      onSelectionChanged: (Set<PaletteType> newSelection) {
        palette.setPaletteType(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
  
  Widget _buildPalettePreview(BuildContext context, PaletteModel palette) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  PaletteModel.getPaletteDescription(palette.paletteType),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                Spacer(),
                Text(
                  "${palette.currentPalette.length} colors",
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: palette.currentPalette.map((color) => 
                GestureDetector(
                  onTap: () => palette.copyColorToClipboard(color, context),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: _getContrastColor(color),
                      ),
                    ),
                  ),
                )
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaletteInfo(BuildContext context, PaletteModel palette) {
    final hexColors = palette.currentPalette.map(palette.colorToHex).toList();
    return Row(
      children: [
        Expanded(
          child: Text(
            hexColors.join(" "),
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(Icons.copy, size: 16),
          onPressed: () => palette.copyPaletteToClipboard(context),
          tooltip: "Copy all",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            minimumSize: Size(24, 24),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBaseColorSelector(BuildContext context, PaletteModel palette) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Text("Base Color:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.baseColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            SizedBox(width: 8),
            Text(
              palette.colorToHex(palette.baseColor),
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, PaletteModel palette) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => palette.generateRandomPalette(),
            icon: Icon(Icons.refresh, size: 18),
            label: Text("New Palette"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        if (palette.history.isNotEmpty) ...[
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18),
            onPressed: () => _showClearHistoryDialog(context, palette),
            tooltip: "Clear history",
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildHistorySection(BuildContext context, PaletteModel palette) {
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
            ...palette.history.map((entry) => 
              GestureDetector(
                onTap: () => palette.useHistoryEntry(entry),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        PaletteModel.getPaletteTypeName(entry.paletteType),
                        style: TextStyle(fontSize: 11),
                      ),
                      SizedBox(width: 8),
                      ...entry.colors.take(4).map((c) => Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      )),
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
  
  void _showClearHistoryDialog(BuildContext context, PaletteModel palette) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Delete all palette history entries?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              palette.clearHistory();
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
    return luminance > 0.5 ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5);
  }
}