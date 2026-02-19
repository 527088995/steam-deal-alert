import 'package:flutter_test/flutter_test.dart';
import 'package:steam_game/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SteamDealApp());
    expect(find.byType(SteamDealApp), findsOneWidget);
  });
}
