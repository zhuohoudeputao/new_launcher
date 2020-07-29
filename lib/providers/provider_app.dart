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
      .then((data) {
    List apps = data;
    for (int i = 0; i < apps.length; i++) {
      ApplicationWithIcon app = apps[i] as ApplicationWithIcon;
      actions.add(MyAction(
        name: app.appName,
        keywords: "launch " +
            app.appName.toLowerCase() +
            " " +
            app.packageName.toLowerCase(),
        action: () async {
          DeviceApps.openApp(app.packageName); // launch this app
          appModel.addApp(_customButton(
              Image.memory(
                app.icon,
                width: 40,
                height: 40,
              ), () {
            DeviceApps.openApp(app.packageName);
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
          value: appModel,
          builder: (context, child) => RecentlyUsedAppsCard()));
}

Future<void> _update() async {}

AppModel appModel = AppModel();

class AppModel with ChangeNotifier {
  List<Widget> recentlyUsedApps = <Widget>[];

  void addApp(Widget app) {
    recentlyUsedApps.add(app);
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
    return Card(
      child: Container(
        height: 60,
        child: ListView.builder(
          itemCount: context.watch<AppModel>().recentlyUsedApps.length,
          itemBuilder: (context, index) =>
              context.watch<AppModel>().recentlyUsedApps[index],
          scrollDirection: Axis.horizontal,
        ),
      ),
    );
  }
}

Widget _customButton(Widget icon, void Function() onPressed) {
  return FlatButton(
    onPressed: onPressed,
    child: icon,
    highlightColor: Colors.transparent,
  );
}

// TODO: Frequently used apps

// TODO: Recently used apps
