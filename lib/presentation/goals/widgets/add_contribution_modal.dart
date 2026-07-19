import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/goal.dart';
import '../../../data/repositories/transactions_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AddContributionModal extends ConsumerStatefulWidget {
  final Goal goal;

  const AddContributionModal({super.key, required this.goal});

  @override
  ConsumerState<AddContributionModal> createState() => _AddContributionModalState();
}

class _AddContributionModalState extends ConsumerState<AddContributionModal> {
  final _formKey = GlobalKey<FormState>();
  double _contributionAmount = 0;
  bool _isSaving = false;

  Future<void> _addContribution() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isSaving = true);

      try {
        // ONE ledger write is all that's needed.
        // goalContributionsProvider & goalsProvider both derive from allTransactionsProvider.
        await ref.read(transactionsRepositoryProvider).addTransaction(
          type: 'Goal Contribution',
          title: 'Contribution to ${widget.goal.title}',
          amount: _contributionAmount,
          category: 'Goals',
          referenceId: widget.goal.id,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contribution added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add contribution')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Contribution',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Add money to ${widget.goal.title}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Contribution Amount
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Contribution Amount (₹)',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                autofocus: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Invalid amount';
                  return null;
                },
                onSaved: (val) => _contributionAmount = double.parse(val!),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _addContribution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentAI,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Add Contribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
