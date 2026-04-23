import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/providers/provider_wallpaper.dart';

MyProvider providerSettings = MyProvider(
    name: "Settings",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
}

Future<void> _initActions() async {
  final themeMode = await Global.getValue("Theme.Mode", "system");
  Global.infoModel.addInfoWidget(
      "ThemeMode",
      DarkModeOptionSelector(
        currentMode: themeMode as String,
        onChanged: (newMode) {
          Global.settingsModel.saveValue("Theme.Mode", newMode);
          Global.refreshTheme();
        },
      ),
      title: "Theme Mode");
  
  final cardOpacity = await Global.getValue("CardOpacity", 0.7);
  Global.infoModel.addInfoWidget(
      "CardOpacity",
      CardOpacitySlider(
        value: cardOpacity as double,
        onChanged: (newValue) async {
          Global.cardOpacityValue = newValue;
          Global.settingsModel.saveValue("CardOpacity", newValue);
          await Global.refreshTheme();
        },
      ),
      title: "Card Opacity");
  
  Global.infoModel.addInfoWidget(
      "WallpaperPicker",
      WallpaperPickerButton(
        label: "Change Wallpaper",
        onTap: () async {
          await pickWallpaperFromGallery();
        },
      ),
      title: "Wallpaper");
}

Future<void> _update() async {
  _initActions();
}