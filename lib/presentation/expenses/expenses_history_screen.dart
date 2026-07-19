import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../design_system/components/premium_card.dart';
import '../../domain/entities/expense.dart';
import '../../data/repositories/transactions_repository.dart';

class ExpensesHistoryScreen extends ConsumerStatefulWidget {
  const ExpensesHistoryScreen({super.key});

  @override
  ConsumerState<ExpensesHistoryScreen> createState() => _ExpensesHistoryScreenState();
}

class _ExpensesHistoryScreenState extends ConsumerState<ExpensesHistoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final List<String> _categories = [
    'All', 'Food', 'Transport', 'Shopping', 'Entertainment', 'Bills', 'Health', 'Education', 'Travel', 'Other'
  ];

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentAI,
              surface: AppColors.surfaceHighlight,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHighlight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense?', style: TextStyle(color: Colors.white)),
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
        await ref.read(transactionsRepositoryProvider).deleteTransaction(expense.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  void _showExpenseOptions(Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: const BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Expense Options',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.delete_outline, color: AppColors.negative),
                  title: const Text('Delete Expense', style: TextStyle(color: AppColors.negative, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteExpense(expense);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Expense History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Category Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surfaceHighlight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: AppColors.surfaceHighlight,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                      style: const TextStyle(color: Colors.white),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtered: ${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}',
                      style: const TextStyle(color: AppColors.accentAI),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            
          const SizedBox(height: AppSpacing.md),

          Expanded(
            child: expensesAsync.when(
              data: (allExpenses) {
                // Apply filters
                var filtered = allExpenses.where((e) {
                  final matchQuery = e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                     e.category.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchCategory = _selectedCategory == 'All' || e.category == _selectedCategory;
                  final matchDate = _startDate == null || _endDate == null || 
                                    (e.date.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
                                     e.date.isBefore(_endDate!.add(const Duration(days: 1))));
                  return matchQuery && matchCategory && matchDate;
                }).toList();

                // Guarantee sort order Newest First
                filtered.sort((a, b) => b.date.compareTo(a.date));

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching expenses found.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    
                    IconData icon;
                    switch (tx.category) {
                      case 'Food': icon = Icons.restaurant_outlined; break;
                      case 'Transport': icon = Icons.directions_car_outlined; break;
                      case 'Shopping': icon = Icons.shopping_bag_outlined; break;
                      case 'Entertainment': icon = Icons.movie_outlined; break;
                      default: icon = Icons.receipt_long_outlined;
                    }

                    final timeFormat = DateFormat('MMM d, yyyy').format(tx.date);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GestureDetector(
                        onTap: () => _showExpenseOptions(tx),
                        child: PremiumCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          backgroundColor: AppColors.surfaceHighlight,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.negative.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: AppColors.negative, size: 24),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description.isNotEmpty ? tx.description : tx.category,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tx.category,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeFormat,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-${currencyFormatter.format(tx.amount)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.negative,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
  }
}
