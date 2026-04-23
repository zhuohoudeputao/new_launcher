/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 02:23:00
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/ui.dart';
import 'package:device_apps/device_apps.dart';

MyProvider providerSystem = MyProvider(
    name: "System",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'View logs',
      keywords: 'logs debug error view',
      action: () {
        Global.infoModel.addInfoWidget("Logs", LogViewerWidget(), title: "Logs");
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Open camera',
      keywords: 'camera photo picture capture',
      action: () async {
        try {
          final apps = await DeviceApps.getInstalledApplications(
            includeSystemApps: true,
            onlyAppsWithLaunchIntent: true,
          );
          for (var app in apps) {
            if (app.packageName.toLowerCase().contains('camera')) {
              DeviceApps.openApp(app.packageName);
              Global.loggerModel.info("Opened camera: ${app.packageName}", source: "System");
              return;
            }
          }
          Global.infoModel.addInfo("Camera", "No camera app found", icon: Icon(Icons.camera_alt));
        } catch (e) {
          Global.loggerModel.error("Failed to open camera: $e", source: "System");
        }
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Open settings',
      keywords: 'settings system android device',
      action: () async {
        try {
          DeviceApps.openApp('com.android.settings');
          Global.loggerModel.info("Opened system settings", source: "System");
        } catch (e) {
          Global.loggerModel.error("Failed to open settings: $e", source: "System");
          Global.infoModel.addInfo("Settings", "Failed to open settings", icon: Icon(Icons.settings));
        }
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Open clock',
      keywords: 'clock time alarm timer',
      action: () async {
        try {
          final apps = await DeviceApps.getInstalledApplications(
            includeSystemApps: true,
            onlyAppsWithLaunchIntent: true,
          );
          for (var app in apps) {
            if (app.packageName.toLowerCase().contains('clock') ||
                app.packageName.toLowerCase().contains('deskclock')) {
              DeviceApps.openApp(app.packageName);
              Global.loggerModel.info("Opened clock: ${app.packageName}", source: "System");
              return;
            }
          }
          Global.infoModel.addInfo("Clock", "No clock app found", icon: Icon(Icons.access_time));
        } catch (e) {
          Global.loggerModel.error("Failed to open clock: $e", source: "System");
        }
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Open calculator',
      keywords: 'calculator math compute',
      action: () async {
        try {
          final apps = await DeviceApps.getInstalledApplications(
            includeSystemApps: true,
            onlyAppsWithLaunchIntent: true,
          );
          for (var app in apps) {
            if (app.packageName.toLowerCase().contains('calculator') ||
                app.appName.toLowerCase().contains('calculator')) {
              DeviceApps.openApp(app.packageName);
              Global.loggerModel.info("Opened calculator: ${app.packageName}", source: "System");
              return;
            }
          }
          Global.infoModel.addInfo("Calculator", "No calculator app found", icon: Icon(Icons.calculate));
        } catch (e) {
          Global.loggerModel.error("Failed to open calculator: $e", source: "System");
        }
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {}
Future<void> _update() async {}
