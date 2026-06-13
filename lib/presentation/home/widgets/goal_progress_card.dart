import 'package:flutter/material.dart';
import '../../design_system/components/premium_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.laptop_mac, color: AppColors.textPrimary, size: 28),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laptop Goal',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '76% On Track',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.positive,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Saving ₹110 today keeps you ahead of schedule.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: const LinearProgressIndicator(
                value: 0.76,
                backgroundColor: AppColors.surfaceHighlight,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.positive),
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

