/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-13 00:31:26
 * @Description: file content
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/setting.dart';
import 'package:new_launcher/logger.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/providers/provider_app.dart';
import 'package:new_launcher/providers/provider_system.dart';
import 'package:new_launcher/providers/provider_theme.dart';
import 'package:new_launcher/providers/provider_time.dart';
import 'package:new_launcher/providers/provider_wallpaper.dart';
import 'package:new_launcher/providers/provider_weather.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkModeOptionSelector extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onChanged;

  const DarkModeOptionSelector({
    Key? key,
    required this.currentMode,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Theme Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(currentMode, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => onChanged("light"),
                    child: Text("Light"),
                  ),
                  TextButton(
                    onPressed: () => onChanged("dark"),
                    child: Text("Dark"),
                  ),
                  TextButton(
                    onPressed: () => onChanged("system"),
                    child: Text("System"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey();

/// Now use [Global] to read or write data.
/// [Global] contains models to save and change data, which are accessible for providers.
/// Frequently used methods can be writed here as static.
class Global {
  //_____________________________________________________________Initialize
  /// Initialize. Call this before run [MyApp].
  static Future init() async {
    await settingsModel.init();
    actionModel.init();
    final opacity = await settingsModel.getValue("CardOpacity", 0.7);
    cardOpacityValue = opacity is double ? opacity : 0.7;
    await settingsModel.getValue("WallpaperPicker", true);
    _addSettingsToInfo();
  }

  static void _addSettingsToInfo() {
    infoModel.addInfoWidget(
        "Settings",
        customInfoWidget(
          title: "Settings",
          icon: Icon(Icons.settings),
          onTap: () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => Setting()),
            );
          },
        ),
        title: "Settings");
  }

  static Future<void> refreshTheme() async {
    final provider = Global.providerList.firstWhere((p) => p.name == "Theme");
    await provider.init();
    Global.themeModel.notifyListeners();
    Global.infoModel.notifyListeners();
  }

  //_____________________________________________________________Opacity
  static double cardOpacityValue = 0.7;
  static double get cardOpacity => cardOpacityValue;

  //________________________________________________________BackgroundImage
  /// A model for storing background image.
  static BackgroundImageModel backgroundImageModel = BackgroundImageModel();

  //_______________________________________________________________Settings
  /// A model for storing settings
  static SettingsModel settingsModel = SettingsModel();

  static Future<dynamic> getValue(String key, var defaultValue) {
    return settingsModel.getValue(key, defaultValue);
  }

  //__________________________________________________________________Theme
  /// A model for theme management
  static ThemeModel themeModel = ThemeModel();

  static void setTheme(ThemeData themeData) {
    themeModel.themeData = themeData;
  }

  //___________________________________________________________________Info
  /// A model for managing info widgets
  static InfoModel infoModel = InfoModel();

  //__________________________________________________Action_and_Suggestion
  /// A model for managing actions
  static ActionModel actionModel = ActionModel();
  static LoggerModel loggerModel = LoggerModel();

  static Future<void> addActions(List<MyAction> actions) async {
    actionModel.addActions(actions);
  }

  //____________________________________________________________MyProviders
  /// A list for storing providers
  static List<MyProvider> providerList = [
    providerWallpaper,
    providerTheme,
    providerTime,
    providerWeather,
    providerApp,
    providerSystem,
  ];

  //_______________________________________________________________________
}

class ActionModel with ChangeNotifier {
  Map<String, MyAction> _actionMap = <String, MyAction>{};

  String _searchQuery = "";
  Timer? _debounceTimer;

  String get searchQuery => _searchQuery;

  Future<void> addActions(List<MyAction> actions) async {
    for (MyAction action in actions) {
      addAction(action);
    }
  }

  Future<void> addAction(MyAction action) async {
    _actionMap[action.name] = action;
  }

  List<Widget> _suggestList = <Widget>[];

  List<Widget> get suggestList => _suggestList;

  TextEditingController inputBoxController = TextEditingController();

  Future<void> init() async {
    Global.loggerModel.info("Initializing providers", source: "Global");
    for (MyProvider provider in Global.providerList) {
      try {
        await provider.init();
        Global.loggerModel.info("Provider ${provider.name} initialized", source: "Global");
      } catch (e) {
        Global.loggerModel.error("Provider ${provider.name} init error: $e", source: "Global");
      }
    }
  }

  void generateSuggestList(String input) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = input;
      _suggestList.clear();
      for (MyAction action in _actionMap.values) {
        if (action.canIdentifyBy(input)) {
          _suggestList.add(action.suggestWidget);
        }
      }
      notifyListeners();
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void runFirstAction(String input) {
    if (_suggestList.isNotEmpty) {
      final widget = _suggestList[0];
      if (widget is TextButton) {
        widget.onPressed?.call();
      }
    } else {
      Global.infoModel.addInfo("Help", "I don't know what to do",
          subtitle: "Try type something else.", icon: Icon(Icons.help));
    }
    // some special care
    inputBoxController.clear();
    generateSuggestList(" ");
  }
}

class InfoModel with ChangeNotifier {
  final Map<String, Widget> _infoList = <String, Widget>{};
  final Map<String, String> _titleMap = <String, String>{};
  List<Widget> get infoList => _infoList.values.toList();

  List<Widget> getFilteredList(String query) {
    if (query.isEmpty) return infoList;
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return infoList;
    return _infoList.entries
        .where((e) =>
            e.key.toLowerCase().contains(lowerQuery) ||
            (_titleMap[e.key]?.toLowerCase().contains(lowerQuery) ?? false))
        .map((e) => e.value)
        .toList();
  }

  int get length => _infoList.length;

  /// This method use title as key and add a [customInfoWidget] to infoList
  void addInfo(String key, String title,
      {String? subtitle, Widget? icon, void Function()? onTap}) {
    _titleMap[key] = title;
    this.addInfoWidget(
        key,
        customInfoWidget(
            title: title, subtitle: subtitle ?? '', icon: icon, onTap: onTap));
  }

  /// This method is more flexible for providers
  void addInfoWidget(String key, Widget infoWidget, {String? title}) {
    if (title != null) {
      _titleMap[key] = title;
    }
    _infoList.remove(key);
    _infoList[key] = infoWidget;
    notifyListeners();
  }

  void addInfoWidgetsBatch(List<MapEntry<String, Widget>> widgets, {Map<String, String>? titles}) {
    for (final entry in widgets) {
      _infoList.remove(entry.key);
      _infoList[entry.key] = entry.value;
    }
    if (titles != null) {
      for (final entry in titles.entries) {
        _titleMap[entry.key] = entry.value;
      }
    }
    notifyListeners();
  }
}

class ThemeModel with ChangeNotifier {
  ThemeData? _themeData;
  ThemeData get themeData => _themeData ?? ThemeData();

  set themeData(ThemeData value) {
    _themeData = value;
    notifyListeners();
  }
}

class SettingsModel with ChangeNotifier {
  SharedPreferences? _prefs;
  Map<String, Widget> _settingMap = <String, Widget>{};

  Future init() async {
    _prefs = await SharedPreferences.getInstance();
    final keys = _prefs?.getKeys() ?? <String>{};
    for (String key in keys) {
      final value = _prefs?.get(key);
      if (value != null) {
        _addSettingWidget(key, value);
      }
    }
  }

  List<Widget> get settingList => _settingMap.values.toList();

  void saveValue(String key, var value) {
    final prefs = _prefs;
    if (prefs == null) return;
    if (value is String) {
      prefs.setString(key, value);
    } else if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is double) {
      prefs.setDouble(key, value);
    } else if (value is int) {
      prefs.setInt(key, value);
    } else if (value is List<String>) {
      prefs.setStringList(key, value);
    }
    _addSettingWidget(key, value);
    _triggerProviderUpdate(key);
  }

  void _triggerProviderUpdate(String key) {
    for (final provider in Global.providerList) {
      if (key.startsWith(provider.name + ".")) {
        provider.update();
        Global.loggerModel.info("Provider ${provider.name} updated due to setting: $key", source: "Settings");
      }
    }
  }

  Future<dynamic> getValue(String key, var defaultValue) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    final prefs = _prefs!;
    if (prefs.containsKey(key)) {
      return prefs.get(key);
    } else {
      saveValue(key, defaultValue);
      return defaultValue;
    }
  }

  void _addSettingWidget(String key, var value) {
    if (key == "WallpaperPicker") {
      _settingMap[key] = WallpaperPickerButton(
        label: "Change Wallpaper",
        onTap: () async {
          await pickWallpaperFromGallery();
        },
      );
    } else if (key == "Theme.Mode" && value is String) {
      _settingMap[key] = DarkModeOptionSelector(
        currentMode: value,
        onChanged: (newMode) {
          saveValue(key, newMode);
          Global.refreshTheme();
        },
      );
    } else if (key == "CardOpacity" && value is double) {
      _settingMap[key] = CardOpacitySlider(
          value: value,
          onChanged: (newValue) async {
            Global.cardOpacityValue = newValue;
            saveValue(key, newValue);
            await Global.refreshTheme();
            notifyListeners();
          });
    } else if (value is String) {
      _settingMap[key] = customTextSettingWidget(
          key: key,
          value: value,
          onSubmitted: (newValue) {
            saveValue(key, newValue);
          });
    } else if (value is bool) {
      _settingMap[key] = CustomBoolSettingWidget(
          settingKey: key,
          value: value,
          onChanged: (newValue) {
            saveValue(key, newValue);
            if (key.startsWith("Theme.")) {
              Global.refreshTheme();
            }
          });
    } else if (value is double) {
      _settingMap[key] = customTextSettingWidget(
          key: key,
          value: value,
          onSubmitted: (newValue) {
            saveValue(key, double.parse(newValue));
          });
    } else if (value is int) {
      _settingMap[key] = customTextSettingWidget(
          key: key,
          value: value,
          onSubmitted: (newValue) {
            saveValue(key, int.parse(newValue));
          });
    } else if (value is List<String>) {
    }
    notifyListeners();
  }
}

class BackgroundImageModel with ChangeNotifier {
  // data
  ImageProvider _backgroundImage = NetworkImage(
      "http://bizhi.bcoderss.com/wp-content/uploads/2019/05/pixel-3a-wallpaper-droidviews.jpg");
  // getter or setter
  ImageProvider get backgroundImage {
    return _backgroundImage;
  }

  set backgroundImage(ImageProvider value) {
    _backgroundImage = value;
    notifyListeners();
  }
}
