import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/time_hhmm.dart';

/// 屏幕居中弹窗 + [CupertinoDatePicker] 滚轮（24 小时制）。点「完成」时调用 [onConfirm]。
Future<void> showScrollWheelTimePicker(
  BuildContext context, {
  required String initialHhMm,
  required ValueChanged<String> onConfirm,
}) async {
  final initial = timeOfDayFromHhMm(initialHhMm);
  var selected = DateTime(2020, 1, 1, initial.hour, initial.minute);

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: AppColors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            '取消',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            '选择时间',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onConfirm(
                              '${selected.hour.toString().padLeft(2, '0')}:'
                              '${selected.minute.toString().padLeft(2, '0')}',
                            );
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            '完成',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  SizedBox(
                    height: 216,
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        brightness: Brightness.light,
                        primaryColor: AppColors.blue,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 21,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: true,
                        minuteInterval: 1,
                        initialDateTime: selected,
                        onDateTimeChanged: (DateTime d) {
                          setModalState(() {
                            selected = DateTime(2020, 1, 1, d.hour, d.minute);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
