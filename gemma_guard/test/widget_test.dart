import 'package:flutter_test/flutter_test.dart';

import 'package:gemma_guard/main.dart';

void main() {
  testWidgets('App renders GemmaGuard title', (WidgetTester tester) async {
    await tester.pumpWidget(const GemmaGuardApp());
    await tester.pump();

    expect(find.text('GemmaGuard'), findsOneWidget);
  });
}
