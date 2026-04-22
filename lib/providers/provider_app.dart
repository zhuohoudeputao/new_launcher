/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-22 01:59:04
 * @Description: file content
 */

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// a provider provides some actions
MyProvider providerApp = MyProvider(
    name: "App",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  List<MyAction> actions = <MyAction>[];
  List<ApplicationWithIcon> allAppsWithIcons = [];
  final apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      includeAppIcons: true,
      onlyAppsWithLaunchIntent: false);
  for (var app in apps) {
    if (app is! ApplicationWithIcon) continue;
    final appWithIcon = app as ApplicationWithIcon;
    allAppsWithIcons.add(appWithIcon);
    actions.add(MyAction(
      name: appWithIcon.appName,
      keywords: "launch " +
          appWithIcon.appName.toLowerCase() +
          " " +
          appWithIcon.packageName.toLowerCase(),
      action: () async {
        DeviceApps.openApp(appWithIcon.packageName);
        appStatisticsModel.recordLaunch(appWithIcon.appName);
        Global.loggerModel.info("Launched app: ${appWithIcon.appName}", source: "App");
        appModel.addApp(
            appWithIcon.appName,
            _customButton(
                Image.memory(
                  appWithIcon.icon,
                  width: 60,
                  height: 60,
                ), () {
              DeviceApps.openApp(appWithIcon.packageName);
              appStatisticsModel.recordLaunch(appWithIcon.appName);
            }));
      },
      times: List.generate(24, (index) => 0),
    ));
  }
  allAppsModel.setApps(allAppsWithIcons);

  final topApps = allAppsWithIcons.take(20).toList();
  final appWidgets = topApps.map((app) => 
    MapEntry("app_${app.packageName}", _buildAppCard(app))
  ).toList();
  final appTitles = Map.fromEntries(
    topApps.map((app) => MapEntry("app_${app.packageName}", app.appName))
  );
  Global.infoModel.addInfoWidgetsBatch(appWidgets, titles: appTitles);

  Global.addActions(actions);
}

Future<void> _initActions() async {
  await appStatisticsModel.init();
  Global.infoModel.addInfoWidget(
      "AppStatistics",
      ChangeNotifierProvider.value(
          value: appStatisticsModel,
          builder: (context, child) => AppStatisticsCard()),
      title: "App Statistics");
  Global.infoModel.addInfoWidget(
      "RecentApp",
      ChangeNotifierProvider.value(
          value: appModel,
          builder: (context, child) => RecentlyUsedAppsCard()),
      title: "Recent Apps");
  Global.infoModel.addInfoWidget(
      "AllApps",
      ChangeNotifierProvider.value(
          value: allAppsModel,
          builder: (context, child) => AllAppsCard()),
      title: "All Apps");
}

Future<void> _update() async {}

// Recently used apps
AppModel appModel = AppModel();
AllAppsModel allAppsModel = AllAppsModel();

class AppModel with ChangeNotifier {
  Map<String, Widget> recentApps = Map<String, Widget>();
  List<Widget> get recentlyUsedApps => recentApps.values.toList();
  int get length => recentApps.length;

  Future<void> addApp(String key, Widget app) async {
    recentApps.remove(key);
    recentApps[key] = app;
    notifyListeners();
  }
}

class AllAppsModel with ChangeNotifier {
  List<ApplicationWithIcon> allApps = [];

  Future<void> setApps(List<ApplicationWithIcon> apps) async {
    allApps = apps;
    notifyListeners();
  }

  int get length => allApps.length;
  List<ApplicationWithIcon> get apps => allApps;
}

class AppStatisticsModel extends ChangeNotifier {
  final Map<String, int> _launchCounts = {};
  final Map<String, DateTime> _lastLaunchTime = {};
  
  static const int maxStatsEntries = 50;
  static const String _countsKey = 'AppStatistics.LaunchCounts';
  static const String _timesKey = 'AppStatistics.LastLaunchTimes';
  
  SharedPreferences? _prefs;
  
  List<String> get mostUsedApps {
    final sorted = _launchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }
  
  int getLaunchCount(String appName) => _launchCounts[appName] ?? 0;
  
  DateTime? getLastLaunchTime(String appName) => _lastLaunchTime[appName];
  
  Map<String, int> get allStats => Map.unmodifiable(_launchCounts);
  
  int get totalLaunches => _launchCounts.values.fold(0, (a, b) => a + b);
  
  int get uniqueApps => _launchCounts.length;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPersistedStats();
  }
  
  Future<void> _loadPersistedStats() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    final countsData = prefs.getString(_countsKey);
    final timesData = prefs.getString(_timesKey);
    
    if (countsData != null) {
      try {
        final parts = countsData.split(',');
        for (final part in parts) {
          if (part.isEmpty) continue;
          final kv = part.split(':');
          if (kv.length == 2) {
            _launchCounts[kv[0]] = int.parse(kv[1]);
          }
        }
      } catch (e) {
        Global.loggerModel.warning("Failed to parse launch counts: $e", source: "AppStatistics");
      }
    }
    
    if (timesData != null) {
      try {
        final parts = timesData.split(',');
        for (final part in parts) {
          if (part.isEmpty) continue;
          final kv = part.split(':');
          if (kv.length == 2) {
            _lastLaunchTime[kv[0]] = DateTime.parse(kv[1]);
          }
        }
      } catch (e) {
        Global.loggerModel.warning("Failed to parse launch times: $e", source: "AppStatistics");
      }
    }
    
    if (_launchCounts.isNotEmpty) {
      Global.loggerModel.info("Loaded ${_launchCounts.length} persisted app statistics", source: "AppStatistics");
    }
    
    notifyListeners();
  }
  
  Future<void> _saveStats() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    final countsStr = _launchCounts.entries
      .map((e) => '${e.key}:${e.value}')
      .join(',');
    
    final timesStr = _lastLaunchTime.entries
      .map((e) => '${e.key}:${e.value.toIso8601String()}')
      .join(',');
    
    await prefs.setString(_countsKey, countsStr);
    await prefs.setString(_timesKey, timesStr);
  }
  
  void recordLaunch(String appName) {
    _launchCounts[appName] = (_launchCounts[appName] ?? 0) + 1;
    _lastLaunchTime[appName] = DateTime.now();
    
    if (_launchCounts.length > maxStatsEntries) {
      final leastUsed = _launchCounts.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      _launchCounts.remove(leastUsed.first.key);
      _lastLaunchTime.remove(leastUsed.first.key);
    }
    
    notifyListeners();
    _saveStats();
  }
  
  void clearStats() {
    _launchCounts.clear();
    _lastLaunchTime.clear();
    notifyListeners();
    _saveStats();
  }
  
  void loadStats(Map<String, int> counts, Map<String, DateTime> times) {
    _launchCounts.clear();
    _lastLaunchTime.clear();
    counts.forEach((key, value) {
      _launchCounts[key] = value;
    });
    times.forEach((key, value) {
      _lastLaunchTime[key] = value;
    });
    notifyListeners();
    _saveStats();
  }
}

AppStatisticsModel appStatisticsModel = AppStatisticsModel();

class RecentlyUsedAppsCard extends StatefulWidget {
  @override
  State<RecentlyUsedAppsCard> createState() => RecentlyUsedAppsCardState();
}

class RecentlyUsedAppsCardState extends State<RecentlyUsedAppsCard> {
  @override
  Widget build(BuildContext context) {
    int length = context.watch<AppModel>().length;
    return Card(
      child: Container(
        height: 80,
        child: ListView.builder(
          itemCount: length,
          itemBuilder: (context, index) =>
              context.watch<AppModel>().recentlyUsedApps[length - index - 1],
          scrollDirection: Axis.horizontal,
          reverse: true,
        ),
      ),
    );
  }
}

class AllAppsCard extends StatefulWidget {
  @override
  State<AllAppsCard> createState() => _AllAppsCardState();
}

class _AllAppsCardState extends State<AllAppsCard> {
  @override
  Widget build(BuildContext context) {
    final apps = context.watch<AllAppsModel>().apps;
    return Card(
      child: Container(
        height: 120,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.8,
          ),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return InkWell(
              onTap: () => DeviceApps.openApp(app.packageName),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.memory(
                    app.icon,
                    width: 48,
                    height: 48,
                  ),
                  SizedBox(height: 4),
                  Text(
                    app.appName,
                    style: TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
          scrollDirection: Axis.horizontal,
        ),
      ),
    );
  }
}

Widget _customButton(Widget icon, void Function() onPressed) {
  return Container(
      width: 80,
      child: ClipOval(
          child: TextButton(
        onPressed: onPressed,
        child: icon,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
      )));
}

Widget _buildAppCard(ApplicationWithIcon app) {
  return Card(
    child: ListTile(
      leading: Image.memory(
        app.icon,
        width: 40,
        height: 40,
      ),
      title: Text(app.appName),
      subtitle: Text(app.packageName),
      onTap: () => DeviceApps.openApp(app.packageName),
    ),
  );
}

class AppStatisticsCard extends StatefulWidget {
  @override
  State<AppStatisticsCard> createState() => _AppStatisticsCardState();
}

class _AppStatisticsCardState extends State<AppStatisticsCard> {
  @override
  Widget build(BuildContext context) {
    final stats = context.watch<AppStatisticsModel>();
    final apps = context.watch<AllAppsModel>().apps;
    
    final topApps = stats.mostUsedApps.take(5).toList();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("App Statistics", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${stats.uniqueApps} apps, ${stats.totalLaunches} launches", style: TextStyle(fontSize: 12)),
              ],
            ),
            SizedBox(height: 4),
            if (topApps.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("No app usage data yet", style: TextStyle(fontSize: 12, color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: topApps.length,
                itemBuilder: (context, index) {
                  final appName = topApps[index];
                  final app = apps.where((a) => a.appName == appName).firstOrNull;
                  final count = stats.getLaunchCount(appName);
                  final lastTime = stats.getLastLaunchTime(appName);
                  return _buildStatItem(appName, count, lastTime, app);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String appName, int count, DateTime? lastTime, ApplicationWithIcon? app) {
    String lastLaunchStr = "";
    if (lastTime != null) {
      final diff = DateTime.now().difference(lastTime);
      if (diff.inMinutes < 60) {
        lastLaunchStr = "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        lastLaunchStr = "${diff.inHours}h ago";
      } else {
        lastLaunchStr = "${diff.inDays}d ago";
      }
    }
    
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: app != null 
        ? Image.memory(app.icon, width: 28, height: 28)
        : Icon(Icons.apps, size: 28),
      title: Text(appName, style: TextStyle(fontSize: 13)),
      subtitle: Text("$count launches, $lastLaunchStr", style: TextStyle(fontSize: 11)),
      trailing: Container(
        width: 50,
        alignment: Alignment.centerRight,
        child: Text("$count", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}
