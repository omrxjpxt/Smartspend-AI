import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/goal.dart';
import '../../../data/repositories/transactions_repository.dart';
import '../../providers/app_providers.dart';
import 'add_contribution_modal.dart';

class GoalDetailsModal extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalDetailsModal({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailsModal> createState() => _GoalDetailsModalState();
}

class _GoalDetailsModalState extends ConsumerState<GoalDetailsModal> {

  Future<void> _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHighlight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Goal?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone. All contributions will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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

    if (confirm != true) return;

    try {
      // Deletes goal doc + all contribution transactions → balance auto-restores
      await ref.read(transactionsRepositoryProvider).deleteGoalAndContributions(widget.goal.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete. Please try again.')),
        );
      }
    }
  }

  void _showAddContribution() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddContributionModal(goal: widget.goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormatter = DateFormat('MMM d, yyyy');

    final contributionsAsync = ref.watch(goalContributionsProvider(widget.goal.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(widget.goal.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            widget.goal.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: _deleteGoal,
                          icon: const Icon(Icons.delete_outline, color: AppColors.negative),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Minimal Analytics Box
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Saved', currencyFormatter.format(widget.goal.currentAmount)),
                          const Divider(color: AppColors.border, height: 24),
                          _buildDetailRow('Remaining', currencyFormatter.format(widget.goal.remainingAmount)),
                          const Divider(color: AppColors.border, height: 24),
                          _buildDetailRow('Target', currencyFormatter.format(widget.goal.targetAmount)),
                          const Divider(color: AppColors.border, height: 24),
                          _buildDetailRow('Progress', widget.goal.completionPercentage, isAccent: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddContribution,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Contribution', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentAI,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // History List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    Text(
                      'Contribution History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    contributionsAsync.when(
                      data: (contributions) {
                        if (contributions.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                const Icon(Icons.savings_outlined, size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: AppSpacing.md),
                                const Text(
                                  'No contributions yet',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Start building your goal by adding your first contribution.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                OutlinedButton.icon(
                                  onPressed: _showAddContribution,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Contribution'),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentAI),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: contributions.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHighlight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFormatter.format(c.date),
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  ),
                                  Text(
                                    '+${currencyFormatter.format(c.amount)}',
                                    style: const TextStyle(color: AppColors.positive, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.negative))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAccent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(
          value, 
          style: TextStyle(
            color: isAccent ? AppColors.accentAI : Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
