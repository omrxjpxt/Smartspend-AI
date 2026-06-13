import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../design_system/components/premium_card.dart';
import '../../../domain/entities/balance_transaction.dart';
import '../../../data/repositories/balance_repository.dart';
import '../../../data/repositories/transactions_repository.dart';

class AvailableBalanceModal extends ConsumerStatefulWidget {
  const AvailableBalanceModal({super.key});

  @override
  ConsumerState<AvailableBalanceModal> createState() => _AvailableBalanceModalState();
}

class _AvailableBalanceModalState extends ConsumerState<AvailableBalanceModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedAction = 'add'; // 'add', 'remove', 'edit'
  String _selectedSource = 'Salary';
  final List<String> _sources = ['Salary', 'Freelance', 'Pocket Money', 'Gift', 'Investment Return', 'Other'];

  final _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  bool _isSubmitting = false;

  Future<void> _submitTransaction() async {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final balanceRepo = ref.read(balanceRepositoryProvider);
      final transactionsRepo = ref.read(transactionsRepositoryProvider);
      final currentBalance = ref.read(availableBalanceProvider);

      double finalAmount = amount;
      String finalType = _selectedAction;
      
      if (_selectedAction == 'edit') {
        if (amount > currentBalance) {
          finalAmount = amount - currentBalance;
          finalType = 'adjustment';
        } else if (amount < currentBalance) {
          finalAmount = currentBalance - amount;
          finalType = 'adjustment_remove'; // internally mapping to negative 
        } else {
          // No change
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      // If it's removal or negative adjustment, ensure we track it properly (we can just store amount as positive and handle the 'type' in computation, or store as negative? The computation in app_providers checks type == 'add' || 'adjustment', else subtracts)
      final typeForDb = (finalType == 'adjustment_remove' || finalType == 'remove') ? 'remove' : 'add';

      final transaction = BalanceTransaction(
        id: const Uuid().v4(),
        amount: finalAmount,
        source: _selectedSource,
        type: typeForDb,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        timestamp: DateTime.now(),
      );

      await balanceRepo.addBalanceTransaction(transaction);

      // Log Activity to unified transactions
      await transactionsRepo.addTransaction(
        type: 'Balance Added',
        title: typeForDb == 'add' ? 'Added from $_selectedSource' : 'Removed from Balance',
        amount: finalAmount,
        category: _selectedSource,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(balanceTransactionsProvider);
    final availableBalance = ref.watch(availableBalanceProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
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
                  'Manage Balance',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Current Balance: ${_currencyFormatter.format(availableBalance)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.accentAI,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // Action Selector
                Row(
                  children: [
                    Expanded(child: _buildActionButton('Add', 'add')),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _buildActionButton('Remove', 'remove')),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _buildActionButton('Edit', 'edit')),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Form Fields
                PremiumCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      labelText: _selectedAction == 'edit' ? 'New Balance' : 'Amount',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_selectedAction != 'edit') ...[
                  PremiumCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSource,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceHighlight,
                        items: _sources.map((source) {
                          return DropdownMenuItem(
                            value: source,
                            child: Text(source),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSource = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                PremiumCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Note (Optional)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentAI,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _selectedAction == 'add' ? 'Add Money' : 
                            _selectedAction == 'remove' ? 'Remove Money' : 'Update Balance',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: transactionsAsync.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return const Center(
                          child: Text(
                            'No balance transactions yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isPositive = tx.type == 'add' || tx.type == 'adjustment';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isPositive ? AppColors.positive.withValues(alpha: 0.2) : AppColors.negative.withValues(alpha: 0.2),
                              child: Icon(
                                isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isPositive ? AppColors.positive : AppColors.negative,
                              ),
                            ),
                            title: Text(tx.source),
                            subtitle: Text(DateFormat('MMM d, yyyy').format(tx.timestamp)),
                            trailing: Text(
                              '${isPositive ? '+' : '-'} ${_currencyFormatter.format(tx.amount)}',
                              style: TextStyle(
                                color: isPositive ? AppColors.positive : AppColors.negative,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(String label, String action) {
    final isSelected = _selectedAction == action;
    return GestureDetector(
      onTap: () => setState(() => _selectedAction = action),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentAI : AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentAI : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
