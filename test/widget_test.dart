// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:health_intelligence_poc/main.dart';

void main() {
  testWidgets('App boots with architecture foundation text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HealthIntelligenceApp());

    expect(
      find.text('Health Intelligence POC - Architecture Foundation'),
      findsOneWidget,
    );
  });
}
