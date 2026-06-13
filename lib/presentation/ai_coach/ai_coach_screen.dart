import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/ai_prompts.dart';
import '../../services/ai_service.dart';
import '../../services/financial_context_builder.dart';
import '../../data/repositories/ai_chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import 'widgets/coach_hero.dart';
import 'widgets/suggested_prompts.dart';
import 'widgets/chat_input.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

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

    final chatRepo = ref.read(aiChatRepositoryProvider);
    final contextData = ref.read(financialContextProvider);
    final aiService = ref.read(aiServiceProvider);

    // 1. Add user message
    await chatRepo.addMessage(role: 'user', message: text.trim());
    
    setState(() {
      _isLoading = true;
    });
    
    // Future delay to allow UI to update and scroll
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    // 2. Call AI
    final response = await aiService.generateInsight(
      systemPrompt: AiPrompts.systemPrompt,
      context: contextData,
      userPrompt: text.trim(),
      ref: ref,
    );

    // 3. Add AI message
    await chatRepo.addMessage(role: 'model', message: response);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatHistoryAsync = ref.watch(chatHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            const SizedBox(height: AppSpacing.xl),
            const CoachHero(),
            const SizedBox(height: AppSpacing.xl),
            
            // CHAT HISTORY OR EMPTY STATE
            Expanded(
              child: chatHistoryAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 64, color: AppColors.accentAI.withValues(alpha: 0.5)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No conversation yet.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          SuggestedPrompts(
                            onPromptTap: _handleSendMessage,
                          ),
                        ],
                      ),
                    );
                  }

                  // If messages exist, we show the list.
                  // We'll also prepend suggested prompts at the very top of the list if we want, or keep it sticky.
                  // Let's put suggested prompts sticky above the list.
                  return Column(
                    children: [
                      SuggestedPrompts(onPromptTap: _handleSendMessage),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          physics: const BouncingScrollPhysics(),
                          itemCount: messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return _buildTypingIndicator();
                            }
                            return _buildMessageBubble(messages[index]);
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentAI)),
                error: (e, s) => Center(child: Text('Error loading chat: $e')),
              ),
            ),

            // INPUT AREA
            ChatInput(
              onSend: _handleSendMessage,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md, right: 80),
        padding: const EdgeInsets.all(AppSpacing.md),
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
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentAI,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Text('SmartSpend AI is typing...', style: TextStyle(color: AppColors.textSecondary)),
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
          bottom: AppSpacing.md,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentAI.withValues(alpha: 0.15) : AppColors.surfaceHighlight,
          border: isUser ? Border.all(color: AppColors.accentAI.withValues(alpha: 0.3)) : null,
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
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeFormat,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
