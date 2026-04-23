import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

MyProvider providerWorldClock = MyProvider(
  name: "WorldClock",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

WorldClockModel worldClockModel = WorldClockModel();

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: "World Clock",
      keywords: "world clock timezone time zone add remove",
      action: () {
        Global.infoModel.addInfo("worldclock", "World Clock", subtitle: "View multiple timezones");
      },
      times: List.generate(24, (_) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await worldClockModel.init();
  Global.infoModel.addInfoWidget(
    "WorldClock",
    ChangeNotifierProvider.value(
      value: worldClockModel,
      builder: (context, child) => WorldClockCard(),
    ),
    title: "World Clock",
  );
}

Future<void> _update() async {}

class WorldClockModel with ChangeNotifier {
  static const String _timezonesKey = 'WorldClock.Timezones';
  static const int maxTimezones = 10;
  
  List<String> _timezones = [];
  SharedPreferences? _prefs;
  Timer? _timer;
  bool _disposed = false;
  
  List<String> get timezones => List.unmodifiable(_timezones);
  
  static const Map<String, String> commonTimezones = {
    'UTC': 'UTC',
    'America/New_York': 'New York',
    'America/Los_Angeles': 'Los Angeles',
    'America/Chicago': 'Chicago',
    'Europe/London': 'London',
    'Europe/Paris': 'Paris',
    'Europe/Berlin': 'Berlin',
    'Asia/Tokyo': 'Tokyo',
    'Asia/Shanghai': 'Shanghai',
    'Asia/Hong_Kong': 'Hong Kong',
    'Asia/Singapore': 'Singapore',
    'Asia/Dubai': 'Dubai',
    'Australia/Sydney': 'Sydney',
    'Pacific/Auckland': 'Auckland',
  };
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTimezones();
    _startTimer();
  }
  
  Future<void> _loadTimezones() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    final saved = prefs.getStringList(_timezonesKey);
    if (saved != null && saved.isNotEmpty) {
      _timezones = saved;
    } else {
      _timezones = ['America/New_York', 'Europe/London', 'Asia/Tokyo'];
      await _saveTimezones();
    }
    
    Global.loggerModel.info("Loaded ${_timezones.length} world clocks", source: "WorldClock");
    notifyListeners();
  }
  
  Future<void> _saveTimezones() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    await prefs.setStringList(_timezonesKey, _timezones);
  }
  
  void _startTimer() {
    _timer?.cancel();
    final now = DateTime.now();
    final initialDelay = 60 - now.second;
    
    Timer(Duration(seconds: initialDelay), () {
      if (_disposed) return;
      notifyListeners();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (_disposed) return;
        notifyListeners();
      });
    });
  }
  
  Future<void> addTimezone(String timezone) async {
    if (_timezones.contains(timezone)) {
      Global.loggerModel.warning("Timezone $timezone already exists", source: "WorldClock");
      return;
    }
    
    if (_timezones.length >= maxTimezones) {
      Global.loggerModel.warning("Maximum $maxTimezones timezones reached", source: "WorldClock");
      return;
    }
    
    _timezones.add(timezone);
    await _saveTimezones();
    notifyListeners();
    Global.loggerModel.info("Added timezone: $timezone", source: "WorldClock");
  }
  
  Future<void> removeTimezone(String timezone) async {
    if (!_timezones.contains(timezone)) return;
    
    _timezones.remove(timezone);
    await _saveTimezones();
    notifyListeners();
    Global.loggerModel.info("Removed timezone: $timezone", source: "WorldClock");
  }
  
  DateTime getTimeInTimezone(String timezone) {
    final now = DateTime.now();
    
    try {
      final utc = now.toUtc();
      final offset = getTimezoneOffset(timezone);
      return utc.add(offset);
    } catch (e) {
      return now;
    }
  }
  
  Duration getTimezoneOffset(String timezone) {
    final offsetMap = {
      'UTC': Duration.zero,
      'America/New_York': Duration(hours: -5),
      'America/Los_Angeles': Duration(hours: -8),
      'America/Chicago': Duration(hours: -6),
      'Europe/London': Duration.zero,
      'Europe/Paris': Duration(hours: 1),
      'Europe/Berlin': Duration(hours: 1),
      'Asia/Tokyo': Duration(hours: 9),
      'Asia/Shanghai': Duration(hours: 8),
      'Asia/Hong_Kong': Duration(hours: 8),
      'Asia/Singapore': Duration(hours: 8),
      'Asia/Dubai': Duration(hours: 4),
      'Australia/Sydney': Duration(hours: 11),
      'Pacific/Auckland': Duration(hours: 13),
    };
    
    return offsetMap[timezone] ?? Duration.zero;
  }
  
  String formatTime(String timezone) {
    final time = getTimeInTimezone(timezone);
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  String getDisplayName(String timezone) {
    return commonTimezones[timezone] ?? timezone.split('/').last.replaceAll('_', ' ');
  }
  
  String getDayPeriod(String timezone) {
    final time = getTimeInTimezone(timezone);
    final hour = time.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 21) return 'evening';
    return 'night';
  }
  
  IconData getDayIcon(String timezone) {
    final time = getTimeInTimezone(timezone);
    final hour = time.hour;
    if (hour >= 6 && hour < 18) {
      return Icons.wb_sunny;
    }
    return Icons.nightlight_round;
  }
  
  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class WorldClockCard extends StatefulWidget {
  @override
  State<WorldClockCard> createState() => _WorldClockCardState();
}

class _WorldClockCardState extends State<WorldClockCard> {
  
  Future<void> _showAddTimezoneDialog(BuildContext context) async {
    final model = context.read<WorldClockModel>();
    final available = WorldClockModel.commonTimezones.keys
        .where((tz) => !model.timezones.contains(tz))
        .toList();
    
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All available timezones added')),
      );
      return;
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Timezone'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: available.length,
            itemBuilder: (context, index) {
              final tz = available[index];
              return ListTile(
                leading: Icon(Icons.public),
                title: Text(WorldClockModel.commonTimezones[tz] ?? tz),
                subtitle: Text(tz),
                onTap: () {
                  model.addTimezone(tz);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showRemoveConfirmation(BuildContext context, String timezone) async {
    final model = context.read<WorldClockModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Timezone'),
        content: Text('Remove ${WorldClockModel.commonTimezones[timezone] ?? timezone}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await model.removeTimezone(timezone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<WorldClockModel>();
    final timezones = model.timezones;
    
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "World Clock",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _showAddTimezoneDialog(context),
                  tooltip: "Add timezone",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (timezones.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No timezones added. Tap + to add one.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: timezones.length,
                itemBuilder: (context, index) {
                  final tz = timezones[index];
                  return Dismissible(
                    key: Key(tz),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      model.removeTimezone(tz);
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 16),
                      color: Theme.of(context).colorScheme.error,
                      child: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(
                        model.getDayIcon(tz),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(model.getDisplayName(tz)),
                      subtitle: Text(
                        model.getDayPeriod(tz),
                        style: TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        model.formatTime(tz),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      onLongPress: () => _showRemoveConfirmation(context, tz),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}