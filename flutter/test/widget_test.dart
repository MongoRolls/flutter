import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ke_le_me/main.dart';

void main() {
  testWidgets('App should launch', (WidgetTester tester) async {
    await tester.pumpWidget(const KeLeMeApp());
    await tester.pump();
    // Initial route shows an indeterminate progress indicator; pumpAndSettle never completes.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
