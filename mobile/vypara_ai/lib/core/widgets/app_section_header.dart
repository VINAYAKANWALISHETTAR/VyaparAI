import 'package:flutter/material.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_spacing.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(actionLabel!, style: const TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}
