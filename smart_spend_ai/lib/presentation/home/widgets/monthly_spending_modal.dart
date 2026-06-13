import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../design_system/components/premium_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class MonthlySpendingModal extends ConsumerWidget {
  const MonthlySpendingModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MonthlySpendingModal(),
    );
  }

  static const Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant_outlined,
    'Transport': Icons.directions_car_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Entertainment': Icons.movie_outlined,
    'Bills': Icons.receipt_outlined,
    'Health': Icons.favorite_outline,
    'Education': Icons.school_outlined,
    'Travel': Icons.flight_outlined,
    'Other': Icons.more_horiz,
  };

  static const Map<String, Color> _categoryColors = {
    'Food': Color(0xFFFF8A65),
    'Transport': Color(0xFF4FC3F7),
    'Shopping': Color(0xFFBA68C8),
    'Entertainment': Color(0xFFFFD54F),
    'Bills': Color(0xFF81C784),
    'Health': Color(0xFFE57373),
    'Education': Color(0xFF64B5F6),
    'Travel': Color(0xFF4DB6AC),
    'Other': Color(0xFF90A4AE),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final now = DateTime.now();
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final monthName = DateFormat('MMMM yyyy').format(now);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return expensesAsync.when(
            data: (expenses) {
              // Filter to current month
              final monthlyExpenses = expenses
                  .where((e) => e.date.month == now.month && e.date.year == now.year)
                  .toList();

              final totalSpending = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);

              // Group by category
              final Map<String, double> categoryTotals = {};
              for (final e in monthlyExpenses) {
                categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
              }

              // Sort by amount descending
              final sortedCategories = categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Spending Breakdown',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      monthName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Total
                    PremiumCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      backgroundColor: AppColors.surfaceHighlight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Spending',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(totalSpending),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.negative,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.negative.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.trending_down, color: AppColors.negative, size: 28),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Category breakdown
                    Text(
                      'By Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Expanded(
                      child: sortedCategories.isEmpty
                          ? const Center(
                              child: Text(
                                'No spending recorded this month.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: sortedCategories.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final entry = sortedCategories[index];
                                final percentage = totalSpending > 0
                                    ? (entry.value / totalSpending * 100)
                                    : 0.0;
                                final color = _categoryColors[entry.key] ?? const Color(0xFF90A4AE);
                                final icon = _categoryIcons[entry.key] ?? Icons.more_horiz;

                                return PremiumCard(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  backgroundColor: AppColors.surfaceHighlight,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(icon, color: color, size: 22),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.key,
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: percentage / 100,
                                                backgroundColor: Colors.white10,
                                                valueColor: AlwaysStoppedAnimation(color),
                                                minHeight: 4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            currencyFormatter.format(entry.value),
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
      ),
    );
  }
}
