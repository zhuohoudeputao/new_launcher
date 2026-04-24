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
      onlyAppsWithLaunchIntent: true);
  for (var app in apps) {
    if (app is! ApplicationWithIcon) continue;
    allAppsWithIcons.add(app);
    actions.add(MyAction(
      name: app.appName,
      keywords: "launch " +
          app.appName.toLowerCase() +
          " " +
          app.packageName.toLowerCase(),
      action: () async {
        DeviceApps.openApp(app.packageName);
        appStatisticsModel.recordLaunch(app.appName);
        Global.loggerModel.info("Launched app: ${app.appName}", source: "App");
        appModel.addApp(
            app.appName,
            _customButton(
                Image.memory(
                  app.icon,
                  width: 60,
                  height: 60,
                ), () {
              DeviceApps.openApp(app.packageName);
              appStatisticsModel.recordLaunch(app.appName);
            }));
      },
      times: List.generate(24, (index) => 0),
    ));
  }
  allAppsModel.setApps(allAppsWithIcons);

  final appWidgets = allAppsWithIcons.map((app) => 
    MapEntry("app_${app.packageName}", _buildAppCard(app))
  ).toList();
  final appTitles = Map.fromEntries(
    allAppsWithIcons.map((app) => MapEntry("app_${app.packageName}", app.appName))
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
  final Map<String, Widget> _recentApps = Map<String, Widget>();
  final List<String> _recentOrder = [];
  static const int maxRecentApps = 20;
  
  List<Widget> get recentlyUsedApps => _recentApps.values.toList();
  int get length => _recentApps.length;
  Map<String, Widget> get recentApps => Map.unmodifiable(_recentApps);

  Future<void> addApp(String key, Widget app) async {
    _recentApps.remove(key);
    _recentOrder.remove(key);
    _recentApps[key] = app;
    _recentOrder.add(key);
    
    if (_recentApps.length > maxRecentApps) {
      final oldestKey = _recentOrder.first;
      _recentApps.remove(oldestKey);
      _recentOrder.removeAt(0);
    }
    
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
    
    try {
      final countsStr = _launchCounts.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
      
      final timesStr = _lastLaunchTime.entries
        .map((e) => '${e.key}:${e.value.toIso8601String()}')
        .join(',');
      
      await prefs.setString(_countsKey, countsStr);
      await prefs.setString(_timesKey, timesStr);
    } catch (e) {
      Global.loggerModel.error("Failed to save app statistics: $e", source: "AppStatistics");
    }
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
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Container(
        height: 80,
        child: ListView.builder(
          itemCount: length,
          itemBuilder: (context, index) =>
              context.watch<AppModel>().recentlyUsedApps[length - index - 1],
          scrollDirection: Axis.horizontal,
          reverse: true,
          addRepaintBoundaries: true,
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
    return Card.outlined(
      color: Theme.of(context).cardColor,
      child: Container(
        height: 120,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
          ),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return RepaintBoundary(
              child: InkWell(
                onTap: () => DeviceApps.openApp(app.packageName),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.memory(
                      app.icon,
                      width: 48,
                      height: 48,
                      cacheWidth: 96,
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
              ),
            );
          },
          scrollDirection: Axis.horizontal,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: true,
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
  return Builder(
    builder: (context) => Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Image.memory(
          app.icon,
          width: 40,
          height: 40,
          cacheWidth: 80,
        ),
        title: Text(
          app.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          app.packageName,
          style: TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => DeviceApps.openApp(app.packageName),
      ),
    ),
  );
}

class AppStatisticsCard extends StatefulWidget {
  @override
  State<AppStatisticsCard> createState() => _AppStatisticsCardState();
}

class _AppStatisticsCardState extends State<AppStatisticsCard> {
  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Statistics"),
        content: Text("This will delete all app usage history. This action cannot be undone."),
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
      context.read<AppStatisticsModel>().clearStats();
      Global.loggerModel.info("App statistics cleared by user", source: "AppStatistics");
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<AppStatisticsModel>();
    final apps = context.watch<AllAppsModel>().apps;
    
    final topApps = stats.mostUsedApps.take(5).toList();
    
    return Card.outlined(
      color: Theme.of(context).cardColor,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${stats.uniqueApps} apps, ${stats.totalLaunches} launches", style: TextStyle(fontSize: 12)),
                    if (stats.totalLaunches > 0)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearConfirmation(context),
                        tooltip: "Clear statistics",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 4),
            if (topApps.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("No app usage data yet", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
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
