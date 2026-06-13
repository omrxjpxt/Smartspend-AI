import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class FinancialSnapshotCard extends ConsumerWidget {
  const FinancialSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final availableBalance = ref.watch(availableBalanceProvider);

    final now = DateTime.now();
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final profile = userProfileAsync.valueOrNull;
    final monthlyIncome = profile?.monthlyIncome ?? 0.0;

    final expenses = expensesAsync.valueOrNull ?? [];
    final totalExpenses = expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);

    final netCashFlow = monthlyIncome - totalExpenses;
    final savingsThisMonth = netCashFlow > 0 ? netCashFlow : 0.0;

    final goals = goalsAsync.valueOrNull ?? [];
    final activeGoalsCount = goals.where((g) => g.currentAmount < g.targetAmount).length;

    // Build real insights
    List<Widget> insightWidgets = [];
    
    if (savingsThisMonth > 0) {
      insightWidgets.add(_buildInsightRow(
        context, 
        Icons.check_circle_outline, 
        AppColors.positive, 
        "Saved ${currencyFormatter.format(savingsThisMonth)} this month"
      ));
    } else if (totalExpenses > monthlyIncome && monthlyIncome > 0) {
      insightWidgets.add(_buildInsightRow(
        context, 
        Icons.warning_amber_rounded, 
        AppColors.negative, 
        "Expenses exceeded income by ${currencyFormatter.format(totalExpenses - monthlyIncome)}"
      ));
    }

    if (monthlyIncome > 0 && totalExpenses > 0) {
      final expensePercent = ((totalExpenses / monthlyIncome) * 100).toInt();
      insightWidgets.add(_buildInsightRow(
        context, 
        Icons.pie_chart_outline, 
        AppColors.accentAI, 
        "Expenses are $expensePercent% of monthly income"
      ));
    }

    if (activeGoalsCount > 0) {
      insightWidgets.add(_buildInsightRow(
        context, 
        Icons.flag_outlined, 
        Colors.blue, 
        "$activeGoalsCount active savings ${activeGoalsCount == 1 ? 'goal' : 'goals'}"
      ));
    }

    if (insightWidgets.isEmpty) {
      insightWidgets.add(_buildInsightRow(
        context,
        Icons.info_outline,
        AppColors.textSecondary,
        "Start adding expenses and income to see insights."
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight, // Dark glassmorphism
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accentAI.withValues(alpha: 0.4), // Purple accent glow
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceHighlight.withValues(alpha: 0.9),
              AppColors.surface.withValues(alpha: 0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentAI.withValues(alpha: 0.1), // Premium shadow
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION TITLE
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentAI.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: AppColors.accentAI, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Your money at a glance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accentAI.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xxl),

            // MAIN METRIC
            Center(
              child: Column(
                children: [
                  Text(
                    'Available Balance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    currencyFormatter.format(availableBalance),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxl),

            // METRICS GRID
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _buildSecondaryMetric(context, 'Income', currencyFormatter.format(monthlyIncome))),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Expanded(child: _buildSecondaryMetric(context, 'Expenses', currencyFormatter.format(totalExpenses))),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Divider(color: AppColors.border, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _buildSecondaryMetric(context, 'Savings', currencyFormatter.format(savingsThisMonth))),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Expanded(child: _buildSecondaryMetric(context, 'Active Goals', '$activeGoalsCount')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
            
            // INSIGHTS SECTION
            Text(
              'Insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...insightWidgets,
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryMetric(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInsightRow(BuildContext context, IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
