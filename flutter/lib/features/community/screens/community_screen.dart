import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/widgets/app_toast.dart';
import '../../../common/widgets/glass_card.dart';
import '../../../core/utils/backend_api_error_message.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/care_contact.dart';
import '../providers/heart_provider.dart';
import '../providers/plaza_provider.dart';
import '../widgets/care_contact_card.dart';
import '../widgets/challenge_card.dart';
import '../widgets/streak_display.dart';
import 'add_contact_screen.dart';

/// 社区 Tab — 本地连续打卡挑战 + 组队挑战（服务端）+ 队友管理
class CommunityScreen extends StatefulWidget {
  final UserProvider userProvider;
  final HeartProvider heartProvider;
  final PlazaProvider plazaProvider;

  const CommunityScreen({
    super.key,
    required this.userProvider,
    required this.heartProvider,
    required this.plazaProvider,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    widget.heartProvider.addListener(_onChanged);
    widget.plazaProvider.addListener(_onChanged);
    widget.userProvider.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.heartProvider.removeListener(_onChanged);
    widget.plazaProvider.removeListener(_onChanged);
    widget.userProvider.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    await Future.wait([
      widget.heartProvider.load(),
      widget.plazaProvider.load(),
    ]);
    if (mounted) setState(() => _isLoaded = true);
  }

  Future<void> _onRefresh() async {
    await widget.plazaProvider.refresh();
  }

  Future<void> _addContact() async {
    final result = await Navigator.of(context).push<CareContact>(
      MaterialPageRoute(builder: (_) => const AddContactScreen()),
    );
    if (!mounted || result == null) return;
    try {
      await widget.heartProvider.addContact(result);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, backendApiErrorMessage(e));
      return;
    }
    if (!mounted) return;
    AppToast.success(context, '添加成功');
  }

  Future<void> _removeContact(String id) async {
    try {
      await widget.heartProvider.removeContact(id);
      if (!mounted) return;
      AppToast.info(context, '已移除队友');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, backendApiErrorMessage(e));
    }
  }

  Future<void> _showCreateChallengeDialog() async {
    const durationDays = 7;
    final titleController = TextEditingController(text: '喝水组队');
    final goalController = TextEditingController(
      text: '${widget.userProvider.profile.dailyGoalMl}',
    );
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('创建组队挑战'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '挑战名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: '每人每日达标饮水量 (ml)',
                    helperText:
                        '小队约定同一标准：当天喝够即算打卡成功，重在规律与互相提醒，并非喝得越多越好。',
                    helperMaxLines: 3,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '周期 $durationDays 天：创建后将邀请码发给队友，大家按同一约定每日达标即可。',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('创建'),
            ),
          ],
        ),
      );

      if (!mounted || ok != true) return;

      final parsed = int.tryParse(goalController.text.trim());
      if (parsed == null || parsed < 1 || parsed > 20000) {
        AppToast.error(context, '请填写 1–20000 之间的每日达标量（ml）');
        return;
      }
      final goal = parsed;
      final title = titleController.text.trim().isEmpty
          ? '喝水组队'
          : titleController.text.trim();

      try {
        await widget.plazaProvider.createTeamChallenge(
          title: title,
          goalValue: goal,
          durationDays: durationDays,
        );
        if (!mounted) return;
        AppToast.success(
          context,
          '挑战已创建，请把邀请码发给队友，一起按约定每日达标打卡',
        );
      } on DioException catch (e) {
        if (!mounted) return;
        AppToast.error(context, backendApiErrorMessage(e));
      } catch (e) {
        if (!mounted) return;
        AppToast.error(context, '创建失败：$e');
      }
    } finally {
      titleController.dispose();
      goalController.dispose();
    }
  }

  Future<void> _showJoinChallengeDialog() async {
    final codeController = TextEditingController();
    try {
      final code = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('加入组队挑战'),
          content: TextField(
            controller: codeController,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: '6 位邀请码',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final c = codeController.text.trim().toUpperCase();
                if (c.length != 6) {
                  AppToast.error(ctx, '请输入 6 位邀请码');
                  return;
                }
                Navigator.pop(ctx, c);
              },
              child: const Text('加入'),
            ),
          ],
        ),
      );

      if (!mounted || code == null || code.isEmpty) return;

      try {
        await widget.plazaProvider.joinByInviteCode(code);
        if (!mounted) return;
        AppToast.success(context, '已加入挑战');
      } on DioException catch (e) {
        if (!mounted) return;
        AppToast.error(context, backendApiErrorMessage(e));
      } catch (e) {
        if (!mounted) return;
        AppToast.error(context, '加入失败：$e');
      }
    } finally {
      codeController.dispose();
    }
  }

  Future<void> _confirmLeave(String challengeId) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出挑战'),
        content: const Text('确定退出该组队挑战？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (!mounted || go != true) return;

    try {
      await widget.plazaProvider.leaveChallenge(challengeId);
      if (!mounted) return;
      AppToast.info(context, '已退出');
    } on DioException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message ?? '退出失败');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, '退出失败：$e');
    }
  }

  Future<void> _ackResult(String challengeId) async {
    try {
      await widget.plazaProvider.ackChallengeResult(challengeId);
      if (!mounted) return;
      AppToast.success(context, '已记录');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, backendApiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.blue,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildTeammatesSection()),
              SliverToBoxAdapter(child: _buildChallengeSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeSection() {
    final list = widget.plazaProvider.teamChallenges;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
            child: _CommunitySectionTitle(
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.orange,
              iconBackground: AppColors.orangeLight,
              title: '组队挑战',
              subtitle: '与好友约定每日饮水达标量，互相督促打卡（非比谁喝得多）',
            ),
          ),
          // 操作（窄屏改为上下排列，避免双按钮横向溢出）
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 340;
              final createBtn = FilledButton.icon(
                onPressed: _showCreateChallengeDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('创建挑战'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: narrow
                      ? const Size(double.infinity, 44)
                      : null,
                ),
              );
              final joinBtn = OutlinedButton.icon(
                onPressed: _showJoinChallengeDialog,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('加入挑战'),
                style: OutlinedButton.styleFrom(
                  minimumSize: narrow
                      ? const Size(double.infinity, 44)
                      : null,
                ),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    createBtn,
                    const SizedBox(height: 10),
                    joinBtn,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: createBtn),
                  const SizedBox(width: 10),
                  Expanded(child: joinBtn),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: StreakDisplay(
              streakDays: widget.userProvider.streakDays,
              todayMl: widget.userProvider.todayMl,
              dailyGoalMl: widget.userProvider.profile.dailyGoalMl,
              monthlyHits: widget.userProvider.monthlyHits,
            ),
          ),
          if (widget.plazaProvider.discoverLocalChallenges.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 10),
              child: _CommunitySectionTitle(
                icon: Icons.flag_rounded,
                iconColor: AppColors.orangeFire,
                iconBackground: AppColors.orangeLight,
                title: '打卡挑战 · 发现',
                subtitle: '可加入的公开挑战',
                dense: true,
              ),
            ),
            ...widget.plazaProvider.discoverLocalChallenges.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ChallengeCard(
                  challenge: c,
                  onJoin: () => widget.plazaProvider.joinChallenge(c.id),
                ),
              ),
            ),
          ],
          if (widget.plazaProvider.joinedLocalChallenges.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 10),
              child: _CommunitySectionTitle(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.orangeFire,
                iconBackground: AppColors.orangeLight,
                title: '打卡挑战 · 进行中',
                subtitle: '你正在参与的挑战',
                dense: true,
              ),
            ),
            ...widget.plazaProvider.joinedLocalChallenges.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ChallengeCard(challenge: c),
              ),
            ),
          ],
          if (list.isEmpty) ...[
            const SizedBox(height: 8),
            const _CommunityEmptyHint(
              icon: Icons.handshake_rounded,
              title: '暂无组队挑战',
              message: '创建新挑战或输入 6 位邀请码加入好友',
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 10),
              child: _CommunitySectionTitle(
                icon: Icons.rocket_launch_rounded,
                iconColor: AppColors.blueDark,
                iconBackground: AppColors.blueLight,
                title: '我的组队挑战',
                subtitle: '进行中的小队打卡',
                dense: true,
              ),
            ),
            ...list.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ChallengeCard(
                  challenge: c,
                  onLeave: () => _confirmLeave(c.id),
                  onAckResult: c.status == 'settled' &&
                          c.resultAcknowledgedAt == null
                      ? () => _ackResult(c.id)
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeammatesSection() {
    final contacts = widget.heartProvider.contacts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CommunitySectionTitle(
              icon: Icons.group_rounded,
              iconColor: AppColors.blueDark,
              iconBackground: AppColors.blueLight,
              title: '我的队友',
              subtitle: '通过好友短码添加，互相提醒喝水',
            ),
            const SizedBox(height: 14),
            if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: _CommunityEmptyHint(
                  icon: Icons.person_add_alt_1_rounded,
                  title: '还没有队友',
                  message: '点击下方添加，输入好友短码即可关联',
                  compact: true,
                ),
              )
            else
              ...contacts.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CareContactCard(
                    contact: c,
                    onRemove: () => _removeContact(c.id),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.blueLight.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: _addContact,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.blueDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '添加队友',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分区标题：图标底 + 主副文案，提升扫读与层级。
class _CommunitySectionTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final bool dense;

  const _CommunitySectionTitle({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.subtitle,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = dense ? 14.0 : 16.0;
    final iconBox = dense ? 30.0 : 34.0;
    final iconSize = dense ? 17.0 : 19.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 空状态提示：图标 + 主文案 + 辅助说明。
class _CommunityEmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool compact;

  const _CommunityEmptyHint({
    required this.icon,
    required this.title,
    required this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = AppColors.bgSection;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 10 : 18,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              boxShadow: AppShadows.bar,
            ),
            child: Icon(
              icon,
              size: compact ? 26 : 30,
              color: AppColors.blue.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
