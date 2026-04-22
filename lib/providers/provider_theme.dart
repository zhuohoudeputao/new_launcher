import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';

MyProvider providerTheme = MyProvider(
    name: "Theme",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: "Refresh theme",
      keywords: "refresh theme",
      action: _provideTheme,
      times: List.generate(24, (index) => 0),
    )
  ]);
}

Future<void> _initActions() async {
  await _provideTheme();
}

Future<void> _update() async {
  await _provideTheme();
}

Brightness _getSystemBrightness() {
  return SchedulerBinding.instance.platformDispatcher.platformBrightness;
}

Future<void> _provideTheme() async {
  Brightness brightness = Brightness.light;
  Color cardColor = Colors.white.withOpacity(Global.cardOpacity);
  Color textColor = Colors.black87;

  String modeKey = "Theme.Mode";
  String mode = await Global.getValue(modeKey, "light");

  String darkKey = "Theme.Dark";
  bool legacyDark = await Global.getValue(darkKey, false);
  
  if (mode == "system") {
    brightness = _getSystemBrightness();
  } else if (mode == "dark" || legacyDark) {
    brightness = Brightness.dark;
  }

  String transparentKey = "Theme.Transparent";
  bool transparent = await Global.getValue(transparentKey, true);

  if (brightness == Brightness.dark) {
    cardColor = Colors.grey[850]?.withOpacity(Global.cardOpacity) ?? Colors.grey;
    textColor = Colors.white;
  }

  if (transparent && brightness == Brightness.light) {
    cardColor = Colors.white.withOpacity(Global.cardOpacity);
  }

  Global.setTheme(ThemeData(
    brightness: brightness,
    cardColor: cardColor,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: textColor),
      bodyLarge: TextStyle(color: textColor),
      titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
    ),
  ));
  
  Global.infoModel.notifyListeners();
}
