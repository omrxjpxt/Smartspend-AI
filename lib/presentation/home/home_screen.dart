import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/greeting_header.dart';
import 'widgets/ai_coach_hero_card.dart';
import 'widgets/section_heading.dart';
import 'widgets/financial_snapshot_card.dart';
import 'widgets/home_actions_row.dart';
import 'widgets/recent_activity_list.dart';

import '../../data/repositories/transactions_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Run data migration automatically to preserve old data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsRepositoryProvider).runDataMigration();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final userName = userProfile.valueOrNull?.name ?? 'User';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingHeader(name: userName),
              const AiCoachHeroCard(),
              const SizedBox(height: AppSpacing.xxl),
              const FinancialSnapshotCard(),
              const SizedBox(height: AppSpacing.lg),
              const HomeActionsRow(),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeading(
                title: 'Recent Activity',
                actionText: 'View All →',
                onActionTap: () => context.push('/transactions'),
              ),
              const RecentActivityList(),
              const SizedBox(height: AppSpacing.section),
            ],
          ),
        ),
      ),
    );
  }
}
