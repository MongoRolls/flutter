import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_provider.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../../../common/widgets/glass_card.dart';
import '../services/debug_service.dart';

class DebugScreen extends StatefulWidget {
  final UserProvider userProvider;

  const DebugScreen({super.key, required this.userProvider});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  UserProvider get _p => widget.userProvider;

  final List<TestResult> _results = [];
  final Map<String, bool> _loading = {};
  String _selectedStyle = '温柔';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOutputPanel(),
                  _buildDeviceInfoSection(),
                  _buildNotificationsSection(),
                  _buildProviderSection(),
                  _buildSyncSection(),
                  _buildPersistenceSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgSection,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '调试工具',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'DEBUG',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputPanel() {
    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  '📋 输出日志',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (_results.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _results.clear()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSection,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '清空',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text(
                      '执行测试操作后结果将显示在此处',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    reverse: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final r = _results[_results.length - 1 - index];
                      return _buildResultItem(r);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(TestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgSection,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(result.statusIcon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                result.formattedTime,
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          if (result.detail != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgMain,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                result.detail!,
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceInfoSection() {
    final info = DebugService.instance.platformInfo;
    final platform = info['platform'] ?? '-';
    final dartVersion = info['dartVersion'] ?? '-';
    final dartShort = dartVersion.length > 30
        ? '${dartVersion.substring(0, 30)}…'
        : dartVersion;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📱', '设备信息'),
          const SizedBox(height: 12),
          _infoRow('平台', platform),
          _infoRow('Dart 版本', dartShort),
          _infoRow('是否 Web', info['isWeb'] ?? '-'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🔔', '通知测试'),
          const SizedBox(height: 12),
          _actionRow(
            label: '检查通知权限',
            icon: Icons.notifications_outlined,
            color: AppColors.blue,
            onTap: () => _runTest(
              '检查通知权限',
              () => DebugService.instance.checkNotificationPermission(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '提醒风格:',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              const SizedBox(width: 8),
              ...['温柔', '活泼', '严肃'].map((s) {
                final isSelected = s == _selectedStyle;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStyle = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blue
                            : AppColors.bgSection,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          _actionRow(
            label: '触发即时通知',
            icon: Icons.send,
            color: AppColors.orange,
            onTap: () => _runTest(
              '触发即时通知',
              () => DebugService.instance.showImmediateTestNotification(
                _selectedStyle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _actionRow(
            label: '调度提醒(7天)',
            icon: Icons.schedule,
            color: AppColors.green,
            onTap: () => _runTest(
              '调度提醒(7天)',
              () => DebugService.instance.scheduleTestReminders(_p.profile),
            ),
          ),
          const SizedBox(height: 8),
          _actionRow(
            label: '取消全部通知',
            icon: Icons.cancel_outlined,
            color: AppColors.textPrimary,
            isDestructive: true,
            onTap: () => _runTestWithConfirm(
              '取消全部通知',
              '确认取消所有已调度的通知？',
              () => DebugService.instance.cancelAllNotifications(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📊', '状态检查'),
          const SizedBox(height: 12),
          _actionRow(
            label: '查看当前状态',
            icon: Icons.visibility_outlined,
            color: AppColors.blue,
            onTap: () {
              final result = DebugService.instance.inspectProviderState(_p);
              setState(() => _results.insert(0, result));
            },
          ),
          const SizedBox(height: 8),
          _actionRow(
            label: '添加测试饮水250ml',
            icon: Icons.add_circle_outline,
            color: AppColors.green,
            onTap: () => _runTest(
              '添加测试饮水',
              () => DebugService.instance.addTestDrink(_p),
            ),
          ),
          const SizedBox(height: 8),
          _actionRow(
            label: '清空今日饮水',
            icon: Icons.delete_outline,
            color: AppColors.textPrimary,
            isDestructive: true,
            onTap: () => _runTestWithConfirm(
              '清空今日饮水',
              '确认清空今日所有饮水记录？',
              () => DebugService.instance.resetTodayIntake(_p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSection() {
    final syncInfo = DebugService.instance.getSyncStatus();
    final lastSync = syncInfo['lastSyncAt'] as String? ?? '从未';
    final pendingCount = syncInfo['pendingCount'] as int? ?? 0;
    final failedCount = syncInfo['failedCount'] as int? ?? 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🔄', '数据同步'),
          const SizedBox(height: 12),
          _infoRow('最后同步', lastSync),
          _infoRow('待同步', '$pendingCount 条'),
          _infoRow('失败', '$failedCount 条'),
          const SizedBox(height: 12),
          _actionRow(
            label: '立即同步',
            icon: Icons.sync,
            color: AppColors.blue,
            onTap: () => _runTest(
              '立即同步',
              () => DebugService.instance.triggerManualSync(_p),
            ),
          ),
          const SizedBox(height: 8),
          _actionRow(
            label: '查看待同步队列',
            icon: Icons.queue,
            color: AppColors.orange,
            onTap: () => _runTest(
              '查看待同步队列',
              () => DebugService.instance.inspectPendingQueue(),
            ),
          ),
          const SizedBox(height: 8),
          _actionRow(
            label: '清空失败队列',
            icon: Icons.cleaning_services,
            color: AppColors.textPrimary,
            isDestructive: true,
            onTap: () => _runTestWithConfirm(
              '清空失败队列',
              '确认清空所有失败的同步记录？',
              () => DebugService.instance.clearFailedQueue(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistenceSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('💾', '持久化'),
          const SizedBox(height: 12),
          _actionRow(
            label: '导出全部SharedPrefs',
            icon: Icons.download_outlined,
            color: AppColors.blue,
            onTap: () => _runTest(
              '导出全部SharedPrefs',
              () => DebugService.instance.dumpAllPrefs(),
            ),
          ),
          const SizedBox(height: 8),
          _actionRow(
            label: '清空今日数据',
            icon: Icons.cleaning_services_outlined,
            color: AppColors.textPrimary,
            isDestructive: true,
            onTap: () => _runTestWithConfirm(
              '清空今日数据',
              '确认清空今日所有数据？',
              () => DebugService.instance.clearTodayData(),
            ),
          ),
          const SizedBox(height: 8),
          _actionRow(
            label: '重置全部数据',
            icon: Icons.restore,
            color: AppColors.textPrimary,
            isDestructive: true,
            onTap: () => _runTestWithConfirm(
              '重置全部数据',
              '确认重置所有数据？此操作不可恢复，将返回引导页。\n\n将清空：用户档案、饮水记录、健康档案、会话摘要、自定义提醒。',
              () async {
                final result = await DebugService.instance.clearAllData(_p);
                if (mounted) {
                  setState(() => _results.insert(0, result));
                  if (result.status == TestStatus.success) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/onboarding',
                          (route) => false,
                        );
                      }
                    });
                  }
                }
                return result;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isLoading = _loading[label] ?? false;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSection,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      ),
                    )
                  : Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? AppColors.orange
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              isDestructive
                  ? Icons.warning_amber_outlined
                  : Icons.chevron_right,
              size: 16,
              color: isDestructive ? AppColors.orange : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runTest(
    String label,
    Future<TestResult> Function() test,
  ) async {
    setState(() => _loading[label] = true);
    try {
      final result = await test();
      if (mounted) {
        setState(() {
          _results.insert(0, result);
          _loading[label] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results.insert(
            0,
            TestResult(
              status: TestStatus.failure,
              label: label,
              message: '执行失败',
              detail: e.toString(),
              timestamp: DateTime.now(),
            ),
          );
          _loading[label] = false;
        });
      }
    }
  }

  Future<void> _runTestWithConfirm(
    String label,
    String confirmMessage,
    Future<TestResult> Function() test,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: '确认操作',
      message: confirmMessage,
      cancelLabel: '取消',
      confirmLabel: '确认',
    );
    if (confirmed == true) {
      await _runTest(label, test);
    }
  }

  Widget _sectionTitle(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}
