import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/error_handler.dart';
import 'widgets/goals_overview_card.dart';
import 'widgets/goal_card.dart';
import 'widgets/goal_progress_analytics_widget.dart';
import 'widgets/create_goal_modal.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormatter = DateFormat('MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              const GoalsOverviewCard(),
              const SizedBox(height: AppSpacing.xxl),
              const Padding(
                padding: EdgeInsets.only(left: 24, bottom: 16),
                child: Text('Active Goals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
              ...goals.when(
                data: (goalsList) {
                  if (goalsList.isEmpty) {
                    return [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Center(
                          child: Text(
                            'No active goals. Create one to start saving!',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    ];
                  }
                  return goalsList.map((goal) => GoalCard(
                    title: goal.title,
                    emoji: goal.emoji,
                    currentAmount: currencyFormatter.format(goal.currentAmount),
                    targetAmount: currencyFormatter.format(goal.targetAmount),
                    progress: goal.progress,
                    completionPercentage: goal.completionPercentage,
                    monthlyContribution: '${currencyFormatter.format(goal.monthlyContribution)}/mo',
                    estimatedCompletion: dateFormatter.format(goal.estimatedCompletion),
                  )).toList();
                },
                loading: () => [const Center(child: CircularProgressIndicator())],
                error: (error, stack) => [Center(child: AppErrorWidget(error: error))],
              ),
              const SizedBox(height: AppSpacing.xl),
              const GoalProgressAnalyticsWidget(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateGoalModal(),
          );
        },
        backgroundColor: AppColors.primaryAction,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Create Goal',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
