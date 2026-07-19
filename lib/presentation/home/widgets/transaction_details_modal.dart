import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/app_transaction.dart';
import '../../../data/repositories/transactions_repository.dart';

class TransactionDetailsModal extends ConsumerWidget {
  final AppTransaction transaction;

  const TransactionDetailsModal({super.key, required this.transaction});

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHighlight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Transaction?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(transactionsRepositoryProvider).deleteTransaction(transaction.id);
        if (context.mounted) {
          Navigator.pop(context); // Close the modal on success
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted successfully.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      case 'Investment Purchase':
        icon = Icons.trending_up;
        color = AppColors.accentAI;
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
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.negative),
                onPressed: () => _deleteTransaction(context, ref),
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

