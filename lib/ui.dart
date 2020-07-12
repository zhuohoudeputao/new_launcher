/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 18:09:05
 * @Description: file content
 */

import 'package:flutter/material.dart';

Widget customInfoWidget({String title, String subtitle=""}) {
  // custom Text Widget
  // String head = ">_ "; // shell style information
  return Card(
    color: Colors.white70,
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

Widget customSuggestWidget({String name, Function onPressed}) {
  return FlatButton(
    onPressed: onPressed,
    child: Text(name),
    textColor: Colors.white,
  );
}
