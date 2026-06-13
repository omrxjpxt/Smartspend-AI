import 'package:intl/intl.dart';
import '../domain/entities/goal.dart';

class GoalInsightService {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  /// Current mode: Rule-based insights derived strictly from user data.
  /// Future mode: Gemini-generated insights based on Goal, Expense, Income, and Investment data.
  List<String> generateInsights(List<Goal> goals) {
    if (goals.isEmpty) {
      return [];
    }

    final List<String> insights = [];

    for (final goal in goals) {
      final remaining = goal.targetAmount - goal.currentAmount;

      // Completed Goal
      if (remaining <= 0) {
        insights.add("You have successfully reached your ${goal.title} goal!");
        continue;
      }

      // Percentage completed
      final percentage = (goal.progress * 100).toInt();
      if (percentage > 0) {
        insights.add("You have completed $percentage% of your ${goal.title} goal. ${_currencyFormatter.format(remaining)} remaining.");
      } else {
        insights.add("${_currencyFormatter.format(remaining)} remaining to reach your ${goal.title} goal.");
      }

      // Time estimate based on monthly contribution
      if (goal.monthlyContribution > 0) {
        final monthsRemaining = (remaining / goal.monthlyContribution).ceil();
        insights.add("At your current pace of ${_currencyFormatter.format(goal.monthlyContribution)}/month, your ${goal.title} goal may be completed in approximately $monthsRemaining months.");

        // Check if behind or ahead of schedule based on deadline
        if (goal.estimatedCompletion.isAfter(DateTime.now())) {
          final now = DateTime.now();
          final monthsUntilDeadline = (goal.estimatedCompletion.year - now.year) * 12 + goal.estimatedCompletion.month - now.month;
          
          if (monthsUntilDeadline > 0) {
            final requiredMonthly = remaining / monthsUntilDeadline;
            if (goal.monthlyContribution < requiredMonthly) {
              insights.add("Increase monthly contributions for ${goal.title} to ${_currencyFormatter.format(requiredMonthly)} to stay on track for your deadline.");
            } else if (goal.monthlyContribution > requiredMonthly * 1.2) {
              insights.add("Your current savings pace for ${goal.title} is ahead of schedule.");
            }
          }
        }
      }
    }

    // Return the top 3 most relevant insights
    return insights.take(3).toList();
  }
}
