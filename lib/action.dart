/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-11 10:47:33
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'ui.dart';

class MyAction {
  String name; // the name or key of the action
  String
      keywords; // use for search, combine as one string with blank between them
  // Core action, what this action does
  // This action will influence infoWidgets
  // So infoList must be global
  Function action;
  List<int> times; // 24 hours, every num means times in an hour
  Widget suggestWidget; // Widget show in suggestList

  // initialization
  MyAction({
    String name,
    String keywords,
    Function action,
    List<int> times,
    Widget suggestWidget, // define how to generate suggestWidget
  }) {
    this.name = name;
    this.keywords = keywords.toLowerCase();
    this.action = action;
    this.times = times;
    if (suggestWidget == null) {
      this.suggestWidget = _suggestWidget();
    } else {
      this.suggestWidget = suggestWidget;
    }
  }

  // add '_' before the func to make it 'private'

  // get the frequency of this action in this hour
  int timesInHour(double hour) {
    return times[hour.floor()];
  }

  // whether search string is in keywords
  // remember that keywords is lowercased
  bool strInKeywords(String input) {
    return keywords.contains(input.toLowerCase());
  }

  Widget _suggestWidget() {
    return customSuggestWidget(name: this.name, onPressed: this.action);
  }
}
