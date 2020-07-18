/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-16 11:49:35
 * @Description: file content
 */ 

import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';

MyProvider providerWallpaper = MyProvider(initContent:initWallpaper);

List<MyAction> initWallpaper() {
  List<MyAction> actions = <MyAction>[];
  if (providerWallpaper.needUpdate()) {
    actions.add(MyAction(
      name: "Time now",
      keywords: "time now when",
      action: null,
      times: List.generate(
          24, (index) => 0), 
      suggestWidget: null,
    ));
    // do at the beginning
    
    // set updated
    providerWallpaper.setUpdated();
  }
  return actions;
}
