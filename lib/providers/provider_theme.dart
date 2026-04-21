import 'package:flutter/material.dart';
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

Future<void> _update() async {}

Future<void> _provideTheme() async {
  Brightness brightness = Brightness.light;
  Color cardColor = Colors.white.withOpacity(Global.cardOpacity);
  Color textColor = Colors.black87;

  String darkKey = "Theme.Dark";
  bool dark = await Global.getValue(darkKey, false);

  String transparentKey = "Theme.Transparent";
  bool transparent = await Global.getValue(transparentKey, true);

  if (dark) {
    brightness = Brightness.dark;
    cardColor =
        Colors.grey[850]?.withOpacity(Global.cardOpacity) ?? Colors.grey;
    textColor = Colors.white;
  }

  if (transparent) {
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
}
