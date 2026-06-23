import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/investment.dart';
import '../../domain/entities/investment_transaction.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/insight.dart';
import '../../domain/entities/goal.dart';
import '../../data/repositories/goals_repository.dart';
import '../../data/repositories/investments_repository.dart';
import '../../data/repositories/expenses_repository.dart';
import '../../data/repositories/balance_repository.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../domain/entities/balance_transaction.dart';
import '../../domain/entities/app_notification.dart';
import '../../data/repositories/transactions_repository.dart';

// 1. Expenses Provider (Firebase Stream)
final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final repository = ref.watch(expensesRepositoryProvider);
  return repository.watchExpenses();
});

// 2. Transactions Provider
// Handled directly inside transactions_repository.dart via allTransactionsProvider

// 3. Investments Provider (Firebase Stream)
final investmentsProvider = StreamProvider<List<Investment>>((ref) {
  final repository = ref.watch(investmentsRepositoryProvider);
  return repository.watchInvestments();
});

// 3.5 Investment Transactions Provider (Firebase Stream)
final investmentTransactionsProvider = StreamProvider<List<InvestmentTransaction>>((ref) {
  final repository = ref.watch(investmentsRepositoryProvider);
  return repository.watchTransactions();
});

// 4. Accounts Provider (Static for now)
final accountsProvider = StateProvider<List<Account>>((ref) {
  return [
    const Account(id: 'a1', bankName: 'HDFC Bank', accountType: 'Savings', mask: '**** 4591', balance: 145000),
  ];
});

// ----- Goals & Budgets -----

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  return repository.watchGoals();
});

final totalGoalSavingsProvider = Provider<double>((ref) {
  final goals = ref.watch(goalsProvider).valueOrNull ?? [];
  return goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
});

final goalContributionsProvider = StreamProvider.family<List<GoalContribution>, String>((ref, goalId) {
  final repository = ref.watch(goalsRepositoryProvider);
  return repository.watchGoalContributions(goalId);
});

// 6. User Profile Provider (Firebase Stream)
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchProfile();
});

// 7. Balance Transactions Provider (Firebase Stream)
final balanceTransactionsProvider = StreamProvider<List<BalanceTransaction>>((ref) {
  final repository = ref.watch(balanceRepositoryProvider);
  return repository.watchBalanceTransactions();
});

// 8. Available Balance Computed Provider (Historical Received - Historical Expenses)
final availableBalanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  return transactions.fold(0.0, (sum, tx) {
    if (tx.type == 'Income' || tx.type == 'Received') return sum + tx.amount;
    if (tx.type == 'Expense') return sum - tx.amount;
    if (tx.type == 'Investment Sale') return sum + tx.amount;
    if (tx.type == 'Investment Purchase' || tx.type == 'Investment') return sum - tx.amount;
    if (tx.type == 'Goal Contribution') return sum - tx.amount;
    return sum;
  });
});

// 8.1 Current Month Received Provider
final currentMonthReceivedProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return transactions.fold(0.0, (sum, tx) {
    if ((tx.type == 'Income' || tx.type == 'Received') && 
        tx.createdAt.month == now.month && 
        tx.createdAt.year == now.year) {
      return sum + tx.amount;
    }
    return sum;
  });
});

// 8.2 Current Month Expenses Provider
final currentMonthExpensesProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return transactions.fold(0.0, (sum, tx) {
    if (tx.type == 'Expense' && 
        tx.createdAt.month == now.month && 
        tx.createdAt.year == now.year) {
      return sum + tx.amount;
    }
    return sum;
  });
});

// 9. Notifications Provider (Firebase Stream)
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.watchNotifications();
});

// 10. AI Insights Engine Provider (Computed Dynamically)
final aiInsightsProvider = Provider<AsyncValue<List<Insight>>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final goalsAsync = ref.watch(goalsProvider);
  
  if (expensesAsync.isLoading || goalsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  
  final expenses = expensesAsync.valueOrNull ?? [];
  final goals = goalsAsync.valueOrNull ?? [];
  
  List<Insight> insights = [];
  final now = DateTime.now();

  // Insight 1: Spending Analysis
  if (expenses.isNotEmpty) {
    final recentExpenses = expenses
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 7))))
        .fold(0.0, (sum, e) => sum + e.amount);
        
    final previousExpenses = expenses
        .where((e) => e.date.isBefore(now.subtract(const Duration(days: 7))) && e.date.isAfter(now.subtract(const Duration(days: 14))))
        .fold(0.0, (sum, e) => sum + e.amount);

    if (previousExpenses > 0) {
      if (recentExpenses < previousExpenses) {
        final drop = ((previousExpenses - recentExpenses) / previousExpenses * 100).toInt();
        insights.add(Insight(
          id: 'i_spend_good',
          message: 'You spent $drop% less this week compared to last week. Great discipline!',
          type: 'spending',
          generatedAt: now,
          isPositive: true,
        ));
      } else if (recentExpenses > previousExpenses * 1.2) {
        final spike = ((recentExpenses - previousExpenses) / previousExpenses * 100).toInt();
        insights.add(Insight(
          id: 'i_spend_bad',
          message: 'Your spending is up $spike% this week. Keep an eye on your budget.',
          type: 'spending',
          generatedAt: now,
          isPositive: false,
        ));
      }
    }
  }

  // Insight 2: Goal Analysis
  if (goals.isNotEmpty) {
    final closestGoal = goals.reduce((a, b) => a.progress > b.progress ? a : b);
    
    if (closestGoal.progress > 0.8 && closestGoal.progress < 1.0) {
      insights.add(Insight(
        id: 'i_goal_near',
        message: 'You are so close! Only ₹${(closestGoal.targetAmount - closestGoal.currentAmount).toInt()} left to reach your ${closestGoal.title} goal.',
        type: 'savings',
        generatedAt: now,
        isPositive: true,
      ));
    }
  }

  if (expenses.isEmpty && goals.isEmpty) {
    insights.add(Insight(
      id: 'i_empty_state',
      message: 'Add expenses and goals to unlock personalized AI insights.',
      type: 'system',
      generatedAt: now,
      isPositive: true,
    ));
  }

  return AsyncValue.data(insights);
});

