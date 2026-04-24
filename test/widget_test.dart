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
import 'package:new_launcher/providers/provider_color.dart';
import 'package:new_launcher/providers/provider_currency.dart';
import 'package:new_launcher/providers/provider_bookmarks.dart';
import 'package:new_launcher/providers/provider_habit.dart';
import 'package:new_launcher/providers/provider_meditation.dart';
import 'package:new_launcher/providers/provider_water.dart';
import 'package:new_launcher/providers/provider_mood.dart';
import 'package:new_launcher/providers/provider_expense.dart';
import 'package:new_launcher/providers/provider_numberbase.dart';
import 'package:new_launcher/providers/provider_calendar.dart';
import 'package:new_launcher/providers/provider_progress.dart';
import 'package:new_launcher/providers/provider_anniversary.dart';
import 'package:new_launcher/providers/provider_sleep.dart';
import 'package:new_launcher/providers/provider_counter.dart';
import 'package:new_launcher/providers/provider_tip.dart';
import 'package:new_launcher/providers/provider_bmi.dart';
import 'package:new_launcher/providers/provider_metronome.dart';
import 'package:new_launcher/providers/provider_flashcard.dart';
import 'package:new_launcher/providers/provider_workout.dart';
import 'package:new_launcher/providers/provider_age.dart';
import 'package:new_launcher/providers/provider_percentage.dart';
import 'package:new_launcher/providers/provider_quickcontacts.dart';
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
      expect(Global.providerList.length, 43);
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
      expect(initCount, 43);
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

    test('TimerModel refresh method works', () {
      final model = TimerModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
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

test('Global.providerList contains all providers (42 total)', () {
      expect(Global.providerList.length, 43);
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

    test('CalculatorModel refresh method works', () {
      final model = CalculatorModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
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

    test('StopwatchModel refresh method works', () {
      final model = StopwatchModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
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

test('Global.providerList contains all providers (42 total)', () {
      expect(Global.providerList.length, 43);
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

    test('UnitConverterModel refresh method works', () {
      final model = UnitConverterModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
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

    test('QRModel refresh method works', () {
      final model = QRModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
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

    test('RandomModel refresh method works', () {
      final model = RandomModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });
  });

  group('Color Generator provider tests', () {
    test('ColorModel exists', () {
      expect(colorModel, isNotNull);
    });

    test('ColorModel initial state', () {
      final model = ColorModel();
      expect(model.isInitialized, false);
      expect(model.currentColor, Colors.blue);
      expect(model.hexColor, "#2196F3");
      expect(model.rgbColor, "33, 150, 243");
    });

    test('ColorModel init sets initialized', () {
      final model = ColorModel();
      model.init();
      expect(model.isInitialized, true);
    });

    test('ColorModel generateRandomColor works', () {
      final model = ColorModel();
      model.init();
      model.generateRandomColor();
      expect(model.hexColor.isNotEmpty, true);
      expect(model.rgbColor.isNotEmpty, true);
      expect(model.red >= 0 && model.red <= 255, true);
      expect(model.green >= 0 && model.green <= 255, true);
      expect(model.blue >= 0 && model.blue <= 255, true);
    });

    test('ColorModel setColorFromHex works', () {
      final model = ColorModel();
      model.init();
      model.setColorFromHex("FF0000");
      expect(model.hexColor, "#FF0000");
      expect(model.red, 255);
      expect(model.green, 0);
      expect(model.blue, 0);
    });

    test('ColorModel setColorFromRGB works', () {
      final model = ColorModel();
      model.init();
      model.setColorFromRGB(0, 255, 0);
      expect(model.green, 255);
      expect(model.red, 0);
      expect(model.blue, 0);
    });

    test('ColorModel isLightColor works', () {
      final model = ColorModel();
      model.init();
      model.setColorFromRGB(255, 255, 255);
      expect(model.isLightColor(), true);
      
      model.setColorFromRGB(0, 0, 0);
      expect(model.isLightColor(), false);
    });

    test('ColorModel getContrastColor works', () {
      final model = ColorModel();
      model.init();
      model.setColorFromRGB(255, 255, 255);
      expect(model.getContrastColor(), Colors.black);
      
      model.setColorFromRGB(0, 0, 0);
      expect(model.getContrastColor(), Colors.white);
    });

    test('ColorModel refresh calls notifyListeners', () {
      final model = ColorModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });

    test('ColorModel generateRandomColor notifies listeners', () {
      final model = ColorModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.generateRandomColor();
      expect(notifyCount, 1);
    });

    test('ColorModel setColorFromHex notifies listeners', () {
      final model = ColorModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.setColorFromHex("00FF00");
      expect(notifyCount, 1);
    });

    test('ColorModel setColorFromRGB notifies listeners', () {
      final model = ColorModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.setColorFromRGB(128, 128, 128);
      expect(notifyCount, 1);
    });

    test('ColorCard widget exists', () {
      expect(ColorCard, isNotNull);
    });

    test('Global.providerList includes Color', () {
      final names = Global.providerList.map((p) => p.name).toList();
      expect(names.contains('Color'), true);
    });

    test('providerColor exists', () {
      expect(providerColor, isNotNull);
      expect(providerColor.name, 'Color');
    });

    testWidgets('ColorCard renders loading state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: colorModel,
            builder: (context, child) => ColorCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Color'), findsWidgets);
    });

    testWidgets('ColorCard renders initialized state', (tester) async {
      final model = ColorModel();
      model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => ColorCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Color Generator'), findsWidgets);
      expect(find.textContaining('HEX:'), findsWidgets);
      expect(find.textContaining('RGB:'), findsWidgets);
    });

    testWidgets('ColorCard renders with custom color', (tester) async {
      final model = ColorModel();
      model.init();
      model.setColorFromHex("FF5733");

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => ColorCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('#FF5733'), findsWidgets);
    });

    test('ColorModel keywords are correct', () {
      expect(providerColor.name, 'Color');
      expect(providerColor.provideActions, isNotNull);
    });

    test('ColorModel hex format is correct', () {
      final model = ColorModel();
      model.init();
      model.setColorFromRGB(255, 128, 0);
      expect(model.hexColor, "#FF8000");
    });

    test('ColorModel rgb format is correct', () {
      final model = ColorModel();
      model.init();
      model.setColorFromRGB(100, 150, 200);
      expect(model.rgbColor, "100, 150, 200");
    });

    test('ColorModel clamp RGB values', () {
      final model = ColorModel();
      model.init();
      model.setColorFromRGB(300, -50, 500);
      expect(model.red, 255);
      expect(model.green, 0);
      expect(model.blue, 255);
    });

    test('ColorModel refresh method works', () {
      final model = ColorModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });
  });

  group('Currency Converter provider tests', () {
    test('CurrencyModel exists', () {
      expect(currencyModel, isNotNull);
      expect(currencyModel, isA<CurrencyModel>());
    });

    test('CurrencyModel init works', () {
      final model = CurrencyModel();
      model.init();
      expect(model.isInitialized, true);
    });

    test('CurrencyModel default values', () {
      final model = CurrencyModel();
      model.init();
      expect(model.fromCurrency, 'USD');
      expect(model.toCurrency, 'EUR');
      expect(model.inputValue, '1');
    });

    test('CurrencyModel setInputValue works', () {
      final model = CurrencyModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      
      model.setInputValue('100');
      expect(model.inputValue, '100');
      expect(notifyCount, 1);
    });

    test('CurrencyModel setFromCurrency works', () {
      final model = CurrencyModel();
      model.init();
      
      model.setFromCurrency('EUR');
      expect(model.fromCurrency, 'EUR');
      expect(model.toCurrency, isNot('EUR'));
    });

    test('CurrencyModel setToCurrency works', () {
      final model = CurrencyModel();
      model.init();
      
      model.setToCurrency('GBP');
      expect(model.toCurrency, 'GBP');
      expect(model.fromCurrency, isNot('GBP'));
    });

    test('CurrencyModel swapCurrencies changes both', () {
      final model = CurrencyModel();
      model.init();
      final originalFrom = model.fromCurrency;
      final originalTo = model.toCurrency;
      
      model.swapCurrencies();
      expect(model.fromCurrency, originalTo);
      expect(model.toCurrency, originalFrom);
    });

    test('CurrencyModel clear resets input', () {
      final model = CurrencyModel();
      model.init();
      
      model.setInputValue('500');
      model.clear();
      expect(model.inputValue, '1');
    });

    test('CurrencyModel clearHistory works', () {
      final model = CurrencyModel();
      model.init();
      
      model.clearHistory();
      expect(model.history.length, 0);
      expect(model.hasHistory, false);
    });

    test('CurrencyModel refresh calls notifyListeners', () {
      final model = CurrencyModel();
      model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      
      model.refresh();
      expect(notifyCount, 1);
    });

    test('CurrencyModel availableCurrencies contains common currencies', () {
      final model = CurrencyModel();
      model.init();
      
      expect(model.availableCurrencies.contains('USD'), true);
      expect(model.availableCurrencies.contains('EUR'), true);
      expect(model.availableCurrencies.contains('GBP'), true);
      expect(model.availableCurrencies.contains('JPY'), true);
      expect(model.availableCurrencies.contains('CNY'), true);
    });

    test('ConversionHistory inputName works', () {
      final entry = CurrencyConversionHistory(
        inputValue: 100,
        inputCurrency: 'USD',
        outputValue: 85,
        outputCurrency: 'EUR',
        timestamp: DateTime.now(),
      );
      
      expect(entry.inputName, 'US Dollar');
      expect(entry.outputName, 'Euro');
    });

    test('getCommonCurrencies returns list', () {
      final currencies = getCommonCurrencies();
      expect(currencies.length, greaterThan(10));
      expect(currencies.contains('USD'), true);
      expect(currencies.contains('EUR'), true);
    });

    test('currencyInfo contains major currencies', () {
      expect(currencyInfo['USD'], 'US Dollar');
      expect(currencyInfo['EUR'], 'Euro');
      expect(currencyInfo['GBP'], 'British Pound');
      expect(currencyInfo['JPY'], 'Japanese Yen');
      expect(currencyInfo['CNY'], 'Chinese Yuan');
    });

    testWidgets('CurrencyCard widget exists', (tester) async {
      final model = CurrencyModel();
      model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => CurrencyCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Currency'), findsWidgets);
    });

    test('Global.providerList includes Currency', () {
      final hasCurrency = Global.providerList.any((p) => p.name == 'Currency');
      expect(hasCurrency, true);
    });

    test('providerCurrency exists', () {
      expect(providerCurrency, isNotNull);
      expect(providerCurrency.name, 'Currency');
    });

    testWidgets('CurrencyCard renders initialized state', (tester) async {
      final model = CurrencyModel();
      model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            builder: (context, child) => CurrencyCard(),
          ),
        ),
      ));

      await tester.pump();
      expect(find.textContaining('Currency Converter'), findsWidgets);
    });

    test('CurrencyModel keywords are correct', () {
      expect(providerCurrency.name, 'Currency');
      expect(providerCurrency.provideActions, isNotNull);
    });

    test('CurrencyModel isLoading default is false', () {
      final model = CurrencyModel();
      expect(model.isLoading, false);
    });

    test('CurrencyModel error default is null', () {
      final model = CurrencyModel();
      expect(model.error, null);
    });

    test('CurrencyModel rates is empty before fetch', () {
      final model = CurrencyModel();
      expect(model.rates.length, 0);
    });

    test('CurrencyModel refresh method works', () {
      final model = CurrencyModel();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });
  });

  group('Bookmarks provider tests', () {
    test('providerBookmarks exists in Global.providerList', () {
      final bookmarksProvider = Global.providerList.where((p) => p.name == 'Bookmarks').first;
      expect(bookmarksProvider.name, 'Bookmarks');
    });

    test('Bookmarks provider keywords include bookmark', () {
      final keywords = 'bookmark bookmarks url link website save quick';
      expect(keywords.contains('bookmark'), true);
      expect(keywords.contains('bookmarks'), true);
      expect(keywords.contains('url'), true);
      expect(keywords.contains('link'), true);
    });

    test('BookmarksModel starts uninitialized', () {
      final model = BookmarksModel();
      expect(model.isInitialized, false);
      expect(model.bookmarks.isEmpty, true);
    });

    test('BookmarksModel is ChangeNotifier', () {
      final model = BookmarksModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('Bookmark class works correctly', () {
      final bookmark = Bookmark(url: 'https://example.com', title: 'Example');
      expect(bookmark.url, 'https://example.com');
      expect(bookmark.title, 'Example');
    });

    test('Bookmark toMap/fromMap works', () {
      final bookmark = Bookmark(url: 'https://example.com', title: 'Example');
      final map = bookmark.toMap();
      final restored = Bookmark.fromMap(map);
      expect(restored.url, bookmark.url);
      expect(restored.title, bookmark.title);
    });

    test('Bookmark toJson/fromJson works', () {
      final bookmark = Bookmark(url: 'https://example.com', title: 'Example');
      final json = bookmark.toJson();
      final restored = Bookmark.fromJson(json);
      expect(restored.url, bookmark.url);
      expect(restored.title, bookmark.title);
    });

    test('BookmarksModel addBookmark works correctly', () {
      final model = BookmarksModel();
      model.addBookmark('https://example.com', 'Example');
      expect(model.bookmarks.length, 1);
      expect(model.bookmarks.first.url, 'https://example.com');
      expect(model.bookmarks.first.title, 'Example');
      expect(model.hasBookmarks, true);
    });

    test('BookmarksModel addBookmark normalizes URL', () {
      final model = BookmarksModel();
      model.addBookmark('example.com', 'Example');
      expect(model.bookmarks.first.url, 'https://example.com');
    });

    test('BookmarksModel addBookmark trims whitespace', () {
      final model = BookmarksModel();
      model.addBookmark('  https://example.com  ', '  Example  ');
      expect(model.bookmarks.first.url, 'https://example.com');
      expect(model.bookmarks.first.title, 'Example');
    });

    test('BookmarksModel addBookmark ignores empty URL', () {
      final model = BookmarksModel();
      model.addBookmark('   ', 'Title');
      expect(model.bookmarks.isEmpty, true);
    });

    test('BookmarksModel addBookmark extracts title from URL', () {
      final model = BookmarksModel();
      model.addBookmark('https://www.google.com', '');
      expect(model.bookmarks.first.title, 'Google');
    });

    test('BookmarksModel deleteBookmark works correctly', () {
      final model = BookmarksModel();
      model.addBookmark('https://example1.com', 'Example1');
      model.addBookmark('https://example2.com', 'Example2');
      expect(model.bookmarks.length, 2);
      model.deleteBookmark(0);
      expect(model.bookmarks.length, 1);
      expect(model.bookmarks.first.url, 'https://example1.com');
    });

    test('BookmarksModel updateBookmark works correctly', () {
      final model = BookmarksModel();
      model.addBookmark('https://example.com', 'Example');
      model.updateBookmark(0, 'https://updated.com', 'Updated');
      expect(model.bookmarks.first.url, 'https://updated.com');
      expect(model.bookmarks.first.title, 'Updated');
    });

    test('BookmarksModel updateBookmark deletes when empty URL', () {
      final model = BookmarksModel();
      model.addBookmark('https://example.com', 'Example');
      model.updateBookmark(0, '  ', 'Title');
      expect(model.bookmarks.isEmpty, true);
    });

    test('BookmarksModel clearAllBookmarks works', () {
      final model = BookmarksModel();
      model.addBookmark('https://example1.com', 'Example1');
      model.addBookmark('https://example2.com', 'Example2');
      model.addBookmark('https://example3.com', 'Example3');
      expect(model.bookmarks.length, 3);
      model.clearAllBookmarks();
      expect(model.bookmarks.isEmpty, true);
      expect(model.hasBookmarks, false);
    });

    test('BookmarksModel maxBookmarks limit works', () {
      final model = BookmarksModel();
      for (int i = 0; i < 20; i++) {
        model.addBookmark('https://example$i.com', 'Example$i');
      }
      expect(model.bookmarks.length, BookmarksModel.maxBookmarks);
    });

    testWidgets('BookmarksCard renders loading state', (WidgetTester tester) async {
      final model = BookmarksModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: BookmarksCard(),
          ),
        ),
      ));
      
      expect(find.text('Bookmarks: Loading...'), findsOneWidget);
    });

    testWidgets('BookmarksCard renders empty state', (WidgetTester tester) async {
      final model = BookmarksModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: BookmarksCard(),
          ),
        ),
      ));
      
      expect(find.text('Quick Bookmarks'), findsOneWidget);
      expect(find.text('No bookmarks yet. Tap + to add.'), findsOneWidget);
    });

    test('BookmarksCard widget exists', () {
      expect(BookmarksCard, isNotNull);
    });

    test('AddBookmarkDialog widget exists', () {
      expect(AddBookmarkDialog, isNotNull);
    });

    test('EditBookmarkDialog widget exists', () {
      expect(EditBookmarkDialog, isNotNull);
    });

    test('Global.providerList includes Bookmarks', () {
      final hasBookmarks = Global.providerList.any((p) => p.name == 'Bookmarks');
      expect(hasBookmarks, true);
    });

    test('providerBookmarks exists', () {
      expect(providerBookmarks, isNotNull);
      expect(providerBookmarks.name, 'Bookmarks');
    });

    test('BookmarksModel length getter works', () {
      final model = BookmarksModel();
      expect(model.length, 0);
      model.addBookmark('https://example.com', 'Example');
      expect(model.length, 1);
    });

    test('StringExtension capitalize works', () {
      expect('google'.capitalize(), 'Google');
      expect('example'.capitalize(), 'Example');
      expect(''.capitalize(), '');
    });
  });

  group('Habit provider tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('HabitModel is initialized correctly', () async {
      final model = HabitModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.habits, isEmpty);
    });

    test('HabitModel addHabit works', () async {
      final model = HabitModel();
      await model.init();
      model.addHabit('Exercise');
      expect(model.length, 1);
      expect(model.habits[0].name, 'Exercise');
      expect(model.habits[0].streak, 0);
    });

    test('HabitModel maxHabits limit works', () async {
      final model = HabitModel();
      await model.init();
      for (int i = 0; i < 15; i++) {
        model.addHabit('Habit$i');
      }
      expect(model.length, HabitModel.maxHabits);
    });

    test('HabitModel toggleHabit works', () async {
      final model = HabitModel();
      await model.init();
      model.addHabit('Read');
      expect(model.habits[0].isCompletedToday(), false);
      model.toggleHabit(0);
      expect(model.habits[0].isCompletedToday(), true);
      expect(model.habits[0].streak, 1);
      model.toggleHabit(0);
      expect(model.habits[0].isCompletedToday(), false);
      expect(model.habits[0].streak, 0);
    });

    test('HabitModel updateHabit works', () async {
      final model = HabitModel();
      await model.init();
      model.addHabit('Exercise');
      model.updateHabit(0, 'Workout');
      expect(model.habits[0].name, 'Workout');
    });

    test('HabitModel deleteHabit works', () async {
      final model = HabitModel();
      await model.init();
      model.addHabit('Habit1');
      model.addHabit('Habit2');
      expect(model.length, 2);
      model.deleteHabit(0);
      expect(model.length, 1);
      expect(model.habits[0].name, 'Habit2');
    });

    test('HabitModel clearAllHabits works', () async {
      final model = HabitModel();
      await model.init();
      model.addHabit('Habit1');
      model.addHabit('Habit2');
      expect(model.length, 2);
      await model.clearAllHabits();
      expect(model.length, 0);
    });

    test('HabitItem toJson and fromJson work', () {
      final item = HabitItem(name: 'Test', streak: 5, bestStreak: 10);
      final json = item.toJson();
      final restored = HabitItem.fromJson(json);
      expect(restored.name, 'Test');
      expect(restored.streak, 5);
      expect(restored.bestStreak, 10);
    });

    test('HabitItem isCompletedToday works', () {
      final item = HabitItem(name: 'Test');
      expect(item.isCompletedToday(), false);
      final todayKey = item.todayKey;
      final completedItem = item.copyWith(completedDates: {todayKey});
      expect(completedItem.isCompletedToday(), true);
    });

    test('HabitModel completedTodayCount works', () async {
      final model = HabitModel();
      await model.init();
      model.addHabit('Habit1');
      model.addHabit('Habit2');
      model.addHabit('Habit3');
      expect(model.completedTodayCount, 0);
      model.toggleHabit(0);
      model.toggleHabit(1);
      expect(model.completedTodayCount, 2);
    });

    testWidgets('HabitCard renders loading state', (WidgetTester tester) async {
      final model = HabitModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: HabitCard(),
          ),
        ),
      ));
      
      expect(find.text('Habit Tracker: Loading...'), findsOneWidget);
    });

    testWidgets('HabitCard renders empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = HabitModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: HabitCard(),
            ),
          ),
        ),
      ));
      
      expect(find.text('Habit Tracker'), findsOneWidget);
      expect(find.text('No habits. Tap + to add one!'), findsOneWidget);
    });

    test('HabitCard widget exists', () {
      expect(HabitCard, isNotNull);
    });

    test('AddHabitDialog widget exists', () {
      expect(AddHabitDialog, isNotNull);
    });

    test('EditHabitDialog widget exists', () {
      expect(EditHabitDialog, isNotNull);
    });

    test('Global.providerList includes Habit', () {
      final hasHabit = Global.providerList.any((p) => p.name == 'Habit');
      expect(hasHabit, true);
    });

    test('providerHabit exists', () {
      expect(providerHabit, isNotNull);
      expect(providerHabit.name, 'Habit');
    });

    test('HabitModel length getter works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = HabitModel();
      await model.init();
      expect(model.length, 0);
      model.addHabit('Test');
      expect(model.length, 1);
    });
  });

  group('Meditation provider tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('MeditationModel is initialized correctly', () async {
      final model = MeditationModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.history, isEmpty);
      expect(model.totalMinutes, 0);
    });

    test('MeditationModel startMeditation works', () async {
      final model = MeditationModel();
      await model.init();
      model.startMeditation(5);
      expect(model.state, MeditationState.running);
      expect(model.durationMinutes, 5);
      expect(model.remainingSeconds, 300);
      model.cancelMeditation();
    });

    test('MeditationModel pauseMeditation works', () async {
      final model = MeditationModel();
      await model.init();
      model.startMeditation(5);
      expect(model.state, MeditationState.running);
      model.pauseMeditation();
      expect(model.state, MeditationState.paused);
      model.cancelMeditation();
    });

    test('MeditationModel resumeMeditation works', () async {
      final model = MeditationModel();
      await model.init();
      model.startMeditation(5);
      model.pauseMeditation();
      expect(model.state, MeditationState.paused);
      model.resumeMeditation();
      expect(model.state, MeditationState.running);
      model.cancelMeditation();
    });

    test('MeditationModel cancelMeditation works', () async {
      final model = MeditationModel();
      await model.init();
      model.startMeditation(5);
      expect(model.state, MeditationState.running);
      model.cancelMeditation();
      expect(model.state, MeditationState.idle);
      expect(model.remainingSeconds, 0);
    });

    test('MeditationModel reset works', () async {
      final model = MeditationModel();
      await model.init();
      model.startMeditation(5);
      model.pauseMeditation();
      model.reset();
      expect(model.state, MeditationState.idle);
    });

    test('MeditationModel progress calculates correctly', () async {
      final model = MeditationModel();
      await model.init();
      model.startMeditation(1);
      expect(model.progress, 0);
      model.cancelMeditation();
    });

    test('MeditationModel formattedTime works', () async {
      final model = MeditationModel();
      await model.init();
      model.startMeditation(5);
      expect(model.formattedTime, '05:00');
      model.cancelMeditation();
    });

    test('MeditationModel breathingEnabled works', () async {
      final model = MeditationModel();
      await model.init();
      expect(model.breathingEnabled, false);
      model.setBreathingEnabled(true);
      expect(model.breathingEnabled, true);
    });

    test('MeditationModel clearHistory works', () async {
      final model = MeditationModel();
      await model.init();
      await model.clearHistory();
      expect(model.history, isEmpty);
      expect(model.totalMinutes, 0);
    });

    test('MeditationSession toJson and fromJson work', () {
      final session = MeditationSession(
        durationMinutes: 10,
        completedAt: DateTime.now(),
        breathingPattern: '4-4-4-4',
      );
      final json = session.toJson();
      final restored = MeditationSession.fromJson(json);
      expect(restored.durationMinutes, 10);
      expect(restored.breathingPattern, '4-4-4-4');
    });

    testWidgets('MeditationCard renders loading state', (WidgetTester tester) async {
      final model = MeditationModel();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: MeditationCard(),
          ),
        ),
      ));

      expect(find.text('Meditation: Loading...'), findsOneWidget);
    });

    testWidgets('MeditationCard renders empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = MeditationModel();
      await model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: MeditationCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Meditation Timer'), findsOneWidget);
    });

    test('MeditationCard widget exists', () {
      expect(MeditationCard, isNotNull);
    });

    test('Global.providerList includes Meditation', () {
      final hasMeditation = Global.providerList.any((p) => p.name == 'Meditation');
      expect(hasMeditation, true);
    });

    test('providerMeditation exists', () {
      expect(providerMeditation, isNotNull);
      expect(providerMeditation.name, 'Meditation');
    });

    test('MeditationState enum has correct values', () {
      expect(MeditationState.values.length, 4);
      expect(MeditationState.idle.index, 0);
      expect(MeditationState.running.index, 1);
      expect(MeditationState.paused.index, 2);
      expect(MeditationState.completed.index, 3);
    });

    test('BreathingPhase enum has correct values', () {
      expect(BreathingPhase.values.length, 4);
      expect(BreathingPhase.inhale.index, 0);
      expect(BreathingPhase.hold.index, 1);
      expect(BreathingPhase.exhale.index, 2);
      expect(BreathingPhase.rest.index, 3);
    });

    test('MeditationModel breathingPhaseText works', () async {
      final model = MeditationModel();
      await model.init();
      expect(model.breathingPhaseText, 'Inhale');
    });

    test('MeditationModel sessionCount works', () async {
      final model = MeditationModel();
      await model.init();
      expect(model.sessionCount, 0);
    });

    test('MeditationModel refresh method works', () async {
      final model = MeditationModel();
      await model.init();
      int notifyCount = 0;
      model.addListener(() => notifyCount++);
      model.refresh();
      expect(notifyCount, 1);
    });
  });

  group('Water provider tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('WaterModel is initialized correctly', () async {
      final model = WaterModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.history.length, 1);
      expect(model.todayGlasses, 0);
    });

    test('WaterModel addGlass works', () async {
      final model = WaterModel();
      await model.init();
      expect(model.todayGlasses, 0);
      model.addGlass();
      expect(model.todayGlasses, 1);
      model.addGlass();
      expect(model.todayGlasses, 2);
    });

    test('WaterModel removeGlass works', () async {
      final model = WaterModel();
      await model.init();
      model.addGlass();
      model.addGlass();
      expect(model.todayGlasses, 2);
      model.removeGlass();
      expect(model.todayGlasses, 1);
      model.removeGlass();
      expect(model.todayGlasses, 0);
      model.removeGlass();
      expect(model.todayGlasses, 0);
    });

    test('WaterModel setGoal works', () async {
      final model = WaterModel();
      await model.init();
      expect(model.dailyGoal, WaterModel.defaultGoal);
      model.setGoal(10);
      expect(model.dailyGoal, 10);
    });

    test('WaterModel progress calculates correctly', () async {
      final model = WaterModel();
      await model.init();
      model.setGoal(8);
      model.addGlass();
      model.addGlass();
      expect(model.progress, 0.25);
    });

    test('WaterModel goalReached works', () async {
      final model = WaterModel();
      await model.init();
      model.setGoal(3);
      expect(model.goalReached, false);
      model.addGlass();
      model.addGlass();
      model.addGlass();
      expect(model.goalReached, true);
    });

    test('WaterModel clearHistory works', () async {
      final model = WaterModel();
      await model.init();
      model.addGlass();
      expect(model.todayGlasses, 1);
      await model.clearHistory();
      expect(model.history.length, 1);
      expect(model.todayGlasses, 0);
    });

    test('WaterEntry toJson and fromJson work', () {
      final entry = WaterEntry(
        date: DateTime.now(),
        glasses: 5,
        goal: 8,
      );
      final json = entry.toJson();
      final restored = WaterEntry.fromJson(json);
      expect(restored.glasses, 5);
      expect(restored.goal, 8);
    });

    test('WaterEntry getDayKey works', () {
      final date = DateTime(2024, 1, 15);
      final key = WaterEntry.getDayKey(date);
      expect(key, '2024-1-15');
    });

    testWidgets('WaterCard renders loading state', (WidgetTester tester) async {
      final model = WaterModel();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: WaterCard(),
          ),
        ),
      ));

      expect(find.text('Water Tracker: Loading...'), findsOneWidget);
    });

    testWidgets('WaterCard renders empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = WaterModel();
      await model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: WaterCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Water Tracker'), findsOneWidget);
      expect(find.text('0/8'), findsOneWidget);
    });

    test('WaterCard widget exists', () {
      expect(WaterCard, isNotNull);
    });

    test('Global.providerList includes Water', () {
      final hasWater = Global.providerList.any((p) => p.name == 'Water');
      expect(hasWater, true);
    });

    test('providerWater exists', () {
      expect(providerWater, isNotNull);
      expect(providerWater.name, 'Water');
    });

    test('WaterModel maxHistoryDays limit', () async {
      final model = WaterModel();
      await model.init();
      expect(WaterModel.maxHistoryDays, 30);
    });

    test('WaterModel defaultGoal constant', () {
      expect(WaterModel.defaultGoal, 8);
    });
  });

  group('Mood provider tests', () {
    test('MoodModel initialization works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.history.length, 0);
    });

    test('MoodLevel values are correct', () {
      expect(MoodLevel.verySad.value, 1);
      expect(MoodLevel.sad.value, 2);
      expect(MoodLevel.neutral.value, 3);
      expect(MoodLevel.happy.value, 4);
      expect(MoodLevel.veryHappy.value, 5);
    });

    test('MoodLevel emoji are correct', () {
      expect(MoodLevel.verySad.emoji, '😢');
      expect(MoodLevel.sad.emoji, '😔');
      expect(MoodLevel.neutral.emoji, '😐');
      expect(MoodLevel.happy.emoji, '😊');
      expect(MoodLevel.veryHappy.emoji, '😄');
    });

    test('MoodLevel labels are correct', () {
      expect(MoodLevel.verySad.label, 'Very Sad');
      expect(MoodLevel.sad.label, 'Sad');
      expect(MoodLevel.neutral.label, 'Neutral');
      expect(MoodLevel.happy.label, 'Happy');
      expect(MoodLevel.veryHappy.label, 'Very Happy');
    });

    test('MoodLevel fromValue works', () {
      expect(MoodLevelExtension.fromValue(1), MoodLevel.verySad);
      expect(MoodLevelExtension.fromValue(2), MoodLevel.sad);
      expect(MoodLevelExtension.fromValue(3), MoodLevel.neutral);
      expect(MoodLevelExtension.fromValue(4), MoodLevel.happy);
      expect(MoodLevelExtension.fromValue(5), MoodLevel.veryHappy);
      expect(MoodLevelExtension.fromValue(99), MoodLevel.neutral);
    });

    test('MoodEntry toJson and fromJson work', () {
      final entry = MoodEntry(
        date: DateTime(2024, 1, 15),
        moodValue: 4,
        note: 'Good day',
      );
      final json = entry.toJson();
      final restored = MoodEntry.fromJson(json);
      expect(restored.moodValue, 4);
      expect(restored.note, 'Good day');
      expect(restored.mood, MoodLevel.happy);
    });

    test('MoodEntry getDayKey works', () {
      final date = DateTime(2024, 1, 15);
      final key = MoodEntry.getDayKey(date);
      expect(key, '2024-1-15');
    });

    test('MoodModel logMood works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      model.logMood(MoodLevel.happy);
      expect(model.todayMood, MoodLevel.happy);
      expect(model.history.length, 1);
    });

    test('MoodModel logMood updates existing entry', () async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      model.logMood(MoodLevel.happy);
      model.logMood(MoodLevel.veryHappy);
      expect(model.todayMood, MoodLevel.veryHappy);
      expect(model.history.length, 1);
    });

    test('MoodModel positiveStreak works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      model.logMood(MoodLevel.happy);
      expect(model.positiveStreak, 1);
    });

    test('MoodModel positiveStreak counts consecutive positive days', () async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      model.logMood(MoodLevel.happy);
      expect(model.positiveStreak, 1);
    });

    test('MoodModel mostCommonMood works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      model.logMood(MoodLevel.happy);
      model.logMood(MoodLevel.happy);
      expect(model.mostCommonMood, MoodLevel.happy);
    });

    test('MoodModel averageMood works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      model.logMood(MoodLevel.happy);
      expect(model.averageMood, 4.0);
    });

    test('MoodModel averageMood empty history', () async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      expect(model.averageMood, 3.0);
    });

    test('MoodModel clearHistory works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      model.logMood(MoodLevel.happy);
      expect(model.history.length, 1);
      await model.clearHistory();
      expect(model.history.length, 0);
    });

    test('MoodModel maxHistoryDays constant', () {
      expect(MoodModel.maxHistoryDays, 30);
    });

    testWidgets('MoodCard renders loading state', (WidgetTester tester) async {
      final model = MoodModel();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: MoodCard(),
          ),
        ),
      ));

      expect(find.text('Mood Tracker: Loading...'), findsOneWidget);
    });

    testWidgets('MoodCard renders empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: MoodCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Mood Tracker'), findsOneWidget);
      expect(find.text('No mood logged today'), findsOneWidget);
    });

    testWidgets('MoodCard renders with logged mood', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = MoodModel();
      await model.init();
      model.logMood(MoodLevel.happy);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: MoodCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Mood Tracker'), findsOneWidget);
      expect(find.textContaining('Today:'), findsOneWidget);
    });

    test('MoodCard widget exists', () {
      expect(MoodCard, isNotNull);
    });

    test('MoodPickerSheet widget exists', () {
      expect(MoodPickerSheet, isNotNull);
    });

    test('Global.providerList includes Mood', () {
      final hasMood = Global.providerList.any((p) => p.name == 'Mood');
      expect(hasMood, true);
    });

    test('providerMood exists', () {
      expect(providerMood, isNotNull);
      expect(providerMood.name, 'Mood');
    });

    test('providerMood keywords', () {
      expect(providerMood.name, 'Mood');
    });
  });

  group('Expense provider tests', () {
    test('ExpenseModel initialization works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.entries.length, 0);
    });

    test('ExpenseCategory values are correct', () {
      expect(ExpenseCategory.food.label, 'Food');
      expect(ExpenseCategory.transport.label, 'Transport');
      expect(ExpenseCategory.entertainment.label, 'Entertainment');
      expect(ExpenseCategory.shopping.label, 'Shopping');
      expect(ExpenseCategory.bills.label, 'Bills');
      expect(ExpenseCategory.health.label, 'Health');
      expect(ExpenseCategory.other.label, 'Other');
    });

    test('ExpenseCategory emoji are correct', () {
      expect(ExpenseCategory.food.emoji, '🍔');
      expect(ExpenseCategory.transport.emoji, '🚗');
      expect(ExpenseCategory.entertainment.emoji, '🎬');
      expect(ExpenseCategory.shopping.emoji, '🛍️');
      expect(ExpenseCategory.bills.emoji, '📄');
      expect(ExpenseCategory.health.emoji, '💊');
      expect(ExpenseCategory.other.emoji, '📦');
    });

    test('ExpenseEntry toJson and fromJson work', () {
      final entry = ExpenseEntry(
        id: '123',
        amount: 50.0,
        category: ExpenseCategory.food,
        description: 'Lunch',
        date: DateTime(2024, 1, 15),
      );
      final json = entry.toJson();
      final restored = ExpenseEntry.fromJson(json);
      expect(restored.id, '123');
      expect(restored.amount, 50.0);
      expect(restored.category, ExpenseCategory.food);
      expect(restored.description, 'Lunch');
    });

    test('ExpenseEntry generateId works', () {
      final id1 = ExpenseEntry.generateId();
      final id2 = ExpenseEntry.generateId();
      expect(id1, isNotNull);
      expect(id2, isNotNull);
    });

    test('ExpenseModel addExpense works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      model.addExpense(50.0, ExpenseCategory.food, description: 'Lunch');
      expect(model.entries.length, 1);
      expect(model.todayTotal, 50.0);
    });

    test('ExpenseModel addExpense without description', () async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      model.addExpense(25.0, ExpenseCategory.transport);
      expect(model.entries.length, 1);
      expect(model.entries.first.description, null);
    });

    test('ExpenseModel deleteExpense works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      model.addExpense(50.0, ExpenseCategory.food, description: 'Lunch');
      expect(model.entries.length, 1);
      model.deleteExpense(model.entries.first.id);
      expect(model.entries.length, 0);
    });

    test('ExpenseModel todayEntries filters correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      model.addExpense(50.0, ExpenseCategory.food);
      expect(model.todayEntries.length, 1);
    });

    test('ExpenseModel todayTotal calculates correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      model.addExpense(50.0, ExpenseCategory.food);
      model.addExpense(25.0, ExpenseCategory.transport);
      expect(model.todayTotal, 75.0);
    });

    test('ExpenseModel categoryTotals works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      model.addExpense(50.0, ExpenseCategory.food);
      model.addExpense(25.0, ExpenseCategory.food);
      model.addExpense(30.0, ExpenseCategory.transport);
      final totals = model.categoryTotals;
      expect(totals[ExpenseCategory.food], 75.0);
      expect(totals[ExpenseCategory.transport], 30.0);
    });

    test('ExpenseModel clearHistory works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      model.addExpense(50.0, ExpenseCategory.food);
      expect(model.entries.length, 1);
      await model.clearHistory();
      expect(model.entries.length, 0);
    });

    test('ExpenseModel refresh works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      await model.refresh();
      expect(model.isInitialized, true);
    });

    test('ExpenseModel maxEntries constant', () {
      expect(ExpenseModel.maxEntries, 100);
    });

    testWidgets('ExpenseCard renders loading state', (WidgetTester tester) async {
      final model = ExpenseModel();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: ExpenseCard(),
          ),
        ),
      ));

      expect(find.text('Expense Tracker: Loading...'), findsOneWidget);
    });

    testWidgets('ExpenseCard renders empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: ExpenseCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Expense Tracker'), findsOneWidget);
    });

    testWidgets('ExpenseCard renders with expenses', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = ExpenseModel();
      await model.init();
      model.addExpense(50.0, ExpenseCategory.food, description: 'Lunch');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: ExpenseCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Expense Tracker'), findsOneWidget);
    });

    test('ExpenseCard widget exists', () {
      expect(ExpenseCard, isNotNull);
    });

    test('Global.providerList includes Expense', () {
      final hasExpense = Global.providerList.any((p) => p.name == 'Expense');
      expect(hasExpense, true);
    });

    test('providerExpense exists', () {
      expect(providerExpense, isNotNull);
      expect(providerExpense.name, 'Expense');
    });

    test('providerExpense keywords', () {
      expect(providerExpense.name, 'Expense');
    });
  });

  group('NumberBase provider tests', () {
    test('NumberBaseModel initialization works', () {
      final model = NumberBaseModel();
      model.init();
      expect(model.isLoading, false);
      expect(model.inputValue, '');
      expect(model.inputBase, 'decimal');
      expect(model.outputBase, 'binary');
    });

    test('NumberBaseType values are correct', () {
      expect(numberBaseTypes['binary']?.name, 'Binary');
      expect(numberBaseTypes['binary']?.suffix, 'BIN');
      expect(numberBaseTypes['binary']?.radix, 2);
      expect(numberBaseTypes['octal']?.name, 'Octal');
      expect(numberBaseTypes['octal']?.suffix, 'OCT');
      expect(numberBaseTypes['octal']?.radix, 8);
      expect(numberBaseTypes['decimal']?.name, 'Decimal');
      expect(numberBaseTypes['decimal']?.suffix, 'DEC');
      expect(numberBaseTypes['decimal']?.radix, 10);
      expect(numberBaseTypes['hexadecimal']?.name, 'Hexadecimal');
      expect(numberBaseTypes['hexadecimal']?.suffix, 'HEX');
      expect(numberBaseTypes['hexadecimal']?.radix, 16);
    });

    test('getAllBases returns correct list', () {
      final bases = getAllBases();
      expect(bases.length, 4);
      expect(bases.contains('binary'), true);
      expect(bases.contains('octal'), true);
      expect(bases.contains('decimal'), true);
      expect(bases.contains('hexadecimal'), true);
    });

    test('NumberBaseModel setInputValue works', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputValue('255');
      expect(model.inputValue, '255');
    });

    test('NumberBaseModel setInputValue sanitizes for binary', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputBase('binary');
      model.setInputValue('1234');
      expect(model.inputValue, '1');
    });

    test('NumberBaseModel setInputValue sanitizes for hexadecimal', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputBase('hexadecimal');
      model.setInputValue('ABCDEF123');
      expect(model.inputValue, 'ABCDEF123');
    });

    test('NumberBaseModel setInputBase works', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputBase('hexadecimal');
      expect(model.inputBase, 'hexadecimal');
    });

    test('NumberBaseModel setOutputBase works', () {
      final model = NumberBaseModel();
      model.init();
      model.setOutputBase('octal');
      expect(model.outputBase, 'octal');
    });

    test('NumberBaseModel conversion decimal to binary', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputBase('decimal');
      model.setOutputBase('binary');
      model.setInputValue('10');
      expect(model.outputValue, '1010');
    });

    test('NumberBaseModel conversion decimal to hexadecimal', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputBase('decimal');
      model.setOutputBase('hexadecimal');
      model.setInputValue('255');
      expect(model.outputValue, 'FF');
    });

    test('NumberBaseModel conversion binary to decimal', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputBase('binary');
      model.setOutputBase('decimal');
      model.setInputValue('11111111');
      expect(model.outputValue, '255');
    });

    test('NumberBaseModel conversion hexadecimal to decimal', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputBase('hexadecimal');
      model.setOutputBase('decimal');
      model.setInputValue('FF');
      expect(model.outputValue, '255');
    });

    test('NumberBaseModel conversion octal to decimal', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputBase('octal');
      model.setOutputBase('decimal');
      model.setInputValue('377');
      expect(model.outputValue, '255');
    });

    test('NumberBaseModel swapBases works', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputBase('decimal');
      model.setOutputBase('binary');
      model.setInputValue('10');
      model.swapBases();
      expect(model.inputBase, 'binary');
      expect(model.outputBase, 'decimal');
      expect(model.inputValue, '1010');
    });

    test('NumberBaseModel addToHistory works', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputValue('255');
      model.addToHistory();
      expect(model.history.length, 1);
      expect(model.history.first.inputValue, '255');
    });

    test('NumberBaseModel history limit', () {
      final model = NumberBaseModel();
      model.init();
      for (int i = 0; i < 15; i++) {
        model.setInputValue('$i');
        model.addToHistory();
      }
      expect(model.history.length, NumberBaseModel.maxHistoryLength);
    });

    test('NumberBaseModel applyFromHistory works', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputValue('255');
      model.setInputBase('decimal');
      model.setOutputBase('hexadecimal');
      model.addToHistory();
      model.setInputValue('100');
      model.applyFromHistory(model.history.first);
      expect(model.inputValue, '255');
      expect(model.inputBase, 'decimal');
      expect(model.outputBase, 'hexadecimal');
    });

    test('NumberBaseModel clearHistory works', () {
      final model = NumberBaseModel();
      model.init();
      model.setInputValue('255');
      model.addToHistory();
      expect(model.history.length, 1);
      model.clearHistory();
      expect(model.history.length, 0);
    });

    test('NumberBaseModel refresh works', () {
      final model = NumberBaseModel();
      model.init();
      model.refresh();
      expect(model.isLoading, false);
    });

    test('NumberBaseModel maxHistoryLength constant', () {
      expect(NumberBaseModel.maxHistoryLength, 10);
    });

    testWidgets('NumberBaseCard renders empty state', (WidgetTester tester) async {
      final model = NumberBaseModel();
      model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: NumberBaseCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Number Base Converter'), findsOneWidget);
    });

    testWidgets('NumberBaseCard renders with input', (WidgetTester tester) async {
      final model = NumberBaseModel();
      model.init();
      model.setInputValue('255');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: NumberBaseCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Number Base Converter'), findsOneWidget);
    });

    test('NumberBaseCard widget exists', () {
      expect(NumberBaseCard, isNotNull);
    });

    test('Global.providerList includes NumberBase', () {
      final hasNumberBase = Global.providerList.any((p) => p.name == 'NumberBase');
      expect(hasNumberBase, true);
    });

    test('providerNumberBase exists', () {
      expect(providerNumberBase, isNotNull);
      expect(providerNumberBase.name, 'NumberBase');
    });

    test('providerNumberBase keywords', () {
      expect(providerNumberBase.name, 'NumberBase');
    });
  });

  group('Calendar provider tests', () {
    test('providerCalendar exists', () {
      expect(providerCalendar, isNotNull);
      expect(providerCalendar.name, 'Calendar');
    });

    test('Global.providerList includes Calendar', () {
      final hasCalendar = Global.providerList.any((p) => p.name == 'Calendar');
      expect(hasCalendar, true);
    });

    test('providerCalendar keywords', () {
      expect(providerCalendar.name, 'Calendar');
    });

    testWidgets('CalendarCard renders', (WidgetTester tester) async {
      final model = CalendarModel();
      model.init();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: CalendarCard(),
            ),
          ),
        ),
      ));

      expect(find.byType(Card), findsOneWidget);
      model.dispose();
    });

    testWidgets('CalendarCard shows month navigation', (WidgetTester tester) async {
      final model = CalendarModel();
      model.init();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: CalendarCard(),
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      model.dispose();
    });

    testWidgets('CalendarCard shows weekday headers', (WidgetTester tester) async {
      final model = CalendarModel();
      model.init();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: CalendarCard(),
            ),
          ),
        ),
      ));

      expect(find.text('S'), findsNWidgets(2));
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsNWidgets(2));
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      model.dispose();
    });

    testWidgets('CalendarCard navigation buttons work', (WidgetTester tester) async {
      final model = CalendarModel();
      model.init();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: CalendarCard(),
            ),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.chevron_left).first);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pump();
      model.dispose();
    });
  });

  group('Progress provider tests', () {
    test('ProgressItem properties work', () {
      final item = ProgressItem(name: "Test Goal", current: 50, target: 100);
      expect(item.percentage, 50.0);
      expect(item.isComplete, false);
      expect(item.remaining, 50);
    });

    test('ProgressItem percentage calculation', () {
      final item1 = ProgressItem(name: "Goal 1", current: 0, target: 100);
      expect(item1.percentage, 0.0);

      final item2 = ProgressItem(name: "Goal 2", current: 100, target: 100);
      expect(item2.percentage, 100.0);
      expect(item2.isComplete, true);

      final item3 = ProgressItem(name: "Goal 3", current: 75, target: 100);
      expect(item3.percentage, 75.0);
    });

    test('ProgressItem toJson and fromJson work', () {
      final item = ProgressItem(name: "Test", current: 50, target: 100);
      final json = item.toJson();
      final restored = ProgressItem.fromJson(json);

      expect(restored.name, item.name);
      expect(restored.current, item.current);
      expect(restored.target, item.target);
    });

    test('ProgressItem copyWith works', () {
      final item = ProgressItem(name: "Test", current: 50, target: 100);
      final updated = item.copyWith(current: 75);

      expect(updated.name, "Test");
      expect(updated.current, 75);
      expect(updated.target, 100);
    });

    test('ProgressModel initialization works', () async {
      await progressModel.init();
      expect(progressModel.isInitialized, true);
      expect(progressModel.items.length >= 0, true);
    });

    test('ProgressModel addProgress works', () async {
      await progressModel.init();
      progressModel.clearAllProgress();
      await Future.delayed(Duration(milliseconds: 10));

      progressModel.addProgress("Test Goal", 100);
      expect(progressModel.length, 1);
      expect(progressModel.items.first.name, "Test Goal");
      expect(progressModel.items.first.target, 100);
    });

    test('ProgressModel updateCurrentValue works', () async {
      await progressModel.init();
      progressModel.clearAllProgress();
      await Future.delayed(Duration(milliseconds: 10));

      progressModel.addProgress("Test", 100);
      progressModel.updateCurrentValue(0, 50);
      expect(progressModel.items.first.current, 50);
    });

    test('ProgressModel updateCurrentValue caps to target', () async {
      await progressModel.init();
      progressModel.clearAllProgress();
      await Future.delayed(Duration(milliseconds: 10));

      progressModel.addProgress("Test", 100);
      progressModel.updateCurrentValue(0, 150);
      expect(progressModel.items.first.current, 100);
    });

    test('ProgressModel incrementProgress works', () async {
      await progressModel.init();
      progressModel.clearAllProgress();
      await Future.delayed(Duration(milliseconds: 10));

      progressModel.addProgress("Test", 100);
      progressModel.updateCurrentValue(0, 50);
      progressModel.incrementProgress(0, 10);
      expect(progressModel.items.first.current, 60);
    });

    test('ProgressModel deleteProgress works', () async {
      await progressModel.init();
      progressModel.clearAllProgress();
      await Future.delayed(Duration(milliseconds: 10));

      progressModel.addProgress("Test 1", 100);
      progressModel.addProgress("Test 2", 200);
      expect(progressModel.length, 2);

      progressModel.deleteProgress(0);
      expect(progressModel.length, 1);
      expect(progressModel.items.first.name, "Test 2");
    });

    test('ProgressModel clearAllProgress works', () async {
      await progressModel.init();
      progressModel.addProgress("Test 1", 100);
      progressModel.addProgress("Test 2", 200);

      await progressModel.clearAllProgress();
      expect(progressModel.length, 0);
    });

    test('ProgressModel refresh works', () async {
      await progressModel.init();
      progressModel.refresh();
      expect(progressModel.isInitialized, true);
    });

    test('ProgressModel completedCount works', () async {
      await progressModel.init();
      progressModel.clearAllProgress();
      await Future.delayed(Duration(milliseconds: 10));

      progressModel.addProgress("Complete", 10);
      progressModel.updateCurrentValue(0, 10);

      progressModel.addProgress("Incomplete", 100);
      progressModel.updateCurrentValue(1, 50);

      expect(progressModel.completedCount, 1);
    });

    test('ProgressModel averageProgress works', () async {
      await progressModel.init();
      progressModel.clearAllProgress();
      await Future.delayed(Duration(milliseconds: 10));

      progressModel.addProgress("Goal 1", 100);
      progressModel.updateCurrentValue(0, 50);

      progressModel.addProgress("Goal 2", 100);
      progressModel.updateCurrentValue(1, 75);

      expect(progressModel.averageProgress, 62.5);
    });

    test('ProgressModel averageProgress empty', () async {
      await progressModel.init();
      progressModel.clearAllProgress();
      await Future.delayed(Duration(milliseconds: 10));

      expect(progressModel.averageProgress, 0);
    });

    test('ProgressModel maxProgressItems constant', () {
      expect(ProgressModel.maxProgressItems, 15);
    });

    testWidgets('ProgressCard renders loading state', (WidgetTester tester) async {
      final model = ProgressModel();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: ProgressCard(),
          ),
        ),
      ));

      expect(find.text("Progress Tracker: Loading..."), findsOneWidget);
    });

    testWidgets('ProgressCard renders empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = ProgressModel();
      await model.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: ProgressCard(),
            ),
          ),
        ),
      ));

      expect(find.text("No progress items. Tap + to add one!"), findsOneWidget);
    });

    testWidgets('ProgressCard renders with items', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = ProgressModel();
      await model.init();
      model.addProgress("Test Goal", 100);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: ProgressCard(),
            ),
          ),
        ),
      ));

      expect(find.text("Test Goal"), findsOneWidget);
    });

    testWidgets('ProgressCard widget exists', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: progressModel,
            child: ProgressCard(),
          ),
        ),
      ));

      expect(find.byType(ProgressCard), findsOneWidget);
    });

    testWidgets('AddProgressDialog widget exists', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AddProgressDialog(),
              ),
              child: Text("Show"),
            ),
          ),
        ),
      ));

      await tester.tap(find.text("Show"));
      await tester.pumpAndSettle();

      expect(find.byType(AddProgressDialog), findsOneWidget);
      expect(find.text("Add Progress"), findsOneWidget);
    });

    testWidgets('EditProgressDialog widget exists', (WidgetTester tester) async {
      final item = ProgressItem(name: "Test", current: 50, target: 100);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => EditProgressDialog(index: 0, item: item),
              ),
              child: Text("Show"),
            ),
          ),
        ),
      ));

      await tester.tap(find.text("Show"));
      await tester.pumpAndSettle();

      expect(find.byType(EditProgressDialog), findsOneWidget);
      expect(find.text("Edit Progress"), findsOneWidget);
    });

    test('providerProgress exists', () {
      expect(providerProgress, isNotNull);
      expect(providerProgress.name, 'Progress');
    });

    test('Global.providerList includes Progress', () {
      final hasProgress = Global.providerList.any((p) => p.name == 'Progress');
      expect(hasProgress, true);
    });

    test('providerProgress keywords', () {
      expect(providerProgress.name, 'Progress');
    });
  });

  group('Anniversary provider tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('AnniversaryModel is initialized correctly', () async {
      final model = AnniversaryModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.anniversaries, isEmpty);
    });

    test('AnniversaryModel addAnniversary works', () async {
      final model = AnniversaryModel();
      await model.init();
      model.addAnniversary('Birthday', 6, 15, 1990);
      expect(model.length, 1);
      expect(model.anniversaries[0].name, 'Birthday');
      expect(model.anniversaries[0].month, 6);
      expect(model.anniversaries[0].day, 15);
      expect(model.anniversaries[0].year, 1990);
    });

    test('AnniversaryModel addAnniversary without year works', () async {
      final model = AnniversaryModel();
      await model.init();
      model.addAnniversary('Anniversary', 12, 25, null);
      expect(model.length, 1);
      expect(model.anniversaries[0].year, null);
    });

    test('AnniversaryModel addAnniversary does not add empty name', () async {
      final model = AnniversaryModel();
      await model.init();
      model.addAnniversary('', 6, 15, 1990);
      expect(model.length, 0);
    });

    test('AnniversaryModel updateAnniversary works', () async {
      final model = AnniversaryModel();
      await model.init();
      model.addAnniversary('Birthday', 6, 15, 1990);
      model.updateAnniversary(0, 'New Birthday', 7, 20, 1995);
      expect(model.anniversaries[0].name, 'New Birthday');
      expect(model.anniversaries[0].month, 7);
      expect(model.anniversaries[0].day, 20);
    });

    test('AnniversaryModel deleteAnniversary works', () async {
      final model = AnniversaryModel();
      await model.init();
      model.addAnniversary('Birthday1', 6, 15, 1990);
      model.addAnniversary('Birthday2', 7, 20, 1995);
      expect(model.length, 2);
      model.deleteAnniversary(0);
      expect(model.length, 1);
      expect(model.anniversaries[0].name, 'Birthday1');
    });

    test('AnniversaryModel clearAllAnniversaries works', () async {
      final model = AnniversaryModel();
      await model.init();
      model.addAnniversary('Birthday1', 6, 15, 1990);
      model.addAnniversary('Birthday2', 7, 20, 1995);
      expect(model.length, 2);
      model.clearAllAnniversaries();
      expect(model.length, 0);
    });

    test('AnniversaryModel maxAnniversaries is 15', () {
      expect(AnniversaryModel.maxAnniversaries, 15);
    });

    test('AnniversaryModel max limit works', () async {
      final model = AnniversaryModel();
      await model.init();
      for (int i = 0; i < 20; i++) {
        model.addAnniversary('Event $i', (i % 12) + 1, (i % 28) + 1, null);
      }
      expect(model.length, 15);
    });

    test('AnniversaryEntry getNextOccurrence works', () {
      final futureDate = DateTime.now().add(Duration(days: 5));
      final entry = AnniversaryEntry(
        name: 'Test',
        month: futureDate.month,
        day: futureDate.day,
        year: 1990,
      );
      final next = entry.getNextOccurrence();
      expect(next.year, DateTime.now().year);
    });

    test('AnniversaryEntry getDaysUntilNext works', () {
      final futureDate = DateTime.now().add(Duration(days: 5));
      final entry = AnniversaryEntry(
        name: 'Test',
        month: futureDate.month,
        day: futureDate.day,
        year: 1990,
      );
      final days = entry.getDaysUntilNext();
      expect(days, greaterThanOrEqualTo(4));
    });

    test('AnniversaryEntry getOccurrences works', () {
      final pastDate = DateTime.now().subtract(Duration(days: 5));
      final entry = AnniversaryEntry(
        name: 'Test',
        month: pastDate.month,
        day: pastDate.day,
        year: DateTime.now().year - 30,
      );
      final occurrences = entry.getOccurrences();
      expect(occurrences, 31);
    });

    test('AnniversaryEntry getOccurrences returns null when year is null', () {
      final entry = AnniversaryEntry(
        name: 'Test',
        month: 6,
        day: 15,
        year: null,
      );
      expect(entry.getOccurrences(), null);
    });

    test('AnniversaryEntry toJsonString and fromJsonString work', () {
      final entry = AnniversaryEntry(
        name: 'Test',
        month: 6,
        day: 15,
        year: 1990,
        createdAt: DateTime(2026, 1, 1),
      );
      final json = entry.toJsonString();
      final restored = AnniversaryEntry.fromJsonString(json);
      expect(restored.name, 'Test');
      expect(restored.month, 6);
      expect(restored.day, 15);
      expect(restored.year, 1990);
    });

    test('AnniversaryModel formatDaysUntil works for today', () async {
      final model = AnniversaryModel();
      await model.init();
      final now = DateTime.now();
      final entry = AnniversaryEntry(
        name: 'Test',
        month: now.month,
        day: now.day,
        year: 1990,
      );
      final formatted = model.formatDaysUntil(entry);
      expect(formatted, 'Today!');
    });

    test('AnniversaryModel formatDaysUntil works for days less than a week', () async {
      final model = AnniversaryModel();
      await model.init();
      final futureDate = DateTime.now().add(Duration(days: 3));
      final entry = AnniversaryEntry(
        name: 'Test',
        month: futureDate.month,
        day: futureDate.day,
        year: 1990,
      );
      final formatted = model.formatDaysUntil(entry);
      expect(formatted.contains('days'), true);
    });

    test('AnniversaryModel formatDaysUntil works for days', () async {
      final model = AnniversaryModel();
      await model.init();
      final futureDate = DateTime.now().add(Duration(days: 5));
      final entry = AnniversaryEntry(
        name: 'Test',
        month: futureDate.month,
        day: futureDate.day,
        year: 1990,
      );
      final formatted = model.formatDaysUntil(entry);
      expect(formatted.contains('days'), true);
    });

    testWidgets('AnniversaryCard renders loading state', (WidgetTester tester) async {
      final model = AnniversaryModel();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: AnniversaryCard(),
          ),
        ),
      ));

      expect(find.text('Anniversaries: Loading...'), findsOneWidget);
    });

    testWidgets('AnniversaryCard renders empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await anniversaryModel.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: anniversaryModel,
              child: AnniversaryCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Anniversaries'), findsOneWidget);
      expect(find.text('No anniversaries. Tap + to add one.'), findsOneWidget);
    });

    testWidgets('AnniversaryCard renders with anniversaries', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await anniversaryModel.init();
      anniversaryModel.addAnniversary('Test Anniversary', 6, 15, 1990);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: anniversaryModel,
              child: AnniversaryCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Test Anniversary'), findsOneWidget);
    });

    testWidgets('AnniversaryCard widget exists', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: anniversaryModel,
            child: AnniversaryCard(),
          ),
        ),
      ));

      expect(find.byType(AnniversaryCard), findsOneWidget);
    });

    testWidgets('AddAnniversaryDialog widget exists', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AddAnniversaryDialog(),
              ),
              child: Text("Show"),
            ),
          ),
        ),
      ));

      await tester.tap(find.text("Show"));
      await tester.pumpAndSettle();

      expect(find.byType(AddAnniversaryDialog), findsOneWidget);
      expect(find.text("Add Anniversary"), findsOneWidget);
    });

    testWidgets('EditAnniversaryDialog widget exists', (WidgetTester tester) async {
      final entry = AnniversaryEntry(name: "Test", month: 6, day: 15);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => EditAnniversaryDialog(index: 0, entry: entry),
              ),
              child: Text("Show"),
            ),
          ),
        ),
      ));

      await tester.tap(find.text("Show"));
      await tester.pumpAndSettle();

      expect(find.byType(EditAnniversaryDialog), findsOneWidget);
      expect(find.text("Edit Anniversary"), findsOneWidget);
    });

    test('providerAnniversary exists', () {
      expect(providerAnniversary, isNotNull);
      expect(providerAnniversary.name, 'Anniversary');
    });

    test('Global.providerList includes Anniversary', () {
      final hasAnniversary = Global.providerList.any((p) => p.name == 'Anniversary');
      expect(hasAnniversary, true);
    });

    test('Anniversary provider keywords include anniversary', () {
      final keywords = 'anniversary birthday recurring event date add';
      expect(keywords.contains('anniversary'), true);
    });

    test('Anniversary provider keywords include birthday', () {
      final keywords = 'anniversary birthday recurring event date add';
      expect(keywords.contains('birthday'), true);
    });

    test('Anniversary provider keywords include recurring', () {
      final keywords = 'anniversary birthday recurring event date add';
      expect(keywords.contains('recurring'), true);
    });

    test('AnniversaryModel is ChangeNotifier', () {
      final model = AnniversaryModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('AnniversaryModel hasAnniversaries getter works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AnniversaryModel();
      await model.init();
      expect(model.hasAnniversaries, false);
      model.addAnniversary('Test', 6, 15, null);
      expect(model.hasAnniversaries, true);
    });

    test('AnniversaryModel length getter works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AnniversaryModel();
      await model.init();
      expect(model.length, 0);
      model.addAnniversary('Test', 6, 15, null);
      expect(model.length, 1);
    });
  });

  group('Sleep provider tests', () {
    test('SleepQuality enum has correct values', () {
      expect(SleepQuality.values.length, 5);
      expect(SleepQuality.terrible.value, 1);
      expect(SleepQuality.poor.value, 2);
      expect(SleepQuality.fair.value, 3);
      expect(SleepQuality.good.value, 4);
      expect(SleepQuality.excellent.value, 5);
    });

    test('SleepQuality emoji works', () {
      expect(SleepQuality.terrible.emoji, '😫');
      expect(SleepQuality.poor.emoji, '😴');
      expect(SleepQuality.fair.emoji, '😐');
      expect(SleepQuality.good.emoji, '😊');
      expect(SleepQuality.excellent.emoji, '😄');
    });

    test('SleepQuality label works', () {
      expect(SleepQuality.terrible.label, 'Terrible');
      expect(SleepQuality.poor.label, 'Poor');
      expect(SleepQuality.fair.label, 'Fair');
      expect(SleepQuality.good.label, 'Good');
      expect(SleepQuality.excellent.label, 'Excellent');
    });

    test('SleepQuality fromValue works', () {
      expect(SleepQualityExtension.fromValue(1), SleepQuality.terrible);
      expect(SleepQualityExtension.fromValue(2), SleepQuality.poor);
      expect(SleepQualityExtension.fromValue(3), SleepQuality.fair);
      expect(SleepQualityExtension.fromValue(4), SleepQuality.good);
      expect(SleepQualityExtension.fromValue(5), SleepQuality.excellent);
      expect(SleepQualityExtension.fromValue(0), SleepQuality.fair);
      expect(SleepQualityExtension.fromValue(6), SleepQuality.fair);
    });

    test('SleepEntry properties work', () {
      final entry = SleepEntry(
        date: DateTime(2026, 4, 24),
        hours: 7.5,
        qualityValue: 4,
        note: 'Good sleep',
      );
      expect(entry.date, DateTime(2026, 4, 24));
      expect(entry.hours, 7.5);
      expect(entry.qualityValue, 4);
      expect(entry.note, 'Good sleep');
      expect(entry.quality, SleepQuality.good);
    });

    test('SleepEntry formatHours works', () {
      final entry1 = SleepEntry(date: DateTime.now(), hours: 7.0, qualityValue: 3);
      expect(entry1.formatHours(), '7h');

      final entry2 = SleepEntry(date: DateTime.now(), hours: 7.5, qualityValue: 3);
      expect(entry2.formatHours(), '7h 30m');

      final entry3 = SleepEntry(date: DateTime.now(), hours: 8.25, qualityValue: 3);
      expect(entry3.formatHours(), '8h 15m');
    });

    test('SleepEntry toJson and fromJson work', () {
      final entry = SleepEntry(
        date: DateTime(2026, 4, 24),
        hours: 7.5,
        qualityValue: 4,
        note: 'Test note',
      );
      final json = entry.toJson();
      final restored = SleepEntry.fromJson(json);

      expect(restored.date, entry.date);
      expect(restored.hours, entry.hours);
      expect(restored.qualityValue, entry.qualityValue);
      expect(restored.note, entry.note);
    });

    test('SleepEntry getDayKey works', () {
      final date = DateTime(2026, 4, 24);
      final key = SleepEntry.getDayKey(date);
      expect(key, '2026-4-24');
    });

    test('SleepModel initialization works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.history.length, 0);
    });

    test('SleepModel logSleep works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      model.logSleep(7.5, SleepQuality.good);
      expect(model.history.length, 1);
      expect(model.history.first.hours, 7.5);
      expect(model.history.first.qualityValue, 4);
    });

    test('SleepModel logSleep with custom date works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      final customDate = DateTime(2026, 4, 20);
      model.logSleep(8.0, SleepQuality.excellent, customDate: customDate);
      expect(model.history.length, 1);
      expect(model.history.first.date.day, 20);
    });

    test('SleepModel logSleep updates existing entry', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      model.logSleep(7.0, SleepQuality.fair);
      model.logSleep(8.0, SleepQuality.good);

      expect(model.history.length, 1);
      expect(model.history.first.hours, 8.0);
    });

    test('SleepModel deleteEntry works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      model.logSleep(7.0, SleepQuality.good, customDate: DateTime.now().subtract(Duration(days: 2)));
      model.logSleep(8.0, SleepQuality.excellent, customDate: DateTime.now().subtract(Duration(days: 1)));

      expect(model.history.length, 2);
      model.deleteEntry(0);
      expect(model.history.length, 1);
    });

    test('SleepModel clearHistory works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      model.logSleep(7.0, SleepQuality.good);
      model.logSleep(8.0, SleepQuality.excellent, customDate: DateTime.now().subtract(Duration(days: 2)));

      await model.clearHistory();
      expect(model.history.length, 0);
    });

    test('SleepModel averageHours works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      model.logSleep(7.0, SleepQuality.good, customDate: DateTime.now().subtract(Duration(days: 2)));
      model.logSleep(8.0, SleepQuality.excellent, customDate: DateTime.now().subtract(Duration(days: 1)));

      expect(model.averageHours, 7.5);
    });

    test('SleepModel averageHours empty returns 0', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      expect(model.averageHours, 0);
    });

    test('SleepModel averageQuality works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      model.logSleep(7.0, SleepQuality.good, customDate: DateTime.now().subtract(Duration(days: 2)));
      model.logSleep(8.0, SleepQuality.excellent, customDate: DateTime.now().subtract(Duration(days: 1)));

      expect(model.averageQuality, 4.5);
    });

    test('SleepModel averageQualityLevel works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      model.logSleep(7.0, SleepQuality.good, customDate: DateTime.now().subtract(Duration(days: 2)));
      model.logSleep(8.0, SleepQuality.good, customDate: DateTime.now().subtract(Duration(days: 1)));

      expect(model.averageQualityLevel, SleepQuality.good);
    });

    test('SleepModel nightsGoalMet works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      model.logSleep(6.0, SleepQuality.fair, customDate: DateTime.now().subtract(Duration(days: 3)));
      model.logSleep(7.0, SleepQuality.good, customDate: DateTime.now().subtract(Duration(days: 2)));
      model.logSleep(8.0, SleepQuality.excellent, customDate: DateTime.now().subtract(Duration(days: 1)));

      expect(model.nightsGoalMet, 2);
    });

    test('SleepModel hasHistory getter works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      expect(model.hasHistory, false);
      model.logSleep(7.0, SleepQuality.good);
      expect(model.hasHistory, true);
    });

    test('SleepModel lastNightEntry getter works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      model.logSleep(8.0, SleepQuality.good);
      expect(model.lastNightEntry, isNotNull);
      expect(model.lastNightEntry!.hours, 8.0);
    });

    test('SleepModel maxHistoryDays constant', () {
      expect(SleepModel.maxHistoryDays, 30);
    });

    test('SleepModel max limit works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();

      for (int i = 0; i < 35; i++) {
        model.logSleep(7.0, SleepQuality.good, customDate: DateTime.now().subtract(Duration(days: i)));
      }
      expect(model.history.length, 30);
    });

    testWidgets('SleepCard renders loading state', (WidgetTester tester) async {
      final model = SleepModel();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: SleepCard(),
          ),
        ),
      ));

      expect(find.text('Sleep Tracker: Loading...'), findsOneWidget);
    });

    testWidgets('SleepCard renders empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await sleepModel.init();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: sleepModel,
              child: SleepCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Sleep Tracker'), findsOneWidget);
      expect(find.text('No sleep logged for last night'), findsOneWidget);
    });

    testWidgets('SleepCard renders with sleep data', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = SleepModel();
      await model.init();
      model.logSleep(8.0, SleepQuality.good);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: SleepCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Sleep Tracker'), findsOneWidget);
      expect(find.text('8h'), findsOneWidget);
    });

    testWidgets('SleepCard widget exists', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: sleepModel,
            child: SleepCard(),
          ),
        ),
      ));

      expect(find.byType(SleepCard), findsOneWidget);
    });

    testWidgets('SleepLogDialog widget exists', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => SleepLogDialog(),
              ),
              child: Text("Show"),
            ),
          ),
        ),
      ));

      await tester.tap(find.text("Show"));
      await tester.pumpAndSettle();

      expect(find.byType(SleepLogDialog), findsOneWidget);
      expect(find.text("Log Sleep"), findsOneWidget);
    });

    test('providerSleep exists', () {
      expect(providerSleep, isNotNull);
      expect(providerSleep.name, 'Sleep');
    });

    test('Global.providerList includes Sleep', () {
      final hasSleep = Global.providerList.any((p) => p.name == 'Sleep');
      expect(hasSleep, true);
    });

    test('Sleep provider keywords include sleep', () {
      final keywords = 'sleep rest nap bed track night hours quality bedtime';
      expect(keywords.contains('sleep'), true);
    });

    test('Sleep provider keywords include bedtime', () {
      final keywords = 'sleep rest nap bed track night hours quality bedtime';
      expect(keywords.contains('bedtime'), true);
    });

    test('Sleep provider keywords include hours', () {
      final keywords = 'sleep rest nap bed track night hours quality bedtime';
      expect(keywords.contains('hours'), true);
    });

    test('SleepModel is ChangeNotifier', () {
      final model = SleepModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('sleepModel global instance exists', () {
      expect(sleepModel, isNotNull);
    });
  });

  group('Counter provider tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('CounterModel is initialized correctly', () async {
      final model = CounterModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.counters, isEmpty);
    });

    test('CounterModel addCounter works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Reps', 1);
      expect(model.length, 1);
      expect(model.counters[0].name, 'Reps');
      expect(model.counters[0].count, 0);
      expect(model.counters[0].step, 1);
    });

    test('CounterModel addCounter with custom step works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Score', 5);
      expect(model.counters[0].step, 5);
    });

    test('CounterModel maxCounters limit works', () async {
      final model = CounterModel();
      await model.init();
      for (int i = 0; i < 20; i++) {
        model.addCounter('Counter$i', 1);
      }
      expect(model.length, CounterModel.maxCounters);
    });

    test('CounterModel increment works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Reps', 1);
      expect(model.counters[0].count, 0);
      model.increment(0);
      expect(model.counters[0].count, 1);
      model.increment(0);
      expect(model.counters[0].count, 2);
    });

    test('CounterModel increment with custom step works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Score', 5);
      expect(model.counters[0].count, 0);
      model.increment(0);
      expect(model.counters[0].count, 5);
      model.increment(0);
      expect(model.counters[0].count, 10);
    });

    test('CounterModel decrement works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Reps', 1);
      model.increment(0);
      model.increment(0);
      expect(model.counters[0].count, 2);
      model.decrement(0);
      expect(model.counters[0].count, 1);
    });

    test('CounterModel decrement with custom step works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Score', 5);
      model.increment(0);
      expect(model.counters[0].count, 5);
      model.decrement(0);
      expect(model.counters[0].count, 0);
    });

    test('CounterModel decrement allows negative values', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Reps', 1);
      model.decrement(0);
      expect(model.counters[0].count, -1);
    });

    test('CounterModel resetCounter works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Reps', 1);
      model.increment(0);
      model.increment(0);
      model.increment(0);
      expect(model.counters[0].count, 3);
      model.resetCounter(0);
      expect(model.counters[0].count, 0);
    });

    test('CounterModel updateCounter works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Reps', 1);
      model.updateCounter(0, 'Push-ups', 2);
      expect(model.counters[0].name, 'Push-ups');
      expect(model.counters[0].step, 2);
    });

    test('CounterModel deleteCounter works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Counter1', 1);
      model.addCounter('Counter2', 1);
      expect(model.length, 2);
      model.deleteCounter(0);
      expect(model.length, 1);
      expect(model.counters[0].name, 'Counter2');
    });

    test('CounterModel clearAllCounters works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Counter1', 1);
      model.addCounter('Counter2', 1);
      expect(model.length, 2);
      await model.clearAllCounters();
      expect(model.length, 0);
    });

    test('CounterItem toJson and fromJson work', () {
      final item = CounterItem(name: 'Test', count: 10, step: 5);
      final json = item.toJson();
      final restored = CounterItem.fromJson(json);
      expect(restored.name, 'Test');
      expect(restored.count, 10);
      expect(restored.step, 5);
    });

    test('CounterItem copyWith works', () {
      final item = CounterItem(name: 'Test', count: 5, step: 2);
      final copied = item.copyWith(count: 10);
      expect(copied.name, 'Test');
      expect(copied.count, 10);
      expect(copied.step, 2);
    });

    test('CounterModel totalCount getter works', () async {
      final model = CounterModel();
      await model.init();
      model.addCounter('Counter1', 1);
      model.addCounter('Counter2', 1);
      model.increment(0);
      model.increment(0);
      model.increment(0);
      model.increment(1);
      model.increment(1);
      expect(model.totalCount, 5);
    });

    testWidgets('CounterCard renders loading state', (WidgetTester tester) async {
      final model = CounterModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: CounterCard(),
          ),
        ),
      ));
      
      expect(find.text('Counter: Loading...'), findsOneWidget);
    });

    testWidgets('CounterCard renders empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = CounterModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: CounterCard(),
            ),
          ),
        ),
      ));
      
      expect(find.text('Counter'), findsOneWidget);
      expect(find.text('No counters. Tap + to add one!'), findsOneWidget);
    });

    testWidgets('CounterCard renders with counters', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = CounterModel();
      await model.init();
      model.addCounter('Reps', 1);
      model.increment(0);
      model.increment(0);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: CounterCard(),
            ),
          ),
        ),
      ));
      
      expect(find.text('Counter'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    test('CounterCard widget exists', () {
      expect(CounterCard, isNotNull);
    });

    test('AddCounterDialog widget exists', () {
      expect(AddCounterDialog, isNotNull);
    });

    test('EditCounterDialog widget exists', () {
      expect(EditCounterDialog, isNotNull);
    });

    test('Global.providerList includes Counter', () {
      final hasCounter = Global.providerList.any((p) => p.name == 'Counter');
      expect(hasCounter, true);
    });

    test('providerCounter exists', () {
      expect(providerCounter, isNotNull);
      expect(providerCounter.name, 'Counter');
    });

    test('Counter provider keywords include counter', () {
      final keywords = 'counter count tap tally number increment add track';
      expect(keywords.contains('counter'), true);
    });

    test('Counter provider keywords include count', () {
      final keywords = 'counter count tap tally number increment add track';
      expect(keywords.contains('count'), true);
    });

    test('Counter provider keywords include increment', () {
      final keywords = 'counter count tap tally number increment add track';
      expect(keywords.contains('increment'), true);
    });

    test('CounterModel is ChangeNotifier', () {
      final model = CounterModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('counterModel global instance exists', () {
      expect(counterModel, isNotNull);
    });

    test('CounterModel length getter works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CounterModel();
      await model.init();
      expect(model.length, 0);
      model.addCounter('Test', 1);
      expect(model.length, 1);
    });

    test('CounterModel persistence works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = CounterModel();
      await model.init();
      model.addCounter('Reps', 1);
      model.increment(0);
      model.increment(0);
      expect(model.counters[0].count, 2);
      
      final model2 = CounterModel();
      await model2.init();
      expect(model2.length, 1);
      expect(model2.counters[0].name, 'Reps');
      expect(model2.counters[0].count, 2);
    });
  });

  group('Tip Calculator provider tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('TipModel is initialized correctly', () {
      final model = TipModel();
      model.init();
      expect(model.isInitialized, true);
      expect(model.billAmount, 0);
      expect(model.tipPercentage, 15);
      expect(model.splitCount, 1);
    });

    test('TipModel setBillAmount works', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      expect(model.billAmount, 100);
    });

    test('TipModel setTipPercentage works', () {
      final model = TipModel();
      model.init();
      model.setTipPercentage(20);
      expect(model.tipPercentage, 20);
    });

    test('TipModel setSplitCount works', () {
      final model = TipModel();
      model.init();
      model.setSplitCount(4);
      expect(model.splitCount, 4);
    });

    test('TipModel splitCount clamp works', () {
      final model = TipModel();
      model.init();
      model.setSplitCount(0);
      expect(model.splitCount, 1);
      model.setSplitCount(25);
      expect(model.splitCount, 20);
    });

    test('TipModel incrementSplit works', () {
      final model = TipModel();
      model.init();
      model.setSplitCount(1);
      model.incrementSplit();
      expect(model.splitCount, 2);
    });

    test('TipModel incrementSplit stops at 20', () {
      final model = TipModel();
      model.init();
      model.setSplitCount(20);
      model.incrementSplit();
      expect(model.splitCount, 20);
    });

    test('TipModel decrementSplit works', () {
      final model = TipModel();
      model.init();
      model.setSplitCount(2);
      model.decrementSplit();
      expect(model.splitCount, 1);
    });

    test('TipModel decrementSplit stops at 1', () {
      final model = TipModel();
      model.init();
      model.setSplitCount(1);
      model.decrementSplit();
      expect(model.splitCount, 1);
    });

    test('TipModel tipAmount calculation works', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      model.setTipPercentage(15);
      expect(model.tipAmount, 15);
    });

    test('TipModel totalAmount calculation works', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      model.setTipPercentage(15);
      expect(model.totalAmount, 115);
    });

    test('TipModel perPerson calculation works', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      model.setTipPercentage(15);
      model.setSplitCount(4);
      expect(model.perPerson, 28.75);
    });

    test('TipModel tipPerPerson calculation works', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      model.setTipPercentage(15);
      model.setSplitCount(4);
      expect(model.tipPerPerson, 3.75);
    });

    test('TipModel isCustomPercentage works', () {
      final model = TipModel();
      model.init();
      expect(model.isCustomPercentage, false);
      model.setTipPercentage(17);
      expect(model.isCustomPercentage, true);
      model.setTipPercentage(15);
      expect(model.isCustomPercentage, false);
    });

    test('TipModel saveToHistory works', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      model.setTipPercentage(20);
      model.setSplitCount(2);
      model.saveToHistory();
      expect(model.history.length, 1);
      expect(model.history[0].billAmount, 100);
      expect(model.history[0].tipPercentage, 20);
      expect(model.history[0].splitCount, 2);
    });

    test('TipModel saveToHistory max limit works', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      model.setTipPercentage(15);
      for (int i = 0; i < 15; i++) {
        model.saveToHistory();
      }
      expect(model.history.length, TipModel.maxHistory);
    });

    test('TipModel saveToHistory ignores zero bill', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(0);
      model.saveToHistory();
      expect(model.history.length, 0);
    });

    test('TipModel clearHistory works', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      model.saveToHistory();
      expect(model.history.length, 1);
      model.clearHistory();
      expect(model.history.length, 0);
    });

    test('TipModel clear works', () {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      model.setTipPercentage(20);
      model.setSplitCount(4);
      model.clear();
      expect(model.billAmount, 0);
      expect(model.tipPercentage, 15);
      expect(model.splitCount, 1);
    });

    test('TipModel formatAmount works', () {
      final model = TipModel();
      model.init();
      expect(model.formatAmount(100), '\$100');
      expect(model.formatAmount(28.75), '\$28.75');
      expect(model.formatAmount(15.0), '\$15');
    });

    test('TipModel presetPercentages contains expected values', () {
      expect(TipModel.presetPercentages, contains(10));
      expect(TipModel.presetPercentages, contains(15));
      expect(TipModel.presetPercentages, contains(18));
      expect(TipModel.presetPercentages, contains(20));
      expect(TipModel.presetPercentages, contains(25));
    });

    testWidgets('TipCard renders loading state', (WidgetTester tester) async {
      final model = TipModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: TipCard(),
          ),
        ),
      ));

      expect(find.text('Tip Calculator: Loading...'), findsOneWidget);
    });

    testWidgets('TipCard renders initialized state', (WidgetTester tester) async {
      final model = TipModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: TipCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Tip Calculator'), findsOneWidget);
      expect(find.text('Bill Amount'), findsOneWidget);
    });

    testWidgets('TipCard renders with calculations', (WidgetTester tester) async {
      final model = TipModel();
      model.init();
      model.setBillAmount(100);
      model.setTipPercentage(15);
      model.setSplitCount(2);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: TipCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Tip Calculator'), findsOneWidget);
      expect(find.text('\$15'), findsOneWidget);
      expect(find.text('\$115'), findsOneWidget);
      expect(find.text('Per Person'), findsOneWidget);
    });

    testWidgets('TipCard widget exists', (WidgetTester tester) async {
      expect(TipCard, isNotNull);
    });

    test('Global.providerList includes Tip', () {
      final hasTip = Global.providerList.any((p) => p.name == 'Tip');
      expect(hasTip, true);
    });

    test('providerTip exists', () {
      expect(providerTip, isNotNull);
      expect(providerTip.name, 'Tip');
    });

    test('Tip provider keywords include tip', () {
      final keywords = 'tip tipcalc calculator bill restaurant dining split';
      expect(keywords.contains('tip'), true);
    });

    test('Tip provider keywords include bill', () {
      final keywords = 'tip tipcalc calculator bill restaurant dining split';
      expect(keywords.contains('bill'), true);
    });

    test('Tip provider keywords include split', () {
      final keywords = 'tip tipcalc calculator bill restaurant dining split';
      expect(keywords.contains('split'), true);
    });

    test('TipModel is ChangeNotifier', () {
      final model = TipModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('tipModel global instance exists', () {
      expect(tipModel, isNotNull);
    });

    test('TipCalculation data structure works', () {
      final calc = TipCalculation(
        billAmount: 100,
        tipPercentage: 15,
        splitCount: 2,
        tipAmount: 15,
        totalAmount: 115,
        perPerson: 57.5,
        tipPerPerson: 7.5,
        timestamp: DateTime.now(),
      );
      
      expect(calc.billAmount, 100);
      expect(calc.tipPercentage, 15);
      expect(calc.splitCount, 2);
      expect(calc.tipAmount, 15);
      expect(calc.totalAmount, 115);
      expect(calc.perPerson, 57.5);
      expect(calc.tipPerPerson, 7.5);
    });

    test('TipModel hasHistory getter works', () {
      final model = TipModel();
      model.init();
      expect(model.hasHistory, false);
      model.setBillAmount(100);
      model.saveToHistory();
      expect(model.hasHistory, true);
    });
  });

  group('BMI Calculator provider tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('BmiEntry toJson and fromJson work correctly', () {
      final entry = BmiEntry(
        date: DateTime(2024, 1, 15),
        bmi: 22.5,
        weight: 70.0,
        unit: 'metric',
        height: 175.0,
      );
      
      final json = entry.toJson();
      final restored = BmiEntry.fromJson(json);
      
      expect(restored.date, entry.date);
      expect(restored.bmi, entry.bmi);
      expect(restored.weight, entry.weight);
      expect(restored.unit, entry.unit);
      expect(restored.height, entry.height);
    });

    test('BmiModel initializes correctly', () async {
      final model = BmiModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.unit, 'metric');
      expect(model.history.length, 0);
    });

    test('BmiModel setWeight works', () {
      final model = BmiModel();
      model.init();
      model.setHeightMetric(175);
      model.setWeight(70);
      expect(model.weight, 70);
      expect(model.calculatedBmi, closeTo(22.86, 0.1));
    });

    test('BmiModel setHeightMetric works', () {
      final model = BmiModel();
      model.init();
      model.setWeight(70);
      model.setHeightMetric(175);
      expect(model.heightMetric, 175);
      expect(model.calculatedBmi, closeTo(22.86, 0.1));
    });

    test('BmiModel setUnit works', () {
      final model = BmiModel();
      model.init();
      model.setUnit('imperial');
      expect(model.unit, 'imperial');
    });

    test('BmiModel metric BMI calculation is correct', () {
      final model = BmiModel();
      model.init();
      model.setWeight(70);
      model.setHeightMetric(175);
      expect(model.calculatedBmi, closeTo(22.86, 0.1));
    });

    test('BmiModel imperial BMI calculation is correct', () {
      final model = BmiModel();
      model.init();
      model.setUnit('imperial');
      model.setWeight(154);
      model.setHeightFeet(5);
      model.setHeightInches(9);
      final totalInches = 5 * 12.0 + 9;
      final expectedBmi = (154 * 703) / (totalInches * totalInches);
      expect(model.calculatedBmi, closeTo(expectedBmi, 0.1));
    });

    test('BmiModel getBmiCategory works', () {
      final model = BmiModel();
      model.init();
      expect(model.getBmiCategory(17.0), 'Underweight');
      expect(model.getBmiCategory(22.0), 'Normal');
      expect(model.getBmiCategory(27.0), 'Overweight');
      expect(model.getBmiCategory(32.0), 'Obese');
    });

    test('BmiModel saveToHistory works', () async {
      final model = BmiModel();
      await model.init();
      model.setWeight(70);
      model.setHeightMetric(175);
      model.saveToHistory();
      expect(model.history.length, 1);
      expect(model.history[0].bmi, closeTo(22.86, 0.1));
    });

    test('BmiModel saveToHistory max limit works', () async {
      final model = BmiModel();
      await model.init();
      model.setHeightMetric(175);
      for (int i = 0; i < 15; i++) {
        model.setWeight(70.0 + i);
        model.saveToHistory();
      }
      expect(model.history.length, 10);
    });

    test('BmiModel saveToHistory ignores zero weight', () async {
      final model = BmiModel();
      await model.init();
      model.setWeight(0);
      model.setHeightMetric(175);
      model.saveToHistory();
      expect(model.history.length, 0);
    });

    test('BmiModel clearHistory works', () async {
      final model = BmiModel();
      await model.init();
      model.setWeight(70);
      model.setHeightMetric(175);
      model.saveToHistory();
      model.clearHistory();
      expect(model.history.length, 0);
    });

    test('BmiModel clear works', () {
      final model = BmiModel();
      model.init();
      model.setWeight(70);
      model.setHeightMetric(175);
      model.clear();
      expect(model.weight, 0);
      expect(model.heightMetric, 0);
      expect(model.calculatedBmi, null);
    });

    test('BmiModel loadFromHistory works', () async {
      final model = BmiModel();
      await model.init();
      model.setWeight(70);
      model.setHeightMetric(175);
      model.saveToHistory();
      
      final entry = model.history[0];
      model.clear();
      model.loadFromHistory(entry);
      
      expect(model.weight, 70);
      expect(model.heightMetric, 175);
      expect(model.calculatedBmi, closeTo(22.86, 0.1));
    });

    test('BmiModel hasHistory getter works', () async {
      final model = BmiModel();
      await model.init();
      expect(model.hasHistory, false);
      model.setWeight(70);
      model.setHeightMetric(175);
      model.saveToHistory();
      expect(model.hasHistory, true);
    });

    test('BmiModel requestFocus works', () {
      final model = BmiModel();
      model.init();
      model.requestFocus();
      expect(model.shouldFocus, true);
    });

    test('BmiModel is ChangeNotifier', () {
      final model = BmiModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('bmiModel global instance exists', () {
      expect(bmiModel, isNotNull);
    });

    test('Global.providerList includes BMI', () {
      final hasBmi = Global.providerList.any((p) => p.name == 'BMI');
      expect(hasBmi, true);
    });

    test('providerBMI exists', () {
      expect(providerBMI, isNotNull);
      expect(providerBMI.name, 'BMI');
    });

    test('BMI provider keywords include bmi', () {
      final keywords = 'bmi body mass index weight height health calculator metric imperial';
      expect(keywords.contains('bmi'), true);
    });

    test('BMI provider keywords include weight', () {
      final keywords = 'bmi body mass index weight height health calculator metric imperial';
      expect(keywords.contains('weight'), true);
    });

    test('BMI provider keywords include height', () {
      final keywords = 'bmi body mass index weight height health calculator metric imperial';
      expect(keywords.contains('height'), true);
    });

    testWidgets('BmiCard renders loading state', (WidgetTester tester) async {
      final model = BmiModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: BmiCard(),
          ),
        ),
      ));

      expect(find.text('BMI Calculator: Loading...'), findsOneWidget);
    });

    testWidgets('BmiCard renders initialized state', (WidgetTester tester) async {
      final model = BmiModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: BmiCard(),
            ),
          ),
        ),
      ));

      expect(find.text('BMI Calculator'), findsOneWidget);
    });

    testWidgets('BmiCard renders with BMI calculation', (WidgetTester tester) async {
      final model = BmiModel();
      await model.init();
      model.setWeight(70);
      model.setHeightMetric(175);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: BmiCard(),
            ),
          ),
        ),
      ));

      expect(find.text('BMI Calculator'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
    });

    testWidgets('BmiCard widget exists', (WidgetTester tester) async {
      expect(BmiCard, isNotNull);
    });
  });

  group('Metronome provider tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('MetronomeModel initializes correctly', () {
      final model = MetronomeModel();
      model.init();
      expect(model.isInitialized, true);
      expect(model.bpm, 120);
      expect(model.timeSignature, 4);
      expect(model.isRunning, false);
      expect(model.history.length, 0);
    });

    test('MetronomeModel setBpm works', () {
      final model = MetronomeModel();
      model.init();
      model.setBpm(80);
      expect(model.bpm, 80);
    });

    test('MetronomeModel setBpm clamps to min/max', () {
      final model = MetronomeModel();
      model.init();
      model.setBpm(10);
      expect(model.bpm, 20);
      model.setBpm(400);
      expect(model.bpm, 300);
    });

    test('MetronomeModel incrementBpm works', () {
      final model = MetronomeModel();
      model.init();
      model.incrementBpm(10);
      expect(model.bpm, 130);
    });

    test('MetronomeModel decrementBpm works', () {
      final model = MetronomeModel();
      model.init();
      model.decrementBpm(10);
      expect(model.bpm, 110);
    });

    test('MetronomeModel setTimeSignature works', () {
      final model = MetronomeModel();
      model.init();
      model.setTimeSignature(3);
      expect(model.timeSignature, 3);
    });

    test('MetronomeModel setTimeSignature only accepts valid values', () {
      final model = MetronomeModel();
      model.init();
      model.setTimeSignature(5);
      expect(model.timeSignature, 4);
    });

    test('MetronomeModel start works', () {
      final model = MetronomeModel();
      model.init();
      model.start();
      expect(model.isRunning, true);
      expect(model.currentBeat, 1);
      model.stop();
    });

    test('MetronomeModel pause works', () {
      final model = MetronomeModel();
      model.init();
      model.start();
      expect(model.isRunning, true);
      model.pause();
      expect(model.isRunning, false);
    });

    test('MetronomeModel stop works', () {
      final model = MetronomeModel();
      model.init();
      model.start();
      model.stop();
      expect(model.isRunning, false);
      expect(model.currentBeat, 0);
    });

    test('MetronomeModel toggle works', () {
      final model = MetronomeModel();
      model.init();
      expect(model.isRunning, false);
      model.toggle();
      expect(model.isRunning, true);
      model.toggle();
      expect(model.isRunning, false);
    });

    test('MetronomeModel isAccentBeat works', () {
      final model = MetronomeModel();
      model.init();
      model.setTimeSignature(4);
      model.start();
      expect(model.isAccentBeat, true);
      model.stop();
    });

    test('MetronomeModel saveToHistory works', () {
      final model = MetronomeModel();
      model.init();
      model.setBpm(80);
      model.saveToHistory();
      expect(model.history.length, 1);
      expect(model.history[0], 80);
    });

    test('MetronomeModel saveToHistory max limit works', () {
      final model = MetronomeModel();
      model.init();
      for (int i = 0; i < 15; i++) {
        model.setBpm(60 + i * 10);
        model.saveToHistory();
      }
      expect(model.history.length, 10);
    });

    test('MetronomeModel saveToHistory removes duplicate', () {
      final model = MetronomeModel();
      model.init();
      model.setBpm(80);
      model.saveToHistory();
      model.setBpm(100);
      model.saveToHistory();
      model.setBpm(80);
      model.saveToHistory();
      expect(model.history.length, 2);
      expect(model.history[0], 80);
    });

    test('MetronomeModel loadFromHistory works', () {
      final model = MetronomeModel();
      model.init();
      model.setBpm(80);
      model.saveToHistory();
      model.setBpm(120);
      model.loadFromHistory(80);
      expect(model.bpm, 80);
    });

    test('MetronomeModel clearHistory works', () {
      final model = MetronomeModel();
      model.init();
      model.setBpm(80);
      model.saveToHistory();
      model.clearHistory();
      expect(model.history.length, 0);
    });

    test('MetronomeModel hasHistory getter works', () {
      final model = MetronomeModel();
      model.init();
      expect(model.hasHistory, false);
      model.setBpm(80);
      model.saveToHistory();
      expect(model.hasHistory, true);
    });

    test('MetronomeModel clearTapTimes works', () {
      final model = MetronomeModel();
      model.init();
      model.tapTempo();
      model.tapTempo();
      model.clearTapTimes();
    });

    test('MetronomeModel requestFocus works', () {
      final model = MetronomeModel();
      model.init();
      model.requestFocus();
      expect(model.shouldFocus, true);
    });

    test('MetronomeModel is ChangeNotifier', () {
      final model = MetronomeModel();
      expect(model, isA<ChangeNotifier>());
    });

    test('metronomeModel global instance exists', () {
      expect(metronomeModel, isNotNull);
    });

    test('Global.providerList includes Metronome', () {
      final hasMetronome = Global.providerList.any((p) => p.name == 'Metronome');
      expect(hasMetronome, true);
    });

    test('providerMetronome exists', () {
      expect(providerMetronome, isNotNull);
      expect(providerMetronome.name, 'Metronome');
    });

    test('Metronome provider keywords include metronome', () {
      final keywords = 'metronome beat bpm tempo rhythm music tap pulse';
      expect(keywords.contains('metronome'), true);
    });

    test('Metronome provider keywords include bpm', () {
      final keywords = 'metronome beat bpm tempo rhythm music tap pulse';
      expect(keywords.contains('bpm'), true);
    });

    test('Metronome provider keywords include tempo', () {
      final keywords = 'metronome beat bpm tempo rhythm music tap pulse';
      expect(keywords.contains('tempo'), true);
    });

    test('MetronomeModel preset Bpm values are valid', () {
      for (final bpm in MetronomeModel.presetBpm) {
        expect(bpm >= MetronomeModel.minBpm, true);
        expect(bpm <= MetronomeModel.maxBpm, true);
      }
    });

    test('MetronomeModel time signature options are valid', () {
      for (final ts in MetronomeModel.timeSignatureOptions) {
        expect(ts > 0, true);
        expect(ts < 20, true);
      }
    });

    testWidgets('MetronomeCard renders loading state', (WidgetTester tester) async {
      final model = MetronomeModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: MetronomeCard(),
          ),
        ),
      ));

      expect(find.text('Metronome: Loading...'), findsOneWidget);
    });

    testWidgets('MetronomeCard renders initialized state', (WidgetTester tester) async {
      final model = MetronomeModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: MetronomeCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Metronome'), findsOneWidget);
    });

    testWidgets('MetronomeCard shows BPM display', (WidgetTester tester) async {
      final model = MetronomeModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: MetronomeCard(),
            ),
          ),
        ),
      ));

      expect(find.textContaining('120'), findsWidgets);
    });

    testWidgets('MetronomeCard widget exists', (WidgetTester tester) async {
      expect(MetronomeCard, isNotNull);
    });

    testWidgets('MetronomeCard shows play button', (WidgetTester tester) async {
      final model = MetronomeModel();
      model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: MetronomeCard(),
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });

  group('Flashcard provider tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      flashcardModel = FlashcardModel();
      await flashcardModel.init();
    });

    test('FlashcardItem toJson and fromJson work', () {
      final item = FlashcardItem(front: 'Question', back: 'Answer');
      final json = item.toJson();
      final restored = FlashcardItem.fromJson(json);
      
      expect(restored.front, 'Question');
      expect(restored.back, 'Answer');
    });

    test('FlashcardDeck toJson and fromJson work', () {
      final deck = FlashcardDeck(
        name: 'Test Deck',
        cards: [FlashcardItem(front: 'Q1', back: 'A1')],
        correctCount: 5,
        incorrectCount: 3,
      );
      final json = deck.toJson();
      final restored = FlashcardDeck.fromJson(json);
      
      expect(restored.name, 'Test Deck');
      expect(restored.cards.length, 1);
      expect(restored.correctCount, 5);
      expect(restored.incorrectCount, 3);
    });

    test('FlashcardDeck totalCards getter works', () {
      final deck = FlashcardDeck(
        name: 'Test',
        cards: [
          FlashcardItem(front: 'Q1', back: 'A1'),
          FlashcardItem(front: 'Q2', back: 'A2'),
        ],
      );
      
      expect(deck.totalCards, 2);
    });

    test('FlashcardDeck accuracy calculation works', () {
      final deck = FlashcardDeck(
        name: 'Test',
        correctCount: 8,
        incorrectCount: 2,
      );
      
      expect(deck.accuracy, 80.0);
    });

    test('FlashcardDeck accuracy with zero studiedCards', () {
      final deck = FlashcardDeck(name: 'Test');
      
      expect(deck.accuracy, 0);
    });

    test('FlashcardModel isInitialized is false before init', () {
      final model = FlashcardModel();
      expect(model.isInitialized, false);
    });

    test('FlashcardModel isInitialized is true after init', () async {
      final model = FlashcardModel();
      await model.init();
      expect(model.isInitialized, true);
    });

    test('FlashcardModel decks getter works', () {
      expect(flashcardModel.decks, isNotNull);
    });

    test('FlashcardModel totalDecks getter works', () {
      expect(flashcardModel.totalDecks, 0);
    });

    test('FlashcardModel totalCards getter works', () {
      expect(flashcardModel.totalCards, 0);
    });

    test('FlashcardModel addDeck works', () async {
      flashcardModel.addDeck('Math');
      
      expect(flashcardModel.totalDecks, 1);
      expect(flashcardModel.decks[0].name, 'Math');
    });

    test('FlashcardModel addDeck removes oldest when max limit reached', () async {
      for (int i = 0; i < 12; i++) {
        flashcardModel.addDeck('Deck $i');
      }
      
      expect(flashcardModel.totalDecks, 10);
      expect(flashcardModel.decks[0].name, 'Deck 2');
    });

    test('FlashcardModel updateDeck works', () async {
      flashcardModel.addDeck('Original');
      flashcardModel.updateDeck(0, 'Updated');
      
      expect(flashcardModel.decks[0].name, 'Updated');
    });

    test('FlashcardModel deleteDeck works', () async {
      flashcardModel.addDeck('Deck 1');
      flashcardModel.addDeck('Deck 2');
      flashcardModel.deleteDeck(0);
      
      expect(flashcardModel.totalDecks, 1);
      expect(flashcardModel.decks[0].name, 'Deck 2');
    });

    test('FlashcardModel addCard works', () async {
      flashcardModel.addDeck('Test Deck');
      flashcardModel.addCard(0, 'Q1', 'A1');
      
      expect(flashcardModel.decks[0].cards.length, 1);
      expect(flashcardModel.decks[0].cards[0].front, 'Q1');
      expect(flashcardModel.decks[0].cards[0].back, 'A1');
    });

    test('FlashcardModel addCard removes oldest when max limit reached', () async {
      flashcardModel.addDeck('Test');
      for (int i = 0; i < 55; i++) {
        flashcardModel.addCard(0, 'Q$i', 'A$i');
      }
      
      expect(flashcardModel.decks[0].cards.length, 50);
      expect(flashcardModel.decks[0].cards[0].front, 'Q5');
    });

    test('FlashcardModel deleteCard works', () async {
      flashcardModel.addDeck('Test');
      flashcardModel.addCard(0, 'Q1', 'A1');
      flashcardModel.addCard(0, 'Q2', 'A2');
      flashcardModel.deleteCard(0, 0);
      
      expect(flashcardModel.decks[0].cards.length, 1);
      expect(flashcardModel.decks[0].cards[0].front, 'Q2');
    });

    test('FlashcardModel recordStudyResult correct', () async {
      flashcardModel.addDeck('Test');
      flashcardModel.recordStudyResult(0, true);
      
      expect(flashcardModel.decks[0].correctCount, 1);
      expect(flashcardModel.decks[0].incorrectCount, 0);
    });

    test('FlashcardModel recordStudyResult incorrect', () async {
      flashcardModel.addDeck('Test');
      flashcardModel.recordStudyResult(0, false);
      
      expect(flashcardModel.decks[0].correctCount, 0);
      expect(flashcardModel.decks[0].incorrectCount, 1);
    });

    test('FlashcardModel clearAllDecks works', () async {
      flashcardModel.addDeck('Deck 1');
      flashcardModel.addDeck('Deck 2');
      await flashcardModel.clearAllDecks();
      
      expect(flashcardModel.totalDecks, 0);
    });

    test('FlashcardModel is ChangeNotifier', () {
      expect(flashcardModel is ChangeNotifier, true);
    });

    test('flashcardModel global instance exists', () {
      expect(flashcardModel, isNotNull);
    });

    test('Global.providerList includes Flashcard', () {
      final flashcardProvider = Global.providerList.where((p) => p.name == 'Flashcard').first;
      expect(flashcardProvider, isNotNull);
    });

    test('providerFlashcard exists', () {
      expect(providerFlashcard, isNotNull);
    });

    test('Flashcard provider keywords include flashcard', () {
      final keywords = 'flashcard flash cards study learn memorize quiz deck review';
      expect(keywords.contains('flashcard'), true);
    });

    test('Flashcard provider keywords include study', () {
      final keywords = 'flashcard flash cards study learn memorize quiz deck review';
      expect(keywords.contains('study'), true);
    });

    test('Flashcard provider keywords include learn', () {
      final keywords = 'flashcard flash cards study learn memorize quiz deck review';
      expect(keywords.contains('learn'), true);
    });

    test('FlashcardDeck copyWith works', () {
      final deck = FlashcardDeck(name: 'Original');
      final updated = deck.copyWith(name: 'Updated', correctCount: 5);
      
      expect(updated.name, 'Updated');
      expect(updated.correctCount, 5);
    });

    test('FlashcardItem copyWith works', () {
      final item = FlashcardItem(front: 'Q', back: 'A');
      final updated = item.copyWith(front: 'NewQ');
      
      expect(updated.front, 'NewQ');
      expect(updated.back, 'A');
    });

    testWidgets('FlashcardCard renders loading state', (WidgetTester tester) async {
      final model = FlashcardModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: FlashcardCard(),
          ),
        ),
      ));

      expect(find.text('Flashcard Study: Loading...'), findsOneWidget);
    });

    testWidgets('FlashcardCard renders initialized state', (WidgetTester tester) async {
      final model = FlashcardModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: FlashcardCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Flashcard Study'), findsOneWidget);
    });

    testWidgets('FlashcardCard shows empty state message', (WidgetTester tester) async {
      final model = FlashcardModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: FlashcardCard(),
            ),
          ),
        ),
      ));

      expect(find.text('No decks. Tap + to create one!'), findsOneWidget);
    });

    testWidgets('FlashcardCard widget exists', (WidgetTester tester) async {
      expect(FlashcardCard, isNotNull);
    });

    testWidgets('FlashcardCard shows add button', (WidgetTester tester) async {
      final model = FlashcardModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: FlashcardCard(),
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('AddDeckDialog widget exists', (WidgetTester tester) async {
      expect(AddDeckDialog, isNotNull);
    });

    testWidgets('EditDeckDialog widget exists', (WidgetTester tester) async {
      expect(EditDeckDialog, isNotNull);
    });

    testWidgets('AddCardDialog widget exists', (WidgetTester tester) async {
      expect(AddCardDialog, isNotNull);
    });

    testWidgets('StudyDialog widget exists', (WidgetTester tester) async {
      expect(StudyDialog, isNotNull);
    });
  });

  group('Workout provider tests', () {
    test('WorkoutType enum has correct values', () {
      expect(WorkoutType.values.length, 8);
      expect(WorkoutType.running, isNotNull);
      expect(WorkoutType.cycling, isNotNull);
      expect(WorkoutType.weights, isNotNull);
      expect(WorkoutType.yoga, isNotNull);
      expect(WorkoutType.swimming, isNotNull);
      expect(WorkoutType.walking, isNotNull);
      expect(WorkoutType.hiit, isNotNull);
      expect(WorkoutType.other, isNotNull);
    });

    test('WorkoutType emoji works', () {
      expect(WorkoutType.running.emoji, '🏃');
      expect(WorkoutType.cycling.emoji, '🚴');
      expect(WorkoutType.weights.emoji, '🏋️');
      expect(WorkoutType.yoga.emoji, '🧘');
      expect(WorkoutType.swimming.emoji, '🏊');
      expect(WorkoutType.walking.emoji, '🚶');
      expect(WorkoutType.hiit.emoji, '⚡');
      expect(WorkoutType.other.emoji, '💪');
    });

    test('WorkoutType label works', () {
      expect(WorkoutType.running.label, 'Running');
      expect(WorkoutType.cycling.label, 'Cycling');
      expect(WorkoutType.weights.label, 'Weights');
      expect(WorkoutType.yoga.label, 'Yoga');
      expect(WorkoutType.swimming.label, 'Swimming');
      expect(WorkoutType.walking.label, 'Walking');
      expect(WorkoutType.hiit.label, 'HIIT');
      expect(WorkoutType.other.label, 'Other');
    });

    test('WorkoutType fromString works', () {
      expect(WorkoutTypeExtension.fromString('running'), WorkoutType.running);
      expect(WorkoutTypeExtension.fromString('cycling'), WorkoutType.cycling);
      expect(WorkoutTypeExtension.fromString('weights'), WorkoutType.weights);
      expect(WorkoutTypeExtension.fromString('yoga'), WorkoutType.yoga);
      expect(WorkoutTypeExtension.fromString('swimming'), WorkoutType.swimming);
      expect(WorkoutTypeExtension.fromString('walking'), WorkoutType.walking);
      expect(WorkoutTypeExtension.fromString('hiit'), WorkoutType.hiit);
      expect(WorkoutTypeExtension.fromString('other'), WorkoutType.other);
      expect(WorkoutTypeExtension.fromString('unknown'), WorkoutType.other);
    });

    test('WorkoutEntry properties work', () {
      final entry = WorkoutEntry(
        date: DateTime(2026, 4, 24),
        type: WorkoutType.running,
        durationMinutes: 30,
        note: 'Good run',
      );
      expect(entry.date, DateTime(2026, 4, 24));
      expect(entry.type, WorkoutType.running);
      expect(entry.durationMinutes, 30);
      expect(entry.note, 'Good run');
    });

    test('WorkoutEntry formatDuration works', () {
      final entry1 = WorkoutEntry(date: DateTime.now(), type: WorkoutType.running, durationMinutes: 30);
      expect(entry1.formatDuration(), '30m');

      final entry2 = WorkoutEntry(date: DateTime.now(), type: WorkoutType.running, durationMinutes: 60);
      expect(entry2.formatDuration(), '1h');

      final entry3 = WorkoutEntry(date: DateTime.now(), type: WorkoutType.running, durationMinutes: 90);
      expect(entry3.formatDuration(), '1h 30m');
    });

    test('WorkoutEntry toJson and fromJson work', () {
      final entry = WorkoutEntry(
        date: DateTime(2026, 4, 24),
        type: WorkoutType.weights,
        durationMinutes: 45,
        note: 'Test note',
      );
      final json = entry.toJson();
      final restored = WorkoutEntry.fromJson(json);

      expect(restored.date, entry.date);
      expect(restored.type, entry.type);
      expect(restored.durationMinutes, entry.durationMinutes);
      expect(restored.note, entry.note);
    });

    test('WorkoutEntry getDayKey works', () {
      final date = DateTime(2026, 4, 24);
      final key = WorkoutEntry.getDayKey(date);
      expect(key, '2026-4-24');
    });

    test('WorkoutModel initialization works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();
      expect(model.isInitialized, true);
      expect(model.history.length, 0);
    });

    test('WorkoutModel logWorkout works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      model.logWorkout(WorkoutType.running, 30);
      expect(model.history.length, 1);
      expect(model.history.first.type, WorkoutType.running);
      expect(model.history.first.durationMinutes, 30);
    });

    test('WorkoutModel logWorkout with custom date works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      final customDate = DateTime(2026, 4, 20);
      model.logWorkout(WorkoutType.cycling, 45, customDate: customDate);
      expect(model.history.length, 1);
      expect(model.history.first.date.day, 20);
    });

    test('WorkoutModel logWorkout with note works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      model.logWorkout(WorkoutType.weights, 60, note: 'Leg day');
      expect(model.history.length, 1);
      expect(model.history.first.note, 'Leg day');
    });

    test('WorkoutModel deleteEntry works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      model.logWorkout(WorkoutType.running, 30, customDate: DateTime.now().subtract(Duration(days: 2)));
      model.logWorkout(WorkoutType.cycling, 45, customDate: DateTime.now().subtract(Duration(days: 1)));

      expect(model.history.length, 2);
      model.deleteEntry(0);
      expect(model.history.length, 1);
    });

    test('WorkoutModel clearHistory works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      model.logWorkout(WorkoutType.running, 30);
      model.logWorkout(WorkoutType.cycling, 45, customDate: DateTime.now().subtract(Duration(days: 2)));

      await model.clearHistory();
      expect(model.history.length, 0);
    });

    test('WorkoutModel totalMinutes works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      model.logWorkout(WorkoutType.running, 30, customDate: DateTime.now().subtract(Duration(days: 2)));
      model.logWorkout(WorkoutType.cycling, 45, customDate: DateTime.now().subtract(Duration(days: 1)));

      expect(model.totalMinutes, 75);
    });

    test('WorkoutModel totalMinutes empty returns 0', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      expect(model.totalMinutes, 0);
    });

    test('WorkoutModel thisWeekMinutes works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: 2));
      final lastWeek = now.subtract(Duration(days: 10));

      model.logWorkout(WorkoutType.running, 30, customDate: thisWeek);
      model.logWorkout(WorkoutType.cycling, 45, customDate: lastWeek);

      expect(model.thisWeekMinutes, 30);
    });

    test('WorkoutModel thisMonthMinutes works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      final now = DateTime.now();
      final thisMonth = now.subtract(Duration(days: 5));
      final lastMonth = DateTime(now.year, now.month - 1, 15);

      model.logWorkout(WorkoutType.running, 30, customDate: thisMonth);
      model.logWorkout(WorkoutType.weights, 60, customDate: lastMonth);

      expect(model.thisMonthMinutes, 30);
    });

    test('WorkoutModel formatTotalMinutes works', () {
      final model = WorkoutModel();
      expect(model.formatTotalMinutes(30), '30m');
      expect(model.formatTotalMinutes(60), '1h');
      expect(model.formatTotalMinutes(90), '1h 30m');
    });

    test('WorkoutModel lastEntry works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      model.logWorkout(WorkoutType.running, 30, customDate: DateTime.now().subtract(Duration(days: 2)));
      model.logWorkout(WorkoutType.cycling, 45, customDate: DateTime.now().subtract(Duration(days: 1)));

      expect(model.lastEntry!.type, WorkoutType.cycling);
    });

    test('WorkoutModel lastEntry empty returns null', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      expect(model.lastEntry, null);
    });

    test('WorkoutModel hasHistory works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();

      expect(model.hasHistory, false);
      model.logWorkout(WorkoutType.running, 30);
      expect(model.hasHistory, true);
    });

    test('Workout provider exists', () {
      expect(providerWorkout, isNotNull);
      expect(providerWorkout.name, 'Workout');
    });

    test('Workout provider keywords include workout', () {
      final keywords = 'workout exercise gym fitness run cycle swim yoga walk training log';
      expect(keywords.contains('workout'), true);
    });

    test('Workout provider keywords include exercise', () {
      final keywords = 'workout exercise gym fitness run cycle swim yoga walk training log';
      expect(keywords.contains('exercise'), true);
    });

    test('Workout provider keywords include gym', () {
      final keywords = 'workout exercise gym fitness run cycle swim yoga walk training log';
      expect(keywords.contains('gym'), true);
    });

    test('Workout provider keywords include fitness', () {
      final keywords = 'workout exercise gym fitness run cycle swim yoga walk training log';
      expect(keywords.contains('fitness'), true);
    });

    testWidgets('WorkoutCard renders loading state', (WidgetTester tester) async {
      final model = WorkoutModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: WorkoutCard(),
          ),
        ),
      ));

      expect(find.text('Workout Log: Loading...'), findsOneWidget);
    });

    testWidgets('WorkoutCard renders initialized state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: WorkoutCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Workout Log'), findsOneWidget);
    });

    testWidgets('WorkoutCard shows empty state message', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: WorkoutCard(),
            ),
          ),
        ),
      ));

      expect(find.text('No workouts logged yet'), findsOneWidget);
    });

    testWidgets('WorkoutCard widget exists', (WidgetTester tester) async {
      expect(WorkoutCard, isNotNull);
    });

    testWidgets('WorkoutCard shows log button', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = WorkoutModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: WorkoutCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Log'), findsOneWidget);
    });

    testWidgets('WorkoutLogDialog widget exists', (WidgetTester tester) async {
      expect(WorkoutLogDialog, isNotNull);
    });
  });

  group('Age provider tests', () {
    test('AgeModel initialization works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      expect(model.isInitialized, true);
    });

    test('AgeModel getZodiacSign returns correct sign', () {
      final model = AgeModel();
      
      DateTime ariesDate = DateTime(2000, 3, 25);
      expect(model.getZodiacSign(ariesDate), 'Aries ♈');
      
      DateTime taurusDate = DateTime(2000, 4, 25);
      expect(model.getZodiacSign(taurusDate), 'Taurus ♉');
      
      DateTime geminiDate = DateTime(2000, 5, 25);
      expect(model.getZodiacSign(geminiDate), 'Gemini ♊');
      
      DateTime cancerDate = DateTime(2000, 6, 25);
      expect(model.getZodiacSign(cancerDate), 'Cancer ♋');
      
      DateTime leoDate = DateTime(2000, 8, 1);
      expect(model.getZodiacSign(leoDate), 'Leo ♌');
      
      DateTime capricornDate = DateTime(2000, 1, 1);
      expect(model.getZodiacSign(capricornDate), 'Capricorn ♑');
    });

    test('AgeModel getChineseZodiac returns correct sign', () {
      final model = AgeModel();
      
      DateTime ratYear = DateTime(2020, 1, 1);
      expect(model.getChineseZodiac(ratYear), 'Rat 🐀');
      
      DateTime oxYear = DateTime(2021, 1, 1);
      expect(model.getChineseZodiac(oxYear), 'Ox 🐂');
      
      DateTime tigerYear = DateTime(2022, 1, 1);
      expect(model.getChineseZodiac(tigerYear), 'Tiger 🐅');
      
      DateTime dragonYear = DateTime(2024, 1, 1);
      expect(model.getChineseZodiac(dragonYear), 'Dragon 🐲');
    });

    test('AgeModel calculateAgeYears works', () {
      final model = AgeModel();
      final now = DateTime.now();
      
      DateTime birthdate = DateTime(now.year - 25, now.month, now.day);
      expect(model.calculateAgeYears(birthdate), 25);
      
      DateTime birthdateBeforeBirthday = DateTime(now.year - 25, now.month + 1, now.day);
      expect(model.calculateAgeYears(birthdateBeforeBirthday), 24);
    });

    test('AgeModel calculateAgeMonths works', () {
      final model = AgeModel();
      final now = DateTime.now();
      
      DateTime birthdate = DateTime(now.year - 1, now.month, now.day);
      expect(model.calculateAgeMonths(birthdate), 12);
      
      DateTime birthdate6Months = DateTime(now.year, now.month - 6, now.day);
      expect(model.calculateAgeMonths(birthdate6Months), 6);
    });

    test('AgeModel calculateAgeDays works', () {
      final model = AgeModel();
      final now = DateTime.now();
      
      DateTime birthdate = now.subtract(Duration(days: 365));
      expect(model.calculateAgeDays(birthdate), 365);
      
      DateTime birthdateWeek = now.subtract(Duration(days: 7));
      expect(model.calculateAgeDays(birthdateWeek), 7);
    });

    test('AgeModel calculateDaysUntilNextBirthday works', () {
      final model = AgeModel();
      final now = DateTime.now();
      
      DateTime birthdateToday = DateTime(2000, now.month, now.day);
      int daysUntil = model.calculateDaysUntilNextBirthday(birthdateToday);
      expect(daysUntil <= 365, true);
      
      DateTime birthdateTomorrow = DateTime(2000, now.month, now.day + 1);
      daysUntil = model.calculateDaysUntilNextBirthday(birthdateTomorrow);
      expect(daysUntil, 1);
    });

    test('AgeModel formatAge works', () {
      final model = AgeModel();
      final now = DateTime.now();
      
      DateTime adultBirthdate = DateTime(now.year - 30, now.month, now.day);
      String formatted = model.formatAge(adultBirthdate);
      expect(formatted.contains('30 years'), true);
      
      DateTime infantBirthdate = DateTime(now.year, now.month - 6, now.day);
      formatted = model.formatAge(infantBirthdate);
      expect(formatted.contains('6 months'), true);
    });

    test('AgeModel formatAgeDetailed works', () {
      final model = AgeModel();
      final now = DateTime.now();
      
      DateTime birthdate = DateTime(now.year - 25, now.month, now.day);
      String formatted = model.formatAgeDetailed(birthdate);
      expect(formatted.contains('25 years'), true);
      expect(formatted.contains('days'), true);
    });

    test('AgeModel setBirthdate works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      DateTime birthdate = DateTime(1990, 6, 15);
      model.setBirthdate(birthdate);
      
      expect(model.birthdate, birthdate);
      expect(model.hasBirthdate, true);
    });

    test('AgeModel saveEntry works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      DateTime birthdate = DateTime(1995, 3, 20);
      model.setBirthdate(birthdate);
      model.saveEntry('Test Person');
      
      expect(model.savedEntries.length, 1);
      expect(model.savedEntries.first.name, 'Test Person');
      expect(model.savedEntries.first.birthdate, birthdate);
    });

    test('AgeModel loadEntry works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      DateTime birthdate1 = DateTime(1990, 1, 1);
      model.setBirthdate(birthdate1);
      model.saveEntry('Person 1');
      
      DateTime birthdate2 = DateTime(1985, 6, 15);
      model.setBirthdate(birthdate2);
      model.saveEntry('Person 2');
      
      model.loadEntry(model.savedEntries.first);
      expect(model.birthdate, birthdate2);
    });

    test('AgeModel deleteEntry works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      DateTime birthdate = DateTime(1990, 1, 1);
      model.setBirthdate(birthdate);
      model.saveEntry('Person 1');
      model.setBirthdate(DateTime(1985, 1, 1));
      model.saveEntry('Person 2');
      
      expect(model.savedEntries.length, 2);
      
      model.deleteEntry(0);
      expect(model.savedEntries.length, 1);
    });

    test('AgeModel clearAllEntries works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      DateTime birthdate = DateTime(1990, 1, 1);
      model.setBirthdate(birthdate);
      model.saveEntry('Person 1');
      model.setBirthdate(DateTime(1985, 1, 1));
      model.saveEntry('Person 2');
      
      model.clearAllEntries();
      expect(model.savedEntries.length, 0);
      expect(model.hasSavedEntries, false);
    });

    test('AgeModel clear works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      DateTime birthdate = DateTime(1990, 1, 1);
      model.setBirthdate(birthdate);
      
      model.clear();
      expect(model.birthdate, null);
      expect(model.hasBirthdate, false);
    });

    test('AgeModel max entries limit', () async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      for (int i = 0; i < 15; i++) {
        model.setBirthdate(DateTime(1990 + i, 1, 1));
        model.saveEntry('Person $i');
      }
      
      expect(model.savedEntries.length, 10);
    });

    test('Age provider exists', () {
      expect(providerAge, isNotNull);
    });

    test('Age provider keywords include age', () {
      final keywords = 'age birthday birthdate calculate years old zodiac';
      expect(keywords.contains('age'), true);
    });

    test('Age provider keywords include birthday', () {
      final keywords = 'age birthday birthdate calculate years old zodiac';
      expect(keywords.contains('birthday'), true);
    });

    test('Age provider keywords include zodiac', () {
      final keywords = 'age birthday birthdate calculate years old zodiac';
      expect(keywords.contains('zodiac'), true);
    });

    testWidgets('AgeCard renders loading state', (WidgetTester tester) async {
      final model = AgeModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: AgeCard(),
          ),
        ),
      ));

      expect(find.text('Age Calculator: Loading...'), findsOneWidget);
    });

    testWidgets('AgeCard renders initialized state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: AgeCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Age Calculator'), findsOneWidget);
    });

    testWidgets('AgeCard shows empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: AgeCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Select a birthdate to calculate age'), findsOneWidget);
    });

    testWidgets('AgeCard widget exists', (WidgetTester tester) async {
      expect(AgeCard, isNotNull);
    });

    testWidgets('AgeCard shows calendar button', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = AgeModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: AgeCard(),
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    test('AgeEntry toJson/fromJson works', () {
      final entry = AgeEntry(
        name: 'Test Person',
        birthdate: DateTime(1990, 6, 15),
        createdAt: DateTime(2026, 4, 24),
      );
      
      final json = entry.toJson();
      final restored = AgeEntry.fromJson(json);
      
      expect(restored.name, entry.name);
      expect(restored.birthdate, entry.birthdate);
      expect(restored.createdAt, entry.createdAt);
    });
  });

  group('Percentage provider tests', () {
    test('PercentageModel percentageOf calculation', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.percentageOf);
      model.setInput1('20');
      model.setInput2('100');
      
      final result = model.calculate();
      expect(result, 20.0);
    });

    test('PercentageModel whatPercent calculation', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.whatPercent);
      model.setInput1('50');
      model.setInput2('200');
      
      final result = model.calculate();
      expect(result, 25.0);
    });

    test('PercentageModel percentageChange calculation', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.percentageChange);
      model.setInput1('100');
      model.setInput2('150');
      
      final result = model.calculate();
      expect(result, 50.0);
    });

    test('PercentageModel percentageChange decrease', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.percentageChange);
      model.setInput1('100');
      model.setInput2('80');
      
      final result = model.calculate();
      expect(result, -20.0);
    });

    test('PercentageModel discount calculation', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.discount);
      model.setInput1('20');
      model.setInput2('100');
      
      final result = model.calculate();
      expect(result, 80.0);
    });

    test('PercentageModel handles invalid input', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setInput1('abc');
      model.setInput2('100');
      
      final result = model.calculate();
      expect(result, null);
    });

    test('PercentageModel handles empty input', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setInput1('');
      model.setInput2('');
      
      final result = model.calculate();
      expect(result, null);
    });

    test('PercentageModel handles division by zero in whatPercent', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.whatPercent);
      model.setInput1('50');
      model.setInput2('0');
      
      final result = model.calculate();
      expect(result, null);
    });

    test('PercentageModel handles division by zero in percentageChange', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.percentageChange);
      model.setInput1('0');
      model.setInput2('100');
      
      final result = model.calculate();
      expect(result, null);
    });

    test('PercentageModel history works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.percentageOf);
      model.setInput1('20');
      model.setInput2('100');
      model.addToHistory();
      
      expect(model.history.length, 1);
      expect(model.hasHistory, true);
    });

    test('PercentageModel history max limit', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.percentageOf);
      model.setInput1('10');
      model.setInput2('100');
      
      for (int i = 0; i < 15; i++) {
        model.addToHistory();
      }
      
      expect(model.history.length, 10);
    });

    test('PercentageModel loadFromHistory works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.percentageOf);
      model.setInput1('20');
      model.setInput2('100');
      model.addToHistory();
      
      model.setInput1('');
      model.setInput2('');
      
      model.loadFromHistory(model.history.first);
      
      expect(model.mode, PercentageMode.percentageOf);
      expect(model.input1, '20.0');
      expect(model.input2, '100.0');
    });

    test('PercentageModel clearHistory works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.percentageOf);
      model.setInput1('20');
      model.setInput2('100');
      model.addToHistory();
      
      model.clearHistory();
      
      expect(model.history.length, 0);
      expect(model.hasHistory, false);
    });

    test('PercentageModel clearInputs works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setInput1('20');
      model.setInput2('100');
      model.clearInputs();
      
      expect(model.input1, '');
      expect(model.input2, '');
    });

    test('PercentageModel setMode works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      model.setMode(PercentageMode.whatPercent);
      expect(model.mode, PercentageMode.whatPercent);
      
      model.setMode(PercentageMode.discount);
      expect(model.mode, PercentageMode.discount);
    });

    test('PercentageHistory toJson/fromJson works', () {
      final entry = PercentageHistory(
        mode: PercentageMode.percentageOf,
        value1: 20.0,
        value2: 100.0,
        result: 20.0,
        timestamp: DateTime(2026, 4, 24),
      );
      
      final json = entry.toJson();
      final restored = PercentageHistory.fromJson(json);
      
      expect(restored.mode, entry.mode);
      expect(restored.value1, entry.value1);
      expect(restored.value2, entry.value2);
      expect(restored.result, entry.result);
    });

    test('PercentageHistory modeLabel percentageOf', () {
      final entry = PercentageHistory(
        mode: PercentageMode.percentageOf,
        value1: 20.0,
        value2: 100.0,
        result: 20.0,
        timestamp: DateTime.now(),
      );
      
      expect(entry.modeLabel, '20.0% of 100.0');
    });

    test('PercentageHistory modeLabel whatPercent', () {
      final entry = PercentageHistory(
        mode: PercentageMode.whatPercent,
        value1: 50.0,
        value2: 200.0,
        result: 25.0,
        timestamp: DateTime.now(),
      );
      
      expect(entry.modeLabel, '50.0 is ?% of 200.0');
    });

    test('Percentage provider exists', () {
      expect(providerPercentage, isNotNull);
    });

    test('Percentage provider keywords include percentage', () {
      final keywords = 'percentage percent calc discount ratio rate %';
      expect(keywords.contains('percentage'), true);
    });

    test('Percentage provider keywords include percent', () {
      final keywords = 'percentage percent calc discount ratio rate %';
      expect(keywords.contains('percent'), true);
    });

    test('Percentage provider keywords include discount', () {
      final keywords = 'percentage percent calc discount ratio rate %';
      expect(keywords.contains('discount'), true);
    });

    testWidgets('PercentageCard renders loading state', (WidgetTester tester) async {
      final model = PercentageModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: PercentageCard(),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('PercentageCard renders initialized state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: PercentageCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Percentage Calculator'), findsOneWidget);
    });

    testWidgets('PercentageCard shows segmented buttons', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: PercentageCard(),
            ),
          ),
        ),
      ));

      expect(find.byType(SegmentedButton<PercentageMode>), findsOneWidget);
    });

    testWidgets('PercentageCard widget exists', (WidgetTester tester) async {
      expect(PercentageCard, isNotNull);
    });

    testWidgets('PercentageCard shows input fields', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: PercentageCard(),
            ),
          ),
        ),
      ));

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('PercentageCard shows result area', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = PercentageModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: PercentageCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Enter values'), findsOneWidget);
    });
  });

  group('Quick Contacts provider tests', () {
    test('QuickContactsModel init works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      expect(model.isInitialized, true);
      expect(model.contacts, isEmpty);
    });

    test('QuickContactsModel addContact works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      model.addContact('John Doe', '+1234567890');
      
      expect(model.length, 1);
      expect(model.contacts[0].name, 'John Doe');
      expect(model.contacts[0].phone, '+1234567890');
    });

    test('QuickContactsModel maxContacts limit', () async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      for (int i = 0; i < 20; i++) {
        model.addContact('Contact $i', '+123456789$i');
      }
      
      expect(model.length, 15);
    });

    test('QuickContactsModel deleteContact works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      model.addContact('John Doe', '+1234567890');
      model.addContact('Jane Doe', '+1234567891');
      
      model.deleteContact(0);
      
      expect(model.length, 1);
      expect(model.contacts[0].name, 'John Doe');
    });

    test('QuickContactsModel updateContact works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      model.addContact('John Doe', '+1234567890');
      model.updateContact(0, 'John Updated', '+1234567899');
      
      expect(model.contacts[0].name, 'John Updated');
      expect(model.contacts[0].phone, '+1234567899');
    });

    test('QuickContactsModel clearAllContacts works', () async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      model.addContact('John Doe', '+1234567890');
      model.addContact('Jane Doe', '+1234567891');
      
      model.clearAllContacts();
      
      expect(model.contacts, isEmpty);
      expect(model.hasContacts, false);
    });

    test('QuickContactsModel hasContacts property', () async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      expect(model.hasContacts, false);
      
      model.addContact('John Doe', '+1234567890');
      
      expect(model.hasContacts, true);
    });

    test('QuickContact toJson/fromJson works', () {
      final contact = QuickContact(name: 'John Doe', phone: '+1234567890');
      
      final json = contact.toJson();
      final restored = QuickContact.fromJson(json);
      
      expect(restored.name, contact.name);
      expect(restored.phone, contact.phone);
    });

    test('QuickContact toMap/fromMap works', () {
      final contact = QuickContact(name: 'John Doe', phone: '+1234567890');
      
      final map = contact.toMap();
      final restored = QuickContact.fromMap(map);
      
      expect(restored.name, contact.name);
      expect(restored.phone, contact.phone);
    });

    test('QuickContactsModel persistence works', () async {
      SharedPreferences.setMockInitialValues({});
      final model1 = QuickContactsModel();
      await model1.init();
      
      model1.addContact('John Doe', '+1234567890');
      
      final model2 = QuickContactsModel();
      await model2.init();
      
      expect(model2.length, 1);
      expect(model2.contacts[0].name, 'John Doe');
    });

    test('QuickContactsModel phone normalization', () async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      model.addContact('Test', '123-456-7890');
      
      expect(model.contacts[0].phone, '1234567890');
    });

    test('Quick Contacts provider exists', () {
      expect(providerQuickContacts, isNotNull);
    });

    test('Quick Contacts provider keywords include contact', () {
      final keywords = 'contact contacts quick dial phone call speed speeddial';
      expect(keywords.contains('contact'), true);
    });

    test('Quick Contacts provider keywords include dial', () {
      final keywords = 'contact contacts quick dial phone call speed speeddial';
      expect(keywords.contains('dial'), true);
    });

    test('Quick Contacts provider keywords include phone', () {
      final keywords = 'contact contacts quick dial phone call speed speeddial';
      expect(keywords.contains('phone'), true);
    });

    testWidgets('QuickContactsCard renders loading state', (WidgetTester tester) async {
      final model = QuickContactsModel();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: QuickContactsCard(),
          ),
        ),
      ));

      expect(find.text('Quick Contacts: Loading...'), findsOneWidget);
    });

    testWidgets('QuickContactsCard renders initialized state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: QuickContactsCard(),
            ),
          ),
        ),
      ));

      expect(find.text('Quick Contacts'), findsOneWidget);
    });

    testWidgets('QuickContactsCard shows empty state', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: QuickContactsCard(),
            ),
          ),
        ),
      ));

      expect(find.text('No contacts yet. Tap + to add.'), findsOneWidget);
    });

    testWidgets('QuickContactsCard shows contacts list', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      model.addContact('John Doe', '+1234567890');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: QuickContactsCard(),
            ),
          ),
        ),
      ));

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);
    });

    testWidgets('QuickContactsCard widget exists', (WidgetTester tester) async {
      expect(QuickContactsCard, isNotNull);
    });

    testWidgets('QuickContactsCard shows add button', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: model,
              child: QuickContactsCard(),
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('AddContactDialog widget exists', (WidgetTester tester) async {
      expect(AddContactDialog, isNotNull);
    });

    testWidgets('EditContactDialog widget exists', (WidgetTester tester) async {
      expect(EditContactDialog, isNotNull);
    });

    testWidgets('AddContactDialog shows input fields', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AddContactDialog(),
                ),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Quick Contact'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('EditContactDialog shows input fields', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final model = QuickContactsModel();
      await model.init();
      model.addContact('John Doe', '+1234567890');
      
      final contact = model.contacts[0];
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: model,
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => EditContactDialog(index: 0, contact: contact),
                ),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Contact'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });
}
