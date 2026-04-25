import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

CoordinatesConverterModel coordinatesConverterModel = CoordinatesConverterModel();

MyProvider providerCoordinatesConverter = MyProvider(
    name: "CoordinatesConverter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Coordinates Converter',
      keywords: 'coordinates convert decimal dms degree latitude longitude gps location',
      action: () => coordinatesConverterModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  coordinatesConverterModel.init();
  Global.infoModel.addInfoWidget(
      "CoordinatesConverter",
      ChangeNotifierProvider.value(
          value: coordinatesConverterModel,
          builder: (context, child) => CoordinatesConverterCard()),
      title: "Coordinates Converter");
}

Future<void> _update() async {
  coordinatesConverterModel.refresh();
}

class CoordinatesConversionHistory {
  final double latitude;
  final double longitude;
  final String dmsLatitude;
  final String dmsLongitude;
  final DateTime timestamp;

  CoordinatesConversionHistory({
    required this.latitude,
    required this.longitude,
    required this.dmsLatitude,
    required this.dmsLongitude,
    required this.timestamp,
  });
}

class CoordinatesConverterModel extends ChangeNotifier {
  double _latitude = 40.7128;
  double _longitude = -74.0060;
  bool _isInitialized = false;
  final List<CoordinatesConversionHistory> _history = [];
  static const int maxHistory = 10;

  double get latitude => _latitude;
  double get longitude => _longitude;
  String get dmsLatitude => _convertToDMS(_latitude, true);
  String get dmsLongitude => _convertToDMS(_longitude, false);
  bool get isInitialized => _isInitialized;
  List<CoordinatesConversionHistory> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("CoordinatesConverter initialized", source: "CoordinatesConverter");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("CoordinatesConverter refreshed", source: "CoordinatesConverter");
  }

  void setLatitude(double value) {
    _latitude = _clampCoordinate(value, true);
    notifyListeners();
  }

  void setLongitude(double value) {
    _longitude = _clampCoordinate(value, false);
    notifyListeners();
  }

  void setLatitudeFromString(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      setLatitude(parsed);
    }
  }

  void setLongitudeFromString(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      setLongitude(parsed);
    }
  }

  double _clampCoordinate(double value, bool isLatitude) {
    if (isLatitude) {
      return value.clamp(-90.0, 90.0);
    } else {
      return value.clamp(-180.0, 180.0);
    }
  }

  String _convertToDMS(double decimal, bool isLatitude) {
    final absolute = decimal.abs();
    final degrees = absolute.floor();
    final minutesDecimal = (absolute - degrees) * 60;
    final minutes = minutesDecimal.floor();
    final seconds = ((minutesDecimal - minutes) * 60).round();

    final direction = isLatitude
        ? (decimal >= 0 ? 'N' : 'S')
        : (decimal >= 0 ? 'E' : 'W');

    return '${degrees}° ${minutes}\' ${seconds}" ${direction}';
  }

  static double convertDMStoDecimal(int degrees, int minutes, int seconds, String direction) {
    var decimal = degrees + minutes / 60.0 + seconds / 3600.0;
    if (direction == 'S' || direction == 'W') {
      decimal = -decimal;
    }
    return decimal;
  }

  void swapCoordinates() {
    final temp = _latitude;
    _latitude = _longitude.clamp(-90.0, 90.0);
    _longitude = temp.clamp(-180.0, 180.0);
    notifyListeners();
    Global.loggerModel.info("Coordinates swapped", source: "CoordinatesConverter");
  }

  void clear() {
    _latitude = 0.0;
    _longitude = 0.0;
    notifyListeners();
    Global.loggerModel.info("CoordinatesConverter cleared", source: "CoordinatesConverter");
  }

  void addToHistory() {
    if (_latitude == 0 && _longitude == 0) return;

    _history.insert(0, CoordinatesConversionHistory(
      latitude: _latitude,
      longitude: _longitude,
      dmsLatitude: dmsLatitude,
      dmsLongitude: dmsLongitude,
      timestamp: DateTime.now(),
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }

    notifyListeners();
    Global.loggerModel.info("Coordinates conversion added to history", source: "CoordinatesConverter");
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("CoordinatesConverter history cleared", source: "CoordinatesConverter");
  }

  void useHistoryEntry(CoordinatesConversionHistory entry) {
    _latitude = entry.latitude;
    _longitude = entry.longitude;
    notifyListeners();
  }
}

class CoordinatesConverterCard extends StatefulWidget {
  @override
  State<CoordinatesConverterCard> createState() => _CoordinatesConverterCardState();
}

class _CoordinatesConverterCardState extends State<CoordinatesConverterCard> {
  bool _showHistory = false;
  late TextEditingController _latController;
  late TextEditingController _lonController;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(text: '40.7128');
    _lonController = TextEditingController(text: '-74.0060');
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final converter = context.watch<CoordinatesConverterModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!converter.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 24),
              SizedBox(width: 12),
              Text("Coordinates Converter: Loading..."),
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
                  "Coordinates Converter",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (converter.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.location_on : Icons.history, size: 18),
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

  Widget _buildConverterView(CoordinatesConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _buildLatitudeInput(converter)),
            SizedBox(width: 8),
            Expanded(child: _buildLongitudeInput(converter)),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'DMS Format',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 4),
              Text(
                'Lat: ${converter.dmsLatitude}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Lon: ${converter.dmsLongitude}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.swap_horiz),
              onPressed: converter.swapCoordinates,
              tooltip: "Swap coordinates",
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: converter.addToHistory,
              tooltip: "Save to history",
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLatitudeInput(CoordinatesConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latitude (°)',
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(height: 4),
        TextField(
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '-90 to 90',
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          controller: _latController,
          onChanged: (value) => converter.setLatitudeFromString(value),
        ),
      ],
    );
  }

  Widget _buildLongitudeInput(CoordinatesConverterModel converter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Longitude (°)',
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(height: 4),
        TextField(
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '-180 to 180',
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          controller: _lonController,
          onChanged: (value) => converter.setLongitudeFromString(value),
        ),
      ],
    );
  }

  Widget _buildHistoryView(CoordinatesConverterModel converter) {
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
            title: Text('DD: ${entry.latitude}, ${entry.longitude}'),
            subtitle: Text(
              'DMS: ${entry.dmsLatitude}, ${entry.dmsLongitude}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              converter.useHistoryEntry(entry);
              _latController.text = entry.latitude.toString();
              _lonController.text = entry.longitude.toString();
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
        content: Text("Clear all coordinates conversion history?"),
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
      context.read<CoordinatesConverterModel>().clearHistory();
    }
  }
}