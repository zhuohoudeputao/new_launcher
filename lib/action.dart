/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-11 10:47:33
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'ui.dart';

/// [MyAction] class is representing the actions can be done by user.
class MyAction {
  /// the name or key of the action
  String name;

  /// use for search, combine as one string with blank between them
  String _keywords;

  /// Core action, what this action actually does.
  /// This action will influence infoWidgets, So infoList will be global.
  Function _action;
  List<int> _times; // 24 hours, every num means times in an hour
  Widget _suggestWidget; // Widget show in suggestList
  Widget get suggestWidget {
    return _suggestWidget;
  }

  /// Initialization
  MyAction({
    String name,
    String keywords,
    Function action,
    List<int> times,
    Widget suggestWidget, // define how to generate suggestWidget
  }) {
    this.name = name;
    this._keywords = keywords.toLowerCase();
    this._action = action;
    this._times = times;
    if (suggestWidget == null) {
      this._suggestWidget = customSuggestWidget(name: name, onPressed: action);
    } else {
      this._suggestWidget = suggestWidget;
    }
  }

  // add '_' before the func to make it 'private'

  /// call for action
  void action() {
    _action.call();
  }

  /// get the frequency of this action in this hour
  int frequency(double hour) {
    return _times[hour.floor()];
  }

  /// when this action is taken, add frequency by 1
  void frequencyAdd() {
    _times[DateTime.now().hour - 1] += 1;
  }

  /// whether search string is in keywords
  /// remember that keywords is lowercased
  bool canIdentifyBy(String searchStr) {
    return this._keywords.contains(searchStr.toLowerCase());
  }

}
