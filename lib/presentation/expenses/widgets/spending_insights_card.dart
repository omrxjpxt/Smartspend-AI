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
    final expenses = expensesAsync.valueOrNull ?? [];

    final received = ref.watch(currentMonthReceivedProvider);
    final balance = ref.watch(availableBalanceProvider);

    final now = DateTime.now();
    
    // Calculate current month expenses and categories
    double totalSpend = 0;
    Map<String, double> categories = {};
    
    for (var e in expenses) {
      if (e.date.month == now.month && e.date.year == now.year) {
        totalSpend += e.amount;
        categories[e.category] = (categories[e.category] ?? 0) + e.amount;
      }
    }

    // Calculate previous month expenses for trend
    final previousMonthExpenses = expenses
        .where((e) => (now.month == 1 
            ? e.date.month == 12 && e.date.year == now.year - 1 
            : e.date.month == now.month - 1 && e.date.year == now.year))
        .fold(0.0, (sum, e) => sum + e.amount);

    double? trendPercent;
    bool isTrendPositive = false; // "Positive" means we spent MORE (bad for expenses), wait, let's just define up/down.
    if (previousMonthExpenses > 0) {
      trendPercent = ((totalSpend - previousMonthExpenses) / previousMonthExpenses) * 100;
      isTrendPositive = trendPercent > 0;
    }

    // Health Score Logic
    String statusTitle;
    String statusMessage;
    Color statusColor;
    IconData statusIcon;

    if (totalSpend == 0) {
      statusTitle = 'No Spending Yet';
      statusMessage = 'Start tracking your expenses.';
      statusColor = Colors.purpleAccent;
      statusIcon = Icons.account_balance_wallet_outlined;
    } else if (balance < 0) {
      statusTitle = 'Overspending';
      final overspent = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(balance.abs());
      statusMessage = 'You have spent $overspent more than received this month.';
      statusColor = AppColors.negative;
      statusIcon = Icons.warning_amber_rounded;
    } else if (balance <= 0.25 * received) {
      statusTitle = 'Watch Spending';
      statusMessage = 'You are approaching your monthly limit.';
      statusColor = AppColors.warning;
      statusIcon = Icons.info_outline;
    } else {
      statusTitle = 'Excellent';
      statusMessage = 'You are managing your spending well.';
      statusColor = AppColors.positive;
      statusIcon = Icons.check_circle_outline;
    }

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    // Dynamic Pie Chart Data
    final List<Color> pieColors = [
      AppColors.accentAI,
      AppColors.positive,
      AppColors.warning,
      AppColors.textTertiary,
      Colors.indigoAccent,
      Colors.teal,
    ];
    
    List<PieChartSectionData> pieSections = [];
    if (categories.isEmpty) {
      pieSections = [
        PieChartSectionData(color: AppColors.surface, value: 100, title: '', radius: 20)
      ];
    } else {
      int colorIdx = 0;
      categories.forEach((key, value) {
        pieSections.add(PieChartSectionData(
          color: pieColors[colorIdx % pieColors.length],
          value: value,
          title: '',
          radius: 20,
        ));
        colorIdx++;
      });
    }

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
                if (trendPercent != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: (isTrendPositive ? AppColors.negative : AppColors.positive).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isTrendPositive ? Icons.arrow_upward : Icons.arrow_downward, 
                          color: isTrendPositive ? AppColors.negative : AppColors.positive, 
                          size: 16
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${trendPercent.abs().toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isTrendPositive ? AppColors.negative : AppColors.positive,
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
                      sections: pieSections,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          statusTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: statusColor,
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
              statusMessage,
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
