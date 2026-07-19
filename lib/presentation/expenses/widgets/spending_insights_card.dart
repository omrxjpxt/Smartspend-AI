import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../design_system/components/premium_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SpendingInsightsCard extends ConsumerWidget {
  const SpendingInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSpent = ref.watch(currentMonthExpensesProvider);
    final monthlyBudget = ref.watch(monthlyBudgetProvider);

    // Previous month comparison
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.valueOrNull ?? [];
    final now = DateTime.now();

    // Current month category breakdown
    final Map<String, double> categories = {};
    for (var e in expenses) {
      if (e.date.month == now.month && e.date.year == now.year) {
        categories[e.category] = (categories[e.category] ?? 0) + e.amount;
      }
    }

    // Previous month total for trend
    final previousMonthExpenses = expenses
        .where((e) => (now.month == 1
            ? e.date.month == 12 && e.date.year == now.year - 1
            : e.date.month == now.month - 1 && e.date.year == now.year))
        .fold(0.0, (sum, e) => sum + e.amount);

    double? trendPercent;
    bool isTrendUp = false;
    if (previousMonthExpenses > 0) {
      trendPercent = ((totalSpent - previousMonthExpenses) / previousMonthExpenses) * 100;
      isTrendUp = trendPercent > 0;
    }

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final hasBudget = monthlyBudget > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PremiumCard(
        backgroundColor: AppColors.surfaceHighlight,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "This Month" + trend badge
            _buildHeader(context, trendPercent, isTrendUp),
            const SizedBox(height: AppSpacing.lg),

            // Primary metric: Total Spent
            _buildHeroMetric(context, currencyFormatter, totalSpent),
            const SizedBox(height: AppSpacing.xl),

            // Budget section or No-Budget CTA
            if (hasBudget)
              _buildBudgetSection(context, currencyFormatter, totalSpent, monthlyBudget)
            else
              _buildNoBudgetCTA(context),

            const SizedBox(height: AppSpacing.lg),

            // Insight
            _buildInsight(
              context,
              totalSpent: totalSpent,
              monthlyBudget: monthlyBudget,
              hasBudget: hasBudget,
              categories: categories,
              trendPercent: trendPercent,
              previousMonthExpenses: previousMonthExpenses,
              currencyFormatter: currencyFormatter,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // Header row: "This Month" label + trend badge
  // -------------------------------------------------------
  Widget _buildHeader(BuildContext context, double? trendPercent, bool isTrendUp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'This Month',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
        ),
        if (trendPercent != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.xs + 1,
            ),
            decoration: BoxDecoration(
              color: (isTrendUp ? AppColors.negative : AppColors.positive)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTrendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isTrendUp ? AppColors.negative : AppColors.positive,
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  '${trendPercent.abs().toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isTrendUp ? AppColors.negative : AppColors.positive,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------
  // Hero metric: "Total Spent" + ₹X
  // -------------------------------------------------------
  Widget _buildHeroMetric(BuildContext context, NumberFormat formatter, double totalSpent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Spent',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatter.format(totalSpent),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -1.0,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // Budget section: progress bar + status + secondary metrics
  // -------------------------------------------------------
  Widget _buildBudgetSection(
    BuildContext context,
    NumberFormat formatter,
    double totalSpent,
    double monthlyBudget,
  ) {
    final spendRatio = totalSpent / monthlyBudget;
    final remaining = monthlyBudget - totalSpent;
    final percentUsed = (spendRatio * 100).clamp(0.0, 999.0);

    // Status logic
    String statusLabel;
    Color statusColor;
    IconData statusIcon;

    if (spendRatio <= 0.6) {
      statusLabel = 'Excellent';
      statusColor = AppColors.positive;
      statusIcon = Icons.check_circle_rounded;
    } else if (spendRatio <= 0.8) {
      statusLabel = 'Good';
      statusColor = AppColors.positive;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (spendRatio <= 1.0) {
      statusLabel = 'Watch Spending';
      statusColor = AppColors.warning;
      statusIcon = Icons.info_outline_rounded;
    } else {
      statusLabel = 'Budget Exceeded';
      statusColor = AppColors.negative;
      statusIcon = Icons.warning_amber_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        _buildProgressBar(context, spendRatio, statusColor, percentUsed),
        const SizedBox(height: AppSpacing.md),

        // Status badge
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 6),
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Secondary metrics: Budget | Remaining
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSecondaryMetric(
                  context,
                  label: 'Budget',
                  value: formatter.format(monthlyBudget),
                  dotColor: AppColors.textTertiary,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.border,
              ),
              Expanded(
                child: _buildSecondaryMetric(
                  context,
                  label: 'Remaining',
                  value: formatter.format(remaining),
                  dotColor: remaining >= 0 ? AppColors.positive : AppColors.negative,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // Animated progress bar
  // -------------------------------------------------------
  Widget _buildProgressBar(BuildContext context, double ratio, Color color, double percentUsed) {
    final clampedRatio = ratio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${percentUsed.toStringAsFixed(0)}% spent',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (ratio > 1.0)
              Text(
                '${((ratio - 1.0) * 100).toStringAsFixed(0)}% over',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.negative,
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: clampedRatio),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // Secondary metric column (Budget / Remaining)
  // -------------------------------------------------------
  Widget _buildSecondaryMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color dotColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // No-budget CTA
  // -------------------------------------------------------
  Widget _buildNoBudgetCTA(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentAI.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.accentAI.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            color: AppColors.accentAI.withValues(alpha: 0.7),
            size: 28,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No monthly budget set',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Set one to receive better spending insights.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () {
              // Navigate to Profile screen where budget/income can be configured
              Navigator.of(context).pushNamed('/profile');
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.accentAI.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set Budget',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.accentAI,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.accentAI, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // Data-driven insight
  // -------------------------------------------------------
  Widget _buildInsight(
    BuildContext context, {
    required double totalSpent,
    required double monthlyBudget,
    required bool hasBudget,
    required Map<String, double> categories,
    required double? trendPercent,
    required double previousMonthExpenses,
    required NumberFormat currencyFormatter,
  }) {
    String insight = '';

    // Find top category
    String? topCategory;
    double topCategoryAmount = 0;
    double topCategoryPercent = 0;
    if (categories.isNotEmpty && totalSpent > 0) {
      final sorted = categories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sorted.first.key;
      topCategoryAmount = sorted.first.value;
      topCategoryPercent = (topCategoryAmount / totalSpent) * 100;
    }

    // Priority-ordered insight generation
    if (hasBudget && totalSpent > monthlyBudget) {
      final overAmount = totalSpent - monthlyBudget;
      insight = 'You\'ve exceeded your monthly budget by ${currencyFormatter.format(overAmount)}.';
    } else if (topCategory != null && topCategoryPercent > 40) {
      insight = '$topCategory represents ${topCategoryPercent.toStringAsFixed(0)}% of your spending.';
    } else if (trendPercent != null && trendPercent < 0) {
      final savedAmount = previousMonthExpenses - totalSpent;
      insight = 'You spent ${currencyFormatter.format(savedAmount)} less than last month.';
    } else if (trendPercent != null && trendPercent > 0) {
      insight = 'Your spending is up ${trendPercent.toStringAsFixed(0)}% compared to last month.';
    } else if (hasBudget) {
      final spendPercent = ((totalSpent / monthlyBudget) * 100).toStringAsFixed(0);
      insight = 'You have used $spendPercent% of your monthly budget.';
    } else if (topCategory != null) {
      insight = 'Top category: $topCategory (${currencyFormatter.format(topCategoryAmount)}).';
    } else {
      insight = 'Start tracking expenses to unlock spending insights.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              insight,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
