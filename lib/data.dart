/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-13 00:31:26
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey();
List<Widget> infoList = <Widget>[];
List<Widget> suggestList = <Widget>[];
Map<Widget, MyAction> suggestWidgetToAction = <Widget, MyAction>{};
ImageProvider backgroundImage;
    // NetworkImage('http://www.005.tv/uploads/allimg/171017/14033330Y-27.jpg');

class InfoData {}

class SettingData {
  //TODO: add setting function storing in sqlite database
}

/// A class handling all data events, including 
/// adding a widget to list, getting the total list only readable, etc.
class MyData{
  
}
