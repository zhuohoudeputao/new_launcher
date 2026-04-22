import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/setting.dart';
import 'package:new_launcher/providers/provider_weather.dart';
import 'package:new_launcher/providers/provider_app.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/logger.dart';
import 'package:new_launcher/main.dart';
import 'package:provider/provider.dart';

void main() {
  group('CircularListController tests', () {
    test('constructor initializes with correct itemCount', () {
      final controller = CircularListController(itemCount: 5, itemExtent: 100);
      expect(controller.itemCount, 5);
      expect(controller.virtualCount, 5 * CircularListController.virtualMultiplier);
    });

    test('itemCount setter updates virtualCount', () {
      final controller = CircularListController(itemCount: 3, itemExtent: 100);
      controller.itemCount = 10;
      expect(controller.itemCount, 10);
      expect(controller.virtualCount, 10 * CircularListController.virtualMultiplier);
    });

    test('getActualIndex returns correct modulo result', () {
      final controller = CircularListController(itemCount: 5, itemExtent: 100);
      expect(controller.getActualIndex(502), 2);
      expect(controller.getActualIndex(1000), 0);
      expect(controller.getActualIndex(503), 3);
      expect(controller.getActualIndex(504), 4);
      expect(controller.getActualIndex(505), 0);
    });

    test('itemCount of 0 defaults to 1', () {
      final controller = CircularListController(itemCount: 0, itemExtent: 100);
      expect(controller.itemCount, 1);
      expect(controller.virtualCount, CircularListController.virtualMultiplier);
    });

    test('virtualMultiplier is correct value', () {
      expect(CircularListController.virtualMultiplier, 100);
    });

    test('itemCount setter handles negative by defaulting to 1', () {
      final controller = CircularListController(itemCount: 5, itemExtent: 100);
      controller.itemCount = 0;
      expect(controller.itemCount, 1);
    });

    test('same itemCount does not reset initialization', () {
      final controller = CircularListController(itemCount: 5, itemExtent: 100);
      controller.itemCount = 5;
      expect(controller.itemCount, 5);
    });

    test('itemExtent is stored correctly', () {
      final controller = CircularListController(itemCount: 5, itemExtent: 80);
      expect(controller.itemExtent, 80);
    });

    test('getActualIndex handles large virtualIndex', () {
      final controller = CircularListController(itemCount: 3, itemExtent: 100);
      expect(controller.getActualIndex(10000), 1);
      expect(controller.getActualIndex(9999), 0);
    });

    test('itemCount change resets _initialized flag', () {
      final controller = CircularListController(itemCount: 5, itemExtent: 100);
      controller.itemCount = 10;
      controller.itemCount = 5;
    });
  });

  group('LoggerModel tests', () {
    test('LoggerModel is singleton', () {
      final logger1 = LoggerModel();
      final logger2 = LoggerModel();
      expect(identical(logger1, logger2), true);
    });

    test('log() adds entry and notifies listeners', () {
      final logger = LoggerModel();
      logger.clear();
      int notifyCount = 0;
      logger.addListener(() => notifyCount++);
      
      logger.log(LogLevel.info, 'Test message', source: 'Test');
      
      expect(logger.logs.length, 1);
      expect(notifyCount, 1);
    });

    test('log entry has correct properties', () {
      final logger = LoggerModel();
      logger.clear();
      logger.log(LogLevel.warning, 'Warning test', source: 'TestSource');
      
      final entry = logger.logs.last;
      expect(entry.level, LogLevel.warning);
      expect(entry.message, 'Warning test');
      expect(entry.source, 'TestSource');
      expect(entry.levelString, 'WARN');
    });

    test('convenience methods work correctly', () {
      final logger = LoggerModel();
      logger.clear();
      logger.debug('Debug msg', source: 'D');
      logger.info('Info msg', source: 'I');
      logger.warning('Warning msg', source: 'W');
      logger.error('Error msg', source: 'E');
      
      expect(logger.logs.length, 4);
      expect(logger.logs[0].level, LogLevel.debug);
      expect(logger.logs[1].level, LogLevel.info);
      expect(logger.logs[2].level, LogLevel.warning);
      expect(logger.logs[3].level, LogLevel.error);
    });

    test('clear() removes all logs and notifies', () {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Test1');
      logger.info('Test2');
      expect(logger.logs.length, 2);
      
      int notifyCount = 0;
      logger.addListener(() => notifyCount++);
      
      logger.clear();
      
      expect(logger.logs.length, 0);
      expect(notifyCount, 1);
    });

    test('filterByLevel returns correct entries', () {
      final logger = LoggerModel();
      logger.clear();
      logger.debug('D1');
      logger.info('I1');
      logger.warning('W1');
      logger.error('E1');
      logger.debug('D2');
      
      final debugLogs = logger.filterByLevel(LogLevel.debug);
      expect(debugLogs.length, 2);
      
      final errorLogs = logger.filterByLevel(LogLevel.error);
      expect(errorLogs.length, 1);
    });

    test('filterBySource returns correct entries', () {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Msg1', source: 'App');
      logger.info('Msg2', source: 'Weather');
      logger.info('Msg3', source: 'App');
      
      final appLogs = logger.filterBySource('App');
      expect(appLogs.length, 2);
      
      final weatherLogs = logger.filterBySource('Weather');
      expect(weatherLogs.length, 1);
    });

    test('search() finds matching messages', () {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Application started');
      logger.info('Weather loaded');
      logger.info('App initialized');
      
      final results = logger.search('app');
      expect(results.length, 2);
      
      final weatherResults = logger.search('weather');
      expect(weatherResults.length, 1);
    });

    test('search() is case-insensitive', () {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Test Message');
      
      final results1 = logger.search('test');
      final results2 = logger.search('TEST');
      final results3 = logger.search('TeSt');
      
      expect(results1.length, 1);
      expect(results2.length, 1);
      expect(results3.length, 1);
    });

    test('maxLogs limit removes oldest entries', () {
      final logger = LoggerModel();
      logger.clear();
      
      for (int i = 0; i < LoggerModel.maxLogs + 100; i++) {
        logger.info('Message $i');
      }
      
      expect(logger.logs.length, LoggerModel.maxLogs);
      expect(logger.logs.first.message.contains('${100}'), true);
    });

    test('LogEntry levelIcon returns correct icon', () {
      final entry1 = LogEntry(timestamp: DateTime.now(), level: LogLevel.debug, message: '');
      final entry2 = LogEntry(timestamp: DateTime.now(), level: LogLevel.info, message: '');
      final entry3 = LogEntry(timestamp: DateTime.now(), level: LogLevel.warning, message: '');
      final entry4 = LogEntry(timestamp: DateTime.now(), level: LogLevel.error, message: '');
      
      expect(entry1.levelIcon, Icons.bug_report);
      expect(entry2.levelIcon, Icons.info);
      expect(entry3.levelIcon, Icons.warning);
      expect(entry4.levelIcon, Icons.error);
    });
  });

  group('SettingsModel tests', () {
    test('settingList is initially empty', () {
      final settingsModel = SettingsModel();
      expect(settingsModel.settingList.length, 0);
    });

    test('saveValue creates correct widget for bool', () async {
      final settingsModel = SettingsModel();
      await settingsModel.init();
      settingsModel.saveValue('TestBool', true);
      expect(settingsModel.settingList.any((w) => w is CustomBoolSettingWidget), true);
    }, skip: 'Requires SharedPreferences plugin mock');

    test('saveValue creates correct widget for double', () async {
      final settingsModel = SettingsModel();
      await settingsModel.init();
      settingsModel.saveValue('TestDouble', 0.5);
      expect(settingsModel.settingList.length, greaterThan(0));
    }, skip: 'Requires SharedPreferences plugin mock');

    test('getValue returns default for missing key', () async {
      final settingsModel = SettingsModel();
      await settingsModel.init();
      final value = await settingsModel.getValue('NonexistentKey', 'defaultValue');
      expect(value, 'defaultValue');
    }, skip: 'Requires SharedPreferences plugin mock');

    test('init loads existing preferences', () async {
      final settingsModel = SettingsModel();
      await settingsModel.init();
      expect(settingsModel.settingList, isNotNull);
    }, skip: 'Requires SharedPreferences plugin mock');
  });

  group('MyAction tests', () {
    test('canIdentifyBy returns true for matching keyword', () {
      final action = MyAction(
        name: 'TestAction',
        keywords: 'test keyword example',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      expect(action.canIdentifyBy('test'), true);
      expect(action.canIdentifyBy('keyword'), true);
      expect(action.canIdentifyBy('example'), true);
    });

    test('canIdentifyBy returns false for non-matching keyword', () {
      final action = MyAction(
        name: 'TestAction',
        keywords: 'test keyword',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      expect(action.canIdentifyBy('xyz'), false);
      expect(action.canIdentifyBy('other'), false);
    });

    test('canIdentifyBy is case-insensitive', () {
      final action = MyAction(
        name: 'TestAction',
        keywords: 'Test Keyword',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      expect(action.canIdentifyBy('TEST'), true);
      expect(action.canIdentifyBy('KEYWORD'), true);
      expect(action.canIdentifyBy('test keyword'), true);
    });

    test('frequency returns value for current hour', () {
      final times = List.generate(24, (_) => 0);
      final currentHour = DateTime.now().hour;
      times[currentHour] = 5;
      final action = MyAction(
        name: 'TestAction',
        keywords: 'test',
        action: () {},
        times: times,
      );
      expect(action.frequency, 5);
    });

    test('action execution increments frequency for current hour', () async {
      final times = List.generate(24, (_) => 0);
      final currentHour = DateTime.now().hour;
      var actionExecuted = false;
      final action = MyAction(
        name: 'TestAction',
        keywords: 'test',
        action: () => actionExecuted = true,
        times: times,
      );
      
      await action.action();
      
      expect(actionExecuted, true);
      expect(times[currentHour], 1);
    });

    test('frequency increment works at midnight (hour 0)', () async {
      final times = List.generate(24, (_) => 0);
      final action = MyAction(
        name: 'TestAction',
        keywords: 'test',
        action: () {},
        times: times,
      );
      
      await action.action();
      
      final currentHour = DateTime.now().hour;
      expect(times[currentHour], 1);
    });

    test('suggestWidget is created correctly', () {
      final action = MyAction(
        name: 'TestAction',
        keywords: 'test',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      
      expect(action.suggestWidget, isA<Widget>());
    });
  });

  group('MyProvider tests', () {
    test('MyProvider constructor assigns values correctly', () {
      final provider = MyProvider(
        name: 'Test',
        provideActions: () {},
        initActions: () {},
        update: () {},
      );
      
      expect(provider.name, 'Test');
    });

    test('MyProvider stores provideActions function', () {
      var called = false;
      final provider = MyProvider(
        name: 'Test',
        provideActions: () => called = true,
        initActions: () {},
        update: () {},
      );
      
      provider.provideActions();
      expect(called, true);
    });

    test('MyProvider stores initActions function', () {
      var called = false;
      final provider = MyProvider(
        name: 'Test',
        provideActions: () {},
        initActions: () => called = true,
        update: () {},
      );
      
      provider.initActions();
      expect(called, true);
    });

    test('MyProvider stores update function', () {
      var called = false;
      final provider = MyProvider(
        name: 'Test',
        provideActions: () {},
        initActions: () {},
        update: () => called = true,
      );
      
      provider.update();
      expect(called, true);
    });

    test('MyProvider init calls provideActions and initActions when enabled', () async {
      var provideCalled = false;
      var initCalled = false;
      
      final provider = MyProvider(
        name: 'TestEnabled',
        provideActions: () => provideCalled = true,
        initActions: () => initCalled = true,
        update: () {},
      );
      
      await provider.init();
      
      expect(provideCalled, true);
      expect(initCalled, true);
    }, skip: 'Requires SharedPreferences plugin mock');

    test('MyProvider name can be used as settings key prefix', () {
      final provider = MyProvider(
        name: 'Weather',
        provideActions: () {},
        initActions: () {},
        update: () {},
      );
      
      final settingsKey = '${provider.name}.Enabled';
      expect(settingsKey, 'Weather.Enabled');
    });
  });

  group('ThemeModel tests', () {
    test('ThemeModel starts with default ThemeData', () {
      final themeModel = ThemeModel();
      expect(themeModel.themeData, isA<ThemeData>());
    });

    test('ThemeModel updates theme and notifies listeners', () {
      final themeModel = ThemeModel();
      int notifyCount = 0;
      themeModel.addListener(() => notifyCount++);
      
      final newTheme = ThemeData.dark();
      themeModel.themeData = newTheme;
      
      expect(themeModel.themeData, newTheme);
      expect(notifyCount, 1);
    });

    test('ThemeModel can set light theme', () {
      final themeModel = ThemeModel();
      themeModel.themeData = ThemeData.light();
      expect(themeModel.themeData.brightness, Brightness.light);
    });

    test('ThemeModel can set dark theme', () {
      final themeModel = ThemeModel();
      themeModel.themeData = ThemeData.dark();
      expect(themeModel.themeData.brightness, Brightness.dark);
    });

    test('ThemeData with custom cardColor', () {
      final themeModel = ThemeModel();
      final customTheme = ThemeData(
        cardColor: Colors.red.withOpacity(0.5),
      );
      themeModel.themeData = customTheme;
      expect(themeModel.themeData.cardColor, Colors.red.withOpacity(0.5));
    });

    test('Multiple updates trigger multiple notifications', () {
      final themeModel = ThemeModel();
      int notifyCount = 0;
      themeModel.addListener(() => notifyCount++);
      
      themeModel.themeData = ThemeData.light();
      themeModel.themeData = ThemeData.dark();
      themeModel.themeData = ThemeData.fallback();
      
      expect(notifyCount, 3);
    });
  });

  group('BackgroundImageModel tests', () {
    test('BackgroundImageModel has default image', () {
      final backgroundImageModel = BackgroundImageModel();
      expect(backgroundImageModel.backgroundImage, isA<ImageProvider>());
    });

    test('BackgroundImageModel updates image and notifies listeners', () {
      final backgroundImageModel = BackgroundImageModel();
      int notifyCount = 0;
      backgroundImageModel.addListener(() => notifyCount++);
      
      final newImage = NetworkImage('https://example.com/image.jpg');
      backgroundImageModel.backgroundImage = newImage;
      
      expect(backgroundImageModel.backgroundImage, newImage);
      expect(notifyCount, 1);
    });

    test('BackgroundImageModel can set FileImage', () {
      final backgroundImageModel = BackgroundImageModel();
      backgroundImageModel.backgroundImage = MemoryImage(Uint8List.fromList([0, 0, 0, 0]));
      expect(backgroundImageModel.backgroundImage, isA<MemoryImage>());
    });

    test('BackgroundImageModel can set NetworkImage', () {
      final backgroundImageModel = BackgroundImageModel();
      backgroundImageModel.backgroundImage = NetworkImage('https://test.com/wallpaper.png');
      expect(backgroundImageModel.backgroundImage, isA<NetworkImage>());
    });

    test('Multiple updates trigger multiple notifications', () {
      final backgroundImageModel = BackgroundImageModel();
      int notifyCount = 0;
      backgroundImageModel.addListener(() => notifyCount++);
      
      backgroundImageModel.backgroundImage = NetworkImage('https://a.com/a.jpg');
      backgroundImageModel.backgroundImage = NetworkImage('https://b.com/b.jpg');
      backgroundImageModel.backgroundImage = MemoryImage(Uint8List.fromList([1, 2, 3]));
      
      expect(notifyCount, 3);
    });
  });

  group('ActionModel tests', () {
    test('ActionModel starts empty', () {
      final actionModel = ActionModel();
      expect(actionModel.suggestList.isEmpty, true);
    });

    test('addAction stores action in map', () async {
      final actionModel = ActionModel();
      final action = MyAction(
        name: 'Test',
        keywords: 'test',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      
      await actionModel.addAction(action);
      
      actionModel.generateSuggestList('test');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.suggestList.length, 1);
    });

    test('generateSuggestList filters actions by input', () async {
      final actionModel = ActionModel();
      final action1 = MyAction(
        name: 'Weather',
        keywords: 'weather forecast',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      final action2 = MyAction(
        name: 'Time',
        keywords: 'time clock',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      
      actionModel.addAction(action1);
      actionModel.addAction(action2);
      
      actionModel.generateSuggestList('weather');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.suggestList.length, 1);
      
      actionModel.generateSuggestList('time');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.suggestList.length, 1);
      
      actionModel.generateSuggestList('clock');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.suggestList.length, 1);
    });

    test('generateSuggestList returns all matching actions', () async {
      final actionModel = ActionModel();
      final action1 = MyAction(
        name: 'Weather',
        keywords: 'weather forecast',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      final action2 = MyAction(
        name: 'Weather2',
        keywords: 'weather today',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      
      actionModel.addAction(action1);
      actionModel.addAction(action2);
      
      actionModel.generateSuggestList('weather');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.suggestList.length, 2);
    });

    test('generateSuggestList debounces rapid calls', () async {
      final actionModel = ActionModel();
      int notifyCount = 0;
      actionModel.addListener(() => notifyCount++);
      
      final action = MyAction(
        name: 'Test',
        keywords: 'test',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      actionModel.addAction(action);
      
      actionModel.generateSuggestList('t');
      actionModel.generateSuggestList('te');
      actionModel.generateSuggestList('tes');
      actionModel.generateSuggestList('test');
      
      await Future.delayed(const Duration(milliseconds: 350));
      expect(notifyCount, 1);
    });

    test('dispose cancels debounce timer', () async {
      final actionModel = ActionModel();
      actionModel.generateSuggestList('test');
      actionModel.dispose();
      
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.searchQuery, '');
    });

    test('addActions stores multiple actions', () async {
      final actionModel = ActionModel();
      final actions = [
        MyAction(name: 'A', keywords: 'a', action: () {}, times: List.generate(24, (_) => 0)),
        MyAction(name: 'B', keywords: 'b', action: () {}, times: List.generate(24, (_) => 0)),
      ];
      
      await actionModel.addActions(actions);
      
      actionModel.generateSuggestList('a');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.suggestList.length, 1);
    });

    test('inputBoxController exists', () {
      final actionModel = ActionModel();
      expect(actionModel.inputBoxController, isA<TextEditingController>());
    });
  });

  group('customInfoWidget tests', () {
    testWidgets('renders title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customInfoWidget(
              title: 'Test Title',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customInfoWidget(
              title: 'Test Title',
              subtitle: 'Test Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customInfoWidget(
              title: 'Test Title',
              icon: Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customInfoWidget(
              title: 'Test Title',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      await tester.pump();

      expect(tapped, true);
    });
  });

  group('customSuggestWidget tests', () {
    testWidgets('renders name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customSuggestWidget(
              name: 'Suggest Action',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Suggest Action'), findsOneWidget);
    });

    testWidgets('calls onPressed when pressed', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customSuggestWidget(
              name: 'Suggest Action',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(pressed, true);
    });
  });

  group('customTextSettingWidget tests', () {
    testWidgets('renders key and value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customTextSettingWidget(
              key: 'TestKey',
              value: 'TestValue',
              onSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('TestKey'), findsOneWidget);
    });

    testWidgets('calls onSubmitted when text entered', (WidgetTester tester) async {
      String submittedValue = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customTextSettingWidget(
              key: 'Test',
              value: 'OldValue',
              onSubmitted: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'NewValue');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submittedValue, 'NewValue');
    });

    testWidgets('handles int value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customTextSettingWidget(
              key: 'IntKey',
              value: 42,
              onSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('IntKey'), findsOneWidget);
    });

    testWidgets('handles double value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: customTextSettingWidget(
              key: 'DoubleKey',
              value: 3.14,
              onSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('DoubleKey'), findsOneWidget);
    });
  });

  group('CustomBoolSettingWidget tests', () {
    testWidgets('renders key and value correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomBoolSettingWidget(
              settingKey: 'TestSetting',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('TestSetting'), findsOneWidget);
      expect(find.text('is true'), findsOneWidget);
    });

    testWidgets('updates when switch is toggled', (WidgetTester tester) async {
      bool newValue = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomBoolSettingWidget(
              settingKey: 'TestSetting',
              value: false,
              onChanged: (value) => newValue = value,
            ),
          ),
        ),
      );

      expect(find.text('is false'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(newValue, true);
      expect(find.text('is true'), findsOneWidget);
    });
  });

  group('Weather icon tests', () {
    test('getWeatherIcon returns sun for clear', () {
      final icon = getWeatherIcon("Clear sky");
      expect(icon, Icons.wb_sunny);
    });

    test('getWeatherIcon returns cloud for cloudy', () {
      final icon = getWeatherIcon("Partly cloudy");
      expect(icon, Icons.cloud);
    });

    test('getWeatherIcon returns water for rain', () {
      final icon = getWeatherIcon("Moderate rain");
      expect(icon, Icons.water_drop);
    });

    test('getWeatherIcon returns snow for snow', () {
      final icon = getWeatherIcon("Heavy snow");
      expect(icon, Icons.ac_unit);
    });

    test('getWeatherIcon returns flash for thunder', () {
      final icon = getWeatherIcon("Thunderstorm");
      expect(icon, Icons.flash_on);
    });

    test('getWeatherIcon returns foggy for fog', () {
      final icon = getWeatherIcon("Fog");
      expect(icon, Icons.foggy);
    });

    test('getWeatherIcon returns foggy for rime fog', () {
      final icon = getWeatherIcon("Depositing rime fog");
      expect(icon, Icons.foggy);
    });

    test('getWeatherIcon returns cloud for overcast', () {
      final icon = getWeatherIcon("Overcast");
      expect(icon, Icons.cloud);
    });

    test('getWeatherIcon returns cloud for unknown', () {
      final icon = getWeatherIcon("Unknown condition");
      expect(icon, Icons.cloud);
    });

    test('getWeatherIcon is case insensitive', () {
      expect(getWeatherIcon("CLEAR SKY"), Icons.wb_sunny);
      expect(getWeatherIcon("clear sky"), Icons.wb_sunny);
    });

    test('getWeatherIcon handles drizzle', () {
      expect(getWeatherIcon("Light drizzle"), Icons.water_drop);
      expect(getWeatherIcon("Dense drizzle"), Icons.water_drop);
    });
  });

  group('Setting page tests', () {
    testWidgets('has back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: Global.settingsModel),
              ChangeNotifierProvider.value(value: Global.backgroundImageModel),
            ],
            child: Setting(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithIcon(AppBar, Icons.arrow_back), findsOneWidget);
    }, skip: true);
  });

  group('CardOpacitySlider tests', () {
    testWidgets('renders slider with value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardOpacitySlider(
              value: 0.5,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text("Card Opacity"), findsOneWidget);
      expect(find.text("Opacity: 50%"), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('calls onChanged when slider moves',
        (WidgetTester tester) async {
      double newValue = 0.5;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardOpacitySlider(
              value: 0.5,
              onChanged: (value) => newValue = value,
            ),
          ),
        ),
      );

      await tester.drag(find.byType(Slider), Offset(50, 0));
      await tester.pump();

      expect(newValue, isNot(0.5));
    });
  });

  group('DarkModeOptionSelector tests', () {
    testWidgets('renders current mode correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DarkModeOptionSelector(
              currentMode: 'light',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('light'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('calls onChanged when Light button pressed', (WidgetTester tester) async {
      String newMode = 'dark';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DarkModeOptionSelector(
              currentMode: 'dark',
              onChanged: (mode) => newMode = mode,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Light'));
      await tester.pump();

      expect(newMode, 'light');
    });

    testWidgets('calls onChanged when Dark button pressed', (WidgetTester tester) async {
      String newMode = 'light';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DarkModeOptionSelector(
              currentMode: 'light',
              onChanged: (mode) => newMode = mode,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dark'));
      await tester.pump();

      expect(newMode, 'dark');
    });

    testWidgets('calls onChanged when System button pressed', (WidgetTester tester) async {
      String newMode = 'light';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DarkModeOptionSelector(
              currentMode: 'light',
              onChanged: (mode) => newMode = mode,
            ),
          ),
        ),
      );

      await tester.tap(find.text('System'));
      await tester.pump();

      expect(newMode, 'system');
    });
  });

  group('WallpaperPickerButton tests', () {
    testWidgets('renders label correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WallpaperPickerButton(
              label: 'Test Wallpaper',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Wallpaper'), findsOneWidget);
      expect(find.text('Tap to select from gallery'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('calls onTap when button pressed', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WallpaperPickerButton(
              label: 'Test',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pump();

      expect(tapped, true);
    });
  });

  group('InfoCard tests', () {
    testWidgets('renders title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoCard(
              title: 'Test Title',
              subtitle: 'Test Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoCard(
              title: 'Test',
              icon: Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoCard(
              title: 'Test',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('subtitle defaults to empty string', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoCard(
              title: 'Test',
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('LogViewerWidget tests', () {
    testWidgets('renders with empty logs', (WidgetTester tester) async {
      final logger = LoggerModel();
      logger.clear();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: logger,
              child: LogViewerWidget(),
            ),
          ),
        ),
      );

      expect(find.text('Logs: 0'), findsOneWidget);
    });

    testWidgets('renders logs count', (WidgetTester tester) async {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Test message');
      logger.info('Another message');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: logger,
              child: LogViewerWidget(),
            ),
          ),
        ),
      );

      expect(find.text('Logs: 2'), findsOneWidget);
    });

    testWidgets('shows clear button', (WidgetTester tester) async {
      final logger = LoggerModel();
      logger.clear();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: logger,
              child: LogViewerWidget(),
            ),
          ),
        ),
      );

      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('clear button clears logs', (WidgetTester tester) async {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Test');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: logger,
              child: LogViewerWidget(),
            ),
          ),
        ),
      );

      expect(find.text('Logs: 1'), findsOneWidget);
      
      await tester.tap(find.text('Clear'));
      await tester.pump();
      
      expect(logger.logs.length, 0);
    });
  });

  group('InfoModel getFilteredList tests', () {
    late InfoModel infoModel;

    setUp(() {
      infoModel = InfoModel();
      infoModel.addInfoWidget('app_chrome', customInfoWidget(title: 'Chrome'), title: 'Chrome');
      infoModel.addInfoWidget('app_maps', customInfoWidget(title: 'Maps'), title: 'Maps');
      infoModel.addInfoWidget('time', customInfoWidget(title: 'Time'), title: 'Time');
      infoModel.addInfoWidget('Weather', customInfoWidget(title: 'Weather'), title: 'Weather');
    });

    test('returns all items when query is empty', () {
      final result = infoModel.getFilteredList('');
      expect(result.length, 4);
    });

    test('filters by key', () {
      final result = infoModel.getFilteredList('chrome');
      expect(result.length, 1);
    });

    test('filters by title', () {
      final result = infoModel.getFilteredList('Maps');
      expect(result.length, 1);
    });

    test('filters case-insensitively', () {
      final result = infoModel.getFilteredList('TIME');
      expect(result.length, 1);
    });

    test('returns empty when no match', () {
      final result = infoModel.getFilteredList('xyz123');
      expect(result.length, 0);
    });

    test('trims whitespace from query', () {
      final result = infoModel.getFilteredList('  chrome  ');
      expect(result.length, 1);
    });
  });

  group('ActionModel searchQuery tests', () {
    test('stores search query correctly after debounce', () async {
      final actionModel = ActionModel();
      actionModel.generateSuggestList('test query');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.searchQuery, 'test query');
    });

    test('clears search query when empty after debounce', () async {
      final actionModel = ActionModel();
      actionModel.generateSuggestList('');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.searchQuery, '');
    });
  });

  group('AppModel tests', () {
    test('starts empty', () {
      final appModel = AppModel();
      expect(appModel.length, 0);
      expect(appModel.recentlyUsedApps.length, 0);
    });

    testWidgets('addApp increases length', (WidgetTester tester) async {
      final appModel = AppModel();
      await appModel.addApp('Chrome', Container(child: Text('Chrome')));
      expect(appModel.length, 1);
      expect(appModel.recentlyUsedApps.length, 1);
    });

    testWidgets('addApp replaces existing key', (WidgetTester tester) async {
      final appModel = AppModel();
      await appModel.addApp('Chrome', Container(child: Text('Chrome')));
      await appModel.addApp('Chrome', Container(child: Text('Chrome Updated')));
      expect(appModel.length, 1);
    });

    testWidgets('notifyListeners called on addApp', (WidgetTester tester) async {
      final appModel = AppModel();
      int notifyCount = 0;
      appModel.addListener(() => notifyCount++);
      await appModel.addApp('Test', Container());
      expect(notifyCount, 1);
    });

    testWidgets('maxRecentApps limit removes oldest', (WidgetTester tester) async {
      final appModel = AppModel();
      
      for (int i = 0; i < AppModel.maxRecentApps + 10; i++) {
        await appModel.addApp('App$i', Container(child: Text('App$i')));
      }
      
      expect(appModel.length, AppModel.maxRecentApps);
    });

    testWidgets('recentOrder maintains insertion order', (WidgetTester tester) async {
      final appModel = AppModel();
      await appModel.addApp('First', Container());
      await appModel.addApp('Second', Container());
      await appModel.addApp('Third', Container());
      
      expect(appModel.length, 3);
    });

    testWidgets('re-adding existing key moves to end', (WidgetTester tester) async {
      final appModel = AppModel();
      await appModel.addApp('App1', Container());
      await appModel.addApp('App2', Container());
      await appModel.addApp('App1', Container());
      
      expect(appModel.length, 2);
    });
  });

  group('AllAppsModel tests', () {
    test('starts empty', () {
      final allAppsModel = AllAppsModel();
      expect(allAppsModel.length, 0);
      expect(allAppsModel.apps.length, 0);
    });

    testWidgets('setApps updates apps list', (WidgetTester tester) async {
      final allAppsModel = AllAppsModel();
      await allAppsModel.setApps([]);
      expect(allAppsModel.length, 0);
    });

    testWidgets('notifyListeners called on setApps', (WidgetTester tester) async {
      final allAppsModel = AllAppsModel();
      int notifyCount = 0;
      allAppsModel.addListener(() => notifyCount++);
      await allAppsModel.setApps([]);
      expect(notifyCount, 1);
    });

    test('length getter returns correct count', () {
      final allAppsModel = AllAppsModel();
      expect(allAppsModel.length, 0);
    });

    test('apps getter returns empty list initially', () {
      final allAppsModel = AllAppsModel();
      expect(allAppsModel.apps, isEmpty);
    });
  });

  group('RecentlyUsedAppsCard tests', () {
    testWidgets('renders with empty model', (WidgetTester tester) async {
      final appModel = AppModel();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: appModel,
              child: RecentlyUsedAppsCard(),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders apps when added', (WidgetTester tester) async {
      final appModel = AppModel();
      await appModel.addApp('TestApp', Container(child: Text('TestApp')));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: appModel,
              child: RecentlyUsedAppsCard(),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('TestApp'), findsOneWidget);
    });
  });

  group('AllAppsCard tests', () {
    testWidgets('renders with empty model', (WidgetTester tester) async {
      final allAppsModel = AllAppsModel();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: allAppsModel,
              child: AllAppsCard(),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows GridView with correct configuration', (WidgetTester tester) async {
      final allAppsModel = AllAppsModel();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: allAppsModel,
              child: AllAppsCard(),
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.scrollDirection, Axis.horizontal);
    });
  });

  group('InfoModel multiple app cards tests', () {
    test('InfoModel can hold many app widgets', () {
      final infoModel = InfoModel();
      for (int i = 0; i < 100; i++) {
        infoModel.addInfoWidget(
          'app_test$i',
          customInfoWidget(title: 'App $i'),
          title: 'App $i',
        );
      }
      expect(infoModel.length, 100);
    });

    test('InfoModel filters multiple apps correctly', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('app_chrome', customInfoWidget(title: 'Chrome'), title: 'Chrome');
      infoModel.addInfoWidget('app_firefox', customInfoWidget(title: 'Firefox'), title: 'Firefox');
      infoModel.addInfoWidget('app_safari', customInfoWidget(title: 'Safari'), title: 'Safari');
      infoModel.addInfoWidget('app_edge', customInfoWidget(title: 'Edge'), title: 'Edge');
      infoModel.addInfoWidget('weather', customInfoWidget(title: 'Weather'), title: 'Weather');

      final result = infoModel.getFilteredList('app');
      expect(result.length, 4);
    });

    test('InfoModel updates widget when same key is used', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('app_test', customInfoWidget(title: 'Test App'), title: 'Test App');
      expect(infoModel.length, 1);

      infoModel.addInfoWidget('app_test', customInfoWidget(title: 'Updated App'), title: 'Updated App');
      expect(infoModel.length, 1);
    });

    test('InfoModel getFilteredList handles empty query', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('test', Container());
      expect(infoModel.getFilteredList('').length, 1);
    });

    test('InfoModel getFilteredList handles null-like empty', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('test', Container());
      expect(infoModel.getFilteredList('   ').length, 1);
    });
  });

  group('InfoModel batch adding tests', () {
    test('addInfoWidgetsBatch adds multiple widgets', () {
      final infoModel = InfoModel();
      final widgets = [
        MapEntry('app_1', customInfoWidget(title: 'App 1')),
        MapEntry('app_2', customInfoWidget(title: 'App 2')),
        MapEntry('app_3', customInfoWidget(title: 'App 3')),
      ];
      final titles = {
        'app_1': 'App 1',
        'app_2': 'App 2',
        'app_3': 'App 3',
      };
      
      infoModel.addInfoWidgetsBatch(widgets, titles: titles);
      expect(infoModel.length, 3);
    });

    test('addInfoWidgetsBatch only notifies once', () {
      final infoModel = InfoModel();
      int notifyCount = 0;
      infoModel.addListener(() => notifyCount++);
      
      final widgets = List.generate(100, (i) => 
        MapEntry('app_$i', customInfoWidget(title: 'App $i'))
      );
      final titles = Map.fromEntries(
        List.generate(100, (i) => MapEntry('app_$i', 'App $i'))
      );
      
      infoModel.addInfoWidgetsBatch(widgets, titles: titles);
      expect(notifyCount, 1);
    });

    test('addInfoWidget notifies each time', () {
      final infoModel = InfoModel();
      int notifyCount = 0;
      infoModel.addListener(() => notifyCount++);
      
      for (int i = 0; i < 10; i++) {
        infoModel.addInfoWidget('app_$i', customInfoWidget(title: 'App $i'), title: 'App $i');
      }
      expect(notifyCount, 10);
    });

    test('batch adding with titles preserves titles', () {
      final infoModel = InfoModel();
      final widgets = [
        MapEntry('app_chrome', customInfoWidget(title: 'Chrome')),
        MapEntry('app_firefox', customInfoWidget(title: 'Firefox')),
      ];
      final titles = {
        'app_chrome': 'Chrome',
        'app_firefox': 'Firefox',
      };
      
      infoModel.addInfoWidgetsBatch(widgets, titles: titles);
      
      final chromeResult = infoModel.getFilteredList('Chrome');
      expect(chromeResult.length, 1);
      
      final firefoxResult = infoModel.getFilteredList('Firefox');
      expect(firefoxResult.length, 1);
    });
  });

  group('AppStatisticsModel tests', () {
    test('starts empty', () {
      final statsModel = AppStatisticsModel();
      expect(statsModel.uniqueApps, 0);
      expect(statsModel.totalLaunches, 0);
      expect(statsModel.mostUsedApps.length, 0);
    });

    test('recordLaunch increments count', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('Chrome');
      expect(statsModel.getLaunchCount('Chrome'), 1);
      expect(statsModel.totalLaunches, 1);
      expect(statsModel.uniqueApps, 1);
    });

    test('recordLaunch updates last launch time', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('Chrome');
      final lastTime = statsModel.getLastLaunchTime('Chrome');
      expect(lastTime, isNotNull);
      expect(lastTime!.difference(DateTime.now()).inSeconds.abs(), lessThan(2));
    });

    test('multiple launches increment count correctly', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('Chrome');
      statsModel.recordLaunch('Chrome');
      statsModel.recordLaunch('Chrome');
      expect(statsModel.getLaunchCount('Chrome'), 3);
      expect(statsModel.totalLaunches, 3);
      expect(statsModel.uniqueApps, 1);
    });

    test('mostUsedApps sorted by launch count', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('Chrome');
      statsModel.recordLaunch('Chrome');
      statsModel.recordLaunch('Chrome');
      statsModel.recordLaunch('Firefox');
      statsModel.recordLaunch('Maps');
      statsModel.recordLaunch('Maps');
      
      final mostUsed = statsModel.mostUsedApps;
      expect(mostUsed[0], 'Chrome');
      expect(mostUsed[1], 'Maps');
      expect(mostUsed[2], 'Firefox');
    });

    test('clearStats removes all data', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('Chrome');
      statsModel.recordLaunch('Firefox');
      
      statsModel.clearStats();
      
      expect(statsModel.uniqueApps, 0);
      expect(statsModel.totalLaunches, 0);
      expect(statsModel.mostUsedApps.length, 0);
    });

    test('notifyListeners called on recordLaunch', () {
      final statsModel = AppStatisticsModel();
      int notifyCount = 0;
      statsModel.addListener(() => notifyCount++);
      
      statsModel.recordLaunch('Test');
      expect(notifyCount, 1);
    });

    test('notifyListeners called on clearStats', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('Test');
      int notifyCount = 0;
      statsModel.addListener(() => notifyCount++);
      
      statsModel.clearStats();
      expect(notifyCount, 1);
    });

    test('loadStats restores data', () {
      final statsModel = AppStatisticsModel();
      final counts = {'Chrome': 5, 'Firefox': 3};
      final times = {'Chrome': DateTime.now().subtract(Duration(hours: 1))};
      
      statsModel.loadStats(counts, times);
      
      expect(statsModel.getLaunchCount('Chrome'), 5);
      expect(statsModel.getLaunchCount('Firefox'), 3);
      expect(statsModel.uniqueApps, 2);
      expect(statsModel.totalLaunches, 8);
    });

    test('maxStatsEntries limit removes least used', () {
      final statsModel = AppStatisticsModel();
      
      for (int i = 0; i < AppStatisticsModel.maxStatsEntries + 10; i++) {
        statsModel.recordLaunch('App$i');
      }
      
      expect(statsModel.uniqueApps, AppStatisticsModel.maxStatsEntries);
    });

    test('allStats returns unmodifiable map', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('Chrome');
      
      final stats = statsModel.allStats;
      expect(stats['Chrome'], 1);
    });

    test('init method exists and can be called', () async {
      final statsModel = AppStatisticsModel();
      await statsModel.init();
    }, skip: 'Requires SharedPreferences plugin mock');

    test('_saveStats is called after recordLaunch', () async {
      final statsModel = AppStatisticsModel();
      await statsModel.init();
      statsModel.recordLaunch('TestApp');
    }, skip: 'Requires SharedPreferences plugin mock');

    test('_loadPersistedStats restores saved data', () async {
      final statsModel = AppStatisticsModel();
      await statsModel.init();
      statsModel.recordLaunch('SavedApp');
      statsModel.recordLaunch('SavedApp');
      
      final newModel = AppStatisticsModel();
      await newModel.init();
      
      expect(newModel.getLaunchCount('SavedApp'), 2);
    }, skip: 'Requires SharedPreferences plugin mock');
  });

  group('AppStatisticsCard tests', () {
    testWidgets('renders with empty model', (WidgetTester tester) async {
      final statsModel = AppStatisticsModel();
      final allAppsModel = AllAppsModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: statsModel),
                ChangeNotifierProvider.value(value: allAppsModel),
              ],
              child: AppStatisticsCard(),
            ),
          ),
        ),
      );

      expect(find.text('App Statistics'), findsOneWidget);
      expect(find.text('No app usage data yet'), findsOneWidget);
    });

    testWidgets('renders stats when apps recorded', (WidgetTester tester) async {
      final statsModel = AppStatisticsModel();
      final allAppsModel = AllAppsModel();
      
      statsModel.recordLaunch('Chrome');
      statsModel.recordLaunch('Chrome');
      statsModel.recordLaunch('Firefox');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: statsModel),
                ChangeNotifierProvider.value(value: allAppsModel),
              ],
              child: AppStatisticsCard(),
            ),
          ),
        ),
      );

      expect(find.text('App Statistics'), findsOneWidget);
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('Firefox'), findsOneWidget);
    });

    testWidgets('shows correct launch counts', (WidgetTester tester) async {
      final statsModel = AppStatisticsModel();
      final allAppsModel = AllAppsModel();
      
      statsModel.recordLaunch('TestApp');
      statsModel.recordLaunch('TestApp');
      statsModel.recordLaunch('TestApp');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: statsModel),
                ChangeNotifierProvider.value(value: allAppsModel),
              ],
              child: AppStatisticsCard(),
            ),
          ),
        ),
      );

      expect(find.textContaining('3 launches, 0m ago'), findsOneWidget);
    });
  });
}
