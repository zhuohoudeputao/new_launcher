/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 22:37:43
 * @Description:
 */

import 'package:flutter/material.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';

MyProvider providerWeather = MyProvider(
    name: "Weather",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Weather',
      keywords: 'weather now',
      action: _provideWeather,
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  _provideWeather();
}

Future<void> _update() async {}

void _provideWeather() async {
  Global.infoModel.addInfoWidget(
      "Weather",
      customInfoWidget(
          title: "天气服务已禁用", subtitle: "依赖项缺失", icon: Icon(Icons.cloud_off)));
}
