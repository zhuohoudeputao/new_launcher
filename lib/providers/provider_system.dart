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
import 'package:new_launcher/setting.dart';

MyProvider providerSystem = MyProvider(
    name: "System",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
        name: 'Open launcher settings',
        keywords: 'launcher settings',
        action: () {
          navigatorKey.currentState.push(
              MaterialPageRoute(builder: (BuildContext context) => Setting()));
        },
        times: List.generate(24, (index) => 0),
      ),
  ]);
}

Future<void> _initActions() async {}
Future<void> _update() async {}

