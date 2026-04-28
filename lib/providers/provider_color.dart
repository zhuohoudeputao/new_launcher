import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

ColorModel colorModel = ColorModel();

MyProvider providerColor = MyProvider(
    name: "Color",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Random Color',
      keywords: 'color random generate hex rgb picker palette',
      action: () {
        colorModel.generateRandomColor();
        Global.infoModel.addInfo(
            "RandomColor",
            "Random Color",
            subtitle: colorModel.hexColor,
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colorModel.currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(navigatorKey.currentContext!).colorScheme.outline),
              ),
            ),
            onTap: () => colorModel.generateRandomColor());
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'HEX Color',
      keywords: 'hex color code rgb convert',
      action: () {
        colorModel.generateRandomColor();
        Global.infoModel.addInfo(
            "HEXColor",
            "HEX: ${colorModel.hexColor}",
            subtitle: "RGB: ${colorModel.rgbColor}",
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colorModel.currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(navigatorKey.currentContext!).colorScheme.outline),
              ),
            ),
            onTap: () {
              colorModel.generateRandomColor();
            });
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  colorModel.init();
  Global.infoModel.addInfoWidget(
      "Color",
      ChangeNotifierProvider.value(
          value: colorModel,
          builder: (context, child) => ColorCard()),
      title: "Color Generator");
}

Future<void> _update() async {
  colorModel.refresh();
}

class ColorModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;
  
  Color _currentColor = Colors.blue;
  String _hexColor = "#2196F3";
  String _rgbColor = "33, 150, 243";
  int _red = 33;
  int _green = 150;
  int _blue = 243;
  
  bool get isInitialized => _isInitialized;
  Color get currentColor => _currentColor;
  String get hexColor => _hexColor;
  String get rgbColor => _rgbColor;
  int get red => _red;
  int get green => _green;
  int get blue => _blue;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("Color initialized", source: "Color");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void generateRandomColor() {
    _red = _random.nextInt(256);
    _green = _random.nextInt(256);
    _blue = _random.nextInt(256);
    _currentColor = Color.fromRGBO(_red, _green, _blue, 1.0);
    _hexColor = "#${_red.toRadixString(16).padLeft(2, '0').toUpperCase()}${_green.toRadixString(16).padLeft(2, '0').toUpperCase()}${_blue.toRadixString(16).padLeft(2, '0').toUpperCase()}";
    _rgbColor = "$_red, $_green, $_blue";
    notifyListeners();
    Global.loggerModel.info("Color generated: $_hexColor", source: "Color");
  }

  void setColorFromHex(String hex) {
    String cleanHex = hex.replaceAll('#', '').toUpperCase();
    if (cleanHex.length == 6) {
      try {
        _red = int.parse(cleanHex.substring(0, 2), radix: 16);
        _green = int.parse(cleanHex.substring(2, 4), radix: 16);
        _blue = int.parse(cleanHex.substring(4, 6), radix: 16);
        _currentColor = Color.fromRGBO(_red, _green, _blue, 1.0);
        _hexColor = "#$cleanHex";
        _rgbColor = "$_red, $_green, $_blue";
        notifyListeners();
        Global.loggerModel.info("Color set from hex: $_hexColor", source: "Color");
      } catch (e) {
        Global.loggerModel.warning("Invalid hex color: $hex", source: "Color");
      }
    }
  }

  void setColorFromRGB(int r, int g, int b) {
    _red = r.clamp(0, 255);
    _green = g.clamp(0, 255);
    _blue = b.clamp(0, 255);
    _currentColor = Color.fromRGBO(_red, _green, _blue, 1.0);
    _hexColor = "#${_red.toRadixString(16).padLeft(2, '0').toUpperCase()}${_green.toRadixString(16).padLeft(2, '0').toUpperCase()}${_blue.toRadixString(16).padLeft(2, '0').toUpperCase()}";
    _rgbColor = "$_red, $_green, $_blue";
    notifyListeners();
    Global.loggerModel.info("Color set from RGB: $_rgbColor", source: "Color");
  }

  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied: $text"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool isLightColor() {
    double luminance = (_red * 0.299 + _green * 0.587 + _blue * 0.114) / 255;
    return luminance > 0.5;
  }

  Color getContrastColor() {
    return isLightColor() ? Colors.black : Colors.white;
  }
}

class ColorCard extends StatefulWidget {
  @override
  State<ColorCard> createState() => _ColorCardState();
}

class _ColorCardState extends State<ColorCard> {
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _rController = TextEditingController();
  final TextEditingController _gController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  
  @override
  void dispose() {
    _hexController.dispose();
    _rController.dispose();
    _gController.dispose();
    _bController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final color = context.watch<ColorModel>();
    
    if (!color.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.palette, size: 24),
              SizedBox(width: 12),
              Text("Color: Loading..."),
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
              children: [
                Icon(Icons.palette, size: 20),
                SizedBox(width: 8),
                Text(
                  "Color Generator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildColorPreview(context, color),
            SizedBox(height: 12),
            _buildColorInfo(context, color),
            SizedBox(height: 12),
            _buildHexInput(context, color),
            SizedBox(height: 8),
            _buildRGBInput(context, color),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorPreview(BuildContext context, ColorModel color) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: color.currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Center(
                child: Text(
                  "Preview",
                  style: TextStyle(
                    color: color.getContrastColor(),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("HEX: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      SelectableText(color.hexColor, style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.copy, size: 14),
                        onPressed: () => color.copyToClipboard(color.hexColor, context),
                        tooltip: "Copy HEX",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          minimumSize: Size(24, 24),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text("RGB: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      SelectableText(color.rgbColor, style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.copy, size: 14),
                        onPressed: () => color.copyToClipboard("rgb(${color.rgbColor})", context),
                        tooltip: "Copy RGB",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          minimumSize: Size(24, 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 18),
              onPressed: () => color.generateRandomColor(),
              tooltip: "Random color",
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorInfo(BuildContext context, ColorModel color) {
    String colorType = color.isLightColor() ? "Light" : "Dark";
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
        SizedBox(width: 8),
        Text("Type: $colorType", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
        SizedBox(width: 16),
        Icon(Icons.contrast, size: 16, color: Theme.of(context).colorScheme.secondary),
        SizedBox(width: 4),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.getContrastColor(),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        SizedBox(width: 4),
        Text("Contrast", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
      ],
    );
  }
  
  Widget _buildHexInput(BuildContext context, ColorModel color) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Text("HEX:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _hexController,
                decoration: InputDecoration(
                  hintText: "#RRGGBB",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                  prefixText: "#",
                ),
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                maxLength: 6,
                onChanged: (value) {
                  if (value.length == 6) {
                    color.setColorFromHex(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRGBInput(BuildContext context, ColorModel color) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Text("RGB:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _rController,
                decoration: InputDecoration(
                  labelText: "R",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _gController,
                decoration: InputDecoration(
                  labelText: "G",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _bController,
                decoration: InputDecoration(
                  labelText: "B",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.check, size: 18),
              onPressed: () {
                final r = int.tryParse(_rController.text) ?? 0;
                final g = int.tryParse(_gController.text) ?? 0;
                final b = int.tryParse(_bController.text) ?? 0;
                color.setColorFromRGB(r, g, b);
              },
              tooltip: "Apply RGB",
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}