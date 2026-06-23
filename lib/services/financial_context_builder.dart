import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/app_providers.dart';
import '../data/repositories/transactions_repository.dart';
import '../core/utils/currency_formatter.dart';

final financialContextProvider = Provider<String>((ref) {
  final userProfile = ref.watch(userProfileProvider).valueOrNull;
  final availableBalance = ref.watch(availableBalanceProvider);
  final expenses = ref.watch(expensesProvider).valueOrNull ?? [];
  final goals = ref.watch(goalsProvider).valueOrNull ?? [];
  final investments = ref.watch(investmentsProvider).valueOrNull ?? [];
  final transactions = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  
  final now = DateTime.now();
  final currentMonthReceived = ref.watch(currentMonthReceivedProvider);
  
  final monthlyExpenses = expenses
      .where((e) => e.date.month == now.month && e.date.year == now.year)
      .fold(0.0, (sum, e) => sum + e.amount);
      
  final monthlySavings = (currentMonthReceived - monthlyExpenses).clamp(0.0, double.infinity);
  
  final activeGoals = goals.where((g) => g.currentAmount < g.targetAmount).map((g) => {
    "name": g.title,
    "saved": CurrencyFormatter.format(g.currentAmount),
    "target": CurrencyFormatter.format(g.targetAmount),
  }).toList();
  
  final investmentsList = investments.map((i) => {
    "platform": i.platform,
    "asset": i.assetName,
    "amount": CurrencyFormatter.format(i.investedAmount),
    "type": i.investmentType,
  }).toList();
  
  final expenseCategories = <String, String>{};
  final rawCategories = <String, double>{};
  for (final e in expenses) {
    if (e.date.month == now.month && e.date.year == now.year) {
      rawCategories[e.category] = (rawCategories[e.category] ?? 0) + e.amount;
    }
  }
  rawCategories.forEach((key, value) {
    expenseCategories[key] = CurrencyFormatter.format(value);
  });

  final recentTransactions = transactions.take(5).map((t) => {
    "title": t.title,
    "amount": CurrencyFormatter.format(t.amount),
    "type": t.type,
    "date": t.createdAt.toIso8601String().split('T').first,
  }).toList();
  
  final contextMap = {
    "availableBalance": CurrencyFormatter.format(availableBalance),
    "monthlyIncome": CurrencyFormatter.format(currentMonthReceived),
    "monthlyExpenses": CurrencyFormatter.format(monthlyExpenses),
    "monthlySavings": CurrencyFormatter.format(monthlySavings),
    "activeGoals": activeGoals,
    "investments": investmentsList,
    "expenseCategories": expenseCategories,
    "recentTransactions": recentTransactions,
  };
  
  return const JsonEncoder.withIndent('  ').convert(contextMap);
});
