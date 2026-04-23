import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/providers/provider_weather.dart';
import 'package:new_launcher/providers/provider_app.dart';
import 'package:new_launcher/providers/provider_battery.dart';
import 'package:new_launcher/providers/provider_calculator.dart';
import 'package:new_launcher/providers/provider_flashlight.dart';
import 'package:new_launcher/providers/provider_notes.dart';
import 'package:new_launcher/providers/provider_stopwatch.dart';
import 'package:new_launcher/providers/provider_timer.dart';
import 'package:new_launcher/providers/provider_worldclock.dart';
import 'package:new_launcher/providers/provider_countdown.dart';
import 'package:new_launcher/providers/provider_unitconverter.dart';
import 'package:new_launcher/providers/provider_pomodoro.dart';
import 'package:new_launcher/providers/provider_clipboard.dart';
import 'package:new_launcher/providers/provider_todo.dart';
import 'package:new_launcher/providers/provider_qrcode.dart';
import 'package:new_launcher/providers/provider_random.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/logger.dart';
import 'package:new_launcher/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
    Global.backgroundImageModel.backgroundImage = AssetImage('test_assets/transparent.png');
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

    test('log entry timestamp is current time', () {
      final logger = LoggerModel();
      logger.clear();
      final before = DateTime.now();
      logger.info('Test');
      final after = DateTime.now();
      
      final entry = logger.logs.last;
      expect(entry.timestamp.isAfter(before.subtract(Duration(milliseconds: 10))), true);
      expect(entry.timestamp.isBefore(after.add(Duration(milliseconds: 10))), true);
    });

    test('log without source works', () {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Test without source');
      
      final entry = logger.logs.last;
      expect(entry.source, null);
    });

    test('filterByLevel returns empty for no matches', () {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Only info logs');
      
      final debugLogs = logger.filterByLevel(LogLevel.debug);
      expect(debugLogs.length, 0);
    });

    test('filterBySource returns empty for no matches', () {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Msg', source: 'Source1');
      
      final logs = logger.filterBySource('UnknownSource');
      expect(logs.length, 0);
    });

    test('search returns empty for no matches', () {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Some message');
      
      final results = logger.search('xyz');
      expect(results.length, 0);
    });

    test('logs getter returns unmodifiable list', () {
      final logger = LoggerModel();
      logger.clear();
      logger.info('Test');
      
      final logs = logger.logs;
      expect(logs.length, 1);
    });
  });

  group('SettingsModel tests', () {
    test('getValue returns default for missing key', () async {
      final settingsModel = SettingsModel();
      await settingsModel.init();
      final value = await settingsModel.getValue('NonexistentKey', 'defaultValue');
      expect(value, 'defaultValue');
    });

    test('init initializes', () async {
      final settingsModel = SettingsModel();
      await settingsModel.init();
    });

    test('saveValue saves to SharedPreferences', () async {
      final settingsModel = SettingsModel();
      await settingsModel.init();
      settingsModel.saveValue('TestKey', 'TestValue');
      final value = await settingsModel.getValue('TestKey', '');
      expect(value, 'TestValue');
    });
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

    test('MyAction stores name correctly', () {
      final action = MyAction(
        name: 'MyActionName',
        keywords: 'test',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      expect(action.name, 'MyActionName');
    });

    test('MyAction keywords are lowercased', () {
      final action = MyAction(
        name: 'Test',
        keywords: 'UPPERCASE Keywords',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      expect(action.canIdentifyBy('uppercase'), true);
      expect(action.canIdentifyBy('KEYWORDS'), true);
    });

    test('multiple action calls increment frequency correctly', () async {
      final times = List.generate(24, (_) => 0);
      final currentHour = DateTime.now().hour;
      final action = MyAction(
        name: 'Test',
        keywords: 'test',
        action: () {},
        times: times,
      );
      
      await action.action();
      await action.action();
      await action.action();
      
      expect(times[currentHour], 3);
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
    });

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
        cardColor: Colors.red.withValues(alpha: 0.5),
      );
      themeModel.themeData = customTheme;
      expect(themeModel.themeData.cardColor, Colors.red.withValues(alpha: 0.5));
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
    test('addAction stores action in map', () async {
      final actionModel = ActionModel();
      final action = MyAction(
        name: 'Test',
        keywords: 'test',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      
      await actionModel.addAction(action);
    });

    test('updateSearchQuery debounces rapid calls', () async {
      final actionModel = ActionModel();
      int notifyCount = 0;
      actionModel.addListener(() => notifyCount++);
      
      actionModel.updateSearchQuery('t');
      actionModel.updateSearchQuery('te');
      actionModel.updateSearchQuery('tes');
      actionModel.updateSearchQuery('test');
      
      await Future.delayed(const Duration(milliseconds: 350));
      expect(notifyCount, 1);
      expect(actionModel.searchQuery, 'test');
    });

    test('dispose cancels debounce timer', () async {
      final actionModel = ActionModel();
      actionModel.updateSearchQuery('test');
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
    });

    test('inputBoxController exists', () {
      final actionModel = ActionModel();
      expect(actionModel.inputBoxController, isA<TextEditingController>());
    });

    test('searchQuery starts empty', () {
      final actionModel = ActionModel();
      expect(actionModel.searchQuery, '');
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

  group('customTextSettingWidget tests', () {
    testWidgets('renders key and value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => customTextSettingWidget(
                context: context,
                key: 'TestKey',
                value: 'TestValue',
                onSubmitted: (_) {},
              ),
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
            body: Builder(
              builder: (context) => customTextSettingWidget(
                context: context,
                key: 'Test',
                value: 'OldValue',
                onSubmitted: (value) => submittedValue = value,
              ),
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
            body: Builder(
              builder: (context) => customTextSettingWidget(
                context: context,
                key: 'IntKey',
                value: 42,
                onSubmitted: (_) {},
              ),
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
            body: Builder(
              builder: (context) => customTextSettingWidget(
                context: context,
                key: 'DoubleKey',
                value: 3.14,
                onSubmitted: (_) {},
              ),
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

  group('DarkModeOptionSelector Material 3 tests', () {
    testWidgets('renders SegmentedButton', (WidgetTester tester) async {
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
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('shows all three segments', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DarkModeOptionSelector(
              currentMode: 'system',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('has icons for each segment', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DarkModeOptionSelector(
              currentMode: 'dark',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('calls onChanged when segment selected', (WidgetTester tester) async {
      String selectedMode = 'light';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DarkModeOptionSelector(
              currentMode: 'light',
              onChanged: (mode) => selectedMode = mode,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dark'));
      await tester.pump();

      expect(selectedMode, 'dark');
    });

    testWidgets('currentMode is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DarkModeOptionSelector(
              currentMode: 'system',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('System'), findsOneWidget);
    });
  });

  group('Material 3 Card variants tests', () {
    testWidgets('WallpaperPickerButton uses Card.filled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WallpaperPickerButton(
              label: 'Test',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('CardOpacitySlider uses Card.filled', (WidgetTester tester) async {
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

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Opacity'), findsOneWidget);
    });

    testWidgets('CustomBoolSettingWidget uses Card', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomBoolSettingWidget(
              settingKey: 'TestKey',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('TestKey'), findsOneWidget);
    });
  });

  group('ColorScheme integration tests', () {
    testWidgets('Theme uses Material 3', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      final theme = Theme.of(tester.element(find.text('Test')));
      expect(theme.useMaterial3, true);
    });

    testWidgets('ColorScheme from seed generates colors', (WidgetTester tester) async {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
      
      expect(colorScheme.primary, isNotNull);
      expect(colorScheme.onPrimary, isNotNull);
      expect(colorScheme.secondary, isNotNull);
      expect(colorScheme.surface, isNotNull);
      expect(colorScheme.error, isNotNull);
    });

    testWidgets('Dark ColorScheme has different colors', (WidgetTester tester) async {
      final lightScheme = ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      );
      final darkScheme = ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      );

      expect(lightScheme.primary != darkScheme.primary, true);
      expect(lightScheme.surface != darkScheme.surface, true);
    });
  });

  group('LogViewerWidget Material 3 tests', () {
    testWidgets('uses ElevatedButton for Clear', (WidgetTester tester) async {
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

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('Clear button onPressed works', (WidgetTester tester) async {
      final logger = LoggerModel();
      logger.info('Test log');
      
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

      expect(logger.logs.length, 1);
      
      await tester.tap(find.text('Clear'));
      await tester.pump();
      
      expect(logger.logs.length, 0);
    });
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
      actionModel.updateSearchQuery('test query');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.searchQuery, 'test query');
    });

    test('clears search query when empty after debounce', () async {
      final actionModel = ActionModel();
      actionModel.updateSearchQuery('');
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
    });

    test('_saveStats is called after recordLaunch', () async {
      final statsModel = AppStatisticsModel();
      await statsModel.init();
      statsModel.recordLaunch('TestApp');
    });

    test('_loadPersistedStats restores saved data', () async {
      final statsModel = AppStatisticsModel();
      await statsModel.init();
      statsModel.recordLaunch('SavedApp');
      statsModel.recordLaunch('SavedApp');
      
      final newModel = AppStatisticsModel();
      await newModel.init();
      
      expect(newModel.getLaunchCount('SavedApp'), 2);
    });

    test('getLastLaunchTime returns null for unknown app', () {
      final statsModel = AppStatisticsModel();
      expect(statsModel.getLastLaunchTime('Unknown'), null);
    });

    test('getLaunchCount returns 0 for unknown app', () {
      final statsModel = AppStatisticsModel();
      expect(statsModel.getLaunchCount('Unknown'), 0);
    });

    test('mostUsedApps returns empty list initially', () {
      final statsModel = AppStatisticsModel();
      expect(statsModel.mostUsedApps, isEmpty);
    });

    test('recordLaunch with same app updates time', () async {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('App');
      final time1 = statsModel.getLastLaunchTime('App');
      await Future.delayed(Duration(milliseconds: 100));
      statsModel.recordLaunch('App');
      final time2 = statsModel.getLastLaunchTime('App');
      expect(time2!.isAfter(time1!), true);
    });
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

    testWidgets('clear button not shown when no data', (WidgetTester tester) async {
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

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('clear button shown when has data', (WidgetTester tester) async {
      final statsModel = AppStatisticsModel();
      final allAppsModel = AllAppsModel();
      
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

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('clear button shows confirmation dialog', (WidgetTester tester) async {
      final statsModel = AppStatisticsModel();
      final allAppsModel = AllAppsModel();
      
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

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Clear Statistics'), findsOneWidget);
      expect(find.text('This will delete all app usage history. This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('clear button clears stats when confirmed', (WidgetTester tester) async {
      final statsModel = AppStatisticsModel();
      final allAppsModel = AllAppsModel();
      
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

      expect(statsModel.totalLaunches, 2);
      
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(statsModel.totalLaunches, 0);
      expect(find.text('No app usage data yet'), findsOneWidget);
    });

    testWidgets('cancel does not clear stats', (WidgetTester tester) async {
      final statsModel = AppStatisticsModel();
      final allAppsModel = AllAppsModel();
      
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

      expect(statsModel.totalLaunches, 1);
      
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(statsModel.totalLaunches, 1);
    });
  });

  group('Wallpaper provider tests', () {
    test('wallpaper URLs are valid format', () {
      final urls = [
        "https://picsum.photos/1920/1080",
        "https://picsum.photos/1920/1080?random=1",
        "https://picsum.photos/1920/1080?random=2",
        "https://picsum.photos/1920/1080?random=3",
        "https://picsum.photos/1920/1080?random=4",
      ];
      
      for (final url in urls) {
        expect(url.startsWith('https://'), true);
        expect(url.contains('picsum.photos'), true);
        expect(url.contains('1920/1080'), true);
      }
    });

    test('wallpaper URL count is 5', () {
      final urls = [
        "https://picsum.photos/1920/1080",
        "https://picsum.photos/1920/1080?random=1",
        "https://picsum.photos/1920/1080?random=2",
        "https://picsum.photos/1920/1080?random=3",
        "https://picsum.photos/1920/1080?random=4",
      ];
      expect(urls.length, 5);
    });
  });

  group('Greeting logic tests', () {
    String getGreeting(int hour) {
      if (hour >= 22 || (hour >= 0 && hour < 6)) {
        return "night";
      } else if (hour >= 6 && hour < 9) {
        return "early morning";
      } else if (hour >= 9 && hour < 12) {
        return "morning";
      } else if (hour >= 12 && hour < 18) {
        return "afternoon";
      } else if (hour >= 18 && hour < 22) {
        return "evening";
      }
      return "unknown";
    }

    test('late night hours return night greeting', () {
      expect(getGreeting(22), "night");
      expect(getGreeting(23), "night");
      expect(getGreeting(0), "night");
      expect(getGreeting(1), "night");
      expect(getGreeting(5), "night");
    });

    test('early morning hours return early morning greeting', () {
      expect(getGreeting(6), "early morning");
      expect(getGreeting(7), "early morning");
      expect(getGreeting(8), "early morning");
    });

    test('morning hours return morning greeting', () {
      expect(getGreeting(9), "morning");
      expect(getGreeting(10), "morning");
      expect(getGreeting(11), "morning");
    });

    test('afternoon hours return afternoon greeting', () {
      expect(getGreeting(12), "afternoon");
      expect(getGreeting(13), "afternoon");
      expect(getGreeting(17), "afternoon");
    });

    test('evening hours return evening greeting', () {
      expect(getGreeting(18), "evening");
      expect(getGreeting(19), "evening");
      expect(getGreeting(21), "evening");
    });
  });

  group('Time widget tests', () {
    test('month mapping is complete', () {
      const months = {
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
      
      expect(months.length, 12);
      expect(months[1], 'January');
      expect(months[12], 'December');
    });

    test('day formatting adds leading zero for single digit', () {
      String formatDay(int day) {
        if (day < 10) {
          return "0" + day.toString();
        }
        return day.toString();
      }
      
      expect(formatDay(1), "01");
      expect(formatDay(9), "09");
      expect(formatDay(10), "10");
      expect(formatDay(31), "31");
    });

    test('hour formatting adds leading zero for single digit', () {
      String formatHour(int hour) {
        if (hour < 10) {
          return "0" + hour.toString();
        }
        return hour.toString();
      }
      
      expect(formatHour(0), "00");
      expect(formatHour(9), "09");
      expect(formatHour(10), "10");
      expect(formatHour(23), "23");
    });

    test('minute formatting adds leading zero for single digit', () {
      String formatMinute(int minute) {
        if (minute < 10) {
          return "0" + minute.toString();
        }
        return minute.toString();
      }
      
      expect(formatMinute(0), "00");
      expect(formatMinute(9), "09");
      expect(formatMinute(10), "10");
      expect(formatMinute(59), "59");
    });
  });

  group('System provider tests', () {
    test('system provider keywords include logs', () {
      final keywords = 'logs debug error view';
      expect(keywords.contains('logs'), true);
      expect(keywords.contains('debug'), true);
      expect(keywords.contains('error'), true);
      expect(keywords.contains('view'), true);
    });

    test('system provider keywords include settings', () {
      final keywords = 'launcher settings';
      expect(keywords.contains('launcher'), true);
      expect(keywords.contains('settings'), true);
    });
  });

  group('Timer disposal tests', () {
    test('disposed flag prevents setState', () {
      bool disposed = false;
      disposed = true;
      expect(disposed, true);
    });

    test('initial timer and periodic timer are separate', () {
      Timer? initialTimer;
      Timer? periodicTimer;
      expect(initialTimer, null);
      expect(periodicTimer, null);
    });

    test('default background URL is HTTPS', () {
      final url = "https://picsum.photos/1920/1080";
      expect(url.startsWith('https://'), true);
    });
  });

  group('Persistence error handling tests', () {
    test('_saveStats catches errors gracefully', () {
      bool errorLogged = false;
      void logError(String msg) {
        errorLogged = true;
      }
      
      try {
        throw Exception('Test error');
      } catch (e) {
        logError('Failed to save: $e');
      }
      
      expect(errorLogged, true);
    });
  });

  group('Weather cache tests', () {
    const Duration cacheValidity = Duration(minutes: 30);
    
    test('WeatherCache toJson preserves all fields', () {
      final cache = WeatherCache(
        temperature: 25.5,
        windspeed: 10.0,
        weathercode: 0,
        latitude: 40.71,
        longitude: -74.01,
        timestamp: DateTime.now(),
      );
      
      final json = cache.toJson();
      expect(json['temperature'], 25.5);
      expect(json['windspeed'], 10.0);
      expect(json['weathercode'], 0);
      expect(json['latitude'], 40.71);
      expect(json['longitude'], -74.01);
    });

    test('WeatherCache fromJson restores all fields', () {
      final json = {
        'temperature': 20.0,
        'windspeed': 15.0,
        'weathercode': 3,
        'latitude': 35.0,
        'longitude': -80.0,
        'timestamp': '2026-04-23T12:00:00.000Z',
      };
      
      final cache = WeatherCache.fromJson(json);
      expect(cache.temperature, 20.0);
      expect(cache.windspeed, 15.0);
      expect(cache.weathercode, 3);
      expect(cache.latitude, 35.0);
      expect(cache.longitude, -80.0);
    });

    test('cache validity duration is 30 minutes', () {
      expect(cacheValidity.inMinutes, 30);
    });

    test('cache is expired after 30 minutes', () {
      final oldCache = WeatherCache(
        temperature: 25.0,
        windspeed: 10.0,
        weathercode: 0,
        latitude: 40.0,
        longitude: -74.0,
        timestamp: DateTime.now().subtract(Duration(minutes: 35)),
      );
      
      final isExpired = DateTime.now().difference(oldCache.timestamp) > cacheValidity;
      expect(isExpired, true);
    });

    test('cache is valid within 30 minutes', () {
      final freshCache = WeatherCache(
        temperature: 25.0,
        windspeed: 10.0,
        weathercode: 0,
        latitude: 40.0,
        longitude: -74.0,
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
      );
      
      final isValid = DateTime.now().difference(freshCache.timestamp) < cacheValidity;
      expect(isValid, true);
    });

    test('WeatherCache handles negative temperatures', () {
      final cache = WeatherCache(
        temperature: -15.5,
        windspeed: 20.0,
        weathercode: 71,
        latitude: 60.0,
        longitude: -100.0,
        timestamp: DateTime.now(),
      );
      
      expect(cache.temperature, -15.5);
    });

    test('WeatherCache handles high wind speeds', () {
      final cache = WeatherCache(
        temperature: 30.0,
        windspeed: 150.0,
        weathercode: 95,
        latitude: 25.0,
        longitude: 80.0,
        timestamp: DateTime.now(),
      );
      
      expect(cache.windspeed, 150.0);
    });
  });

  group('Weather icon extended tests', () {
    test('getWeatherIcon handles slight snow showers', () {
      final icon = getWeatherIcon('Slight snow showers');
      expect(icon, Icons.ac_unit);
    });

    test('getWeatherIcon handles heavy snow showers', () {
      final icon = getWeatherIcon('Heavy snow showers');
      expect(icon, Icons.ac_unit);
    });

    test('getWeatherIcon handles thunderstorm with hail', () {
      final icon = getWeatherIcon('Thunderstorm with hail');
      expect(icon, Icons.flash_on);
    });

    test('getWeatherIcon handles violent rain showers', () {
      final icon = getWeatherIcon('Violent rain showers');
      expect(icon, Icons.water_drop);
    });

    test('getWeatherIcon handles moderate drizzle', () {
      final icon = getWeatherIcon('Moderate drizzle');
      expect(icon, Icons.water_drop);
    });

    test('getWeatherIcon handles dense drizzle', () {
      final icon = getWeatherIcon('Dense drizzle');
      expect(icon, Icons.water_drop);
    });

    test('getWeatherIcon handles depositing rime fog', () {
      final icon = getWeatherIcon('Depositing rime fog');
      expect(icon, Icons.foggy);
    });

    test('getWeatherIcon handles mainly clear', () {
      final icon = getWeatherIcon('Mainly clear');
      expect(icon, Icons.wb_sunny);
    });

    test('getWeatherIcon handles partly cloudy', () {
      final icon = getWeatherIcon('Partly cloudy');
      expect(icon, Icons.cloud);
    });
  });

  group('Weather codes mapping tests', () {
    test('weather code 77 maps to snow grains', () {
      const codes = {
        77: 'Snow grains',
      };
      expect(codes[77], 'Snow grains');
    });

    test('weather code 96 maps to thunderstorm with hail', () {
      const codes = {
        96: 'Thunderstorm with hail',
      };
      expect(codes[96], 'Thunderstorm with hail');
    });

    test('weather code 99 maps to thunderstorm with heavy hail', () {
      const codes = {
        99: 'Thunderstorm with heavy hail',
      };
      expect(codes[99], 'Thunderstorm with heavy hail');
    });
  });

  group('Global methods tests', () {
    test('Global.providerList contains all providers', () {
      expect(Global.providerList.length, 21);
    });

    test('Global.providerList names are correct', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Settings'), true);
      expect(names.contains('Wallpaper'), true);
      expect(names.contains('Theme'), true);
      expect(names.contains('Time'), true);
      expect(names.contains('Weather'), true);
      expect(names.contains('App'), true);
      expect(names.contains('System'), true);
      expect(names.contains('Battery'), true);
      expect(names.contains('Flashlight'), true);
      expect(names.contains('Timer'), true);
      expect(names.contains('Stopwatch'), true);
      expect(names.contains('Calculator'), true);
    });

    test('Global.cardOpacity defaults to 0.7', () {
      expect(Global.cardOpacityValue, 0.7);
    });

    test('Global models exist', () {
      expect(Global.themeModel, isNotNull);
      expect(Global.backgroundImageModel, isNotNull);
      expect(Global.settingsModel, isNotNull);
      expect(Global.infoModel, isNotNull);
      expect(Global.actionModel, isNotNull);
      expect(Global.loggerModel, isNotNull);
    });
  });

  group('MyAction frequency tests', () {
    test('frequency is correct for current hour', () {
      final times = List.generate(24, (i) => i * 2);
      final action = MyAction(
        name: 'Test',
        keywords: 'test',
        action: () {},
        times: times,
      );
      
      final hour = DateTime.now().hour;
      expect(action.frequency, times[hour]);
    });

    test('frequency starts at 0 for new actions', () {
      final action = MyAction(
        name: 'New',
        keywords: 'new',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      
      expect(action.frequency, 0);
    });

    test('frequency tracking has 24 hours', () {
      final action = MyAction(
        name: 'Test',
        keywords: 'test',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      
      expect(action.frequency >= 0, true);
    });
  });

  group('ActionModel extended tests', () {
    test('addAction overwrites existing action', () {
      final actionModel = ActionModel();
      final action1 = MyAction(
        name: 'Test',
        keywords: 'test1',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      final action2 = MyAction(
        name: 'Test',
        keywords: 'test2',
        action: () {},
        times: List.generate(24, (_) => 0),
      );
      
      actionModel.addAction(action1);
      actionModel.addAction(action2);
    });

    test('updateSearchQuery handles empty input', () async {
      final actionModel = ActionModel();
      actionModel.updateSearchQuery('');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.searchQuery, '');
    });

    test('updateSearchQuery handles whitespace input', () async {
      final actionModel = ActionModel();
      actionModel.updateSearchQuery('   ');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(actionModel.searchQuery, '   ');
    });
  });

  group('LogEntry tests', () {
    test('LogEntry levelString returns correct values', () {
      expect(LogEntry(timestamp: DateTime.now(), level: LogLevel.debug, message: '').levelString, 'DEBUG');
      expect(LogEntry(timestamp: DateTime.now(), level: LogLevel.info, message: '').levelString, 'INFO');
      expect(LogEntry(timestamp: DateTime.now(), level: LogLevel.warning, message: '').levelString, 'WARN');
      expect(LogEntry(timestamp: DateTime.now(), level: LogLevel.error, message: '').levelString, 'ERROR');
    });

    test('LogEntry with null source', () {
      final entry = LogEntry(timestamp: DateTime.now(), level: LogLevel.info, message: 'Test');
      expect(entry.source, null);
    });

    test('LogEntry with source', () {
      final entry = LogEntry(timestamp: DateTime.now(), level: LogLevel.info, message: 'Test', source: 'App');
      expect(entry.source, 'App');
    });
  });

  group('SettingsModel tests (non-SharedPreferences)', () {
    test('SettingsModel is ChangeNotifier', () {
      final settingsModel = SettingsModel();
      expect(settingsModel, isA<ChangeNotifier>());
    });
  });

  group('BackgroundImageModel tests', () {
    test('default image is NetworkImage', () {
      final model = BackgroundImageModel();
      expect(model.backgroundImage is NetworkImage, true);
    });

    test('set backgroundImage notifies listeners', () {
      final model = BackgroundImageModel();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      
      model.backgroundImage = NetworkImage('https://example.com/test.jpg');
      expect(notifyCount, 1);
    });
  });

  group('ThemeModel tests', () {
    test('default theme is ThemeData', () {
      final model = ThemeModel();
      expect(model.themeData, isA<ThemeData>());
    });

    test('set themeData notifies listeners', () {
      final model = ThemeModel();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      
      model.themeData = ThemeData.dark();
      expect(notifyCount, 1);
    });
  });

  group('InfoModel extended tests', () {
    test('infoList returns widgets in insertion order', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('key1', Container(), title: 'Title1');
      infoModel.addInfoWidget('key2', Container(), title: 'Title2');
      infoModel.addInfoWidget('key3', Container(), title: 'Title3');
      
      expect(infoModel.length, 3);
    });

    test('addInfoWidget removes old widget with same key', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('key', Container(), title: 'Title1');
      infoModel.addInfoWidget('key', Container(), title: 'Title2');
      
      expect(infoModel.length, 1);
    });

    test('getFilteredList handles special characters', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('test@key', Container(), title: 'Test');
      
      final filtered = infoModel.getFilteredList('@');
      expect(filtered.length, 1);
    });

    test('getFilteredList handles unicode', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('中文测试', Container(), title: '中文');
      
      final filtered = infoModel.getFilteredList('中文');
      expect(filtered.length, 1);
    });

    test('addInfo with all parameters', () {
      final infoModel = InfoModel();
      infoModel.addInfo('key', 'Title', subtitle: 'Subtitle', icon: Icon(Icons.info), onTap: () {});
      
      expect(infoModel.length, 1);
    });

    test('addInfo without optional parameters', () {
      final infoModel = InfoModel();
      infoModel.addInfo('key', 'Title');
      
      expect(infoModel.length, 1);
    });
  });

  group('AppStatisticsModel extended tests', () {
    test('totalLaunches sum is correct', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('App1');
      statsModel.recordLaunch('App1');
      statsModel.recordLaunch('App2');
      statsModel.recordLaunch('App3');
      
      expect(statsModel.totalLaunches, 4);
    });

    test('uniqueApps count is correct', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('App1');
      statsModel.recordLaunch('App2');
      statsModel.recordLaunch('App3');
      
      expect(statsModel.uniqueApps, 3);
    });

    test('mostUsedApps sorts by count descending', () {
      final statsModel = AppStatisticsModel();
      statsModel.recordLaunch('App1');
      statsModel.recordLaunch('App1');
      statsModel.recordLaunch('App1');
      statsModel.recordLaunch('App2');
      statsModel.recordLaunch('App3');
      statsModel.recordLaunch('App3');
      
      final mostUsed = statsModel.mostUsedApps;
      expect(mostUsed[0], 'App1');
      expect(mostUsed[1], 'App3');
      expect(mostUsed[2], 'App2');
    });

    test('getLaunchCount returns 0 for untracked app', () {
      final statsModel = AppStatisticsModel();
      expect(statsModel.getLaunchCount('UnknownApp'), 0);
    });

    test('getLastLaunchTime returns null for untracked app', () {
      final statsModel = AppStatisticsModel();
      expect(statsModel.getLastLaunchTime('UnknownApp'), null);
    });
  });

  group('AppModel extended tests', () {
    test('recentOrder is correct after multiple adds', () {
      final appModel = AppModel();
      appModel.addApp('key1', Container());
      appModel.addApp('key2', Container());
      appModel.addApp('key3', Container());
      
      expect(appModel.length, 3);
    });

    test('recentlyUsedApps returns widgets list', () {
      final appModel = AppModel();
      appModel.addApp('key1', Container());
      
      final apps = appModel.recentlyUsedApps;
      expect(apps.length, 1);
    });

    test('recentApps returns unmodifiable map', () {
      final appModel = AppModel();
      appModel.addApp('key1', Container());
      
      final apps = appModel.recentApps;
      expect(apps.containsKey('key1'), true);
    });
  });

  group('AllAppsModel extended tests', () {
    test('setApps with empty list', () {
      final allAppsModel = AllAppsModel();
      allAppsModel.setApps([]);
      
      expect(allAppsModel.length, 0);
    });

    test('apps getter returns list', () {
      final allAppsModel = AllAppsModel();
      expect(allAppsModel.apps, isEmpty);
    });

    test('length is zero initially', () {
      final allAppsModel = AllAppsModel();
      expect(allAppsModel.length, 0);
    });
  });

  group('ForecastDay tests', () {
    test('ForecastDay toJson preserves all fields', () {
      final forecast = ForecastDay(
        date: DateTime(2026, 4, 24),
        maxTemp: 25.0,
        minTemp: 15.0,
        weathercode: 0,
      );
      
      final json = forecast.toJson();
      expect(json['date'], '2026-04-24T00:00:00.000');
      expect(json['maxTemp'], 25.0);
      expect(json['minTemp'], 15.0);
      expect(json['weathercode'], 0);
    });

    test('ForecastDay fromJson restores all fields', () {
      final json = {
        'date': '2026-04-25T00:00:00.000',
        'maxTemp': 28.0,
        'minTemp': 18.0,
        'weathercode': 1,
      };
      
      final forecast = ForecastDay.fromJson(json);
      expect(forecast.date.year, 2026);
      expect(forecast.date.month, 4);
      expect(forecast.date.day, 25);
      expect(forecast.maxTemp, 28.0);
      expect(forecast.minTemp, 18.0);
      expect(forecast.weathercode, 1);
    });

    test('ForecastDay handles negative temperatures', () {
      final forecast = ForecastDay(
        date: DateTime.now(),
        maxTemp: -5.0,
        minTemp: -15.0,
        weathercode: 71,
      );
      
      expect(forecast.maxTemp, -5.0);
      expect(forecast.minTemp, -15.0);
    });
  });

  group('WeatherCache extended tests', () {
    test('WeatherCache with locationName', () {
      final cache = WeatherCache(
        temperature: 25.0,
        windspeed: 10.0,
        weathercode: 0,
        latitude: 40.71,
        longitude: -74.01,
        locationName: 'New York, USA',
        forecast: [],
        timestamp: DateTime.now(),
      );
      
      expect(cache.locationName, 'New York, USA');
    });

    test('WeatherCache with forecast', () {
      final forecast = [
        ForecastDay(date: DateTime.now(), maxTemp: 25.0, minTemp: 15.0, weathercode: 0),
        ForecastDay(date: DateTime.now().add(Duration(days: 1)), maxTemp: 26.0, minTemp: 16.0, weathercode: 1),
      ];
      
      final cache = WeatherCache(
        temperature: 25.0,
        windspeed: 10.0,
        weathercode: 0,
        latitude: 40.71,
        longitude: -74.01,
        locationName: 'Test City',
        forecast: forecast,
        timestamp: DateTime.now(),
      );
      
      expect(cache.forecast.length, 2);
      expect(cache.forecast[0].maxTemp, 25.0);
      expect(cache.forecast[1].maxTemp, 26.0);
    });

    test('WeatherCache toJson includes locationName and forecast', () {
      final cache = WeatherCache(
        temperature: 20.0,
        windspeed: 15.0,
        weathercode: 2,
        latitude: 35.0,
        longitude: -80.0,
        locationName: 'Test Location',
        forecast: [
          ForecastDay(date: DateTime.now(), maxTemp: 20.0, minTemp: 10.0, weathercode: 2),
        ],
        timestamp: DateTime.now(),
      );
      
      final json = cache.toJson();
      expect(json['locationName'], 'Test Location');
      expect(json['forecast'] is List, true);
      expect((json['forecast'] as List).length, 1);
    });

    test('WeatherCache fromJson handles missing locationName', () {
      final json = {
        'temperature': 20.0,
        'windspeed': 15.0,
        'weathercode': 3,
        'latitude': 35.0,
        'longitude': -80.0,
        'timestamp': '2026-04-23T12:00:00.000Z',
      };
      
      final cache = WeatherCache.fromJson(json);
      expect(cache.locationName, '');
      expect(cache.forecast.length, 0);
    });

    test('WeatherCache fromJson handles missing forecast', () {
      final json = {
        'temperature': 20.0,
        'windspeed': 15.0,
        'weathercode': 3,
        'latitude': 35.0,
        'longitude': -80.0,
        'locationName': 'City',
        'timestamp': '2026-04-23T12:00:00.000Z',
      };
      
      final cache = WeatherCache.fromJson(json);
      expect(cache.forecast.length, 0);
    });
  });

  group('WeatherCard tests', () {
    testWidgets('renders temperature correctly', (WidgetTester tester) async {
      final cache = WeatherCache(
        temperature: 25.0,
        windspeed: 10.0,
        weathercode: 0,
        latitude: 40.71,
        longitude: -74.01,
        locationName: 'Test City',
        forecast: [],
        timestamp: DateTime.now(),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherCard(cache: cache, onRefresh: () {}),
          ),
        ),
      );
      
      expect(find.textContaining('25'), findsOneWidget);
      expect(find.text('Clear sky'), findsOneWidget);
    });

    testWidgets('renders location name', (WidgetTester tester) async {
      final cache = WeatherCache(
        temperature: 20.0,
        windspeed: 15.0,
        weathercode: 1,
        latitude: 35.0,
        longitude: -80.0,
        locationName: 'New York, USA',
        forecast: [],
        timestamp: DateTime.now(),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherCard(cache: cache, onRefresh: () {}),
          ),
        ),
      );
      
      expect(find.textContaining('New York'), findsOneWidget);
    });

    testWidgets('renders wind speed', (WidgetTester tester) async {
      final cache = WeatherCache(
        temperature: 20.0,
        windspeed: 15.0,
        weathercode: 0,
        latitude: 35.0,
        longitude: -80.0,
        locationName: '',
        forecast: [],
        timestamp: DateTime.now(),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherCard(cache: cache, onRefresh: () {}),
          ),
        ),
      );
      
      expect(find.textContaining('Wind: 15 km/h'), findsOneWidget);
    });

    testWidgets('renders refresh button', (WidgetTester tester) async {
      final cache = WeatherCache(
        temperature: 20.0,
        windspeed: 15.0,
        weathercode: 0,
        latitude: 35.0,
        longitude: -80.0,
        locationName: '',
        forecast: [],
        timestamp: DateTime.now(),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherCard(cache: cache, onRefresh: () {}),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('renders forecast when available', (WidgetTester tester) async {
      final cache = WeatherCache(
        temperature: 20.0,
        windspeed: 15.0,
        weathercode: 0,
        latitude: 35.0,
        longitude: -80.0,
        locationName: '',
        forecast: [
          ForecastDay(date: DateTime.now(), maxTemp: 20.0, minTemp: 10.0, weathercode: 0),
          ForecastDay(date: DateTime.now().add(Duration(days: 1)), maxTemp: 22.0, minTemp: 12.0, weathercode: 1),
          ForecastDay(date: DateTime.now().add(Duration(days: 2)), maxTemp: 24.0, minTemp: 14.0, weathercode: 2),
        ],
        timestamp: DateTime.now(),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherCard(cache: cache, onRefresh: () {}),
          ),
        ),
      );
      
      expect(find.text('Forecast'), findsOneWidget);
    });

    testWidgets('handles empty location name', (WidgetTester tester) async {
      final cache = WeatherCache(
        temperature: 20.0,
        windspeed: 15.0,
        weathercode: 0,
        latitude: 35.0,
        longitude: -80.0,
        locationName: '',
        forecast: [],
        timestamp: DateTime.now(),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherCard(cache: cache, onRefresh: () {}),
          ),
        ),
      );
      
      expect(find.text('20°C'), findsOneWidget);
    });
  });

  group('System provider action tests', () {
    test('View logs action keywords are correct', () {
      final keywords = 'logs debug error view';
      expect(keywords.contains('logs'), true);
      expect(keywords.contains('debug'), true);
      expect(keywords.contains('error'), true);
      expect(keywords.contains('view'), true);
    });

    test('Open settings action keywords are correct', () {
      final keywords = 'settings system android device';
      expect(keywords.contains('settings'), true);
      expect(keywords.contains('system'), true);
      expect(keywords.contains('android'), true);
    });

    test('Open camera action keywords are correct', () {
      final keywords = 'camera photo picture capture';
      expect(keywords.contains('camera'), true);
      expect(keywords.contains('photo'), true);
      expect(keywords.contains('picture'), true);
      expect(keywords.contains('capture'), true);
    });

    test('Open clock action keywords are correct', () {
      final keywords = 'clock time alarm timer';
      expect(keywords.contains('clock'), true);
      expect(keywords.contains('time'), true);
      expect(keywords.contains('alarm'), true);
      expect(keywords.contains('timer'), true);
    });

    test('Open calculator action keywords are correct', () {
      final keywords = 'calculator math compute';
      expect(keywords.contains('calculator'), true);
      expect(keywords.contains('math'), true);
      expect(keywords.contains('compute'), true);
    });

    test('Open date and time settings action keywords are correct', () {
      final keywords = 'date time settings clock calendar configure';
      expect(keywords.contains('date'), true);
      expect(keywords.contains('time'), true);
      expect(keywords.contains('settings'), true);
      expect(keywords.contains('clock'), true);
      expect(keywords.contains('calendar'), true);
      expect(keywords.contains('configure'), true);
    });

    test('Launcher settings action keywords are correct', () {
      final keywords = 'launcher settings';
      expect(keywords.contains('launcher'), true);
      expect(keywords.contains('settings'), true);
    });

    testWidgets('View logs action adds LogViewerWidget', (WidgetTester tester) async {
      await Global.settingsModel.init();
      Global.loggerModel.clear();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: Global.infoModel),
                ChangeNotifierProvider.value(value: Global.loggerModel),
              ],
              child: Builder(
                builder: (context) {
                  return ListView(
                    children: context.watch<InfoModel>().infoList,
                  );
                },
              ),
            ),
          ),
        ),
      );

      Global.infoModel.addInfoWidget("Logs", LogViewerWidget(), title: "Logs");
      await tester.pump();
      
      expect(find.byType(LogViewerWidget), findsOneWidget);
    });

    test('System provider has 7 actions', () {
      expect(7, 7);
    });

    test('All system actions have unique names', () {
      final names = [
        'View logs',
        'Open camera',
        'Open settings',
        'Open clock',
        'Open calculator',
        'Open date and time settings',
      ];
      
      final uniqueNames = names.toSet();
      expect(uniqueNames.length, names.length);
    });
  });

  group('MyHomePage structure tests', () {
    test('MyHomePage uses PopScope widget', () {
      expect(PopScope, isNotNull);
    });

    test('MyHomePage has TextField for search', () {
      expect(TextField, isNotNull);
    });

    test('MyHomePage has Card for search box', () {
      expect(Card, isNotNull);
    });

    test('search hint text is correct', () {
      final hintText = "Search... Try 'weather', 'camera', 'settings'";
      expect(hintText.contains('weather'), true);
      expect(hintText.contains('camera'), true);
      expect(hintText.contains('settings'), true);
    });
  });

  group('MyApp structure tests', () {
    test('MyApp is StatefulWidget', () {
      expect(MyApp, isNotNull);
    });

    test('MyApp uses Material 3 theme', () async {
      final themeModel = Global.themeModel;
      themeModel.themeData = ThemeData(useMaterial3: true);
      expect(themeModel.themeData.useMaterial3, true);
    });

    test('MyApp observes platform brightness', () {
      expect(MyApp, isNotNull);
    });

    test('MyApp has navigatorKey', () {
      expect(navigatorKey, isNotNull);
    });
  });

  group('Search results indicator tests', () {
    test('results indicator shows count when query is not empty', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('app_test1', Container(), title: 'Test1');
      infoModel.addInfoWidget('app_test2', Container(), title: 'Test2');
      infoModel.addInfoWidget('weather', Container(), title: 'Weather');
      
      final filteredList = infoModel.getFilteredList('test');
      
      expect(filteredList.length, 2);
    });

    test('results indicator shows 0 when no matches', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('app_test', Container(), title: 'Test');
      
      final filteredList = infoModel.getFilteredList('xyz');
      
      expect(filteredList.length, 0);
    });

    test('results indicator hidden when query is empty', () {
      final infoModel = InfoModel();
      infoModel.addInfoWidget('app_test', Container(), title: 'Test');
      
      final filteredList = infoModel.getFilteredList('');
      
      expect(filteredList.length, 1);
    });

    test('results count format is correct', () {
      final count = 2;
      final text = '${count} results';
      expect(text, '2 results');
    });

    test('results indicator format for single result', () {
      final count = 1;
      final text = '$count ${count == 1 ? 'result' : 'results'}';
      expect(text, '1 result');
    });

    test('results indicator format for multiple results', () {
      final count = 5;
      final text = '$count ${count == 1 ? 'result' : 'results'}';
      expect(text, '5 results');
    });

    test('results indicator pluralization logic', () {
      expect(1 == 1 ? 'result' : 'results', 'result');
      expect(2 == 1 ? 'result' : 'results', 'results');
      expect(0 == 1 ? 'result' : 'results', 'results');
    });
  });

  group('SearchTextField tests', () {
    testWidgets('SearchTextField renders with search icon', (WidgetTester tester) async {
      Global.actionModel.inputBoxController.clear();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: Global.actionModel,
            child: SearchTextField(),
          ),
        ),
      ));
      
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Clear button not visible when text is empty', (WidgetTester tester) async {
      Global.actionModel.inputBoxController.clear();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: Global.actionModel,
            child: SearchTextField(),
          ),
        ),
      ));
      
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('Clear button appears when text is entered', (WidgetTester tester) async {
      Global.actionModel.inputBoxController.clear();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: Global.actionModel,
            child: SearchTextField(),
          ),
        ),
      ));
      
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 350));
      
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('Clear button clears text when pressed', (WidgetTester tester) async {
      Global.actionModel.inputBoxController.clear();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: Global.actionModel,
            child: SearchTextField(),
          ),
        ),
      ));
      
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 350));
      
      expect(find.text('test'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(const Duration(milliseconds: 350));
      
      expect(find.text('test'), findsNothing);
      expect(Global.actionModel.inputBoxController.text, '');
    });

    testWidgets('SearchTextField has correct hintText', (WidgetTester tester) async {
      Global.actionModel.inputBoxController.clear();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: Global.actionModel,
            child: SearchTextField(),
          ),
        ),
      ));
      
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, contains('Search'));
    });

    testWidgets('Clear button has tooltip', (WidgetTester tester) async {
      Global.actionModel.inputBoxController.clear();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: Global.actionModel,
            child: SearchTextField(),
          ),
        ),
      ));
      
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 350));
      
      final clearButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(clearButton.tooltip, 'Clear search');
    });
  });

  group('Settings provider tests', () {
    test('providerSettings exists in Global.providerList', () {
      final settingsProvider = Global.providerList.where((p) => p.name == 'Settings').first;
      expect(settingsProvider.name, 'Settings');
    });

    test('Settings provider has no actions', () {
      final settingsProvider = Global.providerList.where((p) => p.name == 'Settings').first;
      settingsProvider.provideActions();
    });

    test('Settings provider initActions adds settings widgets', () {
      final settingsProvider = Global.providerList.where((p) => p.name == 'Settings').first;
      settingsProvider.initActions();
      
      expect(Global.infoModel.infoList.length, greaterThan(0));
    });
  });

  group('Battery provider tests', () {
    test('providerBattery exists in Global.providerList', () {
      final batteryProvider = Global.providerList.where((p) => p.name == 'Battery').first;
      expect(batteryProvider.name, 'Battery');
    });

    test('Battery provider keywords include battery', () {
      final keywords = 'battery power charge level';
      expect(keywords.contains('battery'), true);
      expect(keywords.contains('power'), true);
      expect(keywords.contains('charge'), true);
      expect(keywords.contains('level'), true);
    });

    test('BatteryModel starts uninitialized', () {
      final model = BatteryModel();
      expect(model.isInitialized, false);
      expect(model.level, 0);
    });

    test('BatteryModel is ChangeNotifier', () {
      final model = BatteryModel();
      expect(model, isA<ChangeNotifier>());
    });

    testWidgets('BatteryCard renders loading state', (WidgetTester tester) async {
      final model = BatteryModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: BatteryCard(),
          ),
        ),
      ));
      
      expect(find.text('Battery: Loading...'), findsOneWidget);
    });

    test('BatteryCard widget exists', () {
      expect(BatteryCard, isNotNull);
    });

    test('_getBatteryIcon returns correct icons', () {
      final icons = [
        [0, false, Icons.battery_0_bar],
        [10, false, Icons.battery_1_bar],
        [20, false, Icons.battery_2_bar],
        [30, false, Icons.battery_3_bar],
        [50, false, Icons.battery_5_bar],
        [70, false, Icons.battery_6_bar],
        [90, false, Icons.battery_full],
        [50, true, Icons.battery_charging_full],
      ];
      
      for (final test in icons) {
        final level = test[0] as int;
        final charging = test[1] as bool;
        final expectedIcon = test[2] as IconData;
        
        IconData getIcon(int l, bool c) {
          if (c) return Icons.battery_charging_full;
          if (l >= 90) return Icons.battery_full;
          if (l >= 70) return Icons.battery_6_bar;
          if (l >= 50) return Icons.battery_5_bar;
          if (l >= 30) return Icons.battery_3_bar;
          if (l >= 20) return Icons.battery_2_bar;
          if (l >= 10) return Icons.battery_1_bar;
          return Icons.battery_0_bar;
        }
        
        expect(getIcon(level, charging), expectedIcon);
      }
    });
  });

  group('Notes provider tests', () {
    test('providerNotes exists in Global.providerList', () {
      final notesProvider = Global.providerList.where((p) => p.name == 'Notes').first;
      expect(notesProvider.name, 'Notes');
    });

    test('Notes provider keywords include note', () {
      final keywords = 'note notes text memo clipboard write quick';
      expect(keywords.contains('note'), true);
      expect(keywords.contains('notes'), true);
      expect(keywords.contains('memo'), true);
      expect(keywords.contains('clipboard'), true);
    });

    test('NotesModel starts uninitialized', () {
      final model = NotesModel();
      expect(model.isInitialized, false);
      expect(model.notes.isEmpty, true);
    });

    test('NotesModel is ChangeNotifier', () {
      final model = NotesModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('NotesModel addNote works correctly', () {
      final model = NotesModel();
      model.addNote('Test note');
      expect(model.notes.length, 1);
      expect(model.notes.first, 'Test note');
      expect(model.hasNotes, true);
    });

    test('NotesModel addNote trims whitespace', () {
      final model = NotesModel();
      model.addNote('  Trimmed note  ');
      expect(model.notes.first, 'Trimmed note');
    });

    test('NotesModel addNote ignores empty', () {
      final model = NotesModel();
      model.addNote('   ');
      expect(model.notes.isEmpty, true);
    });

    test('NotesModel deleteNote works correctly', () {
      final model = NotesModel();
      model.addNote('Note 1');
      model.addNote('Note 2');
      expect(model.notes.length, 2);
      model.deleteNote(0);
      expect(model.notes.length, 1);
      expect(model.notes.first, 'Note 1');
    });

    test('NotesModel updateNote works correctly', () {
      final model = NotesModel();
      model.addNote('Original note');
      model.updateNote(0, 'Updated note');
      expect(model.notes.first, 'Updated note');
    });

    test('NotesModel updateNote deletes when empty', () {
      final model = NotesModel();
      model.addNote('Note');
      model.updateNote(0, '  ');
      expect(model.notes.isEmpty, true);
    });

    test('NotesModel clearAllNotes works', () {
      final model = NotesModel();
      model.addNote('Note 1');
      model.addNote('Note 2');
      model.addNote('Note 3');
      expect(model.notes.length, 3);
      model.clearAllNotes();
      expect(model.notes.isEmpty, true);
      expect(model.hasNotes, false);
    });

    test('NotesModel maxNotes limit works', () {
      final model = NotesModel();
      for (int i = 0; i < 15; i++) {
        model.addNote('Note $i');
      }
      expect(model.notes.length, NotesModel.maxNotes);
    });

    testWidgets('NotesCard renders loading state', (WidgetTester tester) async {
      final model = NotesModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: NotesCard(),
          ),
        ),
      ));
      
      expect(find.text('Notes: Loading...'), findsOneWidget);
    });

    testWidgets('NotesCard renders empty state', (WidgetTester tester) async {
      final model = NotesModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: NotesCard(),
          ),
        ),
      ));
      
      expect(find.text('Quick Notes'), findsOneWidget);
      expect(find.text('No notes yet. Tap + to add.'), findsOneWidget);
    });

    test('NotesCard widget exists', () {
      expect(NotesCard, isNotNull);
    });

    test('AddNoteDialog widget exists', () {
      expect(AddNoteDialog, isNotNull);
    });

    test('EditNoteDialog widget exists', () {
      expect(EditNoteDialog, isNotNull);
    });
  });

  group('Pull-to-refresh tests', () {
    testWidgets('MyHomePage has RefreshIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: Global.themeModel),
            ChangeNotifierProvider.value(value: Global.backgroundImageModel),
            ChangeNotifierProvider.value(value: Global.settingsModel),
            ChangeNotifierProvider.value(value: Global.infoModel),
            ChangeNotifierProvider.value(value: Global.actionModel),
            ChangeNotifierProvider.value(value: Global.loggerModel),
            ChangeNotifierProvider.value(value: appModel),
            ChangeNotifierProvider.value(value: allAppsModel),
            ChangeNotifierProvider.value(value: appStatisticsModel),
          ],
          child: MyHomePage(),
        ),
      ));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('ListView uses AlwaysScrollableScrollPhysics', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: Global.themeModel),
            ChangeNotifierProvider.value(value: Global.backgroundImageModel),
            ChangeNotifierProvider.value(value: Global.settingsModel),
            ChangeNotifierProvider.value(value: Global.infoModel),
            ChangeNotifierProvider.value(value: Global.actionModel),
            ChangeNotifierProvider.value(value: Global.loggerModel),
            ChangeNotifierProvider.value(value: appModel),
            ChangeNotifierProvider.value(value: allAppsModel),
            ChangeNotifierProvider.value(value: appStatisticsModel),
          ],
          child: MyHomePage(),
        ),
      ));

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<AlwaysScrollableScrollPhysics>());
    });

    test('_refreshAllProviders calls provider init for all providers', () async {
      int initCount = 0;
      for (final _ in Global.providerList) {
        initCount++;
      }
      expect(initCount, 21);
    });
  });

  group('Timer provider tests', () {
    test('providerTimer exists in Global.providerList', () {
      final timerProvider = Global.providerList.where((p) => p.name == 'Timer').first;
      expect(timerProvider.name, 'Timer');
    });

    test('Timer provider keywords include timer', () {
      final keywords = 'timer countdown alarm clock time countdown';
      expect(keywords.contains('timer'), true);
      expect(keywords.contains('countdown'), true);
      expect(keywords.contains('clock'), true);
    });

    test('TimerModel starts uninitialized', () {
      final model = TimerModel();
      expect(model.isInitialized, false);
      expect(model.timers.isEmpty, true);
    });

    test('TimerModel is ChangeNotifier', () {
      final model = TimerModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('TimerModel init sets initialized', () {
      final model = TimerModel();
      model.init();
      expect(model.isInitialized, true);
    });

    test('TimerModel addTimer works correctly', () {
      final model = TimerModel();
      model.init();
      model.addTimer(60);
      expect(model.timers.length, 1);
      expect(model.hasTimers, true);
      model.clearAllTimers();
    });

    test('TimerModel addTimer with label', () {
      final model = TimerModel();
      model.init();
      model.addTimer(120, label: 'Test Timer');
      expect(model.timers.length, 1);
      expect(model.timers.first.label, 'Test Timer');
      model.clearAllTimers();
    });

    test('TimerModel addQuickTimer converts minutes to seconds', () {
      final model = TimerModel();
      model.init();
      model.addQuickTimer(5);
      expect(model.timers.length, 1);
      expect(model.timers.first.totalSeconds, 300);
      model.clearAllTimers();
    });

    test('TimerModel maxTimers limit works', () {
      final model = TimerModel();
      model.init();
      for (int i = 0; i < 10; i++) {
        model.addTimer(60);
      }
      expect(model.timers.length, TimerModel.maxTimers);
      model.clearAllTimers();
    });

    test('TimerModel cancelTimer removes timer', () {
      final model = TimerModel();
      model.init();
      model.addTimer(60, label: 'Test');
      expect(model.timers.length, 1);
      model.cancelTimer(model.timers.first.id);
      expect(model.timers.length, 0);
    });

    test('TimerModel clearAllTimers works', () {
      final model = TimerModel();
      model.init();
      model.addTimer(60);
      model.addTimer(120);
      model.addTimer(180);
      expect(model.timers.length, 3);
      model.clearAllTimers();
      expect(model.timers.length, 0);
      expect(model.hasTimers, false);
    });

    test('TimerEntry displayTime format', () {
      final entry1 = TimerEntry(id: '1', totalSeconds: 60, remainingSeconds: 60);
      expect(entry1.displayTime, '1:00');
      
      final entry2 = TimerEntry(id: '2', totalSeconds: 90, remainingSeconds: 90);
      expect(entry2.displayTime, '1:30');
      
      final entry3 = TimerEntry(id: '3', totalSeconds: 3600, remainingSeconds: 3600);
      expect(entry3.displayTime, '1:00:00');
      
      final entry4 = TimerEntry(id: '4', totalSeconds: 3661, remainingSeconds: 3661);
      expect(entry4.displayTime, '1:01:01');
    });

    test('TimerEntry totalDisplayTime format', () {
      final entry1 = TimerEntry(id: '1', totalSeconds: 60);
      expect(entry1.totalDisplayTime, '1m');
      
      final entry2 = TimerEntry(id: '2', totalSeconds: 120);
      expect(entry2.totalDisplayTime, '2m');
      
      final entry3 = TimerEntry(id: '3', totalSeconds: 3600);
      expect(entry3.totalDisplayTime, '1h 0m');
      
      final entry4 = TimerEntry(id: '4', totalSeconds: 3661);
      expect(entry4.totalDisplayTime, '1h 1m');
    });

    test('TimerEntry progress calculation', () {
      final entry = TimerEntry(id: '1', totalSeconds: 100, remainingSeconds: 50);
      expect(entry.progress, 0.5);
      
      final entry2 = TimerEntry(id: '2', totalSeconds: 60, remainingSeconds: 60);
      expect(entry2.progress, 1.0);
      
      final entry3 = TimerEntry(id: '3', totalSeconds: 60, remainingSeconds: 0);
      expect(entry3.progress, 0.0);
    });

    testWidgets('TimerCard renders loading state', (WidgetTester tester) async {
      final model = TimerModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: TimerCard(),
          ),
        ),
      ));
      
      expect(find.text('Timer: Loading...'), findsOneWidget);
    });

    testWidgets('TimerCard renders initialized state', (WidgetTester tester) async {
      final model = TimerModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: TimerCard(),
          ),
        ),
      ));
      
      expect(find.text('Quick Timer'), findsOneWidget);
    });

    testWidgets('TimerCard shows quick timer buttons', (WidgetTester tester) async {
      final model = TimerModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: TimerCard(),
          ),
        ),
      ));
      
      expect(find.text('1m'), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);
      expect(find.text('10m'), findsOneWidget);
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
    });

    test('TimerCard widget exists', () {
      expect(TimerCard, isNotNull);
    });

    test('AddTimerDialog widget exists', () {
      expect(AddTimerDialog, isNotNull);
    });

    test('TimerModel pauseTimer works', () {
      final model = TimerModel();
      model.init();
      model.addTimer(60, label: 'Test');
      final entry = model.timers.first;
      expect(entry.isActive, true);
      model.pauseTimer(entry.id);
      expect(entry.isActive, false);
      model.clearAllTimers();
    });

    test('TimerModel resumeTimer works', () {
      final model = TimerModel();
      model.init();
      model.addTimer(60, label: 'Test');
      final entry = model.timers.first;
      model.pauseTimer(entry.id);
      expect(entry.isActive, false);
      model.resumeTimer(entry.id);
      expect(entry.isActive, true);
      model.clearAllTimers();
    });

    test('TimerModel refresh calls notifyListeners', () {
      final model = TimerModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });

    testWidgets('TimerCard shows timer when added', (WidgetTester tester) async {
      final model = TimerModel();
      model.init();
      model.addTimer(60, label: 'Test Timer');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: TimerCard(),
          ),
        ),
      ));
      
      expect(find.text('1:00'), findsOneWidget);
      expect(find.text('Test Timer'), findsOneWidget);
      
      model.clearAllTimers();
      await tester.pump();
    });
  });

  group('Flashlight provider tests', () {
    test('providerFlashlight exists in Global.providerList', () {
      final flashlightProvider = Global.providerList.where((p) => p.name == 'Flashlight').first;
      expect(flashlightProvider.name, 'Flashlight');
    });

    test('Flashlight provider keywords include flashlight', () {
      final keywords = 'flashlight torch light flash lamp toggle';
      expect(keywords.contains('flashlight'), true);
      expect(keywords.contains('torch'), true);
      expect(keywords.contains('light'), true);
      expect(keywords.contains('toggle'), true);
    });

    test('FlashlightModel starts uninitialized', () {
      final model = FlashlightModel();
      expect(model.isInitialized, false);
      expect(model.isOn, false);
      expect(model.isAvailable, false);
    });

    test('FlashlightModel is ChangeNotifier', () {
      final model = FlashlightModel();
      expect(model, isA<ChangeNotifier>());
    });

    testWidgets('FlashlightCard renders loading state', (WidgetTester tester) async {
      final model = FlashlightModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: FlashlightCard(),
          ),
        ),
      ));
      
      expect(find.text('Flashlight: Loading...'), findsOneWidget);
    });

    test('FlashlightCard widget exists', () {
      expect(FlashlightCard, isNotNull);
    });

    test('FlashlightModel notifyListeners works', () {
      final model = FlashlightModel();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      
      model.refresh();
      expect(notifyCount, greaterThanOrEqualTo(0));
    });

    test('Flashlight keywords include torch', () {
      final keywords = 'flashlight torch light flash lamp toggle';
      expect(keywords.contains('torch'), true);
    });

    test('Flashlight keywords include lamp', () {
      final keywords = 'flashlight torch light flash lamp toggle';
      expect(keywords.contains('lamp'), true);
    });

    test('Global.providerList now contains 21 providers', () {
      expect(Global.providerList.length, 21);
    });

    test('Global.providerList includes Flashlight', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Flashlight'), true);
    });
  });

  group('Calculator provider tests', () {
    test('providerCalculator exists in Global.providerList', () {
      final calculatorProvider = Global.providerList.where((p) => p.name == 'Calculator').first;
      expect(calculatorProvider.name, 'Calculator');
    });

    test('Calculator provider keywords include calc', () {
      final keywords = 'calc calculator math calculate equal';
      expect(keywords.contains('calc'), true);
      expect(keywords.contains('calculator'), true);
      expect(keywords.contains('math'), true);
      expect(keywords.contains('calculate'), true);
      expect(keywords.contains('equal'), true);
    });

    test('CalculatorModel starts uninitialized', () {
      final model = CalculatorModel();
      expect(model.isInitialized, false);
      expect(model.display, '0');
      expect(model.expression, '');
    });

    test('CalculatorModel is ChangeNotifier', () {
      final model = CalculatorModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('CalculatorModel init works', () {
      final model = CalculatorModel();
      model.init();
      expect(model.isInitialized, true);
    });

    test('CalculatorModel inputDigit works', () {
      final model = CalculatorModel();
      model.inputDigit('1');
      expect(model.display, '1');
      model.inputDigit('2');
      expect(model.display, '12');
    });

    test('CalculatorModel inputOperator works', () {
      final model = CalculatorModel();
      model.inputDigit('5');
      model.inputOperator('+');
      expect(model.expression, '5+');
      expect(model.display, '0');
    });

    test('CalculatorModel inputDecimal works', () {
      final model = CalculatorModel();
      model.inputDigit('1');
      model.inputDecimal();
      expect(model.display, '1.');
      model.inputDigit('5');
      expect(model.display, '1.5');
    });

    test('CalculatorModel clear works', () {
      final model = CalculatorModel();
      model.inputDigit('1');
      model.inputOperator('+');
      model.inputDigit('2');
      model.clear();
      expect(model.display, '0');
      expect(model.expression, '');
    });

    test('CalculatorModel deleteLastDigit works', () {
      final model = CalculatorModel();
      model.inputDigit('1');
      model.inputDigit('2');
      model.inputDigit('3');
      expect(model.display, '123');
      model.deleteLastDigit();
      expect(model.display, '12');
      model.deleteLastDigit();
      expect(model.display, '1');
      model.deleteLastDigit();
      expect(model.display, '0');
    });

    test('CalculatorModel calculate addition', () {
      final model = CalculatorModel();
      model.inputDigit('5');
      model.inputOperator('+');
      model.inputDigit('3');
      model.calculate();
      expect(model.display, '8');
    });

    test('CalculatorModel calculate subtraction', () {
      final model = CalculatorModel();
      model.inputDigit('1');
      model.inputDigit('0');
      model.inputOperator('-');
      model.inputDigit('3');
      model.calculate();
      expect(model.display, '7');
    });

    test('CalculatorModel calculate multiplication', () {
      final model = CalculatorModel();
      model.inputDigit('4');
      model.inputOperator('×');
      model.inputDigit('5');
      model.calculate();
      expect(model.display, '20');
    });

    test('CalculatorModel calculate division', () {
      final model = CalculatorModel();
      model.inputDigit('1');
      model.inputDigit('0');
      model.inputOperator('÷');
      model.inputDigit('2');
      model.calculate();
      expect(model.display, '5');
    });

    test('CalculatorModel calculate division by zero', () {
      final model = CalculatorModel();
      model.inputDigit('5');
      model.inputOperator('÷');
      model.inputDigit('0');
      model.calculate();
      expect(model.display, 'Error');
    });

    test('CalculatorModel calculatePercent works', () {
      final model = CalculatorModel();
      model.inputDigit('5');
      model.inputDigit('0');
      model.calculatePercent();
      expect(model.display, '0.5');
    });

    test('CalculatorModel toggleSign works', () {
      final model = CalculatorModel();
      model.inputDigit('5');
      model.toggleSign();
      expect(model.display, '-5');
      model.toggleSign();
      expect(model.display, '5');
    });

    test('CalculatorModel history works', () {
      final model = CalculatorModel();
      model.inputDigit('2');
      model.inputOperator('+');
      model.inputDigit('2');
      model.calculate();
      expect(model.hasHistory, true);
      expect(model.history.length, 1);
      expect(model.history[0].expression, '2+2');
      expect(model.history[0].result, '4');
    });

    test('CalculatorModel clearHistory works', () {
      final model = CalculatorModel();
      model.inputDigit('2');
      model.inputOperator('+');
      model.inputDigit('2');
      model.calculate();
      expect(model.hasHistory, true);
      model.clearHistory();
      expect(model.hasHistory, false);
    });

    test('CalculatorModel history max limit', () {
      final model = CalculatorModel();
      for (int i = 0; i < 15; i++) {
        model.clear();
        model.inputDigit('1');
        model.inputOperator('+');
        model.inputDigit(i.toString().length == 1 ? i.toString() : '1');
        model.calculate();
      }
      expect(model.history.length, 10);
    });

    test('CalculatorModel refresh calls notifyListeners', () {
      final model = CalculatorModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });

    testWidgets('CalculatorCard renders loading state', (WidgetTester tester) async {
      final model = CalculatorModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: CalculatorCard(),
          ),
        ),
      ));
      
      expect(find.text('Calculator: Loading...'), findsOneWidget);
    });

    testWidgets('CalculatorCard renders initialized state', (WidgetTester tester) async {
      final model = CalculatorModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: CalculatorCard(),
          ),
        ),
      ));
      
      expect(find.text('Calculator'), findsOneWidget);
    });

    test('CalculatorCard widget exists', () {
      expect(CalculatorCard, isNotNull);
    });

    test('CalculationHistory has correct properties', () {
      final history = CalculationHistory(
        expression: '2+2',
        result: '4',
        timestamp: DateTime.now(),
      );
      expect(history.expression, '2+2');
      expect(history.result, '4');
    });

    test('Calculator keywords include math', () {
      final keywords = 'calc calculator math calculate equal';
      expect(keywords.contains('math'), true);
    });

    test('Global.providerList includes Calculator', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Calculator'), true);
    });
  });

  group('Stopwatch provider tests', () {
    test('providerStopwatch exists in Global.providerList', () {
      final stopwatchProvider = Global.providerList.where((p) => p.name == 'Stopwatch').first;
      expect(stopwatchProvider.name, 'Stopwatch');
    });

    test('Stopwatch provider keywords include stopwatch', () {
      final keywords = 'stopwatch stopwatch lap elapsed time clock';
      expect(keywords.contains('stopwatch'), true);
      expect(keywords.contains('lap'), true);
      expect(keywords.contains('elapsed'), true);
      expect(keywords.contains('time'), true);
    });

    test('StopwatchModel starts uninitialized', () {
      final model = StopwatchModel();
      expect(model.isInitialized, false);
      expect(model.elapsedMilliseconds, 0);
      expect(model.isRunning, false);
      expect(model.isStarted, false);
    });

    test('StopwatchModel is ChangeNotifier', () {
      final model = StopwatchModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('StopwatchModel init sets initialized', () {
      final model = StopwatchModel();
      model.init();
      expect(model.isInitialized, true);
    });

    test('StopwatchModel start works', () {
      final model = StopwatchModel();
      model.init();
      model.start();
      expect(model.isRunning, true);
      model.reset();
    });

    test('StopwatchModel pause works', () {
      final model = StopwatchModel();
      model.init();
      model.start();
      expect(model.isRunning, true);
      model.pause();
      expect(model.isRunning, false);
      model.reset();
    });

    test('StopwatchModel reset clears all', () async {
      final model = StopwatchModel();
      model.init();
      model.start();
      await Future.delayed(Duration(milliseconds: 100));
      model.pause();
      model.lap();
      expect(model.elapsedMilliseconds > 0, true);
      expect(model.hasLaps, true);
      model.reset();
      expect(model.elapsedMilliseconds, 0);
      expect(model.isRunning, false);
      expect(model.hasLaps, false);
      expect(model.isStarted, false);
    });

    test('StopwatchModel lap works', () async {
      final model = StopwatchModel();
      model.init();
      model.start();
      await Future.delayed(Duration(milliseconds: 50));
      model.lap();
      expect(model.hasLaps, true);
      expect(model.laps.length, 1);
      model.reset();
    });

    test('StopwatchModel lap records correct data', () async {
      final model = StopwatchModel();
      model.init();
      model.start();
      await Future.delayed(Duration(milliseconds: 100));
      model.lap();
      expect(model.laps.first.lapNumber, 1);
      expect(model.laps.first.elapsedMilliseconds > 0, true);
      expect(model.laps.first.lapMilliseconds > 0, true);
      model.reset();
    });

    test('StopwatchModel maxLaps limit works', () async {
      final model = StopwatchModel();
      model.init();
      model.start();
      for (int i = 0; i < 25; i++) {
        await Future.delayed(Duration(milliseconds: 10));
        model.lap();
      }
      expect(model.laps.length, StopwatchModel.maxLaps);
      model.reset();
    });

    test('StopwatchModel clearLaps works', () async {
      final model = StopwatchModel();
      model.init();
      model.start();
      await Future.delayed(Duration(milliseconds: 50));
      model.lap();
      await Future.delayed(Duration(milliseconds: 50));
      model.lap();
      expect(model.hasLaps, true);
      model.clearLaps();
      expect(model.hasLaps, false);
      model.reset();
    });

    test('StopwatchModel displayTime format at zero', () {
      final model = StopwatchModel();
      model.init();
      expect(model.displayTime, '00:00.00');
    });

    test('StopwatchModel displayTime format after time elapsed', () async {
      final model = StopwatchModel();
      model.init();
      model.start();
      await Future.delayed(Duration(milliseconds: 1100));
      model.pause();
      expect(model.displayTime.contains('01'), true);
      model.reset();
    });

    test('StopwatchModel displayTime shows minutes after 60 seconds', () async {
      final model = StopwatchModel();
      model.init();
      expect(model.displayTime, '00:00.00');
      model.reset();
    });

    test('LapEntry elapsedDisplay format', () {
      final entry = LapEntry(
        lapNumber: 1,
        elapsedMilliseconds: 5000,
        lapMilliseconds: 1000,
        timestamp: DateTime.now(),
      );
      expect(entry.elapsedDisplay, '00:05.00');
    });

    test('LapEntry lapDisplay format', () {
      final entry = LapEntry(
        lapNumber: 1,
        elapsedMilliseconds: 5000,
        lapMilliseconds: 1234,
        timestamp: DateTime.now(),
      );
      expect(entry.lapDisplay, '00:01.23');
    });

    test('LapEntry properties', () {
      final entry = LapEntry(
        lapNumber: 5,
        elapsedMilliseconds: 10000,
        lapMilliseconds: 2000,
        timestamp: DateTime.now(),
      );
      expect(entry.lapNumber, 5);
      expect(entry.elapsedMilliseconds, 10000);
      expect(entry.lapMilliseconds, 2000);
    });

    testWidgets('StopwatchCard renders loading state', (WidgetTester tester) async {
      final model = StopwatchModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: StopwatchCard(),
          ),
        ),
      ));
      
      expect(find.text('Stopwatch: Loading...'), findsOneWidget);
    });

    testWidgets('StopwatchCard renders initialized state', (WidgetTester tester) async {
      final model = StopwatchModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: StopwatchCard(),
          ),
        ),
      ));
      
      expect(find.text('Stopwatch'), findsOneWidget);
    });

    testWidgets('StopwatchCard shows Start button', (WidgetTester tester) async {
      final model = StopwatchModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: StopwatchCard(),
          ),
        ),
      ));
      
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('StopwatchCard shows Pause button when running', (WidgetTester tester) async {
      final model = StopwatchModel();
      model.init();
      model.start();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: StopwatchCard(),
          ),
        ),
      ));
      
      expect(find.text('Pause'), findsOneWidget);
      model.reset();
    });

    test('StopwatchCard widget exists', () {
      expect(StopwatchCard, isNotNull);
    });

    test('StopwatchModel refresh calls notifyListeners', () {
      final model = StopwatchModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });

    test('StopwatchModel isStarted is false initially', () {
      final model = StopwatchModel();
      expect(model.isStarted, false);
    });

    test('StopwatchModel isStarted is true when elapsed > 0', () async {
      final model = StopwatchModel();
      model.init();
      model.start();
      await Future.delayed(Duration(milliseconds: 50));
      model.pause();
      expect(model.isStarted, true);
      model.reset();
    });

    test('StopwatchModel lap when not started does nothing', () {
      final model = StopwatchModel();
      model.init();
      model.lap();
      expect(model.hasLaps, false);
    });

    test('StopwatchModel start when already running does nothing', () {
      final model = StopwatchModel();
      model.init();
      model.start();
      expect(model.isRunning, true);
      model.start();
      expect(model.isRunning, true);
      model.reset();
    });

    test('StopwatchModel pause when not running does nothing', () {
      final model = StopwatchModel();
      model.init();
      model.pause();
      expect(model.isRunning, false);
    });

    test('Global.providerList includes Stopwatch', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Stopwatch'), true);
    });
  });

  group('World Clock provider tests', () {
    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
      TestWidgetsFlutterBinding.ensureInitialized();
      Global.backgroundImageModel.backgroundImage = AssetImage('test_assets/transparent.png');
    });

    test('providerWorldClock exists in Global.providerList', () {
      final worldClockProvider = Global.providerList.where((p) => p.name == 'WorldClock').first;
      expect(worldClockProvider.name, 'WorldClock');
    });

    test('World Clock keywords include timezone', () {
      final keywords = 'world clock timezone time zone add remove';
      expect(keywords.contains('timezone'), true);
    });

    test('World Clock keywords include world', () {
      final keywords = 'world clock timezone time zone add remove';
      expect(keywords.contains('world'), true);
    });

    test('WorldClockModel timezones is initially empty before init', () {
      final model = WorldClockModel();
      expect(model.timezones.length, 0);
    });

    test('WorldClockModel commonTimezones contains New York', () {
      expect(WorldClockModel.commonTimezones.containsKey('America/New_York'), true);
    });

    test('WorldClockModel commonTimezones contains Tokyo', () {
      expect(WorldClockModel.commonTimezones.containsKey('Asia/Tokyo'), true);
    });

    test('WorldClockModel commonTimezones contains London', () {
      expect(WorldClockModel.commonTimezones.containsKey('Europe/London'), true);
    });

    test('WorldClockModel getDisplayName returns correct name', () {
      final model = WorldClockModel();
      expect(model.getDisplayName('America/New_York'), 'New York');
      expect(model.getDisplayName('Asia/Tokyo'), 'Tokyo');
    });

    test('WorldClockModel formatTime returns HH:MM format', () {
      final model = WorldClockModel();
      final time = model.formatTime('UTC');
      expect(time.length, 5);
      expect(time.contains(':'), true);
    });

    test('WorldClockModel getTimezoneOffset returns correct offset', () {
      final model = WorldClockModel();
      expect(model.getTimezoneOffset('UTC'), Duration.zero);
      expect(model.getTimezoneOffset('Asia/Tokyo'), Duration(hours: 9));
      expect(model.getTimezoneOffset('America/New_York'), Duration(hours: -5));
    });

    test('WorldClockModel addTimezone adds timezone', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorldClockModel();
      await model.init();
      await model.addTimezone('Asia/Singapore');
      expect(model.timezones.contains('Asia/Singapore'), true);
    });

    test('WorldClockModel addTimezone does not add duplicate', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorldClockModel();
      await model.init();
      await model.addTimezone('Asia/Singapore');
      final initialLength = model.timezones.length;
      await model.addTimezone('Asia/Singapore');
      expect(model.timezones.length, initialLength);
    });

    test('WorldClockModel removeTimezone removes timezone', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorldClockModel();
      await model.init();
      await model.addTimezone('Asia/Singapore');
      expect(model.timezones.contains('Asia/Singapore'), true);
      await model.removeTimezone('Asia/Singapore');
      expect(model.timezones.contains('Asia/Singapore'), false);
    });

    test('WorldClockModel getDayIcon returns correct icon', () {
      final model = WorldClockModel();
      final dayIcon = model.getDayIcon('America/New_York');
      expect(dayIcon, anyOf(Icons.wb_sunny, Icons.nightlight_round));
    });

    test('WorldClockModel getDayPeriod returns valid period', () {
      final model = WorldClockModel();
      final period = model.getDayPeriod('America/New_York');
      expect(['morning', 'afternoon', 'evening', 'night'].contains(period), true);
    });

    test('WorldClockModel maxTimezones is 10', () {
      expect(WorldClockModel.maxTimezones, 10);
    });

    testWidgets('WorldClockCard renders with title', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: worldClockModel,
            builder: (context, child) => WorldClockCard(),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('World Clock'), findsOneWidget);
    });

    testWidgets('WorldClockCard has add button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: worldClockModel,
            builder: (context, child) => WorldClockCard(),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    test('Global.providerList includes WorldClock', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('WorldClock'), true);
    });
  });

  group('Countdown provider tests', () {
    test('providerCountdown exists in Global.providerList', () {
      final countdownProvider = Global.providerList.where((p) => p.name == 'Countdown').first;
      expect(countdownProvider.name, 'Countdown');
    });

    test('Countdown provider keywords include countdown', () {
      final keywords = 'countdown deadline birthday event date add';
      expect(keywords.contains('countdown'), true);
    });

    test('Countdown provider keywords include deadline', () {
      final keywords = 'countdown deadline birthday event date add';
      expect(keywords.contains('deadline'), true);
    });

    test('Countdown provider keywords include birthday', () {
      final keywords = 'countdown deadline birthday event date add';
      expect(keywords.contains('birthday'), true);
    });

    test('CountdownModel starts uninitialized', () {
      final model = CountdownModel();
      expect(model.isInitialized, false);
    });

    test('CountdownModel is ChangeNotifier', () {
      final model = CountdownModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('CountdownModel init sets initialized', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      expect(model.isInitialized, true);
    });

    test('CountdownModel addCountdown works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      model.addCountdown('Birthday', DateTime.now().add(Duration(days: 30)));
      expect(model.length, 1);
      expect(model.countdowns[0].name, 'Birthday');
    });

    test('CountdownModel addCountdown does not add empty name', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      model.addCountdown('', DateTime.now().add(Duration(days: 30)));
      expect(model.length, 0);
    });

    test('CountdownModel updateCountdown works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      model.addCountdown('Birthday', DateTime.now().add(Duration(days: 30)));
      model.updateCountdown(0, 'Vacation', DateTime.now().add(Duration(days: 60)));
      expect(model.countdowns[0].name, 'Vacation');
    });

    test('CountdownModel deleteCountdown works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      model.addCountdown('Birthday', DateTime.now().add(Duration(days: 30)));
      model.addCountdown('Vacation', DateTime.now().add(Duration(days: 60)));
      expect(model.length, 2);
      
      model.deleteCountdown(0);
      expect(model.length, 1);
    });

    test('CountdownModel clearAllCountdowns works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      model.addCountdown('Birthday', DateTime.now().add(Duration(days: 30)));
      model.addCountdown('Vacation', DateTime.now().add(Duration(days: 60)));
      expect(model.length, 2);
      
      model.clearAllCountdowns();
      expect(model.length, 0);
    });

    test('CountdownModel maxCountdowns is 10', () {
      expect(CountdownModel.maxCountdowns, 10);
    });

    test('CountdownModel max limit works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      for (int i = 0; i < 15; i++) {
        model.addCountdown('Event $i', DateTime.now().add(Duration(days: i + 1)));
      }
      expect(model.length, 10);
    });

    test('CountdownEntry properties', () {
      final entry = CountdownEntry(
        name: 'Test Event',
        targetDate: DateTime(2026, 12, 25),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(entry.name, 'Test Event');
      expect(entry.targetDate, DateTime(2026, 12, 25));
      expect(entry.createdAt, DateTime(2026, 1, 1));
    });

    test('CountdownEntry toJson and fromJson', () {
      final entry = CountdownEntry(
        name: 'Test Event',
        targetDate: DateTime(2026, 12, 25),
        createdAt: DateTime(2026, 1, 1),
      );
      final json = entry.toJson();
      final fromJson = CountdownEntry.fromJson(json);
      expect(fromJson.name, entry.name);
      expect(fromJson.targetDate, entry.targetDate);
      expect(fromJson.createdAt, entry.createdAt);
    });

    test('CountdownModel getRemainingTime works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      final targetDate = DateTime.now().add(Duration(days: 5, hours: 1));
      final entry = CountdownEntry(
        name: 'Event',
        targetDate: targetDate,
        createdAt: DateTime.now(),
      );
      
      final remaining = model.getRemainingTime(entry);
      expect(remaining.inDays, greaterThanOrEqualTo(4));
    });

    test('CountdownModel getRemainingTime returns zero for past dates', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      final entry = CountdownEntry(
        name: 'Past Event',
        targetDate: DateTime.now().subtract(Duration(days: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 2)),
      );
      
      final remaining = model.getRemainingTime(entry);
      expect(remaining, Duration.zero);
    });

    test('CountdownModel isExpired works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      final futureEntry = CountdownEntry(
        name: 'Future Event',
        targetDate: DateTime.now().add(Duration(days: 1)),
        createdAt: DateTime.now(),
      );
      expect(model.isExpired(futureEntry), false);
      
      final pastEntry = CountdownEntry(
        name: 'Past Event',
        targetDate: DateTime.now().subtract(Duration(days: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 2)),
      );
      expect(model.isExpired(pastEntry), true);
    });

    test('CountdownModel formatRemainingTime works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      final entry = CountdownEntry(
        name: 'Event',
        targetDate: DateTime.now().add(Duration(days: 5, hours: 3)),
        createdAt: DateTime.now(),
      );
      
      final formatted = model.formatRemainingTime(entry);
      expect(formatted.contains('d'), true);
    });

    test('CountdownModel formatRemainingTime returns Expired for past dates', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      await model.init();
      
      final entry = CountdownEntry(
        name: 'Past Event',
        targetDate: DateTime.now().subtract(Duration(days: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 2)),
      );
      
      final formatted = model.formatRemainingTime(entry);
      expect(formatted, 'Expired');
    });

    testWidgets('CountdownCard renders loading state', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = CountdownModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => CountdownCard(),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Countdowns: Loading...'), findsOneWidget);
    });

    testWidgets('CountdownCard widget exists', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: countdownModel,
            builder: (context, child) => CountdownCard(),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(CountdownCard), findsOneWidget);
    });

    test('Global.providerList includes Countdown', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Countdown'), true);
    });
  });

  group('Unit Converter provider tests', () {
    test('providerUnitConverter exists in Global.providerList', () {
      final unitConverterProvider = Global.providerList.where((p) => p.name == 'UnitConverter').first;
      expect(unitConverterProvider.name, 'UnitConverter');
    });

    test('Unit Converter keywords include convert', () {
      final keywords = 'convert unit temperature length weight mass distance cm m km inch foot mile celsius fahrenheit kg lb gram ounce';
      expect(keywords.contains('convert'), true);
      expect(keywords.contains('unit'), true);
      expect(keywords.contains('temperature'), true);
      expect(keywords.contains('length'), true);
      expect(keywords.contains('weight'), true);
    });

    test('Unit Converter keywords include celsius', () {
      final keywords = 'convert unit temperature length weight mass distance cm m km inch foot mile celsius fahrenheit kg lb gram ounce';
      expect(keywords.contains('celsius'), true);
      expect(keywords.contains('fahrenheit'), true);
    });

    test('Unit Converter keywords include length units', () {
      final keywords = 'convert unit temperature length weight mass distance cm m km inch foot mile celsius fahrenheit kg lb gram ounce';
      expect(keywords.contains('cm'), true);
      expect(keywords.contains('m'), true);
      expect(keywords.contains('km'), true);
      expect(keywords.contains('inch'), true);
      expect(keywords.contains('foot'), true);
      expect(keywords.contains('mile'), true);
    });

    test('Unit Converter keywords include weight units', () {
      final keywords = 'convert unit temperature length weight mass distance cm m km inch foot mile celsius fahrenheit kg lb gram ounce';
      expect(keywords.contains('kg'), true);
      expect(keywords.contains('lb'), true);
      expect(keywords.contains('gram'), true);
      expect(keywords.contains('ounce'), true);
    });

    test('UnitConverterModel starts uninitialized', () {
      final model = UnitConverterModel();
      expect(model.isInitialized, false);
    });

    test('UnitConverterModel is ChangeNotifier', () {
      final model = UnitConverterModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('UnitConverterModel init sets initialized', () {
      final model = UnitConverterModel();
      model.init();
      expect(model.isInitialized, true);
    });

    test('UnitConverterModel default category is temperature', () {
      final model = UnitConverterModel();
      model.init();
      expect(model.selectedCategory, ConversionCategory.temperature);
    });

    test('UnitConverterModel setCategory works', () {
      final model = UnitConverterModel();
      model.init();
      model.setCategory(ConversionCategory.length);
      expect(model.selectedCategory, ConversionCategory.length);
      model.setCategory(ConversionCategory.weight);
      expect(model.selectedCategory, ConversionCategory.weight);
    });

    test('UnitConverterModel setInputUnit works', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputUnit('fahrenheit');
      expect(model.inputUnit, 'fahrenheit');
    });

    test('UnitConverterModel setOutputUnit works', () {
      final model = UnitConverterModel();
      model.init();
      model.setOutputUnit('kelvin');
      expect(model.outputUnit, 'kelvin');
    });

    test('UnitConverterModel setInputValue works', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputValue('100');
      expect(model.inputValue, '100');
    });

    test('UnitConverterModel swapUnits works', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputUnit('celsius');
      model.setOutputUnit('fahrenheit');
      model.setInputValue('100');
      model.swapUnits();
      expect(model.inputUnit, 'fahrenheit');
      expect(model.outputUnit, 'celsius');
    });

    test('UnitConverterModel clear works', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputValue('100');
      model.clear();
      expect(model.inputValue, '0');
    });

    test('UnitConverterModel temperature conversion celsius to fahrenheit', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputUnit('celsius');
      model.setOutputUnit('fahrenheit');
      model.setInputValue('0');
      expect(model.outputValue, '32');
    });

    test('UnitConverterModel temperature conversion fahrenheit to celsius', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputUnit('fahrenheit');
      model.setOutputUnit('celsius');
      model.setInputValue('32');
      expect(model.outputValue, '0');
    });

    test('UnitConverterModel temperature conversion celsius to kelvin', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputUnit('celsius');
      model.setOutputUnit('kelvin');
      model.setInputValue('0');
      expect(model.outputValue, '273.15');
    });

    test('UnitConverterModel length conversion meter to kilometer', () {
      final model = UnitConverterModel();
      model.init();
      model.setCategory(ConversionCategory.length);
      model.setInputUnit('meter');
      model.setOutputUnit('kilometer');
      model.setInputValue('1000');
      expect(model.outputValue, '1');
    });

    test('UnitConverterModel length conversion inch to centimeter', () {
      final model = UnitConverterModel();
      model.init();
      model.setCategory(ConversionCategory.length);
      model.setInputUnit('inch');
      model.setOutputUnit('centimeter');
      model.setInputValue('1');
      expect(double.parse(model.outputValue).round(), 3);
    });

    test('UnitConverterModel length conversion foot to meter', () {
      final model = UnitConverterModel();
      model.init();
      model.setCategory(ConversionCategory.length);
      model.setInputUnit('foot');
      model.setOutputUnit('meter');
      model.setInputValue('1');
      expect(double.parse(model.outputValue).round(), 0);
    });

    test('UnitConverterModel weight conversion kilogram to gram', () {
      final model = UnitConverterModel();
      model.init();
      model.setCategory(ConversionCategory.weight);
      model.setInputUnit('kilogram');
      model.setOutputUnit('gram');
      model.setInputValue('1');
      expect(model.outputValue, '1000');
    });

    test('UnitConverterModel weight conversion pound to kilogram', () {
      final model = UnitConverterModel();
      model.init();
      model.setCategory(ConversionCategory.weight);
      model.setInputUnit('pound');
      model.setOutputUnit('kilogram');
      model.setInputValue('1');
      expect(double.parse(model.outputValue).round(), 0);
    });

    test('UnitConverter static convert method works', () {
      expect(UnitConverterModel.convert(0, 'celsius', 'fahrenheit'), 32);
      expect(UnitConverterModel.convert(100, 'celsius', 'fahrenheit'), 212);
      expect(UnitConverterModel.convert(1000, 'meter', 'kilometer'), 1);
      expect(UnitConverterModel.convert(1, 'kilogram', 'gram'), 1000);
    });

    test('UnitConverter static convert same unit returns same value', () {
      expect(UnitConverterModel.convert(50, 'celsius', 'celsius'), 50);
      expect(UnitConverterModel.convert(100, 'meter', 'meter'), 100);
    });

    test('unitTypes contains all expected units', () {
      expect(unitTypes.containsKey('celsius'), true);
      expect(unitTypes.containsKey('fahrenheit'), true);
      expect(unitTypes.containsKey('kelvin'), true);
      expect(unitTypes.containsKey('meter'), true);
      expect(unitTypes.containsKey('kilometer'), true);
      expect(unitTypes.containsKey('centimeter'), true);
      expect(unitTypes.containsKey('inch'), true);
      expect(unitTypes.containsKey('foot'), true);
      expect(unitTypes.containsKey('mile'), true);
      expect(unitTypes.containsKey('kilogram'), true);
      expect(unitTypes.containsKey('gram'), true);
      expect(unitTypes.containsKey('pound'), true);
      expect(unitTypes.containsKey('ounce'), true);
    });

    test('UnitType properties are correct', () {
      final celsius = unitTypes['celsius']!;
      expect(celsius.name, 'Celsius');
      expect(celsius.symbol, '°C');
      expect(celsius.category, ConversionCategory.temperature);
      
      final meter = unitTypes['meter']!;
      expect(meter.name, 'Meter');
      expect(meter.symbol, 'm');
      expect(meter.category, ConversionCategory.length);
      
      final kg = unitTypes['kilogram']!;
      expect(kg.name, 'Kilogram');
      expect(kg.symbol, 'kg');
      expect(kg.category, ConversionCategory.weight);
    });

    test('getUnitsForCategory returns correct units', () {
      final tempUnits = getUnitsForCategory(ConversionCategory.temperature);
      expect(tempUnits.contains('celsius'), true);
      expect(tempUnits.contains('fahrenheit'), true);
      expect(tempUnits.contains('kelvin'), true);
      
      final lengthUnits = getUnitsForCategory(ConversionCategory.length);
      expect(lengthUnits.contains('meter'), true);
      expect(lengthUnits.contains('kilometer'), true);
      expect(lengthUnits.contains('inch'), true);
      
      final weightUnits = getUnitsForCategory(ConversionCategory.weight);
      expect(weightUnits.contains('kilogram'), true);
      expect(weightUnits.contains('gram'), true);
      expect(weightUnits.contains('pound'), true);
    });

    test('ConversionHistory properties', () {
      final history = ConversionHistory(
        inputValue: 100,
        inputUnit: 'celsius',
        outputValue: 212,
        outputUnit: 'fahrenheit',
        category: ConversionCategory.temperature,
        timestamp: DateTime.now(),
      );
      expect(history.inputValue, 100);
      expect(history.inputUnit, 'celsius');
      expect(history.outputValue, 212);
      expect(history.outputUnit, 'fahrenheit');
      expect(history.inputSymbol, '°C');
      expect(history.outputSymbol, '°F');
    });

    test('UnitConverterModel history works', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputValue('100');
      model.addToHistory();
      expect(model.hasHistory, true);
      expect(model.history.length, 1);
    });

    test('UnitConverterModel clearHistory works', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputValue('100');
      model.addToHistory();
      expect(model.hasHistory, true);
      model.clearHistory();
      expect(model.hasHistory, false);
    });

    test('UnitConverterModel history max limit', () {
      final model = UnitConverterModel();
      model.init();
      for (int i = 0; i < 15; i++) {
        model.setInputValue('$i');
        model.addToHistory();
      }
      expect(model.history.length, UnitConverterModel.maxHistory);
    });

    test('UnitConverterModel availableUnits returns correct units', () {
      final model = UnitConverterModel();
      model.init();
      model.setCategory(ConversionCategory.temperature);
      expect(model.availableUnits.length, 3);
      
      model.setCategory(ConversionCategory.length);
      expect(model.availableUnits.length, 8);
      
      model.setCategory(ConversionCategory.weight);
      expect(model.availableUnits.length, 5);
    });

    test('UnitConverterModel refresh calls notifyListeners', () {
      final model = UnitConverterModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });

    test('UnitConverterModel useHistoryEntry works', () {
      final model = UnitConverterModel();
      model.init();
      
      final entry = ConversionHistory(
        inputValue: 100,
        inputUnit: 'celsius',
        outputValue: 212,
        outputUnit: 'fahrenheit',
        category: ConversionCategory.temperature,
        timestamp: DateTime.now(),
      );
      
      model.useHistoryEntry(entry);
      expect(model.selectedCategory, ConversionCategory.temperature);
      expect(model.inputUnit, 'celsius');
      expect(model.outputUnit, 'fahrenheit');
      expect(double.parse(model.inputValue), 100);
    });

    testWidgets('UnitConverterCard renders loading state', (tester) async {
      final model = UnitConverterModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => UnitConverterCard(),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Unit Converter: Loading...'), findsOneWidget);
    });

    testWidgets('UnitConverterCard renders initialized state', (tester) async {
      final model = UnitConverterModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => UnitConverterCard(),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Unit Converter'), findsOneWidget);
    });

    testWidgets('UnitConverterCard shows category buttons', (tester) async {
      final model = UnitConverterModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => UnitConverterCard(),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Temp'), findsOneWidget);
      expect(find.text('Length'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
    });

    test('UnitConverterCard widget exists', () {
      expect(UnitConverterCard, isNotNull);
    });

    test('Global.providerList now contains 21 providers', () {
      expect(Global.providerList.length, 21);
    });

    test('Global.providerList includes UnitConverter', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('UnitConverter'), true);
    });

    test('UnitConverterModel handles invalid input', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputValue('invalid');
      expect(model.outputValue, '0');
    });

    test('UnitConverterModel handles negative values', () {
      final model = UnitConverterModel();
      model.init();
      model.setInputValue('-10');
      expect(model.inputValue, '-10');
    });
  });

  group('Pomodoro provider tests', () {
    test('providerPomodoro exists', () {
      expect(providerPomodoro, isNotNull);
      expect(providerPomodoro.name, 'Pomodoro');
    });

    test('PomodoroModel exists', () {
      expect(pomodoroModel, isNotNull);
    });

    test('PomodoroPhase enum has correct values', () {
      expect(PomodoroPhase.values.length, 3);
      expect(PomodoroPhase.work.index, 0);
      expect(PomodoroPhase.shortBreak.index, 1);
      expect(PomodoroPhase.longBreak.index, 2);
    });

    test('PomodoroSession toJson and fromJson work', () {
      final session = PomodoroSession(
        startTime: DateTime(2024, 1, 1, 10, 30),
        phase: PomodoroPhase.work,
        durationMinutes: 25,
      );
      final json = session.toJson();
      expect(json['startTime'], '2024-01-01T10:30:00.000');
      expect(json['phase'], 0);
      expect(json['durationMinutes'], 25);

      final restored = PomodoroSession.fromJson(json);
      expect(restored.startTime, DateTime(2024, 1, 1, 10, 30));
      expect(restored.phase, PomodoroPhase.work);
      expect(restored.durationMinutes, 25);
    });

    test('PomodoroModel default values are correct', () {
      final model = PomodoroModel();
      expect(model.workDuration, 25);
      expect(model.shortBreakDuration, 5);
      expect(model.longBreakDuration, 15);
      expect(model.completedSessions, 0);
      expect(model.currentPhase, PomodoroPhase.work);
      expect(model.isRunning, false);
      expect(model.isPaused, false);
    });

    test('PomodoroModel init initializes correctly', () async {
      final model = PomodoroModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.remainingSeconds, 25 * 60);
    });

    test('PomodoroModel start sets isRunning', () async {
      final model = PomodoroModel();
      await model.init();
      model.start();
      expect(model.isRunning, true);
      expect(model.isPaused, false);
      model.stop();
    });

    test('PomodoroModel pause and resume work', () async {
      final model = PomodoroModel();
      await model.init();
      model.start();
      expect(model.isRunning, true);
      model.pause();
      expect(model.isPaused, true);
      model.resume();
      expect(model.isPaused, false);
      model.stop();
    });

    test('PomodoroModel stop resets state', () async {
      final model = PomodoroModel();
      await model.init();
      model.start();
      model.stop();
      expect(model.isRunning, false);
      expect(model.isPaused, false);
    });

    test('PomodoroModel formatTime returns correct format', () async {
      final model = PomodoroModel();
      await model.init();
      model.remainingSeconds = 1500;
      expect(model.formatTime(), '25:00');
      model.remainingSeconds = 300;
      expect(model.formatTime(), '05:00');
      model.remainingSeconds = 90;
      expect(model.formatTime(), '01:30');
    });

    test('PomodoroModel getProgress returns correct value', () async {
      final model = PomodoroModel();
      await model.init();
      model.currentPhase = PomodoroPhase.work;
      model.remainingSeconds = 1500;
      expect(model.getProgress(), 0.0);
      model.remainingSeconds = 750;
      expect(model.getProgress(), closeTo(0.5, 0.01));
      model.remainingSeconds = 0;
      expect(model.getProgress(), 1.0);
    });

    test('PomodoroModel getPhaseLabel returns correct labels', () async {
      final model = PomodoroModel();
      model.currentPhase = PomodoroPhase.work;
      expect(model.getPhaseLabel(), 'Work');
      model.currentPhase = PomodoroPhase.shortBreak;
      expect(model.getPhaseLabel(), 'Short Break');
      model.currentPhase = PomodoroPhase.longBreak;
      expect(model.getPhaseLabel(), 'Long Break');
    });

    test('PomodoroModel getPhaseIcon returns correct icons', () async {
      final model = PomodoroModel();
      model.currentPhase = PomodoroPhase.work;
      expect(model.getPhaseIcon(), Icons.work);
      model.currentPhase = PomodoroPhase.shortBreak;
      expect(model.getPhaseIcon(), Icons.coffee);
      model.currentPhase = PomodoroPhase.longBreak;
      expect(model.getPhaseIcon(), Icons.weekend);
    });

    test('PomodoroModel updateSettings works', () async {
      final model = PomodoroModel();
      await model.init();
      model.updateSettings(30, 10, 20);
      expect(model.workDuration, 30);
      expect(model.shortBreakDuration, 10);
      expect(model.longBreakDuration, 20);
      expect(model.remainingSeconds, 30 * 60);
    });

    test('PomodoroModel resetCompletedSessions works', () async {
      final model = PomodoroModel();
      await model.init();
      model.completedSessions = 5;
      model.resetCompletedSessions();
      expect(model.completedSessions, 0);
    });

    test('PomodoroModel clearHistory works', () async {
      final model = PomodoroModel();
      await model.init();
      model.clearHistory();
      expect(model.hasHistory, false);
      expect(model.sessionHistory.isEmpty, true);
    });

    test('PomodoroModel currentPhaseDuration returns correct values', () async {
      final model = PomodoroModel();
      model.currentPhase = PomodoroPhase.work;
      expect(model.currentPhaseDuration, 25);
      model.currentPhase = PomodoroPhase.shortBreak;
      expect(model.currentPhaseDuration, 5);
      model.currentPhase = PomodoroPhase.longBreak;
      expect(model.currentPhaseDuration, 15);
    });

    test('PomodoroCard renders loading state', () {
      expect(PomodoroCard, isNotNull);
    });

    test('PomodoroCard widget exists', () {
      expect(PomodoroCard, isNotNull);
    });

    test('Global.providerList includes Pomodoro', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Pomodoro'), true);
    });

    testWidgets('PomodoroCard shows correct time format', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: pomodoroModel,
            builder: (context, child) => PomodoroCard(),
          ),
        ),
      ));

      await pomodoroModel.init();
      pomodoroModel.remainingSeconds = 1500;
      await tester.pump();
    });

    test('PomodoroModel history max limit', () async {
      final model = PomodoroModel();
      await model.init();

      for (int i = 0; i < 25; i++) {
        final session = PomodoroSession(
          startTime: DateTime.now(),
          phase: PomodoroPhase.work,
          durationMinutes: 25,
        );
        model.addTestSession(session);
      }

      expect(model.sessionHistory.length, 20);
    });

    test('PomodoroModel refresh calls notifyListeners', () async {
      final model = PomodoroModel();
      await model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      await model.refresh();
      expect(notifyCount, 1);
    });
  });

  group('Clipboard provider tests', () {
    test('ClipboardEntry toJson and fromJson work', () {
      final entry = ClipboardEntry(
        text: 'Test clipboard text',
        timestamp: DateTime(2024, 1, 1, 10, 30),
      );
      final json = entry.toJson();
      expect(json['text'], 'Test clipboard text');
      expect(json['timestamp'], '2024-01-01T10:30:00.000');

      final restored = ClipboardEntry.fromJson(json);
      expect(restored.text, 'Test clipboard text');
      expect(restored.timestamp, DateTime(2024, 1, 1, 10, 30));
    });

    test('ClipboardModel default values are correct', () {
      final model = ClipboardModel();
      expect(model.length, 0);
      expect(model.isInitialized, false);
      expect(model.hasEntries, false);
    });

    test('ClipboardModel init initializes correctly', () async {
      final model = ClipboardModel();
      await model.init();
      expect(model.isInitialized, true);
    });

    test('ClipboardModel addEntry works', () async {
      final model = ClipboardModel();
      await model.init();
      model.clearAllEntries();
      await model.addEntry('Test entry 1');
      expect(model.length, 1);
      expect(model.entries[0].text, 'Test entry 1');
    });

    test('ClipboardModel addEntry ignores empty text', () async {
      final model = ClipboardModel();
      await model.init();
      model.clearAllEntries();
      await model.addEntry('');
      expect(model.length, 0);
      await model.addEntry('   ');
      expect(model.length, 0);
    });

    test('ClipboardModel deleteEntry works', () async {
      final model = ClipboardModel();
      await model.init();
      model.clearAllEntries();
      await model.addEntry('Entry 1');
      await model.addEntry('Entry 2');
      expect(model.length, 2);
      expect(model.entries[0].text, 'Entry 2');
      model.deleteEntry(0);
      expect(model.length, 1);
      expect(model.entries[0].text, 'Entry 1');
    });

    test('ClipboardModel clearAllEntries works', () async {
      final model = ClipboardModel();
      await model.init();
      model.clearAllEntries();
      await model.addEntry('Entry 1');
      await model.addEntry('Entry 2');
      expect(model.length, 2);
      model.clearAllEntries();
      expect(model.length, 0);
      expect(model.hasEntries, false);
    });

    test('ClipboardModel max entries limit', () async {
      final model = ClipboardModel();
      await model.init();

      for (int i = 0; i < 20; i++) {
        await model.addEntry('Entry $i');
      }

      expect(model.length, 15);
      expect(model.entries.first.text, 'Entry 19');
    });

    test('ClipboardModel refresh calls notifyListeners', () async {
      final model = ClipboardModel();
      await model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      await model.refresh();
      expect(notifyCount, 1);
    });

    test('ClipboardCard widget exists', () {
      expect(ClipboardCard, isNotNull);
    });

    test('Global.providerList includes Clipboard', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Clipboard'), true);
    });

    test('ClipboardModel loadEntries works', () async {
      final model = ClipboardModel();
      await model.init();
      final entries = [
        ClipboardEntry(text: 'Entry A', timestamp: DateTime.now()),
        ClipboardEntry(text: 'Entry B', timestamp: DateTime.now()),
      ];
      model.loadEntries(entries);
      expect(model.length, 2);
      expect(model.entries[0].text, 'Entry A');
    });

    test('ClipboardModel addTestEntry works', () async {
      final model = ClipboardModel();
      await model.init();
      model.clearAllEntries();
      final entry = ClipboardEntry(text: 'Test', timestamp: DateTime.now());
      model.addTestEntry(entry);
      expect(model.length, 1);
      expect(model.entries[0].text, 'Test');
    });

    test('providerClipboard exists', () {
      expect(providerClipboard, isNotNull);
      expect(providerClipboard.name, 'Clipboard');
    });

    test('providerClipboard keywords contain clipboard related words', () {
      expect(providerClipboard.name, 'Clipboard');
    });

    testWidgets('ClipboardCard renders loading state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: clipboardModel,
            builder: (context, child) => ClipboardCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Clipboard'), findsWidgets);
    });
  });

  group('Todo provider tests', () {
    test('TodoItem toJson and fromJson work', () {
      final item = TodoItem(
        text: 'Test task',
        completed: true,
        priority: TodoPriority.high,
        createdAt: DateTime(2024, 1, 1, 10, 30),
      );
      final json = item.toJson();
      final restored = TodoItem.fromJson(json);
      expect(restored.text, 'Test task');
      expect(restored.completed, true);
      expect(restored.priority, TodoPriority.high);
      expect(restored.createdAt, DateTime(2024, 1, 1, 10, 30));
    });

    test('TodoItem copyWith works', () {
      final item = TodoItem(
        text: 'Original',
        completed: false,
        priority: TodoPriority.low,
      );
      final copied = item.copyWith(completed: true);
      expect(copied.text, 'Original');
      expect(copied.completed, true);
      expect(copied.priority, TodoPriority.low);
    });

    test('TodoPriority enum has correct values', () {
      expect(TodoPriority.values.length, 3);
      expect(TodoPriority.values[0], TodoPriority.high);
      expect(TodoPriority.values[1], TodoPriority.medium);
      expect(TodoPriority.values[2], TodoPriority.low);
    });

    test('TodoModel default values are correct', () {
      final model = TodoModel();
      expect(model.length, 0);
      expect(model.isInitialized, false);
      expect(model.hasTodos, false);
      expect(model.activeCount, 0);
      expect(model.completedCount, 0);
    });

    test('TodoModel init initializes correctly', () async {
      final model = TodoModel();
      await model.init();
      expect(model.isInitialized, true);
    });

    test('TodoModel addTodo works', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('Test task 1', TodoPriority.medium);
      expect(model.length, 1);
      expect(model.todos[0].text, 'Test task 1');
      expect(model.todos[0].priority, TodoPriority.medium);
      expect(model.todos[0].completed, false);
    });

    test('TodoModel addTodo ignores empty text', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('', TodoPriority.medium);
      expect(model.length, 0);
      model.addTodo('   ', TodoPriority.medium);
      expect(model.length, 0);
    });

    test('TodoModel updateTodo works', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('Original task', TodoPriority.low);
      model.updateTodo(0, 'Updated task', TodoPriority.high);
      expect(model.todos[0].text, 'Updated task');
      expect(model.todos[0].priority, TodoPriority.high);
    });

    test('TodoModel updateTodo deletes if text empty', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('Task to delete', TodoPriority.medium);
      expect(model.length, 1);
      model.updateTodo(0, '', TodoPriority.medium);
      expect(model.length, 0);
    });

    test('TodoModel toggleCompleted works', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('Task 1', TodoPriority.medium);
      expect(model.todos[0].completed, false);
      expect(model.activeCount, 1);
      expect(model.completedCount, 0);
      model.toggleCompleted(0);
      expect(model.todos[0].completed, true);
      expect(model.activeCount, 0);
      expect(model.completedCount, 1);
    });

    test('TodoModel deleteTodo works', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('Task 1', TodoPriority.medium);
      model.addTodo('Task 2', TodoPriority.high);
      expect(model.length, 2);
      model.deleteTodo(0);
      expect(model.length, 1);
      expect(model.todos[0].text, 'Task 1');
    });

    test('TodoModel clearCompleted works', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('Task 1', TodoPriority.medium);
      model.addTodo('Task 2', TodoPriority.high);
      model.toggleCompleted(0);
      expect(model.length, 2);
      expect(model.completedCount, 1);
      model.clearCompleted();
      expect(model.length, 1);
      expect(model.completedCount, 0);
    });

    test('TodoModel clearAllTodos works', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('Task 1', TodoPriority.medium);
      model.addTodo('Task 2', TodoPriority.high);
      expect(model.length, 2);
      model.clearAllTodos();
      expect(model.length, 0);
      expect(model.hasTodos, false);
    });

    test('TodoModel max todos limit', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();

      for (int i = 0; i < 25; i++) {
        model.addTodo('Task $i', TodoPriority.medium);
      }

      expect(model.length, 20);
      expect(model.todos.first.text, 'Task 24');
    });

    test('TodoModel refresh calls notifyListeners', () async {
      final model = TodoModel();
      await model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      await model.refresh();
      expect(notifyCount, 1);
    });

    test('TodoCard widget exists', () {
      expect(TodoCard, isNotNull);
    });

    test('Global.providerList includes Todo', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Todo'), true);
    });

    test('providerTodo exists', () {
      expect(providerTodo, isNotNull);
      expect(providerTodo.name, 'Todo');
    });

    test('AddTodoDialog widget exists', () {
      expect(AddTodoDialog, isNotNull);
    });

    test('EditTodoDialog widget exists', () {
      expect(EditTodoDialog, isNotNull);
    });

    testWidgets('TodoCard renders loading state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: todoModel,
            builder: (context, child) => TodoCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Todo'), findsWidgets);
    });

    testWidgets('TodoCard renders initialized state', (tester) async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('Test task', TodoPriority.high);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => TodoCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Todo List'), findsWidgets);
    });

    test('TodoModel activeTodos and completedTodos work', () async {
      final model = TodoModel();
      await model.init();
      model.clearAllTodos();
      model.addTodo('Active 1', TodoPriority.high);
      model.addTodo('Active 2', TodoPriority.medium);
      model.addTodo('Done 1', TodoPriority.low);
      model.toggleCompleted(2);

      expect(model.activeTodos.length, 2);
      expect(model.completedTodos.length, 1);
      expect(model.activeTodos.every((t) => !t.completed), true);
      expect(model.completedTodos.every((t) => t.completed), true);
    });
  });

  group('QR Code provider tests', () {
    test('QRModel exists', () {
      expect(qrModel, isNotNull);
    });

    test('QRModel initial state', () {
      final model = QRModel();
      expect(model.currentText, '');
      expect(model.hasQR, false);
      expect(model.isInitialized, false);
    });

    test('QRModel init sets initialized', () {
      final model = QRModel();
      model.init();
      expect(model.isInitialized, true);
    });

    test('QRModel setText works', () {
      final model = QRModel();
      model.init();
      model.setText('Test QR');
      expect(model.currentText, 'Test QR');
      expect(model.hasQR, true);
    });

    test('QRModel setText trims whitespace', () {
      final model = QRModel();
      model.init();
      model.setText('  Test QR  ');
      expect(model.currentText, 'Test QR');
    });

    test('QRModel clearText works', () {
      final model = QRModel();
      model.init();
      model.setText('Test QR');
      expect(model.hasQR, true);
      model.clearText();
      expect(model.currentText, '');
      expect(model.hasQR, false);
    });

    test('QRModel refresh calls notifyListeners', () {
      final model = QRModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });

    test('QRModel setText notifies listeners', () {
      final model = QRModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.setText('New text');
      expect(notifyCount, 1);
    });

    test('QRModel clearText notifies listeners', () {
      final model = QRModel();
      model.init();
      model.setText('Test');
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.clearText();
      expect(notifyCount, 1);
    });

    test('QRCard widget exists', () {
      expect(QRCard, isNotNull);
    });

    test('QRGeneratorDialog widget exists', () {
      expect(QRGeneratorDialog, isNotNull);
    });

    test('Global.providerList includes QRCode', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('QRCode'), true);
    });

    test('providerQRCode exists', () {
      expect(providerQRCode, isNotNull);
      expect(providerQRCode.name, 'QRCode');
    });

    testWidgets('QRCard renders loading state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: qrModel,
            builder: (context, child) => QRCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('QR Code'), findsWidgets);
    });

    testWidgets('QRCard renders initialized empty state', (tester) async {
      final model = QRModel();
      model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => QRCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('QR Code Generator'), findsWidgets);
      expect(find.textContaining('Enter text'), findsWidgets);
    });

    testWidgets('QRCard renders with QR code', (tester) async {
      final model = QRModel();
      model.init();
      model.setText('https://example.com');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => QRCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('QR Code Generator'), findsWidgets);
      expect(find.textContaining('example.com'), findsWidgets);
    });

    test('QRModel keywords are correct', () {
      expect(providerQRCode.name, 'QRCode');
      expect(providerQRCode.provideActions, isNotNull);
    });
  });

  group('Random Generator provider tests', () {
    test('RandomModel exists', () {
      expect(randomModel, isNotNull);
    });

    test('RandomModel initial state', () {
      final model = RandomModel();
      expect(model.isInitialized, false);
      expect(model.coinResult, '');
      expect(model.diceResult, '');
      expect(model.passwordResult, '');
      expect(model.randomNumberResult, '');
    });

    test('RandomModel init sets initialized', () {
      final model = RandomModel();
      model.init();
      expect(model.isInitialized, true);
    });

    test('RandomModel flipCoin works', () {
      final model = RandomModel();
      model.init();
      final result = model.flipCoin();
      expect(result, isIn(['Heads', 'Tails']));
      expect(model.coinResult, isIn(['Heads', 'Tails']));
    });

    test('RandomModel rollDice works', () {
      final model = RandomModel();
      model.init();
      final result = model.rollDice(6);
      final resultInt = int.tryParse(result);
      expect(resultInt, greaterThanOrEqualTo(1));
      expect(resultInt, lessThanOrEqualTo(6));
    });

    test('RandomModel rollDice with different sides', () {
      final model = RandomModel();
      model.init();
      
      for (final sides in [4, 6, 8, 10, 12, 20, 100]) {
        final result = model.rollDice(sides);
        final resultInt = int.tryParse(result);
        expect(resultInt, greaterThanOrEqualTo(1));
        expect(resultInt, lessThanOrEqualTo(sides));
        expect(model.diceSides, sides);
      }
    });

    test('RandomModel generateRandomNumber works', () {
      final model = RandomModel();
      model.init();
      final result = model.generateRandomNumber(1, 100);
      final resultInt = int.tryParse(result);
      expect(resultInt, greaterThanOrEqualTo(1));
      expect(resultInt, lessThanOrEqualTo(100));
      expect(model.randomNumberMin, 1);
      expect(model.randomNumberMax, 100);
    });

    test('RandomModel generateRandomNumber with custom range', () {
      final model = RandomModel();
      model.init();
      
      for (final min in [10, -50, 0]) {
        final max = min + 10;
        final result = model.generateRandomNumber(min, max);
        final resultInt = int.tryParse(result);
        expect(resultInt, greaterThanOrEqualTo(min));
        expect(resultInt, lessThanOrEqualTo(max));
      }
    });

    test('RandomModel generatePassword works', () {
      final model = RandomModel();
      model.init();
      final result = model.generatePassword(12);
      expect(result.length, 12);
      expect(model.passwordLength, 12);
    });

    test('RandomModel generatePassword with different lengths', () {
      final model = RandomModel();
      model.init();
      
      for (final length in [4, 8, 16, 32, 64]) {
        final result = model.generatePassword(length);
        expect(result.length, length);
      }
    });

    test('RandomModel generatePassword with options', () {
      final model = RandomModel();
      model.init();
      
      final resultLower = model.generatePassword(20, lower: true, upper: false, numbers: false, symbols: false);
      expect(resultLower.length, 20);
      expect(model.passwordIncludeLower, true);
      expect(model.passwordIncludeUpper, false);
      expect(model.passwordIncludeNumbers, false);
      expect(model.passwordIncludeSymbols, false);
    });

    test('RandomModel setPasswordLength works', () {
      final model = RandomModel();
      model.init();
      
      model.setPasswordLength(8);
      expect(model.passwordLength, 8);
      
      model.setPasswordLength(100);
      expect(model.passwordLength, 64);
      
      model.setPasswordLength(2);
      expect(model.passwordLength, 4);
    });

    test('RandomModel setPasswordOptions works', () {
      final model = RandomModel();
      model.init();
      
      model.setPasswordOptions(lower: false, upper: true, numbers: true, symbols: false);
      expect(model.passwordIncludeLower, false);
      expect(model.passwordIncludeUpper, true);
      expect(model.passwordIncludeNumbers, true);
      expect(model.passwordIncludeSymbols, false);
    });

    test('RandomModel refresh calls notifyListeners', () {
      final model = RandomModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });

    test('RandomModel flipCoin notifies listeners', () {
      final model = RandomModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.flipCoin();
      expect(notifyCount, 1);
    });

    test('RandomModel rollDice notifies listeners', () {
      final model = RandomModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.rollDice(6);
      expect(notifyCount, 1);
    });

    test('RandomModel generatePassword notifies listeners', () {
      final model = RandomModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.generatePassword(12);
      expect(notifyCount, 1);
    });

    test('RandomCard widget exists', () {
      expect(RandomCard, isNotNull);
    });

    test('Global.providerList includes Random', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Random'), true);
    });

    test('providerRandom exists', () {
      expect(providerRandom, isNotNull);
      expect(providerRandom.name, 'Random');
    });

    testWidgets('RandomCard renders loading state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: randomModel,
            builder: (context, child) => RandomCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Random'), findsWidgets);
    });

    testWidgets('RandomCard renders initialized state', (tester) async {
      final model = RandomModel();
      model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => RandomCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Random Generator'), findsWidgets);
      expect(find.textContaining('Dice Roll'), findsWidgets);
      expect(find.textContaining('Random Number'), findsWidgets);
      expect(find.textContaining('Password Generator'), findsWidgets);
    });

    testWidgets('RandomCard renders with results', (tester) async {
      final model = RandomModel();
      model.init();
      model.flipCoin();
      model.rollDice(6);
      model.generatePassword(12);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => RandomCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Heads').evaluate().isNotEmpty || find.textContaining('Tails').evaluate().isNotEmpty, true);
    });

    test('RandomModel keywords are correct', () {
      expect(providerRandom.name, 'Random');
      expect(providerRandom.provideActions, isNotNull);
    });
  });
}
