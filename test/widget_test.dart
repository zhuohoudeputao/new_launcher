import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/setting.dart';
import 'package:new_launcher/providers/provider_weather.dart';

void main() {
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
          home: Setting(),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
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
}
