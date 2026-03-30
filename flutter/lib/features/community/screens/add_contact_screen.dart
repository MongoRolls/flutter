import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/widgets/app_modal_sheet.dart';
import '../../../common/widgets/app_toast.dart';
import '../../../core/services/backend_api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/backend_api_error_message.dart';
import '../models/care_contact.dart';

/// 添加关怀联系人页面（结构化表单：好友码、关系、备注、头像）
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
  static const _relationshipOptions = [('family', '家人'), ('friend', '朋友')];

  @override
  void dispose() {
    _friendCodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _resolveNickname(String trimmedRemark, Map<String, dynamic> lookup) {
    if (trimmedRemark.isNotEmpty) return trimmedRemark;
    final remote = (lookup['nickname'] as String?)?.trim();
    if (remote != null && remote.isNotEmpty) return remote;
    return '水友';
  }

  Future<void> _save() async {
    final code = _friendCodeController.text.trim().toUpperCase();
    final remark = _nameController.text.trim();
    if (code.isEmpty) {
      AppToast.error(context, '请输入好友短码');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final backend = BackendApiService.instance;
      final lookup = await backend.lookupFriendCode(code);
      final contactId = lookup['userId'] as String;
      final nickname = _resolveNickname(remark, lookup);
      await backend.createCareContact(contactId: contactId, nickname: nickname);

      final contact = CareContact(
        id: contactId,
        name: nickname,
        relationship: _relationship,
        avatarEmoji: _avatarEmoji,
      );
      if (!mounted) return;
      Navigator.of(context).pop(contact);
    } catch (e) {
      if (!mounted) return;
      final msg = backendApiErrorMessage(e);
      AppToast.error(context, msg);
      setState(() => _isSaving = false);
    }
  }

  Future<void> _showMyFriendCodeSheet() async {
    await showAppModalSheet<void>(
      context: context,
      builder: (sheetContext) => const _MyFriendCodeSheet(),
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
            onPressed: _showMyFriendCodeSheet,
            child: const Text('我的短码'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
              hintText: '输入好友短码（例如 AB3K9Q）',
              counterText: '',
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

          // 关系
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
          const SizedBox(height: 24),

          // 备注（可选）
          const Text(
            '昵称备注（可选）',
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
              hintText: '不填则使用对方昵称或默认「水友」',
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

          // 头像
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
          const SizedBox(height: 40),

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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部弹层：展示我的好友短码（非 AlertDialog）
class _MyFriendCodeSheet extends StatefulWidget {
  const _MyFriendCodeSheet();

  @override
  State<_MyFriendCodeSheet> createState() => _MyFriendCodeSheetState();
}

class _MyFriendCodeSheetState extends State<_MyFriendCodeSheet> {
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

  Future<void> _copy(BuildContext outerContext) async {
    if (_friendCode.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _friendCode));
    if (!outerContext.mounted) return;
    AppToast.info(outerContext, '已复制到剪贴板');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '我的好友短码',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_loadError != null)
          Text(
            _loadError!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          )
        else
          SelectableText(
            _friendCode,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.textPrimary,
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isLoading || _loadError != null || _friendCode.isEmpty
                    ? null
                    : () => _copy(context),
                child: const Text('复制'),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _isLoading ? null : _rotate,
          child: const Text('刷新短码'),
        ),
      ],
    );
  }
}
