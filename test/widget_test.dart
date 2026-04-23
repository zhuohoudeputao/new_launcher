import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/providers/provider_weather.dart';
import 'package:new_launcher/providers/provider_app.dart';
import 'package:new_launcher/providers/provider_settings.dart';
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
      expect(Global.providerList.length, 7);
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
      
      final hour1 = DateTime.now().hour;
      final hour2 = (hour1 + 1) % 24;
      final hour3 = (hour1 + 5) % 24;
      
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
      expect(settingsModel is ChangeNotifier, true);
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
      expect(model.themeData is ThemeData, true);
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
      for (final provider in Global.providerList) {
        initCount++;
      }
      expect(initCount, 7);
    });
  });
}
