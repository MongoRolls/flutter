import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/backend_api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/backend_api_error_message.dart';
import '../models/care_contact.dart';

/// 添加关怀联系人页面
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _friendCodeController = TextEditingController();
  final _nameController = TextEditingController();
  String _relationship = 'friend';
  String _avatarEmoji = '😊';
  bool _isSaving = false;

  static const _emojiOptions = ['😊', '👩', '👨', '🧡', '👧', '👦', '🧓', '👴'];
  static const _relationshipOptions = [
    ('mom', '妈妈'),
    ('dad', '爸爸'),
    ('partner', '恋人'),
    ('friend', '朋友'),
  ];

  @override
  void dispose() {
    _friendCodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _friendCodeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入好友短码')));
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入名字')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final backend = BackendApiService.instance;
      final lookup = await backend.lookupFriendCode(code);
      final contactId = lookup['userId'] as String;
      await backend.createCareContact(contactId: contactId, nickname: name);

      final contact = CareContact(
        id: contactId,
        name: name,
        relationship: _relationship,
        avatarEmoji: _avatarEmoji,
      );
      if (!mounted) return;
      Navigator.of(context).pop(contact);
    } catch (e) {
      if (!mounted) return;
      final msg = backendApiErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _isSaving = false);
    }
  }

  Future<void> _showMyFriendCodeDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _MyFriendCodeDialog(messenger: messenger, dialogContext: dialogContext),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加关怀的人'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _showMyFriendCodeDialog,
            child: const Text('我的短码'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 头像选择
          const Text(
            '选择头像',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
                        ? AppColors.pinkBgMedium
                        : AppColors.greySection,
                    border: Border.all(
                      color: isSelected ? AppColors.pink : Colors.transparent,
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

          // 好友短码
          const Text(
            '好友短码',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _friendCodeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 12,
            decoration: InputDecoration(
              hintText: '输入对方短码（例如 AB3K9Q）',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.blue),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 名字输入
          const Text(
            '备注名',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: '输入你给 TA 的备注',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.blue),
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
              color: AppColors.textPrimary,
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
                selectedColor: AppColors.pinkBgMedium,
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
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                _isSaving ? '添加中…' : '添加',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 在 [initState] 中拉取短码，避免在 [build] 里触发异步副作用。
class _MyFriendCodeDialog extends StatefulWidget {
  const _MyFriendCodeDialog({
    required this.messenger,
    required this.dialogContext,
  });

  final ScaffoldMessengerState messenger;
  final BuildContext dialogContext;

  @override
  State<_MyFriendCodeDialog> createState() => _MyFriendCodeDialogState();
}

class _MyFriendCodeDialogState extends State<_MyFriendCodeDialog> {
  String _friendCode = '';
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await BackendApiService.instance.getFriendCode();
      if (!mounted) return;
      setState(() {
        _friendCode = (result['friendCode'] as String?) ?? '';
        _loadError = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = backendApiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _rotate() async {
    setState(() => _isLoading = true);
    try {
      final result = await BackendApiService.instance.rotateFriendCode();
      if (!mounted) return;
      setState(() {
        _friendCode = (result['friendCode'] as String?) ?? '';
        _loadError = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = backendApiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('我的好友短码'),
      content: _isLoading
          ? const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            )
          : (_loadError != null)
              ? Text(
                  _loadError!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                )
              : SelectableText(
                  _friendCode,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(widget.dialogContext).pop(),
          child: const Text('关闭'),
        ),
        TextButton(
          onPressed: _isLoading || _loadError != null || _friendCode.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: _friendCode));
                  widget.messenger.showSnackBar(
                    const SnackBar(content: Text('已复制到剪贴板')),
                  );
                },
          child: const Text('复制'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _rotate,
          child: const Text('刷新短码'),
        ),
      ],
    );
  }
}
