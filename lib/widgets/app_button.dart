import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, text }

enum AppButtonSize { small, medium, large }

/// Custom Button Widget matching React Native Button component
/// Supports multiple variants, sizes, and loading states
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? customColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null && !isLoading;
    final double height = _getHeight();
    final TextStyle textStyle = _getTextStyle();
    final EdgeInsets padding = _getPadding();

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary
                    ? Colors.white
                    : customColor ?? AppColors.primaryPurpleDeep,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: textStyle),
            ],
          );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? AppColors.primaryPurpleDeep,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                (customColor ?? AppColors.primaryPurpleDeep).withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            padding: padding,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppSpacing.buttonBorderRadius,
              ),
            ),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? AppColors.accentBlueBrand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: (customColor ?? AppColors.accentBlueBrand)
                .withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            padding: padding,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppSpacing.buttonBorderRadius,
              ),
            ),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: customColor ?? AppColors.primaryPurpleDeep,
            disabledForegroundColor: AppColors.neutralTextDisabled,
            side: BorderSide(
              color: isDisabled
                  ? AppColors.neutralBorderDisabled
                  : (customColor ?? AppColors.primaryPurpleDeep),
              width: 1.5,
            ),
            padding: padding,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppSpacing.buttonBorderRadius,
              ),
            ),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: customColor ?? AppColors.primaryPurpleDeep,
            disabledForegroundColor: AppColors.neutralTextDisabled,
            padding: padding,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppSpacing.buttonBorderRadius,
              ),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.buttonHeightSmall;
      case AppButtonSize.medium:
        return AppSpacing.buttonHeightMedium;
      case AppButtonSize.large:
        return AppSpacing.buttonHeightLarge;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.buttonSmall;
      case AppButtonSize.medium:
        return AppTextStyles.buttonMedium;
      case AppButtonSize.large:
        return AppTextStyles.buttonLarge;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }
  }
}
