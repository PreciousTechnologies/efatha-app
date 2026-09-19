import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_spacing.dart';

/// Custom Card Widget matching React Native Card component
/// White surface with rounded corners and optional elevation
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? AppSpacing.cardPaddingAll,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.neutralBackgroundLightest,
        borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
        border: border,
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: AppColors.neutralTextMuted.withValues(alpha: 0.1),
                  blurRadius: elevation! * 2,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin ?? AppSpacing.cardMargin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin ?? AppSpacing.cardMargin,
      child: cardContent,
    );
  }
}
