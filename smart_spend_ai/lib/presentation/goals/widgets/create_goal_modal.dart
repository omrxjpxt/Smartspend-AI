import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/goal.dart';
import '../../../../data/repositories/goals_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/repositories/transactions_repository.dart';

class CreateGoalModal extends ConsumerStatefulWidget {
  const CreateGoalModal({super.key});

  @override
  ConsumerState<CreateGoalModal> createState() => _CreateGoalModalState();
}

class _CreateGoalModalState extends ConsumerState<CreateGoalModal> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double _targetAmount = 0;
  double _currentAmount = 0;
  double _monthlyContribution = 0;
  final DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
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
      
      final goal = Goal(
        id: '', // Firestore will generate ID
        title: _name,
        emoji: _getEmojiForCategory(_category),
        currentAmount: _currentAmount,
        targetAmount: _targetAmount,
        monthlyContribution: _monthlyContribution,
        estimatedCompletion: _targetDate,
      );

      await ref.read(goalsRepositoryProvider).createGoal(goal);
      if (_currentAmount > 0) {
        await ref.read(transactionsRepositoryProvider).addTransaction(
          type: 'Goal Contribution',
          title: _name,
          amount: _currentAmount,
          category: _category,
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
                ),
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
                ),
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
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                onSaved: (val) => _targetAmount = double.parse(val!),
              ),
              const SizedBox(height: AppSpacing.md),

              // Current Saved Amount
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Current Saved Amount',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
                initialValue: '0',
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                onSaved: (val) => _currentAmount = double.parse(val!),
              ),
              const SizedBox(height: AppSpacing.md),

              // Monthly Contribution
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Monthly Contribution',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                onSaved: (val) => _monthlyContribution = double.parse(val!),
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
