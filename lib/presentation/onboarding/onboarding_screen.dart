import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/user_profile_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _monthlyIncome = 100000;
  double _monthlySavingsTarget = 20000;
  String _riskProfile = 'Moderate';
  String _investmentExperience = 'Beginner';

  void _nextPage() {
    if (_pageController.page == 3) {
      // Save profile
      ref.read(userProfileRepositoryProvider).updateProfile({
        'name': 'User', // default name
        'monthlyIncome': _monthlyIncome,
        'monthlySavingsTarget': _monthlySavingsTarget,
        'riskProfile': _riskProfile,
        'investmentExperience': _investmentExperience,
        'onboardingCompleted': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      context.go('/home');
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Image.asset(
                'assets/images/logo.png',
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildIncomeStep(),
                  _buildSavingsStep(),
                  _buildRiskStep(),
                  _buildExperienceStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAI,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContainer(String title, String subtitle, Widget child) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl * 2),
          child,
        ],
      ),
    );
  }

  void _showCustomAmountBottomSheet(BuildContext context, String title, double currentValue, Function(double) onSave) {
    final TextEditingController controller = TextEditingController(text: currentValue.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceHighlight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: () {
                  final double? value = double.tryParse(controller.text);
                  if (value != null && value >= 0) {
                    onSave(value);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAI,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomeStep() {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return _buildStepContainer(
      "Let's get to know you",
      "What is your approximate monthly income?",
      Column(
        children: [
          Text(currencyFormatter.format(_monthlyIncome), style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: AppSpacing.xl),
          Slider(
            value: _monthlyIncome.clamp(0.0, 1000000.0),
            min: 0,
            max: 1000000,
            divisions: 100,
            activeColor: AppColors.accentAI,
            onChanged: (val) => setState(() => _monthlyIncome = val),
          ),
          TextButton(
            onPressed: () => _showCustomAmountBottomSheet(
              context,
              'Enter Custom Income',
              _monthlyIncome,
              (val) => setState(() => _monthlyIncome = val),
            ),
            child: Text(
              'Enter Custom Amount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.accentAI,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsStep() {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return _buildStepContainer(
      "Set your target",
      "How much would you like to save each month?",
      Column(
        children: [
          Text(currencyFormatter.format(_monthlySavingsTarget), style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: AppSpacing.xl),
          Slider(
            value: _monthlySavingsTarget.clamp(0.0, 500000.0),
            min: 0,
            max: 500000,
            divisions: 100,
            activeColor: AppColors.accentAI,
            onChanged: (val) => setState(() => _monthlySavingsTarget = val),
          ),
          TextButton(
            onPressed: () => _showCustomAmountBottomSheet(
              context,
              'Enter Custom Savings Target',
              _monthlySavingsTarget,
              (val) => setState(() => _monthlySavingsTarget = val),
            ),
            child: Text(
              'Enter Custom Amount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.accentAI,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskStep() {
    return _buildStepContainer(
      "Risk Profile",
      "How do you feel about investment risk?",
      Column(
        children: ['Conservative', 'Moderate', 'Aggressive'].map((e) => RadioListTile(
          title: Text(e, style: const TextStyle(color: Colors.white)),
          value: e,
          groupValue: _riskProfile,
          activeColor: AppColors.accentAI,
          onChanged: (val) => setState(() => _riskProfile = val.toString()),
        )).toList(),
      ),
    );
  }

  Widget _buildExperienceStep() {
    return _buildStepContainer(
      "Experience",
      "What is your investment experience level?",
      Column(
        children: ['Beginner', 'Intermediate', 'Expert'].map((e) => RadioListTile(
          title: Text(e, style: const TextStyle(color: Colors.white)),
          value: e,
          groupValue: _investmentExperience,
          activeColor: AppColors.accentAI,
          onChanged: (val) => setState(() => _investmentExperience = val.toString()),
        )).toList(),
      ),
    );
  }
}
