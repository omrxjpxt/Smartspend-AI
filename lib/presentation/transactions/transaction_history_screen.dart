import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../design_system/components/premium_card.dart';
import '../../services/monthly_pdf_service.dart';
import '../../domain/entities/app_transaction.dart';
import '../../services/ai_service.dart';
import '../../services/financial_context_builder.dart';
import '../../core/constants/ai_prompts.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  late DateTime _selectedMonth;
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Future<void> _generatePdf(WidgetRef ref, List<AppTransaction> transactions) async {
    if (transactions.isEmpty) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final userProfile = await ref.read(userProfileRepositoryProvider).getProfile();
      final userName = userProfile?.name ?? 'User';
      final userEmail = userProfile?.email ?? '';

      final goals = await ref.read(goalsProvider.future);
      final investments = await ref.read(investmentsProvider.future);

      final contextData = ref.read(financialContextProvider);
      final aiService = ref.read(aiServiceProvider);
      
      final aiSummary = await aiService.generateInsight(
        systemPrompt: AiPrompts.systemPrompt,
        context: contextData,
        userPrompt: '''Generate a financial insights report strictly formatted with the following exact headers:
- Key Achievements
- Spending Analysis
- Savings Analysis
- Investment Analysis
- Recommendations
Under each header, provide exactly 2-3 concise bullet points analyzing my financial performance. Do not output any introductory or concluding text. Do not bold or use asterisks around the headers.''',
        ref: ref,
        bypassRateLimit: true,
      );

      final service = MonthlyPdfService();
      await service.generateAndSaveMonthlyStatement(
        transactions: transactions,
        goals: goals,
        investments: investments,
        monthDate: _selectedMonth,
        userName: userName,
        userEmail: userEmail,
        aiSummary: aiSummary,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statement downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthKey = TransactionsRepository.generateMonthKey(_selectedMonth);
    
    // We use stream directly here so we can filter by month
    final transactionsStream = ref.watch(transactionsRepositoryProvider).watchTransactionsByMonth(monthKey);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Transaction History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          StreamBuilder(
            stream: transactionsStream,
            builder: (context, snapshot) {
              final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
              return IconButton(
                icon: _isGeneratingPdf 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.accentAI, strokeWidth: 2))
                    : Icon(Icons.picture_as_pdf, color: hasData ? AppColors.accentAI : AppColors.textSecondary),
                onPressed: hasData && !_isGeneratingPdf ? () => _generatePdf(ref, snapshot.data!) : null,
                tooltip: 'Download PDF',
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder(
              stream: transactionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  final e = snapshot.error.toString();
                  if (e.contains('failed-precondition') || e.contains('requires an index')) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sync, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Transaction data is being prepared.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This may take a few minutes. Please check back soon.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(
                    child: Text(
                      'Could not load transactions.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 64, color: AppColors.surfaceHighlight),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No transactions found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    
                    IconData icon;
                    Color color;

                    switch (tx.type) {
                      case 'Expense':
                        icon = Icons.receipt_long;
                        color = AppColors.negative;
                        break;
                      case 'Income':
                        icon = Icons.arrow_downward;
                        color = AppColors.positive;
                        break;
                      case 'Balance Added':
                        icon = Icons.account_balance_wallet;
                        color = AppColors.positive;
                        break;
                      case 'Investment':
                        icon = Icons.trending_up;
                        color = AppColors.accentAI;
                        break;
                      case 'Goal Contribution':
                        icon = Icons.flag;
                        color = Colors.blue;
                        break;
                      default:
                        icon = Icons.history;
                        color = AppColors.textSecondary;
                    }

                    final timeFormat = DateFormat('d MMM yyyy • h:mm a').format(tx.createdAt);
                    final subtitle = tx.category ?? tx.type;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: PremiumCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        backgroundColor: AppColors.surfaceHighlight,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
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
                              currencyFormatter.format(tx.amount),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
