import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/investment.dart';
import '../../../../domain/entities/investment_transaction.dart';
import '../../../../data/repositories/transactions_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AddInvestmentModal extends ConsumerStatefulWidget {
  const AddInvestmentModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddInvestmentModal(),
    );
  }

  @override
  ConsumerState<AddInvestmentModal> createState() => _AddInvestmentModalState();
}

class _AddInvestmentModalState extends ConsumerState<AddInvestmentModal> {
  final _formKey = GlobalKey<FormState>();
  String _investmentType = 'Stock';
  String _platform = 'Groww';
  String _assetName = '';
  double _investedAmount = 0;
  double _quantity = 0;
  DateTime _purchaseDate = DateTime.now();
  String? _notes;

  final List<String> _types = [
    'Stock', 'Mutual Fund', 'ETF', 'Gold', 'Crypto', 'Fixed Deposit', 'Other'
  ];

  final List<String> _platforms = [
    'Groww', 'Zerodha', 'Upstox', 'Angel One', 'Coin', 'INDmoney', 'Other'
  ];

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  void _saveInvestment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (_quantity <= 0 || _investedAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount and Quantity must be greater than 0')),
        );
        return;
      }
      
      final purchasePricePerShare = _investedAmount / _quantity;
      final currentPrice = purchasePricePerShare; // Static ledger: no fake gains
      
      final investment = Investment(
        id: '', // Firestore will generate
        platform: _platform,
        investmentType: _investmentType,
        assetName: _assetName,
        symbol: _assetName.substring(0, _assetName.length > 4 ? 4 : _assetName.length).toUpperCase(),
        investedAmount: _investedAmount,
        quantity: _quantity,
        purchasePricePerShare: purchasePricePerShare,
        currentPrice: currentPrice,
        purchaseDate: _purchaseDate,
        notes: _notes,
        createdAt: DateTime.now(),
      );

      debugPrint('--- SAVING INVESTMENT ---');
      debugPrint('investedAmount: $_investedAmount');
      debugPrint('quantity: $_quantity');
      debugPrint('purchasePricePerShare: $purchasePricePerShare');
      debugPrint('currentPrice: $currentPrice');
      debugPrint('currentValue: ${investment.currentValue}');
      debugPrint('profitLoss: ${investment.profitLoss}');
      debugPrint('profitLossPercent: ${investment.profitLossPercent}%');
      
      // Auto-log to global transactions with metadata
      await ref.read(transactionsRepositoryProvider).addTransaction(
        type: 'Investment Purchase', // Use standard type
        title: _assetName,
        amount: _investedAmount,
        category: _platform,
        dateOverride: _purchaseDate,
        metadata: {
          'platform': _platform,
          'investmentType': _investmentType,
          'symbol': investment.symbol,
          'quantity': _quantity,
          'purchasePricePerShare': purchasePricePerShare,
          'currentPrice': currentPrice,
          'notes': _notes,
        },
      );

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
                'Add Investment',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _investmentType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      dropdownColor: AppColors.surfaceHighlight,
                      items: _types.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _investmentType = val!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _platform,
                      decoration: InputDecoration(
                        labelText: 'Platform',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      dropdownColor: AppColors.surfaceHighlight,
                      items: _platforms.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _platform = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Asset Name (e.g. Adani Energy)',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _assetName = val!,
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Invested Amount',
                        prefixText: '₹ ',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Invalid amount' : null,
                      onSaved: (val) => _investedAmount = double.parse(val!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Quantity/Units',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Invalid quantity' : null,
                      onSaved: (val) => _quantity = double.parse(val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Purchase Date',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  child: Text(DateFormat('MMM dd, yyyy').format(_purchaseDate)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Optional Notes',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 2,
                onSaved: (val) => _notes = val,
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveInvestment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentAI,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Investment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
