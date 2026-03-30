import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';

/// 从扫码结果中提取 6 位好友短码（字母数字）。
String? extractFriendCodeFromScan(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final upper = raw.trim().toUpperCase();
  final match = RegExp(r'[A-Z0-9]{6}').firstMatch(upper);
  return match?.group(0);
}

/// 扫描好友短码（iOS / Android）。不支持的平台请勿打开本页。
class ScanFriendCodeScreen extends StatefulWidget {
  const ScanFriendCodeScreen({super.key});

  @override
  State<ScanFriendCodeScreen> createState() => _ScanFriendCodeScreenState();
}

class _ScanFriendCodeScreenState extends State<ScanFriendCodeScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue ?? barcode.displayValue;
      final code = extractFriendCodeFromScan(raw);
      if (code != null) {
        _handled = true;
        if (mounted) Navigator.of(context).pop<String>(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: const Text('扫描好友短码'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '无法打开相机：$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Text(
                '将二维码或条形码置于框内，扫描成功后将自动返回',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 当前设备是否支持扫码页（与 [ScanFriendCodeScreen] 一致）。
bool get supportsFriendCodeScan =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
