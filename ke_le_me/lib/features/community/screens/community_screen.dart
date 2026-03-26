import 'package:flutter/material.dart';

import '../../../common/widgets/glass_card.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/care_contact.dart';
import '../providers/heart_provider.dart';
import '../providers/plaza_provider.dart';
import '../widgets/care_contact_card.dart';
import '../widgets/challenge_card.dart';
import '../widgets/streak_display.dart';
import 'add_contact_screen.dart';

/// 社区 Tab 主页面 — 关怀提醒 + 多喝水挑战
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
  final _messageController = TextEditingController();
  final Set<String> _selectedRecipientIds = {};
  bool _isSending = false;
  bool _showSendPanel = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _messageController.text = '记得多喝水哦 💧';
    widget.heartProvider.addListener(_onChanged);
    widget.plazaProvider.addListener(_onChanged);
    widget.userProvider.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.heartProvider.removeListener(_onChanged);
    widget.plazaProvider.removeListener(_onChanged);
    widget.userProvider.removeListener(_onChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    await widget.heartProvider.load();
    await widget.plazaProvider.load();
    if (mounted) {
      setState(() => _isLoaded = true);
    }
  }

  Future<void> _addContact() async {
    final result = await Navigator.of(context).push<CareContact>(
      MaterialPageRoute(builder: (_) => const AddContactScreen()),
    );
    if (!mounted || result == null) return;
    await widget.heartProvider.addContact(result);
  }

  Future<void> _sendCare() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;
    final list = widget.heartProvider.contacts
        .where((c) => _selectedRecipientIds.contains(c.id))
        .toList();
    if (list.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择要提醒的人')));
      return;
    }
    setState(() => _isSending = true);
    await widget.heartProvider.sendCare(message: msg, recipients: list);
    await widget.plazaProvider.refresh();
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _selectedRecipientIds.clear();
      _showSendPanel = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已发送提醒 ✓'),
        backgroundColor: AppColors.green,
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
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  '社区',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildCareSection()),
            if (_showSendPanel) SliverToBoxAdapter(child: _buildSendPanel()),
            SliverToBoxAdapter(child: _buildPlazaSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  // ── 关怀提醒 ──
  Widget _buildCareSection() {
    final contacts = widget.heartProvider.contacts;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '关怀提醒',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showSendPanel = !_showSendPanel),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _showSendPanel
                          ? AppColors.blue
                          : AppColors.blueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _showSendPanel ? '收起' : '群发提醒',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _showSendPanel
                            ? Colors.white
                            : AppColors.blueDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    '暂无联系人，点击下方按钮，可通过好友短码添加',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      height: 1.4,
                    ),
                  ),
                ),
              )
            else
              ...contacts.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CareContactCard(
                    contact: c,
                    onRemind: () => widget.heartProvider.sendCare(
                      message: '提醒你喝水 💧',
                      recipients: [c],
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: _addContact,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '添加联系人',
                      style: TextStyle(fontSize: 13, color: AppColors.textHint),
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

  // ── 群发提醒面板 ──
  Widget _buildSendPanel() {
    final contacts = widget.heartProvider.contacts;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择提醒对象',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: contacts.map((c) {
                final sel = _selectedRecipientIds.contains(c.id);
                return GestureDetector(
                  onTap: () => setState(() {
                    sel
                        ? _selectedRecipientIds.remove(c.id)
                        : _selectedRecipientIds.add(c.id);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.blueLight : AppColors.bgSection,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.blue : AppColors.divider,
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
                            fontWeight: FontWeight.w500,
                            color: sel
                                ? AppColors.blueDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (sel) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.blueDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _messageController,
              maxLines: 2,
              maxLength: 60,
              decoration: InputDecoration(
                hintText: '输入提醒内容…',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.bgSection,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                counterStyle: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendCare,
                child: Text(_isSending ? '发送中…' : '发送提醒'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 多喝水挑战 ──
  Widget _buildPlazaSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '多喝水挑战',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          GlassCard(
            child: StreakDisplay(
              streakDays: widget.userProvider.streakDays,
              todayMl: widget.userProvider.todayMl,
              dailyGoalMl: widget.userProvider.profile.dailyGoalMl,
              monthlyHits: widget.userProvider.monthlyHits,
            ),
          ),
          if (widget.plazaProvider.joinedChallenges.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                '进行中',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
          if (widget.plazaProvider.discoverChallenges.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                '发现挑战',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
        ],
      ),
    );
  }
}
