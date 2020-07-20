/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 18:09:05
 * @Description: file content
 */

import 'package:flutter/material.dart';
// Contains some custom widgets here

/// ``customInfoWidget`` is designed for displaying a message
/// with informations. The most important part of a "info" should be
/// displayed on title area. And the second important part is displayed
/// on subtitle. Icons will be added soon.
// TODO: add icon ability for info widget.
Widget customInfoWidget({String title, String subtitle = ""}) {
  return Card(
    child: ListTile(
      // leading: icon,
      title: Text(
        title,
        textAlign: TextAlign.left,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
    ),
  );
}

/// ``customSuggestWidget`` is designed for displaying a suggest action
/// above the input box.
Widget customSuggestWidget({String name, Function onPressed}) {
  return FlatButton(
    onPressed: onPressed,
    child: Text(name),
  );
}

Widget customTextSettingWidget(
    {String key, var value, void Function(String) onSubmitted}) {
  return Card(
    child: ListTile(
      // leading: icon,
      title: TextField(
        textAlign: TextAlign.left,
        style: TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: value.toString(),
          labelText: key,
          // helperText: key,
          border: InputBorder.none,
        ),
        onSubmitted: onSubmitted,
        // controller: TextEditingController()..text=value.toString(),
      ),
    ),
  );
}
