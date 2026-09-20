import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vypara_ai/app/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('VyaparaAI'), findsOneWidget);
    expect(find.text('Your AI Business Partner'), findsOneWidget);
  });
}
