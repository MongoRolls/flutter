import 'package:flutter/material.dart';

import '../models/care_contact.dart';

/// 添加关怀联系人页面
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _nameController = TextEditingController();
  String _relationship = 'friend';
  String _avatarEmoji = '😊';

  static const _emojiOptions = ['😊', '👩', '👨', '🧡', '👧', '👦', '🧓', '👴'];
  static const _relationshipOptions = [
    ('mom', '妈妈'),
    ('dad', '爸爸'),
    ('partner', '恋人'),
    ('friend', '朋友'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入名字')));
      return;
    }
    final contact = CareContact(
      id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      relationship: _relationship,
      avatarEmoji: _avatarEmoji,
    );
    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加关怀的人'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 头像选择
          const Text(
            '选择头像',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _emojiOptions.map((emoji) {
              final isSelected = emoji == _avatarEmoji;
              return GestureDetector(
                onTap: () => setState(() => _avatarEmoji = emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0x20FF6B9D)
                        : const Color(0xFFF5F5F5),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF6B9D)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 名字输入
          const Text(
            '名字',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: '输入 TA 的名字',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8EFF5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8EFF5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF29B6F6)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 关系选择
          const Text(
            '关系',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _relationshipOptions.map((option) {
              final isSelected = option.$1 == _relationship;
              return ChoiceChip(
                label: Text(option.$2),
                selected: isSelected,
                selectedColor: const Color(0x20FF6B9D),
                onSelected: (_) => setState(() => _relationship = option.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          // 保存按钮
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29B6F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                '添加',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
