import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../design_system/components/premium_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class _CategoryBudget {
  final String category;
  final double spentAmount;
  final double allocatedAmount;

  _CategoryBudget(this.category, this.spentAmount, this.allocatedAmount);

  double get utilization => allocatedAmount > 0 ? (spentAmount / allocatedAmount).clamp(0.0, 1.0) : 0.0;
}

class CategoryBreakdown extends ConsumerWidget {
  const CategoryBreakdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final userProfile = ref.watch(userProfileProvider);
    final expenses = expensesAsync.valueOrNull ?? [];
    
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final Map<String, double> categoryTotals = {};
    final now = DateTime.now();
    for (var e in expenses) {
      if (e.date.month == now.month && e.date.year == now.year) {
        categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
      }
    }

    final monthlyIncome = userProfile.valueOrNull?.monthlyIncome ?? 100000;
    // Arbitrary default budgets based on income
    final Map<String, double> categoryBudgetsMap = {
      'Housing': monthlyIncome * 0.30,
      'Food': monthlyIncome * 0.20,
      'Transport': monthlyIncome * 0.10,
      'Entertainment': monthlyIncome * 0.10,
      'Shopping': monthlyIncome * 0.10,
      'Bills': monthlyIncome * 0.10,
    };

    final List<_CategoryBudget> budgets = categoryTotals.entries.map((e) {
      final allocated = categoryBudgetsMap[e.key] ?? 10000.0;
      return _CategoryBudget(e.key, e.value, allocated);
    }).toList();

    // Sort by spent amount
    budgets.sort((a, b) => b.spentAmount.compareTo(a.spentAmount));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.lg),
            child: Text(
              'Budget Utilization',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PremiumCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: budgets.isEmpty 
              ? const Center(
                  child: Text('Add expenses to see breakdown', style: TextStyle(color: AppColors.textSecondary)),
                )
              : Column(
              children: budgets.map((budget) {
                IconData icon;
                switch (budget.category) {
                  case 'Housing': icon = Icons.home_outlined; break;
                  case 'Food': icon = Icons.restaurant_outlined; break;
                  case 'Transport': icon = Icons.directions_car_outlined; break;
                  case 'Entertainment': icon = Icons.movie_outlined; break;
                  case 'Shopping': icon = Icons.shopping_bag_outlined; break;
                  case 'Bills': icon = Icons.receipt_outlined; break;
                  default: icon = Icons.category_outlined;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: _buildCategoryRow(
                    context, 
                    budget.category, 
                    currencyFormatter.format(budget.spentAmount), 
                    currencyFormatter.format(budget.allocatedAmount), 
                    budget.utilization, 
                    icon
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, String name, String spent, String budget, double percentage, IconData icon) {
    final bool isOverBudget = percentage >= 0.95;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: const BoxDecoration(
            color: AppColors.surfaceHighlight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$spent / $budget',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOverBudget ? AppColors.warning : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppColors.surfaceHighlight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? AppColors.warning : AppColors.accentAI,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

