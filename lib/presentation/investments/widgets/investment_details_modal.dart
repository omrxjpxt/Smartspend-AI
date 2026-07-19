import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/investment.dart';
import '../../../data/repositories/transactions_repository.dart';

class InvestmentDetailsModal extends ConsumerStatefulWidget {
  final Investment investment;

  const InvestmentDetailsModal({super.key, required this.investment});

  @override
  ConsumerState<InvestmentDetailsModal> createState() =>
      _InvestmentDetailsModalState();
}

class _InvestmentDetailsModalState
    extends ConsumerState<InvestmentDetailsModal> {
  bool _isDeleting = false;

  Future<void> _deleteInvestment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHighlight,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Investment?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await ref
          .read(transactionsRepositoryProvider)
          .deleteTransaction(widget.investment.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to delete. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.investment;
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormatter = DateFormat('MMM d, yyyy');

    final quantity = inv.quantity;
    final quantityStr = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Asset name + type badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentAI.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  inv.investmentType,
                  style: const TextStyle(
                    color: AppColors.accentAI,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            inv.assetName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Detail rows
          _DetailRow(label: 'Invested Amount',
              value: currencyFormatter.format(inv.investedAmount)),
          _DetailRow(label: 'Quantity', value: '$quantityStr units'),
          _DetailRow(label: 'Platform', value: inv.platform),
          _DetailRow(label: 'Date Added',
              value: dateFormatter.format(inv.purchaseDate)),

          if (inv.notes != null && inv.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(label: 'Notes', value: inv.notes!),
          ],

          const SizedBox(height: AppSpacing.xxl),

          if (_isDeleting)
            const Center(child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.negative,
            ))
          else ...[
            // Buy / Sell Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showTransactionModal(context, 'BUY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.positive,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    child: const Text('Buy More',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showTransactionModal(context, 'SELL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentAI,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    child: const Text('Sell Units',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _deleteInvestment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.negative.withValues(alpha: 0.1),
                  foregroundColor: AppColors.negative,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: const Text(
                  'Delete Investment',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Close button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTransactionModal(BuildContext context, String action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InvestmentTransactionSheet(
        investment: widget.investment,
        action: action,
        onSuccess: () {
          Navigator.pop(ctx);
          Navigator.pop(context); // close details modal as well
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable detail row
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction Sheet for Buy / Sell
// ---------------------------------------------------------------------------

class _InvestmentTransactionSheet extends ConsumerStatefulWidget {
  final Investment investment;
  final String action; // 'BUY' or 'SELL'
  final VoidCallback onSuccess;

  const _InvestmentTransactionSheet({
    required this.investment,
    required this.action,
    required this.onSuccess,
  });

  @override
  ConsumerState<_InvestmentTransactionSheet> createState() => _InvestmentTransactionSheetState();
}

class _InvestmentTransactionSheetState extends ConsumerState<_InvestmentTransactionSheet> {
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _submitTransaction() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;

    if (amount <= 0 || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount and quantity')),
      );
      return;
    }

    if (widget.action == 'SELL' && quantity > widget.investment.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot sell more units than you own')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isBuy = widget.action == 'BUY';
      
      // Auto-log to global transactions with metadata
      await ref.read(transactionsRepositoryProvider).addTransaction(
        type: isBuy ? 'Investment Purchase' : 'Investment Sale',
        title: widget.investment.assetName,
        amount: amount,
        category: widget.investment.platform,
        dateOverride: _selectedDate,
        referenceId: widget.investment.id,
        metadata: {
          'platform': widget.investment.platform,
          'investmentType': widget.investment.investmentType,
          'symbol': widget.investment.symbol,
          'quantity': quantity,
          'purchasePricePerShare': amount / quantity,
          'currentPrice': widget.investment.currentPrice,
        },
      );
      
      if (mounted) {
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isBuy ? 'Bought' : 'Sold'} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.action == 'BUY';
    final title = isBuy ? 'Buy More' : 'Sell Units';
    final color = isBuy ? AppColors.positive : AppColors.accentAI;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${widget.investment.assetName} • ${widget.investment.platform}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Quantity Input
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Quantity',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Amount (₹)',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date Selector (simple for now)
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (d != null && mounted) {
                setState(() => _selectedDate = d);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.accentAI))
          else
            ElevatedButton(
              onPressed: _submitTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              child: const Text('Confirm',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
