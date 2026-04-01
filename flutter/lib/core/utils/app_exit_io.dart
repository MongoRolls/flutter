import 'dart:io' show exit, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show SystemNavigator;

/// 重置等操作后退出进程（桌面）或交给系统结束 Activity（移动）。
Future<void> exitAppAfterReset() async {
  if (kIsWeb) return;
  if (Platform.isAndroid || Platform.isIOS) {
    await SystemNavigator.pop();
  } else {
    exit(0);
  }
}
