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

// a provider provides some actions
MyProvider providerApp = MyProvider(
    name: "App",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  List<MyAction> actions = <MyAction>[];
  List<ApplicationWithIcon> allAppsWithIcons = [];
  DeviceApps.getInstalledApplications(
          includeSystemApps: true,
          includeAppIcons: true,
          onlyAppsWithLaunchIntent: true)
      .then((apps) {
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
          _appModel.addApp(
              appWithIcon.appName,
              _customButton(
                  Image.memory(
                    appWithIcon.icon,
                    width: 60,
                    height: 60,
                  ), () {
                DeviceApps.openApp(appWithIcon.packageName);
              }));
        },
        times: List.generate(24, (index) => 0),
      ));
    }
    _allAppsModel.setApps(allAppsWithIcons);
    Global.addActions(actions);
  });
}

Future<void> _initActions() async {
  Global.infoModel.addInfoWidget(
      "RecentApp",
      ChangeNotifierProvider.value(
          value: _appModel,
          builder: (context, child) => RecentlyUsedAppsCard()));

  for (final app in _allAppsModel.apps) {
    Global.infoModel.addInfoWidget(
      "app_${app.packageName}",
      _buildAppCard(app),
    );
  }
}

Future<void> _update() async {}

// Recently used apps
AppModel _appModel = AppModel();
AllAppsModel _allAppsModel = AllAppsModel();

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

// TODO: Frequently used apps

// TODO: Recently used apps
