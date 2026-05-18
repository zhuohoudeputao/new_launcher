import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_launcher/settings_page.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/ui/settings/api_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
    Global.backgroundImageModel.backgroundImage = AssetImage('test_assets/transparent.png');
  });

  group('SettingsPage AI Settings section tests', () {
    testWidgets('AI Settings section header appears in SettingsPage', (WidgetTester tester) async {
      // Build the SettingsPage widget with required providers
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: Global.settingsModel),
              ChangeNotifierProvider.value(value: Global.themeModel),
              ChangeNotifierProvider.value(value: Global.backgroundImageModel),
            ],
            child: const SettingsPage(),
          ),
        ),
      );

      // Wait for the widget to fully render
      await tester.pumpAndSettle();

      // Verify SettingsPage renders
      expect(find.byType(SettingsPage), findsOneWidget);

      // Verify "AI Settings" text exists (this will FAIL in RED phase)
      expect(find.text('AI Settings'), findsOneWidget);

      // Verify Icons.psychology icon exists (this will FAIL in RED phase)
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });
  });

  group('SettingsPage navigation tests', () {
    testWidgets('AI API Keys ListTile navigates to APIKeysSettings', (WidgetTester tester) async {
      // Create a mock NavigatorObserver to track navigation
      final mockObserver = MockNavigatorObserver();
      
      // Build the SettingsPage widget with required providers
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: Global.settingsModel),
              ChangeNotifierProvider.value(value: Global.themeModel),
              ChangeNotifierProvider.value(value: Global.backgroundImageModel),
            ],
            child: const SettingsPage(),
          ),
          navigatorObservers: [mockObserver],
          routes: {
            '/api-keys': (context) => const APIKeysSettings(),
          },
        ),
      );
      
      // Wait for the widget to fully render
      await tester.pumpAndSettle();
      
      // Verify the AI API Keys ListTile exists (this will FAIL in RED phase)
      final apiKeysTile = find.widgetWithText(ListTile, 'AI API Keys');
      expect(apiKeysTile, findsOneWidget, reason: 'AI API Keys ListTile should be present');
      
      // Verify the subtitle exists (this will FAIL in RED phase)
      final subtitleText = find.text('Configure API keys for AI providers');
      expect(subtitleText, findsOneWidget, reason: 'Subtitle should be present');
      
      // Tap the ListTile to trigger navigation
      await tester.tap(apiKeysTile);
      await tester.pump(); // Trigger navigation
      await tester.pump(const Duration(seconds: 1)); // Allow async operations to progress
      
      // Verify navigation to APIKeysSettings occurred (this will FAIL in RED phase)
      expect(mockObserver.pushedRoutes.length, greaterThan(0), reason: 'At least one route should be pushed');
      
      // Verify the pushed route is a MaterialPageRoute
      final pushedRoute = mockObserver.pushedRoutes.last;
      expect(pushedRoute, isA<MaterialPageRoute>(), reason: 'Should push MaterialPageRoute');
      
      // Verify the destination is APIKeysSettings by checking the route settings or builder
      // Note: We can't directly call builder(null) as BuildContext is required
      // Instead, we verify by checking if APIKeysSettings widget appears after navigation
      expect(find.byType(APIKeysSettings), findsOneWidget, reason: 'APIKeysSettings should be visible after navigation');
    });
  });
}

// Mock NavigatorObserver to track navigation events
class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}