import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../design_system/components/premium_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SpendingInsightsCard extends ConsumerWidget {
  const SpendingInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final insightsAsync = ref.watch(aiInsightsProvider);
    
    final expenses = expensesAsync.valueOrNull ?? [];
    final insights = insightsAsync.valueOrNull ?? [];

    final now = DateTime.now();
    final totalSpend = expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    // Look for a spending insight, otherwise use a default
    final spendingInsight = insights.where((i) => i.type == 'spending').firstOrNull?.message 
      ?? 'Your spending is well balanced this month. Keep tracking your daily expenses.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        backgroundColor: AppColors.surfaceHighlight,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      currencyFormatter.format(totalSpend),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.positive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: AppColors.positive, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '14%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.positive,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      startDegreeOffset: 180,
                      sections: [
                        PieChartSectionData(
                          color: AppColors.accentAI,
                          value: 55,
                          title: '',
                          radius: 20,
                        ),
                        PieChartSectionData(
                          color: AppColors.positive,
                          value: 18,
                          title: '',
                          radius: 20,
                        ),
                        PieChartSectionData(
                          color: AppColors.warning,
                          value: 10,
                          title: '',
                          radius: 20,
                        ),
                        PieChartSectionData(
                          color: AppColors.textTertiary,
                          value: 17,
                          title: '',
                          radius: 20,
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'On Budget',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.positive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              spendingInsight,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
