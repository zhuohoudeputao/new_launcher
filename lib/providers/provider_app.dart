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
        action: () {
          DeviceApps.openApp(app.packageName); // launch this app
          Global.infoModel.addInfo(app.appName, app.appName,
              subtitle: "is launched.",
              icon: Image.memory(app.icon), onTap: () {
            DeviceApps.openApp(app.packageName);
          });
        },
        times: List.generate(24, (index) => 0),
        // suggestWidget: null,
      ));
    }
    Global.addActions(actions);
  });
}

Future<void> _initActions() async {}

Future<void> _update() async {}
