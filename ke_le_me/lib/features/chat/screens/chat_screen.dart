import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../services/ai_config.dart';
import '../services/ai_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/suggestion_chips.dart';

class ChatScreen extends StatefulWidget {
  final UserProvider userProvider;

  const ChatScreen({super.key, required this.userProvider});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatProvider _chatProvider;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final aiService = AiService(config: AiConfig.fromEnvironment());
    _chatProvider = ChatProvider(
      aiService: aiService,
      userProvider: widget.userProvider,
    );
    _chatProvider.addListener(_onChatChanged);
    _chatProvider.onToolExecuted = (toolName, result) {
      if (!mounted) return;
      if (toolName == 'save_health_note' && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📝 已记住：${result['saved_content'] ?? ''}'),
            backgroundColor: AppColors.bgCard,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (toolName == 'set_reminder' && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ 已设置提醒：${result['title'] ?? ''}'),
            backgroundColor: AppColors.bgCard,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    };
    _initChat();
  }

  Future<void> _initChat() async {
    await _chatProvider.init();
    if (mounted) {
      setState(() => _initialized = true);
      _scrollToBottom();
    }
  }

  void _onChatChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    await _chatProvider.sendMessage(text);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清空对话'),
        content: const Text('确定要清空所有对话记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _chatProvider.clearHistory();
    }
  }

  @override
  void dispose() {
    _chatProvider.removeListener(_onChatChanged);
    _chatProvider.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_chatProvider.shouldGenerateSummary) {
          unawaited(_chatProvider.generateSummary());
        }
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: _buildAppBar(),
        body: _initialized ? _buildBody() : _buildLoading(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgCard,
      elevation: 0,
      shadowColor: AppColors.shadow,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: AppColors.textPrimary,
        onPressed: () {
          if (_chatProvider.shouldGenerateSummary) {
            unawaited(_chatProvider.generateSummary());
          }
          Navigator.pop(context);
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blueLight,
            ),
            child: Center(
              child: Text(
                '渴',
                style: GoogleFonts.notoSansSc(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AI 健康助手',
            style: GoogleFonts.notoSansSc(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: AppColors.textSecondary,
          onPressed: _confirmClear,
          tooltip: '清空对话',
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.blue),
    );
  }

  Widget _buildBody() {
    final messages = _chatProvider.messages;
    final isGenerating = _chatProvider.isGenerating;

    // 判断是否显示 typing indicator：正在生成且最后一条 assistant 消息内容为空
    final showTyping = isGenerating &&
        (messages.isEmpty ||
            messages.last.role != MessageRole.assistant ||
            messages.last.content.isEmpty);

    // 只显示 user 和 assistant 消息（隐藏 system / tool）
    // 同时过滤掉内容为空的 streaming 占位消息（由 typing indicator 代替）
    final visibleMessages = messages
        .where((m) =>
            (m.role == MessageRole.user || m.role == MessageRole.assistant) &&
            !(m.role == MessageRole.assistant &&
                m.content.isEmpty &&
                m.status == MessageStatus.streaming))
        .toList();

    final showSuggestions = visibleMessages.length <= 1 && !isGenerating;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            itemCount: visibleMessages.length + (showTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (showTyping && index == 0) {
                return const TypingIndicator();
              }
              final msgIndex = visibleMessages.length -
                  1 -
                  (showTyping ? index - 1 : index);
              return ChatBubble(message: visibleMessages[msgIndex]);
            },
          ),
        ),
        if (showSuggestions) ...[
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SuggestionChips(
              onSuggestionTap: (text) => _sendMessage(text),
            ),
          ),
        ],
        const Divider(height: 1, color: AppColors.divider),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: AppColors.bgCard,
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 10
            : 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgSection,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                enabled: !_chatProvider.isGenerating,
                decoration: InputDecoration(
                  hintText: _chatProvider.isGenerating ? '小渴正在思考...' : '输入消息...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _chatProvider.isGenerating
                ? null
                : () => _sendMessage(_textController.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _chatProvider.isGenerating
                    ? AppColors.textHint
                    : AppColors.blue,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
