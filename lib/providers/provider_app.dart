/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 18:12:00
 * @Description: file content
 */

import 'package:device_apps/device_apps.dart';
import 'package:new_launcher/data.dart';
import 'dart:async';

import 'package:new_launcher/action.dart';
import '../ui.dart';
import '../provider.dart';

// a provider provides some actions
MyProvider providerApp = MyProvider(initContent: initApp);

List<Application> apps;
Future getInstallApps() async {
  apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      includeAppIcons: true,
      onlyAppsWithLaunchIntent: true);
}

bool called = false;
List<MyAction> initApp() {
  if (called == false) {
    getInstallApps();
    called = true;
  }
  List<MyAction> actions = <MyAction>[];
  // wait for getInstallApps
  if (apps != null && providerApp.needUpdate()) {
    //generate a widget for every app
    for (Application app in apps) {
      actions.add(MyAction(
        name: app.appName,
        keywords: "launch " +
            app.appName.toLowerCase() +
            " " +
            app.packageName.toLowerCase(),
        action: () {
          DeviceApps.openApp(app.packageName); // launch this app
          infoList.add(customInfoWidget(title: app.appName ,subtitle: "is launched."));
        },
        times: List.generate(24, (index) => 0),
        // infoWidgets: [customInfoWidget(app.appName + " is launched.")],
        suggestWidget: null,
      ));
    }
    //do at the beginning

    // set updated
    providerApp.setUpdated();
  }
  return actions;
}
