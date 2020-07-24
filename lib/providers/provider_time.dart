/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 22:41:27
 * @Description: a provider for time and greeting
 */
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/ui.dart';

/// a provider provides some actions about time
MyProvider providerTime = MyProvider(initContent: _initTime);

/// The funciton [initTime] makes actions about time
/// Each action can be done when the user chooses it
/// And the suggestWidget will be shown in suggestList
List<MyAction> _initTime() {
  List<MyAction> actions = <MyAction>[];
  if (providerTime.needUpdate()) {
    actions.add(MyAction(
      name: "Time now",
      keywords: "time now when is it",
      action: _provideTime,
      times: List.generate(
          24, (index) => 0), // let the frequency big enough to prioritize it
      suggestWidget: null,
    ));
    // do at the beginning
    _provideTime();
    // set updated
    providerTime.setUpdated();
  }
  return actions;
}

/// [provideTime] is the core action of the [MyAction] object
/// which produces some widgets into the infoList showing useful information.
void _provideTime() {
  myData.addInfoWidget("Time", _TimeWidget());
}

class _TimeWidget extends StatefulWidget {
  @override
  _TimeWidgetState createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<_TimeWidget> {
  Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return customTimeWidget();
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  Widget customTimeWidget() {
    // get info
    DateTime now = DateTime.now();

    String greeting;
    int hour = now.hour;
    // greeting
    if (hour >= 22 || (hour >= 0 && hour < 6)) {
      greeting = "Don't strain yourself too much. Good night 🌙";
    }
    if (hour >= 6 && hour < 9) {
      greeting = "Good morning! It's beautiful outside ☀";
    }
    if (hour >= 9 && hour < 12) {
      greeting = "Good morning ☀";
    }
    if (hour >= 12 && hour < 18) {
      greeting = "Good afternoon! Take a cup of coffee ☕";
    }
    if (hour >= 18 && hour < 22) {
      greeting = "Have a good night 🌙";
    }

    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    String month = months[now.month - 1];

    // create widget
    return customInfoWidget(
        title: month +
            " " +
            now.day.toString() +
            ", " +
            now.hour.toString() +
            ":" +
            now.minute.toString(),
        subtitle: greeting);
  }
}
