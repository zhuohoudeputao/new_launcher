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
MyProvider providerApp = MyProvider(initContent: _initApp);

List<MyAction> _actions = <MyAction>[];
bool _returned = false;
bool _success = false;
bool _called = false;
List<MyAction> _initApp() {
  // if (called == false) {
  //   getInstallApps();
  //   called = true;
  // }

  // wait for getInstallApps
  if (!_called && providerApp.needUpdate()) {
    _called = true;
    DeviceApps.getInstalledApplications(
            includeSystemApps: true,
            includeAppIcons: true,
            onlyAppsWithLaunchIntent: true)
        .then((data) {
      List apps = data;
      for (int i = 0; i < apps.length; i++) {
        ApplicationWithIcon app = apps[i] as ApplicationWithIcon;
        _actions.add(MyAction(
          name: app.appName,
          keywords: "launch " +
              app.appName.toLowerCase() +
              " " +
              app.packageName.toLowerCase(),
          action: () {
            DeviceApps.openApp(app.packageName); // launch this app
            myData.addInfo(app.appName,
                subtitle: "is launched.",
                icon: Image.memory(app.icon), onTap: () {
              DeviceApps.openApp(app.packageName);
            });
          },
          times: List.generate(24, (index) => 0),
          // suggestWidget: null,
        ));
      }
      _success = true;
    });
    providerApp.setUpdated();
  }

  // if (apps != null && providerApp.needUpdate()) {
  //   //generate a widget for every app
  //   for (Application app in apps) {
  //     actions.add(MyAction(
  //       name: app.appName,
  //       keywords: "launch " +
  //           app.appName.toLowerCase() +
  //           " " +
  //           app.packageName.toLowerCase(),
  //       action: () {
  //         DeviceApps.openApp(app.packageName); // launch this app
  //         infoList.add(customInfoWidget(
  //             title: app.appName,
  //             subtitle: "is launched.",
  //             onTap: () {
  //               DeviceApps.openApp(app.packageName);
  //             }));
  //       },
  //       times: List.generate(24, (index) => 0),
  //       // suggestWidget: null,
  //     ));
  //   }
  // do at the beginning
  // TODO: show most frequent used apps in infoList
  // set updated

  if (!_returned && _success) {
    _returned = true;
    return _actions;
  }
  return <MyAction>[];
}
