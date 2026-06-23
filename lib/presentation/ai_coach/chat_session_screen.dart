import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/ai_prompts.dart';
import '../../services/ai_service.dart';
import '../../services/financial_context_builder.dart';
import '../../data/repositories/ai_chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import 'widgets/chat_input.dart';

class ChatSessionScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? initialPrompt;

  const ChatSessionScreen({
    super.key,
    this.conversationId,
    this.initialPrompt,
  });

  @override
  ConsumerState<ChatSessionScreen> createState() => _ChatSessionScreenState();
}

class _ChatSessionScreenState extends ConsumerState<ChatSessionScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _currentConversationId;
  final bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialPrompt!);
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final chatRepo = ref.read(aiChatRepositoryProvider);
    final aiService = ref.read(aiServiceProvider);
    final contextData = ref.read(financialContextProvider);

    try {
      // 1. Create conversation if it doesn't exist
      if (_currentConversationId == null) {
        // Generate a quick smart title based on the first prompt
        String title = "New Conversation";
        try {
          title = await aiService.generateInsight(
            systemPrompt:
                "You are a title generator. Generate a 2-4 word concise title for a conversation starting with this prompt. Do not use quotes or prefixes.",
            context: "",
            userPrompt: text.trim(),
            ref: ref,
            bypassRateLimit: true,
          );
        } catch (e) {
          // ignore
        }

        final newId =
            await chatRepo.createConversation(title.trim(), text.trim());
        setState(() {
          _currentConversationId = newId;
        });
      }

      final cid = _currentConversationId!;

      // 2. Add user message
      await chatRepo.addMessage(
          conversationId: cid, role: 'user', message: text.trim());

      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

      // 3. Call AI
      final response = await aiService.generateInsight(
        systemPrompt: AiPrompts.systemPrompt,
        context: contextData,
        userPrompt: text.trim(),
        ref: ref,
      );

      // 4. Add AI message
      await chatRepo.addMessage(
          conversationId: cid, role: 'model', message: response);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('SmartSpend AI',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.border.withValues(alpha: 0.1),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _currentConversationId == null && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 48,
                              color: AppColors.accentAI.withValues(alpha: 0.3)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Send a message to start',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    )
                  : _currentConversationId == null && _isLoading
                      ? _buildLoadingState()
                      : _buildMessageList(),
            ),
            _buildQuickActionsRow(),
            ChatInput(
              onSend: _handleSendMessage,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    final actions = [
      '📊 Analyze Spending',
      '💰 Saving Tips',
      '🎯 Goal Advice',
      '📈 Investment Analysis',
      '⚠ Overspending Alert',
      '📅 Monthly Summary'
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          return ActionChip(
            label: Text(action, style: const TextStyle(fontSize: 13, color: Colors.white)),
            backgroundColor: AppColors.surfaceHighlight,
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              // Strip the emoji before sending
              final prompt = action.substring(2).trim();
              _handleSendMessage(prompt);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypingIndicator(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messagesAsync =
        ref.watch(chatMessagesProvider(_currentConversationId!));

    return messagesAsync.when(
      data: (messages) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.lg),
          physics: const BouncingScrollPhysics(),
          itemCount: messages.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length) {
              return _buildTypingIndicator();
            }
            return _buildMessageBubble(messages[index]);
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentAI)),
      error: (e, s) => Center(
          child: Text('Error loading chat: $e',
              style: const TextStyle(color: AppColors.negative))),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
            bottom: AppSpacing.md, right: 80, left: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentAI,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Text('Thinking...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    final timeFormat = DateFormat('h:mm a').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppSpacing.lg,
          left: isUser ? 50 : AppSpacing.sm,
          right: isUser ? AppSpacing.sm : 50,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.accentAI.withValues(alpha: 0.15)
              : AppColors.surfaceHighlight,
          border: isUser
              ? Border.all(color: AppColors.accentAI.withValues(alpha: 0.3))
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isUser ? Colors.white : AppColors.textPrimary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: isUser ? Alignment.bottomRight : Alignment.bottomLeft,
              child: Text(
                timeFormat,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
