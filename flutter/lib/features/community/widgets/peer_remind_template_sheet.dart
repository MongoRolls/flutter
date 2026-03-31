import 'package:flutter/material.dart';

import '../../../common/widgets/app_modal_sheet.dart';
import '../../../common/widgets/app_toast.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/backend_api_error_message.dart';
import '../../../core/constants/peer_remind_templates.dart';
import '../../../core/services/backend_api_service.dart';

/// 已添加队友卡片上「提醒对方」：选模板后调用后端发送。
Future<void> showPeerRemindTemplateSheet({
  required BuildContext context,
  required String peerDisplayName,
  required String contactUserId,
}) {
  return showAppModalSheet<void>(
    context: context,
    builder: (ctx) => _PeerRemindTemplateBody(
      peerDisplayName: peerDisplayName,
      contactUserId: contactUserId,
    ),
  );
}

class _PeerRemindTemplateBody extends StatefulWidget {
  final String peerDisplayName;
  final String contactUserId;

  const _PeerRemindTemplateBody({
    required this.peerDisplayName,
    required this.contactUserId,
  });

  @override
  State<_PeerRemindTemplateBody> createState() =>
      _PeerRemindTemplateBodyState();
}

class _PeerRemindTemplateBodyState extends State<_PeerRemindTemplateBody> {
  int? _selectedId;
  bool _sending = false;

  Future<void> _send() async {
    final tid = _selectedId;
    if (tid == null || _sending) return;
    setState(() => _sending = true);
    try {
      await BackendApiService.instance.sendCareRemind(
        contactId: widget.contactUserId,
        templateId: tid,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.success(context, '已发送提醒');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, backendApiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pinkBgMedium.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: AppColors.blueDark,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '提醒对方喝水',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '将向「${widget.peerDisplayName}」发送一条喝水提醒，请选择语气模板。',
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kPeerRemindTemplateOptions.map((t) {
            final selected = _selectedId == t.id;
            return FilterChip(
              label: Text(t.label),
              selected: selected,
              onSelected: _sending
                  ? null
                  : (_) => setState(() => _selectedId = t.id),
            );
          }).toList(),
        ),
        if (_selectedId != null) ...[
          const SizedBox(height: 10),
          Text(
            kPeerRemindTemplateOptions
                .firstWhere((t) => t.id == _selectedId)
                .body,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textHint,
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          '若对方未开启本 App 通知，可能无法及时收到提醒。',
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed:
              (_selectedId == null || _sending) ? null : _send,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _sending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Text(
                  '发送',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
