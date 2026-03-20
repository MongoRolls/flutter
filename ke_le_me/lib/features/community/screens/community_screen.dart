import 'package:flutter/material.dart';

import '../../../common/widgets/glass_card.dart';
import '../../../core/providers/user_provider.dart';
import '../models/care_contact.dart';
import '../providers/heart_provider.dart';
import '../providers/plaza_provider.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/care_contact_card.dart';
import '../widgets/care_template_chip.dart';
import '../widgets/care_timeline_item.dart';
import '../widgets/challenge_card.dart';
import '../widgets/streak_display.dart';
import 'add_contact_screen.dart';

/// 社区 Tab 主页面 — 整合心连心与多喝水两大模块
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

  // 发送关怀面板状态
  int _selectedTemplateIndex = 0;
  final _messageController = TextEditingController();
  final Set<String> _selectedRecipientIds = {};
  bool _isSending = false;

  static const _templates = [
    ('☀️', '午后提醒', '下午了，多喝水，我惦记你'),
    ('🌙', '睡前关怀', '睡前喝点水，好梦'),
    ('💪', '运动补水', '刚运动完，记得补水！'),
    ('🌡️', '天气提醒', '今天这么热，多喝水哦'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _messageController.text = _templates[0].$3;
    widget.heartProvider.addListener(_onProviderChanged);
    widget.plazaProvider.addListener(_onProviderChanged);
    widget.userProvider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    widget.heartProvider.removeListener(_onProviderChanged);
    widget.plazaProvider.removeListener(_onProviderChanged);
    widget.userProvider.removeListener(_onProviderChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    await widget.heartProvider.load();
    await widget.plazaProvider.load();
    if (mounted) {
      setState(() => _isLoaded = true);
      _checkNewAchievements();
    }
  }

  void _checkNewAchievements() {
    final newlyUnlocked = widget.plazaProvider.consumeNewlyUnlocked();
    if (newlyUnlocked.isNotEmpty) {
      for (final id in newlyUnlocked) {
        final achievement = widget.plazaProvider.achievements
            .where((a) => a.id == id)
            .firstOrNull;
        if (achievement != null) {
          _showAchievementDialog(achievement.iconEmoji, achievement.title);
        }
      }
    }
  }

  void _showAchievementDialog(String emoji, String title) {
    showDialog(
      context: context,
      builder: (ctx) => _AchievementUnlockDialog(emoji: emoji, title: title),
    );
  }

  Future<void> _addContact() async {
    final result = await Navigator.of(context).push<CareContact>(
      MaterialPageRoute(builder: (_) => const AddContactScreen()),
    );
    if (!mounted) return;
    if (result != null) {
      await widget.heartProvider.addContact(result);
    }
  }

  Future<void> _sendCare() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    final recipients = widget.heartProvider.contacts
        .where((c) => _selectedRecipientIds.contains(c.id))
        .toList();
    if (recipients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择收件人')));
      return;
    }

    setState(() => _isSending = true);
    await widget.heartProvider.sendCare(
      message: message,
      recipients: recipients,
    );
    // 刷新成就
    await widget.plazaProvider.refresh();
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _selectedRecipientIds.clear();
    });
    _checkNewAchievements();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ 关怀已发出！'),
        backgroundColor: const Color(0xFF66BB6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 顶部标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFF8A65)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text('💝', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '社区',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2340),
                          ),
                        ),
                        Text(
                          '关怀你在乎的人，一起健康饮水',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF90A4AE),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 心连心模块
            SliverToBoxAdapter(child: _buildHeartSection()),
            // 发送关怀
            SliverToBoxAdapter(child: _buildSendCareSection()),
            // 关怀足迹
            SliverToBoxAdapter(child: _buildTimelineSection()),
            // 多喝水模块
            SliverToBoxAdapter(child: _buildPlazaSection()),
            // 底部留白
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  // ── 心连心：我的关怀圈 ──
  Widget _buildHeartSection() {
    final contacts = widget.heartProvider.contacts;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0x20FF6B9D),
                    border: Border.all(
                      color: const Color(0x30FF6B9D),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('❤️', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '心连心',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340),
                      ),
                    ),
                    Text(
                      '守护每一口温暖',
                      style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 联系人列表
            ...contacts.map(
              (contact) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CareContactCard(
                  contact: contact,
                  onRemind: () => widget.heartProvider.sendCare(
                    message: '提醒你喝水 💧',
                    recipients: [contact],
                  ),
                ),
              ),
            ),
            // 添加按钮
            GestureDetector(
              onTap: _addContact,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x06FF6B9D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0x35FF6B9D),
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '＋ 添加关怀的人',
                  style: TextStyle(fontSize: 13, color: Color(0xFFE64A6A)),
                ),
              ),
            ),
            // AI 温馨提示
            _buildAiTip(),
          ],
        ),
      ),
    );
  }

  Widget _buildAiTip() {
    // 找到饮水最少的联系人
    final contacts = widget.heartProvider.contacts;
    if (contacts.isEmpty) return const SizedBox.shrink();
    final lowest = contacts.reduce((a, b) => a.progress < b.progress ? a : b);
    if (lowest.progress >= 0.8) return const SizedBox.shrink();

    final hour = DateTime.now().hour;
    final timeHint = hour < 12
        ? '上午'
        : hour < 18
        ? '下午'
        : '晚上';

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x14AB47BC), Color(0x0F7E57C2)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33AB47BC), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFAB47BC), Color(0xFF7E57C2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'AI 温馨提示：',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: '${lowest.name}今天还没有喝够水，现在是$timeHint时段，适合发送一条关怀问候哦～',
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5E35B1),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 发送关怀面板 ──
  Widget _buildSendCareSection() {
    final contacts = widget.heartProvider.contacts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0x20FF6B9D),
                    border: Border.all(
                      color: const Color(0x30FF6B9D),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('📨', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '发送关怀',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340),
                      ),
                    ),
                    Text(
                      '暖心一句，胜过千言万语',
                      style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 2×2 话术模板
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.4,
              children: List.generate(_templates.length, (i) {
                return CareTemplateChip(
                  emoji: _templates[i].$1,
                  title: _templates[i].$2,
                  content: _templates[i].$3,
                  isSelected: _selectedTemplateIndex == i,
                  onTap: () {
                    setState(() {
                      _selectedTemplateIndex = i;
                      _messageController.text = _templates[i].$3;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            // 自定义输入框
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: '或者，用你自己的话说……',
                      hintStyle: TextStyle(color: Color(0xFFB0BEC5)),
                      border: InputBorder.none,
                      isDense: true,
                      counterText: '',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A2E),
                      height: 1.6,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const Divider(height: 1, color: Color(0x0D000000)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildToolIcon('✨', 'AI 润色'),
                      const SizedBox(width: 8),
                      _buildToolIcon('😊', '表情'),
                      const Spacer(),
                      Text(
                        '${_messageController.text.length} / 100',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB0BEC5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 收件人选择
            const Text(
              '发送给：',
              style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: contacts.map((c) {
                final isSelected = _selectedRecipientIds.contains(c.id);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedRecipientIds.remove(c.id);
                    } else {
                      _selectedRecipientIds.add(c.id);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0x20FF6B9D)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0x50FF6B9D)
                            : Colors.white.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.avatarEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? const Color(0xFFC62A6B)
                                : const Color(0xFF455A64),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            // 发送按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendCare,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0x66FF6B9D),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      _isSending ? '发送中...' : '发送关怀',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolIcon(String emoji, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0x0A000000),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  // ── 关怀足迹时间线 ──
  Widget _buildTimelineSection() {
    final records = widget.heartProvider.records;
    if (records.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🕐 关怀足迹',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF90A4AE),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),
            ...records.take(5).map((r) => CareTimelineItem(record: r)),
          ],
        ),
      ),
    );
  }

  // ── 多喝水模块 ──
  Widget _buildPlazaSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '🏆 多喝水',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF90A4AE),
                letterSpacing: 2,
              ),
            ),
          ),
          // 我的打卡
          GlassCard(
            child: StreakDisplay(
              streakDays: widget.userProvider.streakDays,
              todayMl: widget.userProvider.todayMl,
              dailyGoalMl: widget.userProvider.profile.dailyGoalMl,
              monthlyHits: widget.userProvider.monthlyHits,
            ),
          ),
          // 进行中的挑战
          if (widget.plazaProvider.joinedChallenges.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                '进行中的挑战',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2340),
                ),
              ),
            ),
            ...widget.plazaProvider.joinedChallenges.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ChallengeCard(challenge: c),
              ),
            ),
          ],
          // 发现挑战
          if (widget.plazaProvider.discoverChallenges.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                '发现挑战',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2340),
                ),
              ),
            ),
            ...widget.plazaProvider.discoverChallenges.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ChallengeCard(
                  challenge: c,
                  onJoin: () => widget.plazaProvider.joinChallenge(c.id),
                ),
              ),
            ),
          ],
          // 成就墙
          const Padding(
            padding: EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              '成就墙',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340),
              ),
            ),
          ),
          GlassCard(
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
              children: widget.plazaProvider.achievements
                  .map(
                    (a) => AchievementBadge(
                      achievement: a,
                      onTap: a.isUnlocked
                          ? () => _showAchievementDialog(a.iconEmoji, a.title)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 成就解锁庆祝弹窗（带动画）
class _AchievementUnlockDialog extends StatefulWidget {
  final String emoji;
  final String title;

  const _AchievementUnlockDialog({required this.emoji, required this.title});

  @override
  State<_AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<_AchievementUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _opacityAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF29B6F6).withValues(alpha: 0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  '成就解锁！',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF29B6F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('太棒了！'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
