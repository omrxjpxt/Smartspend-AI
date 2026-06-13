import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../design_system/components/premium_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class AssetAllocation extends ConsumerWidget {
  const AssetAllocation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.md),
            child: Text(
              'Group By Platform',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          investmentsAsync.when(
            data: (investments) {
              if (investments.isEmpty) {
                return PremiumCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'No investments yet.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                );
              }

              // Group by platform
              final Map<String, List<String>> platformAssets = {};
              final Map<String, double> platformTotals = {};
              
              for (var i in investments) {
                final plat = i.platform;
                if (!platformAssets.containsKey(plat)) {
                  platformAssets[plat] = [];
                  platformTotals[plat] = 0.0;
                }
                platformAssets[plat]!.add(i.assetName);
                platformTotals[plat] = platformTotals[plat]! + i.investedAmount;
              }

              return Column(
                children: platformAssets.keys.map((platform) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      backgroundColor: AppColors.surfaceHighlight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            platform,
                            style: const TextStyle(
                              color: AppColors.accentAI,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Invested', style: TextStyle(color: AppColors.textSecondary)),
                              Text(
                                currencyFormatter.format(platformTotals[platform]!),
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Assets', style: TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  platformAssets[platform]!.toSet().join(', '),
                                  style: const TextStyle(color: AppColors.textPrimary),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}
