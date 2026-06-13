import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../statement_preview_screen.dart';

class GenerateStatementModal extends ConsumerStatefulWidget {
  const GenerateStatementModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GenerateStatementModal(),
    );
  }

  @override
  ConsumerState<GenerateStatementModal> createState() => _GenerateStatementModalState();
}

class _GenerateStatementModalState extends ConsumerState<GenerateStatementModal> {
  String _selectedPeriod = 'This Month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  void _generate() {
    DateTime start;
    DateTime end;
    final now = DateTime.now();

    if (_selectedPeriod == 'This Month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else if (_selectedPeriod == 'Last Month') {
      start = DateTime(now.year, now.month - 1, 1);
      end = DateTime(now.year, now.month, 0);
    } else {
      if (_customStartDate == null || _customEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date range.')));
        return;
      }
      start = _customStartDate!;
      end = _customEndDate!;
    }

    Navigator.pop(context); // Close modal
    
    // Navigate to preview screen, passing the date range
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StatementPreviewScreen(startDate: start, endDate: end),
    ));
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentAI,
              onPrimary: Colors.white,
              surface: AppColors.surfaceHighlight,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Custom Date Range';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Statement',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Select the statement period for your financial report.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          
          ListTile(
            title: const Text('This Month', style: TextStyle(color: Colors.white)),
            leading: Radio<String>(
              value: 'This Month',
              groupValue: _selectedPeriod,
              activeColor: AppColors.accentAI,
              onChanged: (val) => setState(() => _selectedPeriod = val!),
            ),
          ),
          ListTile(
            title: const Text('Last Month', style: TextStyle(color: Colors.white)),
            leading: Radio<String>(
              value: 'Last Month',
              groupValue: _selectedPeriod,
              activeColor: AppColors.accentAI,
              onChanged: (val) => setState(() => _selectedPeriod = val!),
            ),
          ),
          ListTile(
            title: Text(
              _customStartDate != null && _customEndDate != null && _selectedPeriod == 'Custom Date Range'
                  ? 'Custom: ${DateFormat('dd MMM yyyy').format(_customStartDate!)} - ${DateFormat('dd MMM yyyy').format(_customEndDate!)}'
                  : 'Custom Date Range',
              style: const TextStyle(color: Colors.white),
            ),
            leading: Radio<String>(
              value: 'Custom Date Range',
              groupValue: _selectedPeriod,
              activeColor: AppColors.accentAI,
              onChanged: (val) {
                setState(() => _selectedPeriod = val!);
                _pickDateRange();
              },
            ),
            trailing: IconButton(
              icon: const Icon(Icons.date_range, color: AppColors.accentAI),
              onPressed: _pickDateRange,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentAI,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Generate PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
