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
  Global.infoModel.addInfo("Wallpaper", "Wallpaper loading disabled",
      subtitle: "依赖项缺失，使用默认背景.");
}
