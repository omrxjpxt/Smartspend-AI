import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/goal.dart';
import '../../../../data/repositories/goals_repository.dart';
import '../../../../data/repositories/transactions_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class CreateGoalModal extends ConsumerStatefulWidget {
  const CreateGoalModal({super.key});

  @override
  ConsumerState<CreateGoalModal> createState() => _CreateGoalModalState();
}

class _CreateGoalModalState extends ConsumerState<CreateGoalModal> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double _targetAmount = 0;
  double _initialContribution = 0; // Stored as a ledger entry, NOT on the goal doc
  String _category = 'Gadget';

  final List<String> _categories = [
    'Gadget', 'Vehicle', 'Travel', 'Education', 'House', 'Emergency Fund', 'Investment', 'Other'
  ];

  String _getEmojiForCategory(String category) {
    switch (category) {
      case 'Gadget': return '💻';
      case 'Vehicle': return '🚗';
      case 'Travel': return '✈️';
      case 'Education': return '🎓';
      case 'House': return '🏠';
      case 'Emergency Fund': return '🛡️';
      case 'Investment': return '📈';
      default: return '🎯';
    }
  }

  void _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Goal document stores only immutable metadata — no financial values
      final goal = Goal(
        id: '',
        title: _name,
        emoji: _getEmojiForCategory(_category),
        currentAmount: 0, // Never stored in Firestore; computed from ledger
        targetAmount: _targetAmount,
      );

      // 1. Create the goal metadata document
      // We need the Firestore-generated ID, so we intercept via the repo
      final docRef = await ref.read(goalsRepositoryProvider).createGoalAndGetId(goal);

      // 2. If there's an initial amount, record it as a ledger contribution
      if (_initialContribution > 0) {
        await ref.read(transactionsRepositoryProvider).addTransaction(
          type: 'Goal Contribution',
          title: 'Initial contribution to $_name',
          amount: _initialContribution,
          category: 'Goals',
          referenceId: docRef, // Link to the goal ID
        );
      }

      if (mounted) Navigator.pop(context);
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
                'Create New Goal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppColors.surfaceHighlight,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: AppSpacing.md),

              // Goal Name
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: AppSpacing.md),

              // Target Amount
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                onSaved: (val) => _targetAmount = double.parse(val!),
              ),
              const SizedBox(height: AppSpacing.md),

              // Initial Saved Amount → recorded in ledger, not stored on goal doc
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Already Saved (Optional)',
                  prefixText: '₹ ',
                  helperText: 'Will be recorded as an opening contribution',
                  helperStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                initialValue: '0',
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                onSaved: (val) => _initialContribution = double.parse(val!),
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentAI,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
