import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Placeholder()));
    expect(find.byType(Placeholder), findsOneWidget);
  });
}
