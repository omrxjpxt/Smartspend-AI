import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/ai_chat_repository.dart';
import '../providers/app_providers.dart';
import '../design_system/components/premium_card.dart';

class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentChatsAsync = ref.watch(recentConversationsProvider);
    final userProfile = ref.watch(userProfileProvider);
    final userName = userProfile.valueOrNull?.name ?? 'User';
    final firstName = userName.split(' ').first;

    final suggestedPrompts = [
      'Analyze my spending',
      'How can I save more this month?',
      'Create a savings plan',
      'Help me reach my goals faster',
      'Review my investments',
      'Build an emergency fund',
      'Improve my monthly budget',
      'Generate financial insights',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Coach', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.accentAI),
            tooltip: 'New Chat',
            onPressed: () => context.push('/ai_coach/session'),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER SECTION
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.accentAI.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.accentAI, size: 48),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '${_getGreeting()}, $firstName',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'How can I help with your finances today?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // SUGGESTED PROMPTS
              Text(
                'Suggestions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: suggestedPrompts.map((prompt) {
                  return ActionChip(
                    label: Text(prompt),
                    backgroundColor: AppColors.surfaceHighlight,
                    labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.accentAI.withValues(alpha: 0.2)),
                    ),
                    onPressed: () {
                      context.push('/ai_coach/session', extra: {'initialPrompt': prompt});
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // RECENT CONVERSATIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Conversations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/ai_coach/history'),
                    child: const Text('View All', style: TextStyle(color: AppColors.accentAI)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              recentChatsAsync.when(
                data: (chats) {
                  if (chats.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No recent conversations',
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: chats.map((chat) {
                      final timeFormat = DateFormat('MMM d • h:mm a').format(chat.updatedAt);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: GestureDetector(
                          onTap: () => context.push('/ai_coach/session/${chat.id}'),
                          behavior: HitTestBehavior.opaque,
                          child: PremiumCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            backgroundColor: AppColors.surfaceHighlight,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline, color: AppColors.accentAI, size: 20),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chat.title,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chat.preview,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      timeFormat,
                                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 11),
                                    ),
                                    const SizedBox(height: 4),
                                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentAI)),
                error: (e, s) => Text('Error: $e', style: const TextStyle(color: AppColors.negative)),
              ),
              const SizedBox(height: 80), // Padding for bottom nav bar
            ],
          ),
        ),
      ),
    );
  }
}
