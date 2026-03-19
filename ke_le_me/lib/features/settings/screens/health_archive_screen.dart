import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/memory_fact.dart';
import '../../../core/services/memory_service.dart';
import '../../../common/widgets/glass_card.dart';

class HealthArchiveScreen extends StatefulWidget {
  const HealthArchiveScreen({super.key});

  @override
  State<HealthArchiveScreen> createState() => _HealthArchiveScreenState();
}

class _HealthArchiveScreenState extends State<HealthArchiveScreen> {
  List<MemoryFact> _facts = [];

  @override
  void initState() {
    super.initState();
    _loadFacts();
  }

  void _loadFacts() {
    setState(() {
      _facts = MemoryService.instance.getAllFacts()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _facts.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final entry in groups.entries)
                          if (entry.value.isNotEmpty) ...[
                            _buildGroupCard(entry.key, entry.value),
                          ],
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<MemoryFact>> _buildGroups() {
    final health = <MemoryFact>[];
    final pref = <MemoryFact>[];
    final events = <MemoryFact>[];

    for (final fact in _facts) {
      switch (fact.category) {
        case 'health':
          health.add(fact);
        case 'preference':
        case 'habit':
          pref.add(fact);
        case 'event':
        case 'reminder':
          events.add(fact);
        default:
          health.add(fact);
      }
    }

    return {
      'health': health,
      'preference': pref,
      'event': events,
    };
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
          )
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
            'AI 健康档案',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '${_facts.length} 条',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_outlined,
                size: 36, color: AppColors.blue),
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有健康档案',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '和 AI 助手多聊聊，它会自动记住\n你的健康信息和偏好习惯',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textHint, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String groupKey, List<MemoryFact> facts) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _categoryEmoji(groupKey),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                _categoryLabel(groupKey),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${facts.length} 条',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...facts.asMap().entries.map((entry) {
            final idx = entry.key;
            final fact = entry.value;
            return Column(
              children: [
                if (idx > 0)
                  Container(
                    height: 1,
                    color: AppColors.divider,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                Dismissible(
                  key: Key(fact.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(fact),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                  ),
                  child: _buildFactTile(fact),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFactTile(MemoryFact fact) {
    final dateStr = _formatDate(fact.createdAt);
    final isImportant = fact.importance >= 4;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImportant)
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 6),
              child: Icon(Icons.star_rounded, size: 14, color: AppColors.orange),
            )
          else
            const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (fact.expiresAt != null) ...[
                      const Icon(Icons.schedule_outlined,
                          size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(
                        '到期 ${_formatDate(fact.expiresAt!)}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textHint),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      dateStr,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(MemoryFact fact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除记录',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          '确定删除「${fact.content.length > 20 ? '${fact.content.substring(0, 20)}…' : fact.content}」？',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await MemoryService.instance.deleteFact(fact.id);
      _loadFacts();
      return true;
    }
    return false;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'health' => '健康档案',
      'preference' => '偏好习惯',
      'habit' => '偏好习惯',
      'event' => '待关注事件',
      'reminder' => '待关注事件',
      _ => '其他',
    };
  }

  String _categoryEmoji(String category) {
    return switch (category) {
      'health' => '❤️',
      'preference' || 'habit' => '⭐',
      'event' || 'reminder' => '📌',
      _ => '📝',
    };
  }
}
