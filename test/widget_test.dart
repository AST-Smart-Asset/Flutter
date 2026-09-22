import 'package:flutter_test/flutter_test.dart';
import 'package:smart_asset_app/main.dart';

void main() {
  testWidgets('Smoke test: app renders login screen by default', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAssetApp());
    expect(find.text('Smart Asset Inventory'), findsOneWidget);
    expect(find.textContaining('Badr University'), findsOneWidget);
  });
}
