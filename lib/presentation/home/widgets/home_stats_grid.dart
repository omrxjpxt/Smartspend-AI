import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../design_system/components/premium_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'available_balance_modal.dart';
import 'monthly_spending_modal.dart';

class HomeStatsGrid extends ConsumerWidget {
  const HomeStatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableBalance = ref.watch(availableBalanceProvider);
    final expensesAsync = ref.watch(expensesProvider);

    final expenses = expensesAsync.valueOrNull ?? [];
    final now = DateTime.now();

    final currentMonthExpenses = expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    String formatCompact(double val) {
      if (val.abs() >= 100000) return '₹${(val / 100000).toStringAsFixed(1)}L';
      if (val.abs() >= 1000) return '₹${(val / 1000).toStringAsFixed(1)}k';
      return currencyFormatter.format(val);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AvailableBalanceModal(),
                );
              },
              child: _buildStatCard(
                context,
                'Available Balance',
                formatCompact(availableBalance),
                Icons.account_balance_wallet_outlined,
                AppColors.positive,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: () => MonthlySpendingModal.show(context),
              child: _buildStatCard(
                context,
                'Monthly Spend',
                formatCompact(currentMonthExpenses),
                Icons.receipt_long_outlined,
                AppColors.negative,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color accentColor) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
