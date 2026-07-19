import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/transactions_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';

class AddMoneyModal extends ConsumerStatefulWidget {
  const AddMoneyModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMoneyModal(),
    );
  }

  @override
  ConsumerState<AddMoneyModal> createState() => _AddMoneyModalState();
}

class _AddMoneyModalState extends ConsumerState<AddMoneyModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedSource = 'Salary';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _sources = [
    'Salary',
    'Freelance',
    'Business',
    'Gift',
    'Other'
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.positive,
              surface: AppColors.surfaceHighlight,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncome() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final note = _noteController.text.trim();

      // Add App Transaction (Recent Activity & Ledger)
      await ref.read(transactionsRepositoryProvider).addTransaction(
        type: 'Balance Added', // Unified type for balance additions
        title: note.isNotEmpty ? note : _selectedSource,
        amount: amount,
        category: _selectedSource,
        dateOverride: _selectedDate,
        metadata: {
          'source': _selectedSource,
          'note': note,
        }
      );

      // 3. Update User Profile Monthly Income
      final profileRepo = ref.read(userProfileRepositoryProvider);
      final profile = await profileRepo.getProfile();
      if (profile != null) {
        await profileRepo.updateProfile({
          'monthlyIncome': profile.monthlyIncome + amount,
        });
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Money',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppColors.surfaceHighlight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: AppColors.positive, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedSource,
                items: _sources.map((source) {
                  return DropdownMenuItem(
                    value: source,
                    child: Text(source),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSource = val);
                },
                decoration: InputDecoration(
                  labelText: 'Source',
                  filled: true,
                  fillColor: AppColors.surfaceHighlight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                dropdownColor: AppColors.surfaceHighlight,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  filled: true,
                  fillColor: AppColors.surfaceHighlight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),

              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    filled: true,
                    fillColor: AppColors.surfaceHighlight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.positive,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
