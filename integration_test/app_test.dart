import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:new_launcher/main.dart';
import 'package:new_launcher/data.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App launch integration tests', () {
    testWidgets('app shows search input field', (WidgetTester tester) async {
      await Global.init();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: Global.themeModel),
          ChangeNotifierProvider.value(value: Global.backgroundImageModel),
          ChangeNotifierProvider.value(value: Global.settingsModel),
          ChangeNotifierProvider.value(value: Global.infoModel),
          ChangeNotifierProvider.value(value: Global.actionModel),
          ChangeNotifierProvider.value(value: Global.loggerModel),
        ],
        child: MyApp(),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('app shows background image', (WidgetTester tester) async {
      await Global.init();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: Global.themeModel),
          ChangeNotifierProvider.value(value: Global.backgroundImageModel),
          ChangeNotifierProvider.value(value: Global.settingsModel),
          ChangeNotifierProvider.value(value: Global.infoModel),
          ChangeNotifierProvider.value(value: Global.actionModel),
          ChangeNotifierProvider.value(value: Global.loggerModel),
        ],
        child: MyApp(),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('app shows info cards', (WidgetTester tester) async {
      await Global.init();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: Global.themeModel),
          ChangeNotifierProvider.value(value: Global.backgroundImageModel),
          ChangeNotifierProvider.value(value: Global.settingsModel),
          ChangeNotifierProvider.value(value: Global.infoModel),
          ChangeNotifierProvider.value(value: Global.actionModel),
          ChangeNotifierProvider.value(value: Global.loggerModel),
        ],
        child: MyApp(),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Card), findsWidgets);
    });
  });
}