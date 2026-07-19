import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/app_providers.dart';
import '../design_system/components/premium_card.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final TextEditingController _chatController = TextEditingController();

  void _submitChat(String text) {
    if (text.trim().isEmpty) return;
    final prompt = text.trim();
    _chatController.clear();
    context.push('/ai_coach/session', extra: {'initialPrompt': prompt});
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(aiDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Coach', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textSecondary),
            tooltip: 'Chat History',
            onPressed: () => context.push('/ai_coach/history'),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: dashboardAsync.when(
                data: (data) {
                  if (data['isEmpty'] == true) {
                    return _buildEmptyState();
                  }
                  return _buildDashboard(data);
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentAI)),
                error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.negative))),
              ),
            ),
            _buildStickyChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> data) {
    final int score = data['score'] as int;
    final String healthStatus = data['healthStatus'] as String;
    final String healthReason = data['healthReason'] as String;
    final String todayInsight = data['todayInsight'] as String;
    final List<String> recommendations = List<String>.from(data['recommendations']);
    final Map<String, String> snapshot = Map<String, String>.from(data['snapshot']);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthSection(score, healthStatus, healthReason),
          const SizedBox(height: AppSpacing.xxl),
          _buildInsightSection(todayInsight),
          const SizedBox(height: AppSpacing.xxl),
          _buildRecommendationsSection(recommendations),
          const SizedBox(height: AppSpacing.xxl),
          _buildSnapshotSection(snapshot),
          const SizedBox(height: AppSpacing.xxl),
          _buildQuickQuestionsSection(),
          const SizedBox(height: AppSpacing.lg), // Padding at bottom
        ],
      ),
    );
  }

  Widget _buildHealthSection(int score, String status, String reason) {
    Color statusColor;
    IconData statusIcon;
    if (score >= 80) {
      statusColor = AppColors.positive;
      statusIcon = Icons.check_circle_rounded;
    } else if (score >= 60) {
      statusColor = AppColors.positive; // Or secondary color
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (score >= 40) {
      statusColor = AppColors.warning;
      statusIcon = Icons.info_outline_rounded;
    } else {
      statusColor = AppColors.negative;
      statusIcon = Icons.warning_amber_rounded;
    }

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surfaceHighlight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                score.toString(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.5,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xl),
          Container(
            width: 1,
            height: 60,
            color: AppColors.border,
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Financial Health",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection(String insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Insight",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          backgroundColor: AppColors.accentAI.withValues(alpha: 0.1),
          customBorder: Border.all(color: AppColors.accentAI.withValues(alpha: 0.3)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accentAI, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  insight,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(List<String> recommendations) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommendations",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...recommendations.map((rec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.positive.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: AppColors.positive, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSnapshotSection(Map<String, String> snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Financial Snapshot",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: snapshot.entries.map((entry) {
            return Container(
              width: (MediaQuery.of(context).size.width - (AppSpacing.lg * 2) - AppSpacing.sm) / 2,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickQuestionsSection() {
    final questions = [
      'Where did my money go?',
      'How can I save more?',
      'Can I afford this purchase?',
      'How much can I invest?',
      'Explain my spending.',
      'What changed this month?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Questions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: questions.map((q) {
            return ActionChip(
              label: Text(q),
              backgroundColor: AppColors.surfaceHighlight,
              labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.accentAI.withValues(alpha: 0.2)),
              ),
              onPressed: () => _submitChat(q),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentAI.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insights, color: AppColors.accentAI, size: 64),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'No financial data yet.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Start by adding income or expenses.\n\nYour AI Coach will begin generating personalized insights automatically.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyChatInput() {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.send,
              onSubmitted: _submitChat,
              decoration: InputDecoration(
                hintText: 'Ask anything about your finances...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.accentAI,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              onPressed: () => _submitChat(_chatController.text),
            ),
          ),
        ],
      ),
    );
  }
}
