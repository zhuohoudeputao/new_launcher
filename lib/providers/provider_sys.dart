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

MyProvider providerSys = MyProvider(initContent: initSys);

List<MyAction> initSys() {
  List<MyAction> actions = <MyAction>[];
  if (providerSys.needUpdate()) {
    actions = [
      MyAction(
        name: 'Open launcher settings',
        keywords: 'launcher settings',
        action: () {
          navigatorKey.currentState.push(
              MaterialPageRoute(builder: (BuildContext context) => Setting()));
        },
        times: List.generate(24, (index) => 0),
        suggestWidget: null,
      ),
    ];
    // do at the beginning

    // set updated
    providerSys.setUpdated();
  }
  return actions;
}
