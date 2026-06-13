import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class MetricDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String? contextText;
  final Color? valueColor;

  const MetricDisplay({
    super.key,
    required this.label,
    required this.value,
    this.contextText,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: textTheme.displayMedium?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
        if (contextText != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            contextText!,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
