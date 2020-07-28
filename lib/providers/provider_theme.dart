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
  _provideTheme();
}

Future<void> _update() async {}

void _provideTheme() async {
  Brightness brightness = Brightness.light;
  Color cardColor = Colors.white;

  // for obtain dark or white
  String darkKey = "Theme.Dark";
  // obtain dark state from myData
  bool dark = await Global.getValue(darkKey, false);

  String transparentKey = "Theme.Transparent";
  bool transparent = await Global.getValue(transparentKey, true);

  if (dark) {
    brightness = Brightness.dark;
    cardColor = Colors.grey[850];
  }

  if (transparent) {
    cardColor = Colors.transparent;
  }

  Global.setTheme(ThemeData(
    brightness: brightness,
    cardColor: cardColor,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  ));
}
