import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('CupidGraphApp launches onboarding gatekeeper', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CupidGraphApp());

    // Verify that Google Auth Landing and branding appear first
    expect(find.text('CupidGraph'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
