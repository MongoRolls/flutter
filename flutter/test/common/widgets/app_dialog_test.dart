import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ke_le_me/common/widgets/app_confirm_dialog.dart';
import 'package:ke_le_me/common/widgets/app_info_dialog.dart';
import 'package:ke_le_me/core/theme/app_theme.dart';

void main() {
  testWidgets('destructive confirm primary uses redDeep', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showAppConfirmDialog(
                    context: context,
                    title: '删除',
                    message: '确定？',
                    isDestructive: true,
                    confirmLabel: '删除',
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final buttonFinder = find.widgetWithText(ElevatedButton, '删除');
    expect(buttonFinder, findsOneWidget);
    final style = tester.widget<ElevatedButton>(buttonFinder).style;
    final bg = style?.backgroundColor?.resolve({});
    expect(bg, AppColors.redDeep);
  });

  testWidgets('confirm dialog returns true when confirm tapped', (tester) async {
    Future<bool?>? dialogFuture;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  dialogFuture = showAppConfirmDialog(
                    context: context,
                    title: '标题',
                    message: '正文',
                    confirmLabel: '好',
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('好'));
    await tester.pumpAndSettle();

    expect(await dialogFuture, true);
  });

  testWidgets('info dialog has single primary button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showAppInfoDialog(
                    context: context,
                    title: '提示',
                    message: '说明',
                    buttonLabel: '知道了',
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('知道了'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
