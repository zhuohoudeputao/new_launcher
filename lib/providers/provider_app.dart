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
  DeviceApps.getInstalledApplications(
          includeSystemApps: true,
          includeAppIcons: true,
          onlyAppsWithLaunchIntent: true)
      .then((apps) {
    for (var app in apps) {
      if (app is! ApplicationWithIcon) continue;
      final appWithIcon = app as ApplicationWithIcon;
      // ApplicationWithIcon app = apps[i] as ApplicationWithIcon;
      actions.add(MyAction(
        name: appWithIcon.appName,
        keywords: "launch " +
            appWithIcon.appName.toLowerCase() +
            " " +
            appWithIcon.packageName.toLowerCase(),
        action: () async {
          DeviceApps.openApp(appWithIcon.packageName); // launch this app
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
    Global.addActions(actions);
  });
}

Future<void> _initActions() async {
  Global.infoModel.addInfoWidget(
      "RecentApp",
      ChangeNotifierProvider.value(
          value: _appModel,
          builder: (context, child) => RecentlyUsedAppsCard()));
}

Future<void> _update() async {}

// Recently used apps
AppModel _appModel = AppModel();

class AppModel with ChangeNotifier {
  Map<String, Widget> recentApps = Map<String, Widget>();
  List<Widget> get recentlyUsedApps => recentApps.values.toList();
  int get length => recentApps.length;

  Future<void> addApp(String key, Widget app) async {
    recentApps.remove(key); // remove key will let the index of it become 0
    recentApps[key] = app;
    notifyListeners();
  }
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

// TODO: Frequently used apps

// TODO: Recently used apps
