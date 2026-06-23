import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/app_providers.dart';

class PerformanceChart extends ConsumerWidget {
  const PerformanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(investmentTransactionsProvider);
    final transactions = transactionsAsync.valueOrNull ?? [];

    List<FlSpot> spots = [];
    if (transactions.isNotEmpty) {
      final sorted = List.of(transactions)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      double cumulativeAmount = 0.0;
      final start = sorted.first.timestamp;
      
      for (var tx in sorted) {
        final days = tx.timestamp.difference(start).inDays.toDouble();
        if (tx.action == 'BUY') {
          cumulativeAmount += tx.amount;
        } else if (tx.action == 'SELL') {
          cumulativeAmount -= tx.amount; // Basic tracking of remaining invested amount over time
        }
        
        spots.add(FlSpot(days, cumulativeAmount));
      }
      
      if (spots.length == 1) {
        final todayDays = DateTime.now().difference(start).inDays.toDouble();
        if (todayDays > 0) {
          spots.add(FlSpot(todayDays, cumulativeAmount));
        } else {
          spots.add(FlSpot(1, cumulativeAmount));
        }
      }
    } else {
      spots = const [
        FlSpot(0, 0),
        FlSpot(1, 0),
      ];
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.positive,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.positive.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeFilter(context, '1D', false),
              _buildTimeFilter(context, '1W', false),
              _buildTimeFilter(context, '1M', false),
              _buildTimeFilter(context, '1Y', false),
              _buildTimeFilter(context, 'ALL', true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFilter(BuildContext context, String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceHighlight : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
