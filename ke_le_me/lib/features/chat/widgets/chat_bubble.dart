import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!_isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: _isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildBubble(context),
                const SizedBox(height: 3),
                _buildTimestamp(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.blueLight,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/mascot.png',
          width: 32,
          height: 32,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;
    final isStreaming = message.status == MessageStatus.streaming;
    final isError = message.status == MessageStatus.error;

    final textColor = isError
        ? AppColors.orange
        : _isUser
            ? Colors.white
            : AppColors.textPrimary;

    final content = isStreaming && message.content.isNotEmpty
        ? '${message.content}▍'
        : message.content.isEmpty && isStreaming
            ? '▍'
            : message.content;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isError
              ? AppColors.orangeLight
              : _isUser
                  ? AppColors.blue
                  : AppColors.bgCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: _isUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: _isUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _isUser
            ? Text(content, style: TextStyle(fontSize: 14, height: 1.5, color: textColor))
            : isError && message.content.contains('Key')
                ? _buildApiKeyError(context, content, textColor)
                : _buildMarkdownBody(content, textColor),
      ),
    );
  }

  Widget _buildApiKeyError(BuildContext context, String content, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(content, style: TextStyle(fontSize: 14, height: 1.5, color: textColor)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/settings'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '前往设置 →',
              style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownBody(String content, Color textColor) {
    return MarkdownBody(
      data: content,
      shrinkWrap: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        strong: TextStyle(fontSize: 14, height: 1.5, color: textColor, fontWeight: FontWeight.w700),
        em: TextStyle(fontSize: 14, height: 1.5, color: textColor, fontStyle: FontStyle.italic),
        h1: TextStyle(fontSize: 18, height: 1.4, color: textColor, fontWeight: FontWeight.w700),
        h2: TextStyle(fontSize: 16, height: 1.4, color: textColor, fontWeight: FontWeight.w700),
        h3: TextStyle(fontSize: 15, height: 1.4, color: textColor, fontWeight: FontWeight.w600),
        listBullet: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        code: TextStyle(
          fontSize: 13,
          color: AppColors.blue,
          backgroundColor: AppColors.blueLight,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.bgSection,
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.blue, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        tableBorder: TableBorder.all(color: AppColors.divider, width: 1),
        tableHead: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
        tableBody: TextStyle(fontSize: 13, color: textColor),
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        pPadding: EdgeInsets.zero,
        h1Padding: const EdgeInsets.only(bottom: 4),
        h2Padding: const EdgeInsets.only(bottom: 4),
        h3Padding: const EdgeInsets.only(bottom: 2),
        listIndent: 20,
        listBulletPadding: const EdgeInsets.only(right: 4),
        blockSpacing: 8,
      ),
    );
  }

  Widget _buildTimestamp() {
    final h = message.timestamp.hour.toString().padLeft(2, '0');
    final m = message.timestamp.minute.toString().padLeft(2, '0');
    return Text(
      '$h:$m',
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.textHint,
      ),
    );
  }
}
