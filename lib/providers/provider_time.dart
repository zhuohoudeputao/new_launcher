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
MyProvider providerTime = MyProvider(
    name: "Time",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: "Time now",
      keywords: "time now when is it",
      action: _provideTime,
      times: List.generate(
          24, (index) => 0), // let the frequency big enough to prioritize it
    )
  ]);
}

Future<void> _initActions() async {
  _provideTime();
}

Future<void> _update() async {}


/// [provideTime] is the core action of the [MyAction] object
/// which produces some widgets into the infoList showing useful information.
void _provideTime() {
  _showGreeting().then((value) {
    Global.infoModel.addInfoWidget("Time", _TimeWidget(showGreeting: value));
    // myData.addInfoWidget("Time", _TimeWidget(showGreeting: value));
  });
}

Future<bool> _showGreeting() async {
  String greetingKey = "Time.ShowGreeting";
  // obtain greeting state from myData
  bool showGreeting = await Global.getValue(greetingKey, true);
  return showGreeting;
}

class _TimeWidget extends StatefulWidget {
  final bool showGreeting;

  const _TimeWidget({Key key, this.showGreeting}) : super(key: key);

  @override
  _TimeWidgetState createState() =>
      _TimeWidgetState(showGreeting: showGreeting);
}

class _TimeWidgetState extends State<_TimeWidget> {
  _TimeWidgetState({bool showGreeting}) {
    this.showGreeting = showGreeting;
  }

  Timer timer;
  bool showGreeting;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (DateTime.now().second == 0) {
        setState(() {});
      }
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

    String greeting = "";
    if (showGreeting) {
      int hour = now.hour;
      // greeting
      if (hour >= 22 || (hour >= 0 && hour < 6)) {
        greeting = "Don't strain yourself too much. Good night 🌙";
      } else if (hour >= 6 && hour < 9) {
        greeting = "Good morning! It's beautiful outside ☀";
      } else if (hour >= 9 && hour < 12) {
        greeting = "Good morning ☀";
      } else if (hour >= 12 && hour < 18) {
        greeting = "Good afternoon! Take a cup of coffee ☕";
      } else if (hour >= 18 && hour < 22) {
        greeting = "Have a good night 🌙";
      }
    }

    // month
    Map<int, String> months = {
      1: 'January',
      2: 'February',
      3: 'March',
      4: 'April',
      5: 'May',
      6: 'June',
      7: 'July',
      8: 'August',
      9: 'September',
      10: 'October',
      11: 'November',
      12: 'December'
    };
    String month = months[now.month];

    int day = now.day;
    String dayString = day.toString();
    if (day < 10) {
      dayString = "0" + dayString;
    }

    int hour = now.hour;
    String hourString = hour.toString();
    if (hour < 10) {
      hourString = "0" + hourString;
    }

    int minute = now.minute;
    String minuteString = minute.toString();
    if (minute < 10) {
      minuteString = "0" + minuteString;
    }

    // create widget
    return customInfoWidget(
        title: month + " " + dayString + ", " + hourString + ":" + minuteString,
        subtitle: greeting);
  }
}
