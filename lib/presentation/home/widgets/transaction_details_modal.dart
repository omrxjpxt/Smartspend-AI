import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/app_transaction.dart';

class TransactionDetailsModal extends StatelessWidget {
  final AppTransaction transaction;

  const TransactionDetailsModal({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    Color color;
    IconData icon;
    String prefix = '';
    String displayType = transaction.type;

    switch (transaction.type) {
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
        displayType = 'Received';
        break;
      case 'Balance Added':
        icon = Icons.account_balance_wallet;
        color = AppColors.positive;
        prefix = '+';
        break;
      case 'Investment':
        icon = Icons.trending_up;
        color = AppColors.accentAI;
        prefix = '-';
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

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  transaction.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildDetailRow('Category', transaction.category ?? 'Uncategorized'),
          _buildDetailRow('Type', displayType),
          _buildDetailRow('Amount', '$prefix${currencyFormatter.format(transaction.amount)}', valueColor: color),
          _buildDetailRow('Date', dateFormatter.format(transaction.createdAt)),
          _buildDetailRow('Time', timeFormatter.format(transaction.createdAt)),
          if (transaction.referenceId != null) 
            _buildDetailRow('Source ID', transaction.referenceId!),
          
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentAI,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
