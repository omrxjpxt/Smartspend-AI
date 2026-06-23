import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/app_providers.dart';
import '../../design_system/components/premium_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ExpensesTrendChart extends ConsumerWidget {
  const ExpensesTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.valueOrNull ?? [];
    
    // Group transactions by day for the last 7 days
    final now = DateTime.now();
    final List<double> dailySpend = List.filled(7, 0.0);
    double maxSpend = 0.0;
    final today = DateTime(now.year, now.month, now.day);
    
    for (var tx in expenses) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final diff = today.difference(txDate).inDays;
      if (diff >= 0 && diff < 7) {
        // diff=0 is today, so map it to the end of the array
        final index = 6 - diff;
        dailySpend[index] += tx.amount;
        if (dailySpend[index] > maxSpend) {
          maxSpend = dailySpend[index];
        }
      }
    }
    
    // Ensure maxSpend is not zero to avoid division by zero in charts
    if (maxSpend == 0) maxSpend = 100;
    // Add some padding to the top of the chart
    maxSpend = maxSpend * 1.2;

    final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final currentDayIndex = now.weekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.md),
            child: Text(
              '7-Day Trend',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PremiumCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          // Map index to correct weekday character
                          // idx=6 is today
                          final dayOffset = 6 - idx;
                          final weekdayIdx = (currentDayIndex - dayOffset) % 7;
                          final normalizedIdx = weekdayIdx < 0 ? weekdayIdx + 7 : weekdayIdx;
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              daysOfWeek[normalizedIdx],
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  maxY: maxSpend,
                  barGroups: List.generate(7, (i) {
                    return _buildBarData(i, dailySpend[i], maxSpend, isHighlight: i == 6);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarData(int x, double y, double maxSpend, {bool isHighlight = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isHighlight ? AppColors.accentAI : AppColors.surfaceHighlight,
          width: 24,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxSpend,
            color: AppColors.background,
          ),
        ),
      ],
    );
  }
}
