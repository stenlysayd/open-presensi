import 'package:flutter_test/flutter_test.dart';
import 'package:open_presensi_client/main.dart';

void main() {
  testWidgets('OpenPresensiApp basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenPresensiApp());
    expect(find.byType(OpenPresensiApp), findsOneWidget);
  });
}
