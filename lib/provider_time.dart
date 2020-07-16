/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-16 11:42:42
 * @Description: a provider for time and greeting
 */
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';

import 'action.dart';
import 'ui.dart';
import 'provider.dart';

// a provider provides some actions

MyProvider providerTime = MyProvider(initContent: initTime);

List<MyAction> initTime() {
  List<MyAction> actions = <MyAction>[];
  if (providerTime.needUpdate()) {
    actions.add(MyAction(
      name: "Time now",
      keywords: "time now when",
      action:
          provideTime, // this Action only show time info and do nothing in the background
      times: List.generate(
          24, (index) => 100), // let the frequency big enough to prioritize it
      suggestWidget: null,
    ));
    // do at the beginning
    provideTime();
    // set updated
    providerTime.setUpdated();
  }
  return actions;
}

void provideTime() {
  infoList.add(TimeWidget());
}

class TimeWidget extends StatefulWidget {
  @override
  _TimeWidgetState createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> {
  Timer timer;
  Duration duration = Duration(seconds: 1);
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(duration, (Timer timer) {
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
