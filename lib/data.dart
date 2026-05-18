/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-13 00:31:26
 * @Description: file content
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:new_launcher/ai_engine.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/logger.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/card_config.dart';
import 'package:new_launcher/providers/provider_app.dart';
import 'package:new_launcher/providers/provider_notifications.dart';
import 'package:new_launcher/providers/provider_settings.dart';
import 'package:new_launcher/providers/provider_app_drawer.dart';
import 'package:new_launcher/providers/provider_smart_suggestions.dart';
import 'package:new_launcher/providers/provider_system.dart';
import 'package:new_launcher/providers/provider_theme.dart';
import 'package:new_launcher/providers/provider_time.dart';
import 'package:new_launcher/providers/provider_wallpaper.dart';
import 'package:new_launcher/providers/provider_weather.dart';
import 'package:new_launcher/memory_system.dart';
import 'package:new_launcher/context_builder.dart';
import 'package:new_launcher/ui/animation_helper.dart';
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
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Theme Mode", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: "light",
                  label: Text("Light"),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: "dark",
                  label: Text("Dark"),
                  icon: Icon(Icons.dark_mode),
                ),
                ButtonSegment(
                  value: "system",
                  label: Text("System"),
                  icon: Icon(Icons.settings_suggest),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: (Set<String> newSelection) {
                onChanged(newSelection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.comfortable,
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
    // Initialize memory system with SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await initMemorySystem(prefs);
    initContextBuilder(memorySystem);
    await loadAIConfig();
    actionModel.init();
    final opacity = await settingsModel.getValue("CardOpacity", 0.7);
    cardOpacityValue = opacity is double ? opacity : 0.7;
    await settingsModel.getValue("WallpaperPicker", true);
  }

  static void refreshTheme() {
    Global.themeModel.refresh();
    Global.infoModel.refresh();
  }

  /// Update theme mode synchronously for instant UI update
  static void updateThemeMode(String mode) {
    Brightness brightness = Brightness.light;
    
    if (mode == "system") {
      brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    } else if (mode == "dark") {
      brightness = Brightness.dark;
    }
    
    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: brightness,
    );
    
    // Use cached opacity value
    Color cardColor = colorScheme.surface.withValues(alpha: Global.cardOpacity);
    
    Global.setTheme(ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardColor: cardColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: colorScheme.onSurface),
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        titleMedium: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
      ),
    ));
    
    Global.themeModel.refresh();
    Global.infoModel.refresh();
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
  static AppDrawerModel appDrawerModel = appDrawerModel;

  static Future<void> addActions(List<MyAction> actions) async {
    actionModel.addActions(actions);
  }

  //____________________________________________________________MyProviders
  /// A list for storing providers
  static List<MyProvider> providerList = [
    providerSettings,
    providerWallpaper,
    providerTheme,
    providerTime,
    providerWeather,
    providerApp,
    providerSystem,
    providerSmartSuggestions,
    providerNotifications,
  ];

  /// Map of provider names to their card keys
  /// Used for provider visibility toggles
  static Map<String, List<String>> providerCardKeys = {
    "Settings": ["SettingsCard", "ThemeMode", "CardOpacity", "WallpaperPicker", "APIKeys"],
    "Wallpaper": [], // No cards, only background image
    "Theme": [], // No cards, only theme data
    "Time": ["Time"],
    "Weather": ["Weather"],
    "App": ["AppStatistics", "RecentApp", "AllApps"], // Dynamic app cards handled separately
    "System": ["Logs"],
    "SmartSuggestions": ["SmartSuggestions"],
    "Notifications": ["Notifications"],
  };

  /// Get all card keys for a provider (including dynamic cards)
  static List<String> getProviderCardKeys(String providerName) {
    final staticKeys = providerCardKeys[providerName] ?? [];
    
    // Handle dynamic app cards
    if (providerName == "App") {
      final dynamicKeys = infoModel.infoKeys
          .where((key) => key.startsWith("app_"))
          .toList();
      return [...staticKeys, ...dynamicKeys];
    }
    
    return staticKeys;
  }

  //_______________________________________________________________________
}

class ActionModel with ChangeNotifier {
  Map<String, MyAction> _actionMap = <String, MyAction>{};

  String _searchQuery = "";
  Timer? _debounceTimer;

  String get searchQuery => _searchQuery;
  Map<String, MyAction> get actionMap => Map.unmodifiable(_actionMap);

  Future<void> addActions(List<MyAction> actions) async {
    for (MyAction action in actions) {
      addAction(action);
    }
  }

  Future<void> addAction(MyAction action) async {
    _actionMap[action.name] = action;
  }

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

  void updateSearchQuery(String input) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = input;
      notifyListeners();
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

class InfoModel with ChangeNotifier {
  final Map<String, Widget> _infoList = <String, Widget>{};
  final Map<String, String> _titleMap = <String, String>{};
  final List<CardConfig> _cardConfigs = <CardConfig>[];
  
  /// Animation state tracking for card appearance/disappearance
  final Set<String> _appearingWidgets = <String>{};
  final Set<String> _removingWidgets = <String>{};
  
  /// Animation state caching to avoid redundant notifyListeners during animations
  /// Tracks whether we're in a batch update mode to prevent multiple notifications
  bool _isBatchUpdate = false;
  
  /// Animation throttling: maximum concurrent animations (prevents >8 simultaneous animations)
  static const int maxConcurrentAnimations = 8;
  
  /// Queue for animations waiting to start (when limit is reached)
  final List<String> _animationQueue = <String>[];
  
  /// Currently active animations count
  int _activeAnimationsCount = 0;
  
  List<Widget> get infoList => _infoList.values.toList();
  List<CardConfig> get cardConfigs => List.unmodifiable(_cardConfigs);
  
  /// Get list of all info keys (for smart sorting)
  List<String> get infoKeys => _infoList.keys.toList();
  
  /// Check if a widget is currently appearing (animating in)
  bool isAppearing(String key) => _appearingWidgets.contains(key);
  
  /// Check if a widget is currently removing (animating out)
  bool isRemoving(String key) => _removingWidgets.contains(key);
  
  /// Get current active animations count
  int get activeAnimationsCount => _activeAnimationsCount;
  
  /// Get queued animations count
  int get queuedAnimationsCount => _animationQueue.length;

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
  
  /// Get smart-sorted list based on priority map (key -> priority score)
  /// Higher priority items appear first
  List<Widget> getSmartSortedInfoList(Map<String, double> priorities) {
    if (priorities.isEmpty) return infoList;
    
    // Create sorted entries based on priorities
    final sortedEntries = _infoList.entries.toList();
    
    // Sort by priority (higher first), then by original order for items without priority
    sortedEntries.sort((a, b) {
      final priorityA = priorities[a.key] ?? 0.0;
      final priorityB = priorities[b.key] ?? 0.0;
      
      // Higher priority comes first
      if (priorityA != priorityB) {
        return priorityB.compareTo(priorityA);
      }
      
      // Same priority: maintain original order (by insertion sequence)
      return 0;
    });
    
    return sortedEntries.map((e) => e.value).toList();
  }
  
  /// Get smart-sorted list with search query
  List<Widget> getSmartSortedFilteredList(String query, Map<String, double> priorities) {
    if (query.isEmpty) return getSmartSortedInfoList(priorities);
    
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return getSmartSortedInfoList(priorities);
    
    // Filter first, then sort
    final filteredEntries = _infoList.entries
        .where((e) =>
            e.key.toLowerCase().contains(lowerQuery) ||
            (_titleMap[e.key]?.toLowerCase().contains(lowerQuery) ?? false))
        .toList();
    
    // Sort filtered results by priority
    filteredEntries.sort((a, b) {
      final priorityA = priorities[a.key] ?? 0.0;
      final priorityB = priorities[b.key] ?? 0.0;
      return priorityB.compareTo(priorityA);
    });
    
    return filteredEntries.map((e) => e.value).toList();
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
  /// Backward compatible - converts to CardConfig and calls addCard
  void addInfoWidget(String key, Widget infoWidget, {String? title}) {
    final config = CardConfig(
      key: key,
      widget: infoWidget,
      type: CardType.INFO,
      size: CardSize.MEDIUM,
      layout: CardLayout.LIST,
      title: title,
    );
    addCard(config);
  }

  /// Add a CardConfig to the model
  void addCard(CardConfig config) {
    // Remove existing config with same key
    _cardConfigs.removeWhere((c) => c.key == config.key);
    _cardConfigs.add(config);
    // Also update legacy _infoList for backward compatibility
    _infoList.remove(config.key);
    _infoList[config.key] = config.widget;
    if (config.title != null) {
      _titleMap[config.key] = config.title!;
    }
    
    // Animation throttling: check if we can start animation immediately
    if (_activeAnimationsCount < maxConcurrentAnimations) {
      // Start animation immediately
      _startAppearAnimation(config.key);
    } else {
      // Queue animation for later
      _animationQueue.add(config.key);
      // Still notify listeners to show the card (without animation state)
      if (!_isBatchUpdate) {
        notifyListeners();
      }
    }
  }
  
  /// Start appear animation for a card (with throttling)
  void _startAppearAnimation(String key) {
    _appearingWidgets.add(key);
    _activeAnimationsCount++;
    
    if (!_isBatchUpdate) {
      notifyListeners();
    }
    
    // Schedule removal from appearing set after animation duration
    Future.delayed(AnimationHelper.defaultDuration, () {
      _appearingWidgets.remove(key);
      _activeAnimationsCount--;
      
      // Process queued animations if any
      _processQueuedAnimations();
      
      if (!_isBatchUpdate) {
        notifyListeners();
      }
    });
  }
  
  /// Process queued animations when slots become available
  void _processQueuedAnimations() {
    while (_animationQueue.isNotEmpty && _activeAnimationsCount < maxConcurrentAnimations) {
      final queuedKey = _animationQueue.removeAt(0);
      
      // Check if it's a remove animation (prefix 'remove_')
      if (queuedKey.startsWith('remove_')) {
        final key = queuedKey.substring(7); // Remove 'remove_' prefix
        _startRemoveAnimation(key);
      } else {
        // It's an appear animation
        _startAppearAnimation(queuedKey);
      }
    }
  }

  /// Add multiple CardConfigs to the model with single notifyListeners for performance
  /// Uses batch update mode to prevent redundant notifications during animations
  void addCardsBatch(List<CardConfig> configs) {
    _isBatchUpdate = true;
    
    for (final config in configs) {
      // Remove existing config with same key
      _cardConfigs.removeWhere((c) => c.key == config.key);
      _cardConfigs.add(config);
      // Also update legacy _infoList for backward compatibility
      _infoList.remove(config.key);
      _infoList[config.key] = config.widget;
      if (config.title != null) {
        _titleMap[config.key] = config.title!;
      }
      
      // Queue animations for throttling (batch mode doesn't start animations immediately)
      _animationQueue.add(config.key);
    }
    
    _isBatchUpdate = false;
    
    // Single notifyListeners after all cards are added
    notifyListeners();
    
    // Process queued animations with throttling
    _processQueuedAnimations();
  }

  /// Get cards filtered by layout
  List<CardConfig> getCardsByLayout(CardLayout layout) {
    return _cardConfigs.where((c) => c.layout == layout).toList();
  }

  /// Remove a card by key (with animation throttling)
  void removeCard(String key) {
    // Animation throttling: check if we can start animation immediately
    if (_activeAnimationsCount < maxConcurrentAnimations) {
      // Start remove animation immediately
      _startRemoveAnimation(key);
    } else {
      // Queue animation for later
      _animationQueue.add('remove_$key');
      // Still notify listeners to mark as removing (without animation state)
      _removingWidgets.add(key);
      if (!_isBatchUpdate) {
        notifyListeners();
      }
    }
  }
  
  /// Start remove animation for a card (with throttling)
  void _startRemoveAnimation(String key) {
    // Mark as removing for animation
    _removingWidgets.add(key);
    _activeAnimationsCount++;
    
    if (!_isBatchUpdate) {
      notifyListeners();
    }
    
    // Schedule actual removal after animation duration
    Future.delayed(AnimationHelper.defaultDuration, () {
      _cardConfigs.removeWhere((c) => c.key == key);
      _infoList.remove(key);
      _titleMap.remove(key);
      _removingWidgets.remove(key);
      _activeAnimationsCount--;
      
      // Process queued animations if any
      _processQueuedAnimations();
      
      if (!_isBatchUpdate) {
        notifyListeners();
      }
    });
  }

  void refresh() {
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

  void refresh() {
    notifyListeners();
  }
}

class SettingsModel with ChangeNotifier {
  SharedPreferences? _prefs;

  Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

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

  /// Set provider visibility (enabled/disabled)
  void setProviderEnabled(String provider, bool enabled) {
    saveValue('ProviderVisibility.$provider', enabled);
    
    // Handle card removal/re-addition
    if (!enabled) {
      // Remove provider cards
      final cardKeys = Global.getProviderCardKeys(provider);
      for (final key in cardKeys) {
        Global.infoModel.removeCard(key);
      }
      Global.loggerModel.info("Provider $provider disabled, removed ${cardKeys.length} cards", source: "Settings");
    } else {
      // Re-add provider cards by calling initActions
      final providerObj = Global.providerList.firstWhere(
        (p) => p.name == provider,
        orElse: () => throw Exception("Provider $provider not found"),
      );
      providerObj.initActions();
      Global.loggerModel.info("Provider $provider enabled, re-added cards", source: "Settings");
    }
  }

  /// Check if provider is enabled (default: true)
  bool isProviderEnabled(String provider) {
    final prefs = _prefs;
    if (prefs == null) return true;
    final key = 'ProviderVisibility.$provider';
    if (prefs.containsKey(key)) {
      return prefs.getBool(key) ?? true;
    }
    return true;
  }

  /// Set smart sorting enabled/disabled
  void setSmartSortingEnabled(bool enabled) {
    saveValue('SmartSortingEnabled', enabled);
  }

  /// Check if smart sorting is enabled (default: true)
  bool isSmartSortingEnabled() {
    final prefs = _prefs;
    if (prefs == null) return true;
    final key = 'SmartSortingEnabled';
    if (prefs.containsKey(key)) {
      return prefs.getBool(key) ?? true;
    }
    return true;
  }
}

class BackgroundImageModel with ChangeNotifier {
  // data
  ImageProvider _backgroundImage = NetworkImage(
      "https://picsum.photos/1920/1080");
  // getter or setter
  ImageProvider get backgroundImage {
    return _backgroundImage;
  }

  set backgroundImage(ImageProvider value) {
    _backgroundImage = value;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}
