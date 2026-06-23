import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../design_system/components/premium_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/transactions_repository.dart';
import 'transaction_details_modal.dart';

class RecentActivityList extends ConsumerWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              backgroundColor: AppColors.surfaceHighlight,
              child: Center(
                child: Text(
                  'No recent activity.\nStart adding expenses or goals!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        // Sort transactions manually to guarantee newest first
        final sortedTransactions = List.of(transactions)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Show only top 5 transactions for "Recent Activity" widget
        final recentTransactions = sortedTransactions.take(5).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              ...recentTransactions.map((tx) {
                IconData icon;
                Color color;
                String prefix = '';
                String displaySubtitle = tx.category ?? tx.type;

                // Expense, Income, Balance Added, Investment, Goal Contribution
                switch (tx.type) {
                  case 'Expense':
                    icon = Icons.receipt_long;
                    color = AppColors.negative;
                    prefix = '-';
                    break;
                  case 'Income':
                  case 'Received':
                    icon = Icons.arrow_downward;
                    color = AppColors.positive;
                    prefix = '+';
                    displaySubtitle = tx.category ?? 'Received';
                    break;
                  case 'Balance Added':
                    icon = Icons.account_balance_wallet;
                    color = AppColors.positive;
                    prefix = '+';
                    break;
                  case 'Investment Purchase':
                  case 'Investment':
                    icon = Icons.trending_up;
                    color = AppColors.negative;
                    prefix = '-';
                    break;
                  case 'Investment Sale':
                    icon = Icons.trending_down;
                    color = AppColors.positive;
                    prefix = '+';
                    break;
                  case 'Goal Contribution':
                    icon = Icons.flag;
                    color = Colors.blue;
                    prefix = '-';
                    break;
                  default:
                    icon = Icons.history;
                    color = AppColors.textSecondary;
                }

                final timeFormat = DateFormat('MMM d, yyyy • h:mm a').format(tx.createdAt);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => TransactionDetailsModal(transaction: tx),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      backgroundColor: AppColors.surfaceHighlight,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displaySubtitle,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeFormat,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$prefix${currencyFormatter.format(tx.amount)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading transactions: $e')),
    );
  }
}
