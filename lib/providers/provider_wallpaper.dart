/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-16 11:49:35
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:launcher_helper/launcher_helper.dart';
import 'package:new_launcher/ui.dart';
import 'package:permission_handler/permission_handler.dart';

MyProvider providerWallpaper = MyProvider(initContent: initWallpaper);

List<MyAction> initWallpaper() {
  List<MyAction> actions = <MyAction>[];
  if (providerWallpaper.needUpdate()) {
    // actions.add(MyAction(
    //   name: "Time now",
    //   keywords: "time now when",
    //   action: null,
    //   times: List.generate(
    //       24, (index) => 0),
    //   suggestWidget: null,
    // ));
    // do at the beginning
    readBackground();
    // set updated
    providerWallpaper.setUpdated();
  }
  return actions;
}

Future<void> readBackground() async {
  var status = await Permission.storage.status;
  if (status.isUndetermined || status.isDenied) {
    status = await Permission.storage.request();
  }
  if (status.isGranted) {
    backgroundImage = MemoryImage(await LauncherHelper.getWallpaper);
  } else {
    infoList.add(customInfoWidget(
        title: "Read local backround fail.",
        subtitle: "Using default background. Check the storage permission."));
  }
}