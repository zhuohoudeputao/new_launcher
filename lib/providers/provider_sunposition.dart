import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

SunPositionModel sunPositionModel = SunPositionModel();

MyProvider providerSunPosition = MyProvider(
    name: "SunPosition",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Sun Position',
      keywords: 'sun sunrise sunset golden hour solar noon day length altitude azimuth position',
      action: () {
        Global.infoModel.addInfo(
            "SunPosition",
            "Sun Position",
            subtitle: "Sunrise, sunset, golden hour",
            icon: Icon(Icons.wb_sunny),
            onTap: () {});
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await sunPositionModel.init();
  Global.infoModel.addInfoWidget(
      "SunPosition",
      ChangeNotifierProvider.value(
          value: sunPositionModel,
          builder: (context, child) => SunPositionCard()),
      title: "Sun Position");
}

Future<void> _update() async {
  sunPositionModel.refresh();
}

class SunPositionModel extends ChangeNotifier {
  bool _isInitialized = false;
  DateTime _currentDate = DateTime.now();
  double _latitude = 0;
  double _longitude = 0;
  DateTime? _sunrise;
  DateTime? _sunset;
  DateTime? _solarNoon;
  DateTime? _morningGoldenHourStart;
  DateTime? _morningGoldenHourEnd;
  DateTime? _eveningGoldenHourStart;
  DateTime? _eveningGoldenHourEnd;
  DateTime? _morningBlueHourStart;
  DateTime? _morningBlueHourEnd;
  DateTime? _eveningBlueHourStart;
  DateTime? _eveningBlueHourEnd;
  double _sunAltitude = 0;
  double _sunAzimuth = 0;
  String _locationName = "";
  bool _isDay = true;

  bool get isInitialized => _isInitialized;
  DateTime get currentDate => _currentDate;
  double get latitude => _latitude;
  double get longitude => _longitude;
  DateTime? get sunrise => _sunrise;
  DateTime? get sunset => _sunset;
  DateTime? get solarNoon => _solarNoon;
  DateTime? get morningGoldenHourStart => _morningGoldenHourStart;
  DateTime? get morningGoldenHourEnd => _morningGoldenHourEnd;
  DateTime? get eveningGoldenHourStart => _eveningGoldenHourStart;
  DateTime? get eveningGoldenHourEnd => _eveningGoldenHourEnd;
  DateTime? get morningBlueHourStart => _morningBlueHourStart;
  DateTime? get morningBlueHourEnd => _morningBlueHourEnd;
  DateTime? get eveningBlueHourStart => _eveningBlueHourStart;
  DateTime? get eveningBlueHourEnd => _eveningBlueHourEnd;
  double get sunAltitude => _sunAltitude;
  double get sunAzimuth => _sunAzimuth;
  String get locationName => _locationName;
  bool get isDay => _isDay;

  int get dayLengthMinutes {
    if (_sunrise == null || _sunset == null) return 0;
    return _sunset!.difference(_sunrise!).inMinutes;
  }

  String get dayLengthFormatted {
    int minutes = dayLengthMinutes;
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return "${hours}h ${mins}m";
  }

  Future<void> init() async {
    _isInitialized = true;
    await _getLocation();
    _calculateSunPosition(DateTime.now());
    Global.loggerModel.info("SunPosition initialized", source: "SunPosition");
    notifyListeners();
  }

  Future<void> refresh() async {
    await _getLocation();
    _calculateSunPosition(DateTime.now());
    notifyListeners();
  }

  void setDate(DateTime date) {
    _currentDate = date;
    _calculateSunPosition(date);
    notifyListeners();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationName = "Location disabled";
        _latitude = 0;
        _longitude = 0;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationName = "Permission denied";
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationName = "Permission denied forever";
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);

      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationName = "${_latitude.toStringAsFixed(2)}, ${_longitude.toStringAsFixed(2)}";
    } catch (e) {
      Global.loggerModel.warning("Location error: $e", source: "SunPosition");
      _locationName = "Location unavailable";
      _latitude = 0;
      _longitude = 0;
    }
  }

  void _calculateSunPosition(DateTime date) {
    _currentDate = date;

    if (_latitude == 0 && _longitude == 0) {
      _sunrise = null;
      _sunset = null;
      _solarNoon = null;
      return;
    }

    DateTime utcDate = date.toUtc();
    int dayOfYear = _getDayOfYear(utcDate);

    double declination = _calculateSolarDeclination(dayOfYear);
    double hourAngle = _calculateHourAngle(_latitude, declination);

    double solarNoonOffset = _longitude / 15.0;
    double equationOfTime = _calculateEquationOfTime(dayOfYear);

    DateTime baseTime = DateTime.utc(date.year, date.month, date.day, 12, 0);
    _solarNoon = baseTime.add(Duration(minutes: ((-solarNoonOffset - equationOfTime) * 60).round())).toLocal();

    if (hourAngle.abs() > 90) {
      _sunrise = null;
      _sunset = null;
      _isDay = declination > 0 && _latitude > 0 || declination < 0 && _latitude < 0;
    } else {
      double sunriseHourAngle = -hourAngle;
      double sunsetHourAngle = hourAngle;

      double sunriseOffset = sunriseHourAngle / 15.0 - solarNoonOffset - equationOfTime;
      double sunsetOffset = sunsetHourAngle / 15.0 - solarNoonOffset - equationOfTime;

      _sunrise = baseTime.add(Duration(minutes: (sunriseOffset * 60).round())).toLocal();
      _sunset = baseTime.add(Duration(minutes: (sunsetOffset * 60).round())).toLocal();

      DateTime now = DateTime.now();
      _isDay = now.isAfter(_sunrise!) && now.isBefore(_sunset!);

      _calculateGoldenHours();
      _calculateBlueHours();
    }

    _calculateCurrentSunPosition(date);
  }

  void _calculateGoldenHours() {
    if (_sunrise == null || _sunset == null) return;

    _morningGoldenHourStart = _sunrise!.add(Duration(minutes: 0));
    _morningGoldenHourEnd = _sunrise!.add(Duration(minutes: 60));
    _eveningGoldenHourStart = _sunset!.subtract(Duration(minutes: 60));
    _eveningGoldenHourEnd = _sunset!.add(Duration(minutes: 0));
  }

  void _calculateBlueHours() {
    if (_sunrise == null || _sunset == null) return;

    _morningBlueHourStart = _sunrise!.subtract(Duration(minutes: 40));
    _morningBlueHourEnd = _sunrise!.add(Duration(minutes: 0));
    _eveningBlueHourStart = _sunset!.add(Duration(minutes: 0));
    _eveningBlueHourEnd = _sunset!.add(Duration(minutes: 40));
  }

  void _calculateCurrentSunPosition(DateTime date) {
    if (_latitude == 0 || _longitude == 0) {
      _sunAltitude = 0;
      _sunAzimuth = 0;
      return;
    }

    int dayOfYear = _getDayOfYear(date);
    double declination = _calculateSolarDeclination(dayOfYear);
    double equationOfTime = _calculateEquationOfTime(dayOfYear);

    DateTime utcTime = date.toUtc();
    double hours = utcTime.hour + utcTime.minute / 60.0;

    double solarTime = hours + _longitude / 15.0 + equationOfTime;
    double hourAngleValue = (solarTime - 12) * 15.0;

    double sinAltitude = sin(_latitude * pi / 180) * sin(declination * pi / 180) +
        cos(_latitude * pi / 180) * cos(declination * pi / 180) * cos(hourAngleValue * pi / 180);

    _sunAltitude = asin(sinAltitude) * 180 / pi;

    double cosAzimuth = (sin(declination * pi / 180) - sin(_latitude * pi / 180) * sinAltitude) /
        (cos(_latitude * pi / 180) * cos(_sunAltitude * pi / 180));

    if (cosAzimuth > 1) cosAzimuth = 1;
    if (cosAzimuth < -1) cosAzimuth = -1;

    double azimuth = acos(cosAzimuth) * 180 / pi;
    if (hourAngleValue > 0) {
      azimuth = 360 - azimuth;
    }
    _sunAzimuth = azimuth;
  }

  int _getDayOfYear(DateTime date) {
    DateTime startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  double _calculateSolarDeclination(int dayOfYear) {
    double angle = (2 * pi * (dayOfYear - 81)) / 365;
    return 23.45 * sin(angle);
  }

  double _calculateEquationOfTime(int dayOfYear) {
    double b = (2 * pi * (dayOfYear - 81)) / 365;
    return 9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b);
  }

  double _calculateHourAngle(double latitude, double declination) {
    double latRad = latitude * pi / 180;
    double decRad = declination * pi / 180;

    double cosHourAngle = -tan(latRad) * tan(decRad);
    if (cosHourAngle > 1) return 0;
    if (cosHourAngle < -1) return 90;

    return acos(cosHourAngle) * 180 / pi;
  }

  String formatTime(DateTime? time) {
    if (time == null) return "N/A";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  String formatAltitude(double altitude) {
    if (altitude < 0) return "Below horizon";
    return "${altitude.toStringAsFixed(1)}°";
  }

  String formatAzimuth(double azimuth) {
    return "${azimuth.toStringAsFixed(1)}°";
  }

  String getAzimuthDirection(double azimuth) {
    if (azimuth >= 337.5 || azimuth < 22.5) return "N";
    if (azimuth >= 22.5 && azimuth < 67.5) return "NE";
    if (azimuth >= 67.5 && azimuth < 112.5) return "E";
    if (azimuth >= 112.5 && azimuth < 157.5) return "SE";
    if (azimuth >= 157.5 && azimuth < 202.5) return "S";
    if (azimuth >= 202.5 && azimuth < 247.5) return "SW";
    if (azimuth >= 247.5 && azimuth < 292.5) return "W";
    return "NW";
  }

  bool isGoldenHourNow() {
    DateTime now = DateTime.now();
    if (_morningGoldenHourStart != null && _morningGoldenHourEnd != null) {
      if (now.isAfter(_morningGoldenHourStart!) && now.isBefore(_morningGoldenHourEnd!)) {
        return true;
      }
    }
    if (_eveningGoldenHourStart != null && _eveningGoldenHourEnd != null) {
      if (now.isAfter(_eveningGoldenHourStart!) && now.isBefore(_eveningGoldenHourEnd!)) {
        return true;
      }
    }
    return false;
  }

  bool isBlueHourNow() {
    DateTime now = DateTime.now();
    if (_morningBlueHourStart != null && _morningBlueHourEnd != null) {
      if (now.isAfter(_morningBlueHourStart!) && now.isBefore(_morningBlueHourEnd!)) {
        return true;
      }
    }
    if (_eveningBlueHourStart != null && _eveningBlueHourEnd != null) {
      if (now.isAfter(_eveningBlueHourStart!) && now.isBefore(_eveningBlueHourEnd!)) {
        return true;
      }
    }
    return false;
  }

  String getCurrentPhase() {
    if (isBlueHourNow()) return "Blue Hour";
    if (isGoldenHourNow()) return "Golden Hour";
    if (_isDay) return "Daytime";
    return "Nighttime";
  }

  String getPhaseEmoji() {
    if (isBlueHourNow()) return "💙";
    if (isGoldenHourNow()) return "🌅";
    if (_isDay) return "☀️";
    return "🌙";
  }
}

class SunPositionCard extends StatefulWidget {
  @override
  State<SunPositionCard> createState() => _SunPositionCardState();
}

class _SunPositionCardState extends State<SunPositionCard> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SunPositionModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.wb_sunny, size: 24),
              SizedBox(width: 12),
              Text("Sun Position: Loading..."),
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
                Icon(Icons.wb_sunny, size: 20),
                SizedBox(width: 8),
                Text(
                  "Sun Position",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                ActionChip(
                  label: Text("Today", style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _selectedDate = DateTime.now();
                    model.setDate(_selectedDate);
                  },
                  avatar: Icon(Icons.today, size: 14),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildCurrentPhase(context, model),
            SizedBox(height: 12),
            _buildSunTimes(context, model),
            SizedBox(height: 12),
            _buildGoldenHours(context, model),
            SizedBox(height: 12),
            _buildSunPosition(context, model),
            SizedBox(height: 12),
            _buildDateSelector(context, model),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPhase(BuildContext context, SunPositionModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  model.getPhaseEmoji(),
                  style: TextStyle(fontSize: 32),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  model.getCurrentPhase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (model.locationName.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 4),
                    Text(
                      model.locationName,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSunTimes(BuildContext context, SunPositionModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("Sun Times", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.wb_twilight, size: 14, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Sunrise: ${model.formatTime(model.sunrise)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.brightness_5, size: 14, color: Colors.yellow),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Solar Noon: ${model.formatTime(model.solarNoon)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.nightlight, size: 14, color: Colors.indigo),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Sunset: ${model.formatTime(model.sunset)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timelapse, size: 14, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Day Length: ${model.dayLengthFormatted}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldenHours(BuildContext context, SunPositionModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, size: 16, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("Photography Hours", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text("🌅", style: TextStyle(fontSize: 14)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Morning Golden: ${model.formatTime(model.morningGoldenHourStart)} - ${model.formatTime(model.morningGoldenHourEnd)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text("🌇", style: TextStyle(fontSize: 14)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Evening Golden: ${model.formatTime(model.eveningGoldenHourStart)} - ${model.formatTime(model.eveningGoldenHourEnd)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text("💙", style: TextStyle(fontSize: 14)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Morning Blue: ${model.formatTime(model.morningBlueHourStart)} - ${model.formatTime(model.morningBlueHourEnd)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text("💙", style: TextStyle(fontSize: 14)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Evening Blue: ${model.formatTime(model.eveningBlueHourStart)} - ${model.formatTime(model.eveningBlueHourEnd)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSunPosition(BuildContext context, SunPositionModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore, size: 16, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("Sun Position", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.arrow_upward, size: 14, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Altitude: ${model.formatAltitude(model.sunAltitude)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.navigation, size: 14, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Azimuth: ${model.formatAzimuth(model.sunAzimuth)} (${model.getAzimuthDirection(model.sunAzimuth)})",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, SunPositionModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(
              model.formatDate(model.currentDate),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.edit_calendar, size: 18),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  _selectedDate = picked;
                  model.setDate(picked);
                }
              },
              tooltip: "Select date",
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