import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ParkingModel parkingModel = ParkingModel();

MyProvider providerParking = MyProvider(
    name: "Parking",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Parking',
      keywords: 'parking park car vehicle meter spot location level garage',
      action: () => parkingModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await parkingModel.init();
  Global.infoModel.addInfoWidget(
      "Parking",
      ChangeNotifierProvider.value(
          value: parkingModel,
          builder: (context, child) => ParkingCard()),
      title: "Parking");
}

Future<void> _update() async {
  parkingModel.refresh();
}

class ParkingEntry {
  final String location;
  final String notes;
  final DateTime parkedTime;
  int meterMinutes;
  int meterRemainingSeconds;
  Timer? meterTimer;
  bool meterActive;

  ParkingEntry({
    required this.location,
    this.notes = '',
    required this.parkedTime,
    this.meterMinutes = 0,
    this.meterRemainingSeconds = 0,
    this.meterTimer,
    this.meterActive = false,
  });

  String get displayTime {
    if (meterRemainingSeconds <= 0) return '0:00';
    final hours = meterRemainingSeconds ~/ 3600;
    final minutes = (meterRemainingSeconds % 3600) ~/ 60;
    final seconds = meterRemainingSeconds % 60;
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  double get meterProgress {
    if (meterMinutes <= 0) return 0;
    return meterRemainingSeconds / (meterMinutes * 60);
  }

  bool get meterExpired => meterMinutes > 0 && meterRemainingSeconds <= 0;

  String get parkedDuration {
    final now = DateTime.now();
    final diff = now.difference(parkedTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Map<String, dynamic> toJson() => {
    'location': location,
    'notes': notes,
    'parkedTime': parkedTime.toIso8601String(),
    'meterMinutes': meterMinutes,
    'meterRemainingSeconds': meterRemainingSeconds,
    'meterActive': meterActive,
  };

  factory ParkingEntry.fromJson(Map<String, dynamic> json) {
    return ParkingEntry(
      location: json['location'] ?? '',
      notes: json['notes'] ?? '',
      parkedTime: DateTime.parse(json['parkedTime']),
      meterMinutes: json['meterMinutes'] ?? 0,
      meterRemainingSeconds: json['meterRemainingSeconds'] ?? 0,
      meterActive: json['meterActive'] ?? false,
    );
  }
}

class ParkingModel extends ChangeNotifier {
  ParkingEntry? _currentParking;
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  ParkingEntry? get currentParking => _currentParking;
  bool get isInitialized => _isInitialized;
  bool get hasParking => _currentParking != null;
  bool get hasMeter => _currentParking != null && _currentParking!.meterMinutes > 0;
  bool get meterExpired => _currentParking != null && _currentParking!.meterExpired;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final data = _prefs?.getString('ParkingEntry');
    if (data != null) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        _currentParking = ParkingEntry.fromJson(json);
        if (_currentParking!.meterActive && _currentParking!.meterRemainingSeconds > 0) {
          _startMeterTimer();
        }
      } catch (e) {
        Global.loggerModel.error("Failed to load parking: $e", source: "Parking");
      }
    }
    _isInitialized = true;
    Global.loggerModel.info("Parking initialized", source: "Parking");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Parking refreshed", source: "Parking");
  }

  Future<void> saveParking() async {
    if (_currentParking == null) return;
    final data = jsonEncode(_currentParking!.toJson());
    await _prefs?.setString('ParkingEntry', data);
  }

  void setParking(String location, {String notes = '', int meterMinutes = 0}) {
    _currentParking?.meterTimer?.cancel();
    
    _currentParking = ParkingEntry(
      location: location,
      notes: notes,
      parkedTime: DateTime.now(),
      meterMinutes: meterMinutes,
      meterRemainingSeconds: meterMinutes * 60,
      meterActive: meterMinutes > 0,
    );

    if (meterMinutes > 0) {
      _startMeterTimer();
    }

    saveParking();
    notifyListeners();
    Global.loggerModel.info("Parking set: $location", source: "Parking");
  }

  void _startMeterTimer() {
    if (_currentParking == null) return;
    _currentParking!.meterTimer?.cancel();
    _currentParking!.meterTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_currentParking!.meterRemainingSeconds > 0) {
        _currentParking!.meterRemainingSeconds--;
        notifyListeners();
        if (_currentParking!.meterRemainingSeconds % 60 == 0) {
          saveParking();
        }
      } else {
        _meterExpired();
      }
    });
  }

  void _meterExpired() {
    if (_currentParking == null) return;
    _currentParking!.meterTimer?.cancel();
    _currentParking!.meterActive = false;
    saveParking();
    notifyListeners();
    Global.loggerModel.warning("Parking meter expired!", source: "Parking");
    
    _showExpirationNotification();
  }

  void _showExpirationNotification() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parking meter expired at ${_currentParking!.location}'),
          duration: Duration(seconds: 10),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void pauseMeter() {
    if (_currentParking == null || !_currentParking!.meterActive) return;
    _currentParking!.meterTimer?.cancel();
    _currentParking!.meterActive = false;
    saveParking();
    notifyListeners();
    Global.loggerModel.info("Meter paused", source: "Parking");
  }

  void resumeMeter() {
    if (_currentParking == null || _currentParking!.meterActive) return;
    if (_currentParking!.meterRemainingSeconds > 0) {
      _startMeterTimer();
      _currentParking!.meterActive = true;
      saveParking();
      notifyListeners();
      Global.loggerModel.info("Meter resumed", source: "Parking");
    }
  }

  void addMeterTime(int minutes) {
    if (_currentParking == null) return;
    _currentParking!.meterMinutes += minutes;
    _currentParking!.meterRemainingSeconds += minutes * 60;
    if (!_currentParking!.meterActive && _currentParking!.meterRemainingSeconds > 0) {
      _startMeterTimer();
      _currentParking!.meterActive = true;
    }
    saveParking();
    notifyListeners();
    Global.loggerModel.info("Added $minutes minutes to meter", source: "Parking");
  }

  void clearParking() {
    _currentParking?.meterTimer?.cancel();
    _currentParking = null;
    _prefs?.remove('ParkingEntry');
    notifyListeners();
    Global.loggerModel.info("Parking cleared", source: "Parking");
  }

  void updateLocation(String location) {
    if (_currentParking == null) return;
    _currentParking = ParkingEntry(
      location: location,
      notes: _currentParking!.notes,
      parkedTime: _currentParking!.parkedTime,
      meterMinutes: _currentParking!.meterMinutes,
      meterRemainingSeconds: _currentParking!.meterRemainingSeconds,
      meterActive: _currentParking!.meterActive,
    );
    if (_currentParking!.meterActive) {
      _startMeterTimer();
    }
    saveParking();
    notifyListeners();
  }

  void updateNotes(String notes) {
    if (_currentParking == null) return;
    _currentParking = ParkingEntry(
      location: _currentParking!.location,
      notes: notes,
      parkedTime: _currentParking!.parkedTime,
      meterMinutes: _currentParking!.meterMinutes,
      meterRemainingSeconds: _currentParking!.meterRemainingSeconds,
      meterActive: _currentParking!.meterActive,
    );
    if (_currentParking!.meterActive) {
      _startMeterTimer();
    }
    saveParking();
    notifyListeners();
  }
}

class ParkingCard extends StatefulWidget {
  @override
  State<ParkingCard> createState() => _ParkingCardState();
}

class _ParkingCardState extends State<ParkingCard> {
  final List<int> _quickMeterMinutes = [15, 30, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final parking = context.watch<ParkingModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!parking.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.local_parking, size: 24),
              SizedBox(width: 12),
              Text("Parking: Loading..."),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Parking",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (parking.hasParking)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _showClearConfirmation(context),
                    tooltip: "Clear parking",
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (parking.hasParking) _buildParkingInfo(context, parking)
            else _buildEmptyState(context),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingInfo(BuildContext context, ParkingModel parking) {
    final entry = parking.currentParking!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 20, color: colorScheme.primary),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.location,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (entry.notes.isNotEmpty)
                    Text(
                      entry.notes,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, size: 16),
              onPressed: () => _showEditDialog(context, entry),
              tooltip: "Edit",
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: colorScheme.onSurfaceVariant),
            SizedBox(width: 4),
            Text(
              "Parked for ${entry.parkedDuration}",
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (parking.hasMeter) ...[
          SizedBox(height: 12),
          _buildMeterSection(context, parking, entry),
        ],
      ],
    );
  }

  Widget _buildMeterSection(BuildContext context, ParkingModel parking, ParkingEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpired = parking.meterExpired;
    final meterColor = isExpired ? colorScheme.error : colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer, size: 20, color: meterColor),
            SizedBox(width: 8),
            Text(
              "Meter: ${entry.displayTime}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpired ? colorScheme.error : null,
              ),
            ),
            if (isExpired)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.warning, size: 16, color: colorScheme.error),
              ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: entry.meterProgress,
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: meterColor,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickMeterMinutes.map((mins) => 
                  ActionChip(
                    label: Text('+${mins}m'),
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => parking.addMeterTime(mins),
                  ),
                ).toList(),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (entry.meterActive)
              IconButton(
                icon: Icon(Icons.pause),
                onPressed: () => parking.pauseMeter(),
                tooltip: "Pause meter",
              )
            else if (entry.meterRemainingSeconds > 0)
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () => parking.resumeMeter(),
                tooltip: "Resume meter",
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.local_parking, size: 20),
            SizedBox(width: 8),
            Text("No active parking"),
          ],
        ),
        SizedBox(height: 12),
        ElevatedButton.icon(
          icon: Icon(Icons.add_location_alt),
          label: Text("Set Parking Location"),
          onPressed: () => _showSetParkingDialog(context),
        ),
      ],
    );
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Parking"),
        content: Text("This will remove your current parking location and stop the meter timer."),
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
      context.read<ParkingModel>().clearParking();
    }
  }

  void _showSetParkingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SetParkingDialog(),
    );
  }

  void _showEditDialog(BuildContext context, ParkingEntry entry) {
    showDialog(
      context: context,
      builder: (context) => EditParkingDialog(entry: entry),
    );
  }
}

class SetParkingDialog extends StatefulWidget {
  @override
  State<SetParkingDialog> createState() => _SetParkingDialogState();
}

class _SetParkingDialogState extends State<SetParkingDialog> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _meterController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _meterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Set Parking Location"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: "Location (e.g., Level 2, Spot 15)",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: "Notes (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _meterController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Meter time (minutes, optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            final location = _locationController.text.trim();
            if (location.isEmpty) return;
            final notes = _notesController.text.trim();
            final meterMinutes = int.tryParse(_meterController.text) ?? 0;
            context.read<ParkingModel>().setParking(
              location,
              notes: notes,
              meterMinutes: meterMinutes,
            );
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}

class EditParkingDialog extends StatefulWidget {
  final ParkingEntry entry;

  const EditParkingDialog({required this.entry});

  @override
  State<EditParkingDialog> createState() => _EditParkingDialogState();
}

class _EditParkingDialogState extends State<EditParkingDialog> {
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.entry.location);
    _notesController = TextEditingController(text: widget.entry.notes);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Parking"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: "Location",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: "Notes",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            final location = _locationController.text.trim();
            if (location.isEmpty) return;
            final parking = context.read<ParkingModel>();
            parking.updateLocation(location);
            parking.updateNotes(_notesController.text.trim());
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}