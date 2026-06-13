import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../../../data/repositories/transactions_repository.dart';
import '../../../services/monthly_pdf_service.dart';

class StatementPreviewScreen extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;

  const StatementPreviewScreen({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final investmentsAsync = ref.watch(investmentsProvider);
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statement Preview'),
        backgroundColor: AppColors.surfaceHighlight,
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          
          if (transactionsAsync.isLoading || investmentsAsync.isLoading || goalsAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTransactions = transactionsAsync.valueOrNull ?? [];
          final transactions = allTransactions.where((t) => 
            t.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) && 
            t.createdAt.isBefore(endDate.add(const Duration(days: 1)))
          ).toList();
          
          final investments = investmentsAsync.valueOrNull ?? [];
          final goals = goalsAsync.valueOrNull ?? [];

          return PdfPreview(
            build: (format) => MonthlyPdfService().generateStatementBytes(
              userName: profile.name,
              userEmail: profile.email,
              transactions: transactions,
              investments: investments,
              goals: goals,
              monthDate: startDate,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
