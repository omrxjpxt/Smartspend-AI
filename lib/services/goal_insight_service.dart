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
    }

    // Return the top 3 most relevant insights
    return insights.take(3).toList();
  }
}
