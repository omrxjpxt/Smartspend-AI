import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/goal.dart';
import '../domain/entities/investment.dart';
import '../domain/entities/app_transaction.dart';
import '../presentation/providers/app_providers.dart';
import '../data/repositories/transactions_repository.dart';

final localIntelligenceProvider = Provider<LocalIntelligenceEngine>((ref) {
  return LocalIntelligenceEngine(ref);
});

class Intent {
  static const String analyzeSpending = 'analyze_spending';
  static const String savingTips = 'saving_tips';
  static const String goalAdvice = 'goal_advice';
  static const String investmentAnalysis = 'investment_analysis';
  static const String overspendingAlert = 'overspending_alert';
  static const String monthlySummary = 'monthly_summary';
  static const String unknown = 'unknown';
}

class LocalIntelligenceEngine {
  final Ref ref;
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  LocalIntelligenceEngine(this.ref);

  String detectIntent(String prompt) {
    final lower = prompt.toLowerCase();
    
    if (lower.contains('spend') || lower.contains('budget') || lower.contains('expense')) {
      if (lower.contains('overspend') || lower.contains('alert') || lower.contains('warning')) {
        return Intent.overspendingAlert;
      }
      return Intent.analyzeSpending;
    }
    
    if (lower.contains('save') || lower.contains('saving') || lower.contains('tip')) {
      return Intent.savingTips;
    }
    
    if (lower.contains('goal') || lower.contains('afford') || lower.contains('target')) {
      return Intent.goalAdvice;
    }
    
    if (lower.contains('invest') || lower.contains('portfolio') || lower.contains('holding') || lower.contains('stock')) {
      return Intent.investmentAnalysis;
    }
    
    if (lower.contains('month') || lower.contains('summary') || lower.contains('report')) {
      return Intent.monthlySummary;
    }
    
    return Intent.unknown;
  }

  Future<String?> handleQuery(String prompt) async {
    final intent = detectIntent(prompt);
    
    switch (intent) {
      case Intent.analyzeSpending:
        return _generateSpendingAnalysis();
      case Intent.savingTips:
        return _generateSavingTips();
      case Intent.goalAdvice:
        return _generateGoalAdvice();
      case Intent.investmentAnalysis:
        return _generateInvestmentAnalysis();
      case Intent.overspendingAlert:
        return _generateOverspendingAlert();
      case Intent.monthlySummary:
        return generateMonthlySummary();
      default:
        return null; // Fallback to AI Provider
    }
  }

  // Helper to read current data
  double _getReceivedThisMonth() {
    return ref.read(currentMonthReceivedProvider);
  }

  double _getExpensesThisMonth() {
    return ref.read(currentMonthExpensesProvider);
  }
  
  List<Expense> _getExpenses() {
    return ref.read(expensesProvider).valueOrNull ?? [];
  }
  
  List<Goal> _getGoals() {
    return ref.read(goalsProvider).valueOrNull ?? [];
  }

  List<Investment> _getInvestments() {
    return ref.read(investmentsProvider).valueOrNull ?? [];
  }

  List<AppTransaction> _getTransactions() {
    return ref.read(allTransactionsProvider).valueOrNull ?? [];
  }

  String _format(double amount) => currencyFormatter.format(amount);

  String _generateSpendingAnalysis() {
    final received = _getReceivedThisMonth();
    final spent = _getExpensesThisMonth();
    final expenses = _getExpenses();
    
    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((e) => e.date.month == now.month && e.date.year == now.year).toList();
    
    if (currentMonthExpenses.isEmpty) {
      return "You haven't logged any expenses this month yet.";
    }

    final categories = <String, double>{};
    for (var e in currentMonthExpenses) {
      categories[e.category] = (categories[e.category] ?? 0) + e.amount;
    }
    
    var topCategory = '';
    var maxSpend = 0.0;
    categories.forEach((key, val) {
      if (val > maxSpend) {
        maxSpend = val;
        topCategory = key;
      }
    });

    final percentage = (maxSpend / spent) * 100;
    
    String status = spent > received 
      ? "You are overspending by ${_format(spent - received)}."
      : "You have ${_format(received - spent)} left this month.";

    return '''
You received ${_format(received)} this month and spent ${_format(spent)}.

$status

Top category:
$topCategory ${_format(maxSpend)} (${percentage.toStringAsFixed(1)}%)

Recommendation:
Reduce $topCategory spending by ${_format(maxSpend * 0.15)} (15%) next month to improve cash flow.
'''.trim();
  }

  String _generateSavingTips() {
    final received = _getReceivedThisMonth();
    final spent = _getExpensesThisMonth();
    
    if (received == 0) {
      return "Log your income to see personalized saving tips and calculate your savings rate.";
    }

    final savings = received - spent;
    final rate = (savings / received) * 100;
    
    if (savings <= 0) {
      return '''
Your current savings rate is 0%.
You are spending more than you earn. Try setting a strict budget for your top 2 expense categories.
'''.trim();
    }

    return '''
Your current savings rate is ${rate.toStringAsFixed(1)}%.

Tip:
You could save an additional ${_format(received * 0.05)} by reducing daily miscellaneous spending. 
Try to push your savings rate to 20% by cutting back on non-essential categories.
'''.trim();
  }

  String _generateGoalAdvice() {
    final goals = _getGoals();
    if (goals.isEmpty) {
      return "You don't have any active goals. Set a financial goal to get personalized advice!";
    }

    final activeGoals = goals.where((g) => g.currentAmount < g.targetAmount).toList();
    if (activeGoals.isEmpty) {
      return "Congratulations! You've achieved all your current goals.";
    }

    // Pick the most urgent or highest progress goal
    activeGoals.sort((a, b) => b.progress.compareTo(a.progress));
    final goal = activeGoals.first;
    
    final remaining = goal.targetAmount - goal.currentAmount;
    
    // Calculate average monthly contribution based on transactions
    final txs = _getTransactions().where((t) => t.type == 'Goal Contribution' && t.title == goal.title).toList();
    double avgMonthly = 0.0;
    if (txs.isNotEmpty) {
      final totalContrib = txs.fold(0.0, (sum, t) => sum + t.amount);
      // Rough estimation: if 1 transaction, assume that's the monthly rate
      avgMonthly = totalContrib / (txs.isNotEmpty ? txs.length : 1); 
    }
    
    // Default fallback if no contributions logged
    if (avgMonthly == 0) avgMonthly = remaining * 0.1; // Suggest 10% of remaining

    final months = (remaining / avgMonthly).ceil();

    return '''
${goal.title}

Target:
${_format(goal.targetAmount)}

Saved:
${_format(goal.currentAmount)}

Remaining:
${_format(remaining)}

At an estimated contribution rate of ${_format(avgMonthly)}/month, you will reach your goal in $months months.
'''.trim();
  }

  String _generateInvestmentAnalysis() {
    final investments = _getInvestments();
    if (investments.isEmpty) {
      return "You don't have any investments. Start building your portfolio to see analysis!";
    }

    double totalInvested = 0.0;
    double portfolioValue = 0.0;
    
    var largestHolding = '';
    var largestValue = 0.0;

    for (var i in investments) {
      totalInvested += i.investedAmount;
      final currentValue = i.quantity * i.currentPrice;
      portfolioValue += currentValue;
      
      if (currentValue > largestValue) {
        largestValue = currentValue;
        largestHolding = i.assetName;
      }
    }

    final profit = portfolioValue - totalInvested;
    final profitPct = totalInvested > 0 ? (profit / totalInvested) * 100 : 0.0;
    final sign = profit >= 0 ? '+' : '';

    return '''
Portfolio Value:
${_format(portfolioValue)}

Invested:
${_format(totalInvested)}

Profit:
${_format(profit)} ($sign${profitPct.toStringAsFixed(1)}%)

Largest holding:
$largestHolding
'''.trim();
  }

  String _generateOverspendingAlert() {
    final received = _getReceivedThisMonth();
    final spent = _getExpensesThisMonth();
    
    if (received == 0 && spent > 0) {
      return '''
Alert:
You have spent ${_format(spent)} but have not logged any income this month.
'''.trim();
    }

    if (spent > received) {
      final pct = (spent / received) * 100;
      return '''
Alert:
You spent ${pct.toStringAsFixed(0)}% of your received money this month.
Consider reviewing your budget immediately to prevent debt accumulation.
'''.trim();
    }

    return "No overspending detected. Your spending is well within your income this month.";
  }

  String generateMonthlySummary() {
    final txs = _getTransactions();
    final now = DateTime.now();
    
    double received = 0;
    double expenses = 0;
    double investments = 0;
    double goals = 0;
    
    final categories = <String, double>{};

    for (var tx in txs) {
      if (tx.createdAt.month == now.month && tx.createdAt.year == now.year) {
        if (tx.type == 'Income' || tx.type == 'Received') {
          received += tx.amount;
        } else if (tx.type == 'Expense') {
          expenses += tx.amount;
          final cat = tx.category ?? 'Uncategorized';
          categories[cat] = (categories[cat] ?? 0) + tx.amount;
        } else if (tx.type == 'Investment Purchase' || tx.type == 'Investment') {
          investments += tx.amount;
        } else if (tx.type == 'Goal Contribution') {
          goals += tx.amount;
        }
      }
    }

    final netSavings = received - expenses - investments - goals;
    
    var topCategory = 'None';
    var maxSpend = 0.0;
    categories.forEach((key, val) {
      if (val > maxSpend) {
        maxSpend = val;
        topCategory = key;
      }
    });

    final score = _calculateHealthScore(received, expenses, netSavings);

    return '''
Key Achievements
- Net Cash Flow for the period was ${_format(netSavings)}
- Financial Health Score is $score/100

Spending Analysis
- Total Expenses: ${_format(expenses)}
- Largest Category: $topCategory

Savings Analysis
- Total Received: ${_format(received)}
- Goal Contributions: ${_format(goals)}

Investment Analysis
- New Investments: ${_format(investments)}

Recommendations
- Review $topCategory to identify potential savings
- Try to maintain a positive cash flow next month
'''.trim();
  }

  int _calculateHealthScore(double received, double expenses, double netSavings) {
    if (received == 0) return 50; // Neutral starting point

    int score = 100;
    
    // Penalty for overspending
    if (expenses > received) {
      score -= 40;
    } else {
      // Reward for healthy savings rate (20% is ideal)
      final savingsRate = ((received - expenses) / received);
      if (savingsRate < 0.1) score -= 20;
      else if (savingsRate < 0.2) score -= 10;
    }

    // Reward/penalty for net cash flow including investments/goals
    if (netSavings < 0) {
      score -= 10; // Negative cash flow
    }

    return score.clamp(0, 100);
  }

  Future<Map<String, dynamic>> generateDashboardInsights() async {
    final txs = _getTransactions();
    if (txs.isEmpty) {
      return {'isEmpty': true};
    }

    final now = DateTime.now();
    double received = 0;
    double expenses = 0;
    double investments = 0;
    double goals = 0;
    
    final categories = <String, double>{};
    
    // Monthly Budget from Profile
    final profile = ref.read(userProfileProvider).valueOrNull;
    final monthlyIncome = profile?.monthlyIncome ?? 0;
    final monthlySavingsTarget = profile?.monthlySavingsTarget ?? 0;
    final budget = monthlyIncome - monthlySavingsTarget;

    for (var tx in txs) {
      if (tx.createdAt.month == now.month && tx.createdAt.year == now.year) {
        if (tx.type == 'Income' || tx.type == 'Received') {
          received += tx.amount;
        } else if (tx.type == 'Expense') {
          expenses += tx.amount;
          final cat = tx.category ?? 'Uncategorized';
          categories[cat] = (categories[cat] ?? 0) + tx.amount;
        } else if (tx.type == 'Investment Purchase' || tx.type == 'Investment') {
          investments += tx.amount;
        } else if (tx.type == 'Goal Contribution') {
          goals += tx.amount;
        }
      }
    }

    final netSavings = received - expenses - investments - goals;
    final savingsRate = received > 0 ? ((received - expenses) / received) : 0.0;
    
    var topCategory = 'None';
    var maxSpend = 0.0;
    categories.forEach((key, val) {
      if (val > maxSpend) {
        maxSpend = val;
        topCategory = key;
      }
    });

    final score = _calculateHealthScore(received, expenses, netSavings);
    
    String healthStatus;
    if (score >= 80) healthStatus = 'Excellent';
    else if (score >= 60) healthStatus = 'Good';
    else if (score >= 40) healthStatus = 'Needs Attention';
    else healthStatus = 'Critical';

    String healthReason;
    if (expenses > received && received > 0) {
      healthReason = 'Spending exceeded your income this month.';
    } else if (savingsRate >= 0.2) {
      healthReason = 'You are saving a strong portion of your income.';
    } else if (netSavings < 0) {
      healthReason = 'Negative cash flow detected due to high outflows.';
    } else if (score >= 80) {
      healthReason = 'Your spending and saving balance is very healthy.';
    } else {
      healthReason = 'Your financial health is stable but has room to improve.';
    }

    String todayInsight;
    if (budget > 0 && expenses > budget) {
      todayInsight = 'You have exceeded your monthly budget by ${_format(expenses - budget)}.';
    } else if (maxSpend > 0 && expenses > 0 && (maxSpend / expenses) > 0.4) {
      final pct = ((maxSpend / expenses) * 100).toStringAsFixed(0);
      todayInsight = '$topCategory accounts for $pct% of your expenses this month.';
    } else if (budget > 0 && expenses <= budget) {
      todayInsight = 'You still have ${_format(budget - expenses)} available in your monthly budget.';
    } else if (investments > 0) {
      todayInsight = 'You have invested ${_format(investments)} this month. Keep it up!';
    } else if (goals > 0) {
      todayInsight = 'You have contributed ${_format(goals)} towards your goals this month.';
    } else {
      todayInsight = 'You spent ${_format(expenses)} so far this month.';
    }

    List<String> recommendations = [];
    if (maxSpend > 0) {
      recommendations.add('Reduce $topCategory spending by ${_format(maxSpend * 0.15)} to increase savings.');
    }
    if (netSavings > 0) {
      recommendations.add('You can safely invest ${_format(netSavings)} this month.');
    }
    final allGoals = _getGoals();
    if (allGoals.isNotEmpty) {
      final activeGoals = allGoals.where((g) => g.currentAmount < g.targetAmount).toList();
      if (activeGoals.isNotEmpty) {
        activeGoals.sort((a, b) => b.progress.compareTo(a.progress));
        recommendations.add('You are on track to achieve your ${activeGoals.first.title} goal.');
      }
    }
    if (recommendations.isEmpty) {
      recommendations.add('Start setting financial goals to receive targeted advice.');
      recommendations.add('Log your daily expenses to uncover spending patterns.');
    }

    return {
      'isEmpty': false,
      'score': score,
      'healthStatus': healthStatus,
      'healthReason': healthReason,
      'todayInsight': todayInsight,
      'recommendations': recommendations.take(3).toList(),
      'snapshot': {
        'Income': _format(received),
        'Expenses': _format(expenses),
        'Goal Savings': _format(goals),
        'Investments': _format(investments),
        'Net Cash Flow': _format(netSavings),
        'Savings Rate': '${(savingsRate * 100).toStringAsFixed(1)}%',
        'Largest Expense': topCategory,
      }
    };
  }
}

