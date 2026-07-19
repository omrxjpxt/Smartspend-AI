import 'package:flutter/foundation.dart';
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
import '../../data/repositories/notifications_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../domain/entities/balance_transaction.dart';
import '../../domain/entities/app_notification.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../services/local_intelligence_engine.dart';

// 1. Expenses Provider (Derived from Ledger)
final expensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  
  return transactionsAsync.whenData((transactions) {
    return transactions
        .where((tx) => tx.type == 'Expense')
        .map((tx) => Expense(
              id: tx.id,
              amount: tx.amount,
              category: tx.category ?? 'Other',
              description: tx.title,
              date: tx.createdAt,
              createdAt: tx.createdAt,
            ))
        .toList();
  });
});

// 2. Transactions Provider
// Handled directly inside transactions_repository.dart via allTransactionsProvider

// 3. Investments Provider (Derived from Ledger)
final investmentsProvider = Provider<AsyncValue<List<Investment>>>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  return transactionsAsync.whenData((transactions) {
      final investmentTxs = transactions.where((tx) =>
          tx.type == 'Investment' ||
          tx.type == 'Investment Purchase' ||
          tx.type == 'Buy Investment' ||
          tx.type == 'Investment Buy' ||
          tx.type == 'Investment Sale' ||
          tx.type == 'Sell Investment').toList();

      investmentTxs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Group by symbol
      final Map<String, List<dynamic>> txsBySymbol = {};
      for (final tx in investmentTxs) {
        final symbol = (tx.metadata?['symbol']?.toString() ?? tx.title).trim();
        if (!txsBySymbol.containsKey(symbol)) {
          txsBySymbol[symbol] = [];
        }
        txsBySymbol[symbol]!.add(tx);
      }

      final Map<String, Investment> portfolio = {};
      debugPrint('\n========== INVESTMENT RECONCILIATION REPORT ==========\n');

      for (final entry in txsBySymbol.entries) {
        final symbol = entry.key;
        final txs = entry.value;

        debugPrint('Symbol: $symbol');
        debugPrint('\nBUY TRANSACTIONS');
        
        double totalBuyQty = 0;
        double totalSellQty = 0;
        double netQty = 0;
        double investedAmount = 0;
        double avgCost = 0;
        
        bool hasBuy = false;
        
        // Print Buys
        for (final tx in txs) {
          final isBuy = tx.type != 'Investment Sale' && tx.type != 'Sell Investment';
          if (isBuy) {
            hasBuy = true;
            final rawQty = tx.metadata?['quantity'];
            final qty = (rawQty is num ? rawQty.toDouble() : double.tryParse(rawQty?.toString() ?? '') ?? 1.0);
            final price = tx.metadata?['purchasePricePerShare'] ?? (tx.amount / (qty > 0 ? qty : 1.0));
            debugPrint('- Qty: $qty\n  Price: ₹$price\n  Date: ${tx.createdAt}');
          }
        }
        
        debugPrint('\nSELL TRANSACTIONS');
        // Print Sells
        for (final tx in txs) {
          final isBuy = tx.type != 'Investment Sale' && tx.type != 'Sell Investment';
          if (!isBuy) {
            if (!hasBuy) {
              debugPrint('⚠️ WARNING: SELL occurred before any BUY history for $symbol!');
            }
            final rawQty = tx.metadata?['quantity'];
            final qty = (rawQty is num ? rawQty.toDouble() : double.tryParse(rawQty?.toString() ?? '') ?? 1.0);
            final price = tx.metadata?['currentPrice'] ?? (tx.amount / (qty > 0 ? qty : 1.0));
            debugPrint('- Qty: $qty\n  Price: ₹$price\n  Date: ${tx.createdAt}');
          }
        }
        
        debugPrint('\n---------------------------------');

        // Process engine
        Investment? currentHolding;
        for (final tx in txs) {
          final isBuy = tx.type != 'Investment Sale' && tx.type != 'Sell Investment';
          final rawQty = tx.metadata?['quantity'];
          final txQuantity = (rawQty is num ? rawQty.toDouble() : double.tryParse(rawQty?.toString() ?? '') ?? 1.0);
          final txAmount = tx.amount;
          final rawCurrentPrice = tx.metadata?['currentPrice'];
          final currentTxPrice = (rawCurrentPrice is num 
              ? rawCurrentPrice.toDouble() 
              : double.tryParse(rawCurrentPrice?.toString() ?? '') ?? (txAmount / (txQuantity > 0 ? txQuantity : 1.0)));

          if (isBuy) {
            totalBuyQty += txQuantity;
            if (currentHolding == null) {
              final rawPurchasePrice = tx.metadata?['purchasePricePerShare'];
              final purchasePricePerShare = (rawPurchasePrice is num 
                  ? rawPurchasePrice.toDouble() 
                  : double.tryParse(rawPurchasePrice?.toString() ?? '') ?? (txAmount / (txQuantity > 0 ? txQuantity : 1.0)));
                  
              currentHolding = Investment(
                id: symbol,
                platform: (tx.metadata?['platform']?.toString() ?? tx.category ?? 'Other'),
                investmentType: (tx.metadata?['investmentType']?.toString() ?? 'Other'),
                assetName: (tx.metadata?['assetName']?.toString() ?? tx.title),
                symbol: symbol,
                investedAmount: txAmount,
                quantity: txQuantity,
                purchasePricePerShare: purchasePricePerShare,
                currentPrice: currentTxPrice,
                purchaseDate: tx.createdAt,
                notes: tx.metadata?['notes']?.toString(),
                createdAt: tx.createdAt,
              );
            } else {
              final newQuantity = currentHolding.quantity + txQuantity;
              final newInvestedAmount = currentHolding.investedAmount + txAmount;
              final newAvgCost = newQuantity > 0 ? newInvestedAmount / newQuantity : 0.0;
              
              currentHolding = currentHolding.copyWith(
                quantity: newQuantity,
                investedAmount: newInvestedAmount,
                purchasePricePerShare: newAvgCost,
                currentPrice: currentTxPrice,
              );
            }
            netQty = currentHolding.quantity;
            investedAmount = currentHolding.investedAmount;
            avgCost = currentHolding.purchasePricePerShare;
          } else {
            // SELL
            totalSellQty += txQuantity;
            if (currentHolding != null) {
              final newQuantity = currentHolding.quantity - txQuantity;
              if (newQuantity < -0.0001) {
                debugPrint('⚠️ WARNING: Quantity became negative (${newQuantity.toStringAsFixed(2)})! Ledger might have duplicate sells or missing buys.');
              }
              
              if (newQuantity <= 0.0001) {
                currentHolding = currentHolding.copyWith(
                  quantity: 0.0,
                  investedAmount: 0.0,
                  currentPrice: currentTxPrice,
                );
              } else {
                final sellRatio = txQuantity / currentHolding.quantity;
                final newInvestedAmount = currentHolding.investedAmount - (currentHolding.investedAmount * sellRatio);
                
                currentHolding = currentHolding.copyWith(
                  quantity: newQuantity,
                  investedAmount: newInvestedAmount,
                  currentPrice: currentTxPrice,
                );
              }
              netQty = currentHolding.quantity;
              investedAmount = currentHolding.investedAmount;
            }
          }
        }

        debugPrint('\nTOTAL BUY QUANTITY\n$totalBuyQty');
        debugPrint('\nTOTAL SELL QUANTITY\n$totalSellQty');
        debugPrint('\nNET QUANTITY\n$netQty');
        debugPrint('\nAVERAGE COST\n₹$avgCost');
        debugPrint('\nINVESTED AMOUNT\n₹$investedAmount');
        debugPrint('\nFINAL DECISION');
        
        if (currentHolding != null && currentHolding.quantity > 0.0001) {
          portfolio[symbol] = currentHolding;
          debugPrint('Active in portfolio with ${currentHolding.quantity} units.');
        } else {
          debugPrint('Hidden from portfolio because quantity is zero.');
        }
        
        debugPrint('\n==================================================\n');
      }

      final holdings = portfolio.values.where((inv) => inv.quantity > 0.0001).toList();
      holdings.sort((a, b) => b.currentValue.compareTo(a.currentValue));
      return holdings;
  });
});

// 3.5 Investment Transactions Provider (Derived from Ledger)
final investmentTransactionsProvider = Provider<AsyncValue<List<InvestmentTransaction>>>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  return transactionsAsync.whenData((transactions) {
    return transactions
        .where((tx) => tx.type == 'Investment Purchase' || tx.type == 'Investment Sale' || tx.type == 'Investment')
        .map((tx) => InvestmentTransaction(
              id: tx.id,
              action: tx.type == 'Investment Sale' ? 'SELL' : 'BUY',
              assetName: tx.metadata?['assetName'] ?? tx.title,
              platform: tx.metadata?['platform'] ?? 'Smartspend',
              amount: tx.amount,
              quantity: (tx.metadata?['quantity'] ?? 1.0).toDouble(),
              timestamp: tx.createdAt,
            ))
        .toList();

  });
});

// 4. Accounts Provider (Static for now)
final accountsProvider = StateProvider<List<Account>>((ref) {
  return [
    const Account(id: 'a1', bankName: 'HDFC Bank', accountType: 'Savings', mask: '**** 4591', balance: 145000),
  ];
});

// ----- Goals & Budgets -----

// Raw goals from Firestore (metadata only — no financial values)
final _rawGoalsProvider = StreamProvider<List<Goal>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  return repository.watchGoals();
});

// Goals Provider — computes currentAmount from the ledger dynamically
final goalsProvider = Provider<AsyncValue<List<Goal>>>((ref) {
  final rawGoalsAsync = ref.watch(_rawGoalsProvider);
  final transactionsAsync = ref.watch(allTransactionsProvider);

  if (rawGoalsAsync.isLoading || transactionsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (rawGoalsAsync.hasError) return AsyncValue.error(rawGoalsAsync.error!, rawGoalsAsync.stackTrace!);
  if (transactionsAsync.hasError) return AsyncValue.error(transactionsAsync.error!, transactionsAsync.stackTrace!);

  final rawGoals = rawGoalsAsync.valueOrNull ?? [];
  final transactions = transactionsAsync.valueOrNull ?? [];

  final enriched = rawGoals.map((goal) {
    final contributed = transactions
        .where((tx) => tx.type == 'Goal Contribution' && tx.referenceId == goal.id)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    return goal.copyWith(currentAmount: contributed);
  }).toList();

  return AsyncValue.data(enriched);
});

final totalGoalSavingsProvider = Provider<double>((ref) {
  final goals = ref.watch(goalsProvider).valueOrNull ?? [];
  return goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
});

// Goal Contributions — derived from the ledger, filtered by goal ID
final goalContributionsProvider = Provider.family<AsyncValue<List<GoalContribution>>, String>((ref, goalId) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  return transactionsAsync.whenData((transactions) {
    return transactions
        .where((tx) => tx.type == 'Goal Contribution' && tx.referenceId == goalId)
        .map((tx) => GoalContribution(
              id: tx.id,
              goalId: goalId,
              amount: tx.amount,
              date: tx.createdAt,
            ))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  });
});

// 6. User Profile Provider (Firebase Stream)
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchProfile();
});

// 7. Balance Transactions Provider (Derived from Ledger)
final balanceTransactionsProvider = Provider<AsyncValue<List<BalanceTransaction>>>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  return transactionsAsync.whenData((transactions) {
    return transactions
        .where((tx) => tx.type == 'Balance Added' || (tx.type == 'Expense' && tx.category == 'Balance'))
        .map((tx) => BalanceTransaction(
              id: tx.id,
              amount: tx.amount,
              type: tx.type == 'Balance Added' ? 'add' : 'remove',
              source: tx.category ?? 'Other',
              timestamp: tx.createdAt,
            ))
        .toList();
  });
});

// 8. Available Balance Computed Provider (Historical Received - Historical Expenses)
final availableBalanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  return transactions.fold(0.0, (sum, tx) {
    if (tx.type == 'Income' || tx.type == 'Received' || tx.type == 'Balance Added') return sum + tx.amount;
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
    if ((tx.type == 'Income' || tx.type == 'Received' || tx.type == 'Balance Added') && 
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

// 8.3 Monthly Budget Provider (Derived from UserProfile)
// Budget = monthlyIncome - monthlySavingsTarget
final monthlyBudgetProvider = Provider<double>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) return 0.0;
  return profile.monthlyIncome - profile.monthlySavingsTarget;
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

// 11. AI Dashboard Provider
final aiDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(allTransactionsProvider);
  final engine = ref.read(localIntelligenceProvider);
  return engine.generateDashboardInsights();
});
