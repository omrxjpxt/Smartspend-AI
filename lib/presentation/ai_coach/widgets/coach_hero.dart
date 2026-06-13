import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../../services/financial_context_builder.dart';

class CoachHero extends ConsumerWidget {
  const CoachHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final contextData = ref.watch(financialContextProvider);

    String greetingName = '';
    if (profileAsync.hasValue && profileAsync.value != null) {
      final name = profileAsync.value!.name.trim();
      if (name.isNotEmpty) {
        greetingName = ', $name';
      }
    }

    // Check if user has some data
    final hasData = contextData.contains('Monthly Expenses') && !contextData.contains('Monthly Expenses: \n') ||
                    contextData.contains('Investments') && !contextData.contains('Investments: \n');

    final headerMessage = hasData 
        ? 'Based on your latest financial activity.' 
        : 'Start tracking expenses to receive insights.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accentAI.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.accentAI, size: 36),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Good evening$greetingName.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            headerMessage,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
