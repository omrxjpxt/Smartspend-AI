import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SuggestedPrompts extends StatelessWidget {
  final Function(String) onPromptTap;

  const SuggestedPrompts({super.key, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    final prompts = [
      "💰 How can I save more this month?",
      "📊 Analyze my spending",
      "🎯 Help me reach my goals faster",
      "📈 Review my investments",
      "🧾 Explain this month's expenses",
      "📂 Generate monthly financial summary"
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: prompts.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onPromptTap(prompts[index].substring(2).trim()), // Remove emoji for prompt
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                prompts[index],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
