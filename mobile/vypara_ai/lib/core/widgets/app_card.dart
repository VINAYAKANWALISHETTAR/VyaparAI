import 'package:flutter/material.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/app/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.lg);
    final cardContent = Padding(
      padding: padding ?? AppSpacing.card,
      child: child,
    );
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? cardContent
            : InkWell(onTap: onTap, child: cardContent),
      ),
    );

    return card;
  }
}
