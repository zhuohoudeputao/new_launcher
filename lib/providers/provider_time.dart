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
import 'package:new_launcher/ui/animation_helper.dart';
import 'package:new_launcher/card_config.dart';

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

Future<void> _update() async {
  _provideTime();
}

/// [provideTime] is the core action of the [MyAction] object
/// which produces some widgets into the infoList showing useful information.
void _provideTime() async {
  final showGreeting = await _showGreeting();
  final showSeconds = await _showSeconds();
  Global.infoModel.addCard(CardConfig(
    key: "Time",
    widget: TimeWidget(showGreeting: showGreeting, showSeconds: showSeconds),
    type: CardType.INFO,
    size: CardSize.MEDIUM,
    layout: CardLayout.GRID,
    title: "Time"));
}

Future<bool> _showGreeting() async {
  String greetingKey = "Time.ShowGreeting";
  bool showGreeting = await Global.getValue(greetingKey, true);
  return showGreeting;
}

Future<bool> _showSeconds() async {
  String secondsKey = "Time.ShowSeconds";
  bool showSeconds = await Global.getValue(secondsKey, false);
  return showSeconds;
}

/// TimeWidget displays current time with optional greeting and seconds
/// Made public for testing purposes
class TimeWidget extends StatefulWidget {
  final bool showGreeting;
  final bool showSeconds;

  const TimeWidget({Key? key, required this.showGreeting, required this.showSeconds}) : super(key: key);

  @override
  TimeWidgetState createState() =>
      TimeWidgetState(showGreeting: showGreeting, showSeconds: showSeconds);
}

class TimeWidgetState extends State<TimeWidget> {
  TimeWidgetState({required bool showGreeting, required bool showSeconds}) {
    this.showGreeting = showGreeting;
    this.showSeconds = showSeconds;
  }

  Timer? _initialTimer;
  Timer? _periodicTimer;
  late bool showGreeting;
  late bool showSeconds;
  bool _disposed = false;
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    
    if (showSeconds) {
      _periodicTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (_disposed) return;
        setState(() {});
      });
    } else {
      final initialDelay = 60 - now.second;
      _initialTimer = Timer(Duration(seconds: initialDelay), () {
        if (_disposed) return;
        setState(() {});
        _periodicTimer = Timer.periodic(const Duration(minutes: 1), (Timer timer) {
          if (_disposed) return;
          setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return customTimeWidget();
  }

  @override
  void dispose() {
    _disposed = true;
    _initialTimer?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
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
    const Map<int, String> months = {
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
    String month = months[now.month] ?? '';

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

    String timeString = hourString + ":" + minuteString;
    
    if (showSeconds) {
      int second = now.second;
      String secondString = second.toString();
      if (second < 10) {
        secondString = "0" + secondString;
      }
      timeString = timeString + ":" + secondString;
    }

    // create widget
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: AnimatedSwitcher(
          duration: AnimationHelper.defaultDuration,
          child: Text(
            month + " " + dayString + ", " + timeString,
            key: ValueKey(timeString),
            textAlign: TextAlign.left,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: AnimatedSwitcher(
          duration: AnimationHelper.defaultDuration,
          child: Text(
            greeting,
            key: ValueKey(greeting),
          ),
        ),
      ),
    );
  }
}

/// MinimalTimeWidget displays current time in a minimal format
/// Used for secondary screen with just time display
class MinimalTimeWidget extends StatefulWidget {
  const MinimalTimeWidget({Key? key}) : super(key: key);

  @override
  MinimalTimeWidgetState createState() => MinimalTimeWidgetState();
}

class MinimalTimeWidgetState extends State<MinimalTimeWidget> {
  Timer? _timer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_disposed) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final timeString = '$hour:$minute:$second';

    return AnimatedSwitcher(
      duration: AnimationHelper.defaultDuration,
      child: Text(
        timeString,
        key: ValueKey(timeString),
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
