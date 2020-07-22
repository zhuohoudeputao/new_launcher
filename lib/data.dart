/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-13 00:31:26
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey();
List<Widget> infoList = <Widget>[];
List<Widget> suggestList = <Widget>[];

Map<Widget, MyAction> suggestWidgetToAction = <Widget, MyAction>{};
ImageProvider backgroundImage;
// NetworkImage('http://www.005.tv/uploads/allimg/171017/14033330Y-27.jpg');

/// Use this [myData] to read or write data.
MyData myData = MyData();

/// A class handling all data events, including
/// - adding a widget to list
/// - getting a list with manipulation
/// - etc.
class MyData {
  // Data manipulator
  /// Support for shared_preferences
  SharedPreferences _prefs;

  // Data
  /// A widget list generated for changing settings.
  List<Widget> _settingList = <Widget>[];

  // Initialize
  /// Initialize all data manipulators
  MyData() {
    _getSPInstance();
  }

  /// initialize the SharedPreferences instance
  void _getSPInstance() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// [settingList] is generated for all the settings in shared preferences.
  /// Providers just need to save and use key-value pairs,
  /// don't need to design the widget of setting items.
  List<Widget> get settingList {
    _settingList.clear();
    // generate settingList
    Set<String> keys = _prefs.getKeys();
    for (String key in keys) {
      var value = _prefs.get(key);
      if (value is String) {
        _settingList.add(customTextSettingWidget(
            key: key,
            value: value,
            onSubmitted: (value) {
              _prefs.setString(key, value);
            }));
      }
      if (value is double) {
        _settingList.add(customTextSettingWidget(
            key: key,
            value: value,
            onSubmitted: (value) {
              _prefs.setDouble(key, double.parse(value));
            }));
      }
    }
    return _settingList;
  }

  /// Save key-value pair for providers.
  /// [value] can be a string, bool, double, int or string list.
  /// If the type of [value] is not support, nothing will be store.
  void saveValue(String key, var value) {
    if (value is String) {
      _prefs.setString(key, value);
    } else if (value is bool) {
      _prefs.setBool(key, value);
    } else if (value is double) {
      _prefs.setDouble(key, value);
    } else if (value is int) {
      _prefs.setInt(key, value);
    } else if (value is List<String>) {
      _prefs.setStringList(key, value);
    }
  }

  /// Get value for providers.
  /// If the [key] is not contained in preferences, [null] is returned.
  dynamic getValue(String key) async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.containsKey(key)) {
      return _prefs.get(key);
    } else {
      return null;
    }
  }

  /// A list for storing info widgets
  List<InfoWidget> _infoList = <InfoWidget>[];

  /// This method use title as key and add a [customInfoWidget] to infoList
  void addInfo(String title,
      {String subtitle, Widget icon, void Function() onTap}) {
    this.addInfoWidget(
        title,
        customInfoWidget(
            title: title, subtitle: subtitle, icon: icon, onTap: onTap));
  }

  /// This method is more flexible for providers
  void addInfoWidget(String key, Widget infoWidget) {
    // check if there is a info widget with the same key
    for (int i = 0; i < this._infoList.length; i++) {
      if (this._infoList[i].key == key) {
        this._infoList.removeAt(i);
      }
    }
    // add at the end
    this._infoList.add(InfoWidget(key, infoWidget));
  }

  /// get the infoList
  List<Widget> get infoList {
    List<Widget> infoList = <Widget>[];
    for (int i = 0; i < this._infoList.length; i++) {
      infoList.add(this._infoList[i].infoWidget);
    }
    return infoList;
  }
}

class InfoWidget {
  String key;
  Widget infoWidget;
  DateTime timeStamp;

  InfoWidget(String key, Widget infoWidget) {
    this.key = key;
    this.infoWidget = infoWidget;
    this.timeStamp = DateTime.now();
  }
  bool operator ==(dynamic other) {
    return this.key == other.key;
  }

  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
}
