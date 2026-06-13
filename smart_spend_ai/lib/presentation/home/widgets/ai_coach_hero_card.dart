import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AiCoachHeroCard extends StatelessWidget {
  const AiCoachHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.0),
          gradient: AppColors.aiGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentAI.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'AI Coach',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your capital is\nbreathing easier.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.0,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "You spent ₹840 less than last week. Your dining out expenses dropped by 12%. Keep this up, and you'll hit your laptop savings target 4 days early.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Ask AI Coach',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.accentAI,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

