import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

BatteryModel batteryModel = BatteryModel();

MyProvider providerBattery = MyProvider(
    name: "Battery",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Battery status',
      keywords: 'battery power charge level',
      action: () => batteryModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await batteryModel.init();
  Global.infoModel.addInfoWidget(
      "Battery",
      ChangeNotifierProvider.value(
          value: batteryModel,
          builder: (context, child) => BatteryCard()),
      title: "Battery");
}

Future<void> _update() async {
  await batteryModel.refresh();
}

class BatteryModel extends ChangeNotifier {
  final Battery _battery = Battery();
  int _level = 0;
  BatteryState _state = BatteryState.unknown;
  bool _isInitialized = false;

  int get level => _level;
  BatteryState get state => _state;
  bool get isCharging => _state == BatteryState.charging || _state == BatteryState.connectedNotCharging;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      _level = await _battery.batteryLevel;
      _state = await _battery.batteryState;
      _isInitialized = true;
      Global.loggerModel.info("Battery initialized: $level%, state: $state", source: "Battery");
      
      _battery.onBatteryStateChanged.listen((BatteryState state) {
        if (_state != state) {
          _state = state;
          notifyListeners();
          Global.loggerModel.info("Battery state changed: $state", source: "Battery");
        }
      });
      
      notifyListeners();
    } catch (e) {
      Global.loggerModel.error("Battery init error: $e", source: "Battery");
    }
  }

  Future<void> refresh() async {
    try {
      _level = await _battery.batteryLevel;
      _state = await _battery.batteryState;
      notifyListeners();
      Global.loggerModel.info("Battery refreshed: $level%, state: $state", source: "Battery");
    } catch (e) {
      Global.loggerModel.warning("Battery refresh error: $e", source: "Battery");
    }
  }
}

class BatteryCard extends StatefulWidget {
  @override
  State<BatteryCard> createState() => _BatteryCardState();
}

class _BatteryCardState extends State<BatteryCard> {
  @override
  Widget build(BuildContext context) {
    final battery = context.watch<BatteryModel>();
    
    if (!battery.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.battery_unknown, size: 24),
              SizedBox(width: 12),
              Text("Battery: Loading..."),
            ],
          ),
        ),
      );
    }
    
    final icon = _getBatteryIcon(battery.level, battery.isCharging);
    final stateText = _getStateText(battery.state);
    final color = _getBatteryColor(battery.level);
    
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
                Row(
                  children: [
                    Icon(icon, size: 32, color: color),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${battery.level}%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stateText,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20),
                  onPressed: () => battery.refresh(),
                  tooltip: "Refresh battery",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getBatteryIcon(int level, bool isCharging) {
    if (isCharging) {
      return Icons.battery_charging_full;
    }
    if (level >= 90) return Icons.battery_full;
    if (level >= 70) return Icons.battery_6_bar;
    if (level >= 50) return Icons.battery_5_bar;
    if (level >= 30) return Icons.battery_3_bar;
    if (level >= 20) return Icons.battery_2_bar;
    if (level >= 10) return Icons.battery_1_bar;
    return Icons.battery_0_bar;
  }
  
  String _getStateText(BatteryState state) {
    switch (state) {
      case BatteryState.full:
        return "Full";
      case BatteryState.charging:
        return "Charging";
      case BatteryState.discharging:
        return "Discharging";
      case BatteryState.connectedNotCharging:
        return "Connected (Not Charging)";
      case BatteryState.unknown:
        return "Unknown";
    }
  }
  
  Color _getBatteryColor(int level) {
    final colorScheme = Theme.of(context).colorScheme;
    if (level >= 50) return colorScheme.primary;
    if (level >= 20) return colorScheme.tertiary;
    return colorScheme.error;
  }
}