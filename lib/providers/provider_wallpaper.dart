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
import 'package:permission_handler/permission_handler.dart';

MyProvider providerWallpaper = MyProvider(
    name: "Wallpaper",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: "Refresh Wallpaper",
      keywords: "refresh background wallpaper",
      action: _readBackground,
      times: List.generate(24, (index) => 0),
    )
  ]);
}

Future<void> _initActions() async {
  _readBackground();
}

Future<void> _update() async {
  _readBackground();
}

Future<void> _readBackground() async {
  var status = await Permission.storage.status;
  if (status.isUndetermined || status.isDenied) {
    status = await Permission.storage.request();
  }
  if (status.isGranted) {
    Global.setBackgroundImage(MemoryImage(await LauncherHelper.getWallpaper));
  } else {
    Global.infoModel.addInfo(
        "ReadBackgroundFail", "Read local background fail.",
        subtitle: "Using default background. Check the storage permission.");
  }
}
