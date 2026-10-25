import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('CupidGraphApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CupidGraphApp());

    // Verify that bottom navigation items exist
    expect(find.text('Swipe Feed'), findsOneWidget);
    expect(find.text('Graph Engine'), findsOneWidget);
  });
}
