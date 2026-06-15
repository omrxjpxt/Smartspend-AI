import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/portfolio_hero.dart';
import 'widgets/investments_list.dart';
import 'widgets/add_investment_modal.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddInvestmentModal.show(context),
        backgroundColor: AppColors.accentAI,
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen title
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.xl,
                  bottom: AppSpacing.xxl,
                ),
                child: Text(
                  'Investments',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                ),
              ),

              // Premium portfolio hero
              const PortfolioHero(),
              const SizedBox(height: AppSpacing.xxl),

              // Investment holdings list (includes empty state)
              const InvestmentsList(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
