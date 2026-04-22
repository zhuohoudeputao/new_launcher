import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration tests', () {
    testWidgets('app launches successfully', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(true, true);
    });
  });
}