import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/portfolio_hero.dart';
import 'widgets/asset_allocation.dart';
import 'widgets/investments_list.dart';
import 'widgets/investment_history_list.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.xl),
              PortfolioHero(),
              SizedBox(height: AppSpacing.xxl),
              InvestmentsList(), // Replaces TopHoldings
              SizedBox(height: AppSpacing.xxl),
              AssetAllocation(), // Uses real data
              SizedBox(height: AppSpacing.xxl),
              InvestmentHistoryList(), // New transaction history
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
