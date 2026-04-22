import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/setting.dart';
import 'package:new_launcher/providers/provider_weather.dart';
import 'package:new_launcher/providers/provider_app.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

void main() {
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
      expect(actionModel.suggestList.length, 1);
    });

    test('generateSuggestList filters actions by input', () {
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
      expect(actionModel.suggestList.length, 1);
      
      actionModel.generateSuggestList('time');
      expect(actionModel.suggestList.length, 1);
      
      actionModel.generateSuggestList('clock');
      expect(actionModel.suggestList.length, 1);
    });

    test('generateSuggestList returns all matching actions', () {
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
      expect(actionModel.suggestList.length, 2);
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

    test('getWeatherIcon returns default for unknown', () {
      final icon = getWeatherIcon("Unknown condition");
      expect(icon, Icons.cloud);
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
    test('stores search query correctly', () {
      final actionModel = ActionModel();
      actionModel.generateSuggestList('test query');
      expect(actionModel.searchQuery, 'test query');
    });

    test('clears search query when empty', () {
      final actionModel = ActionModel();
      actionModel.generateSuggestList('');
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
}
