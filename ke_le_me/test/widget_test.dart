import 'package:flutter_test/flutter_test.dart';

import 'package:ke_le_me/main.dart';

void main() {
  testWidgets('App should launch', (WidgetTester tester) async {
    await tester.pumpWidget(const KeLeMeApp());
    await tester.pumpAndSettle();
  });
}
