import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Efatha Church App Text Styles
/// Typography hierarchy for consistent text styling
class AppTextStyles {
  // Headlines (24-32pt, bold)
  static const TextStyle headlineXLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.neutralTextPrimary,
    height: 1.2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.neutralTextPrimary,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.neutralTextPrimary,
    height: 1.2,
  );

  // Section Titles (16-18pt, semi-bold)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralTextPrimary,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralTextPrimary,
    height: 1.3,
  );

  // Body Copy (14-16pt)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.neutralTextPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.neutralTextPrimary,
    height: 1.5,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.neutralTextPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMediumWeight = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.neutralTextPrimary,
    height: 1.5,
  );

  // Metadata Labels (12-14pt)
  static const TextStyle metadataLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.neutralTextMuted,
    height: 1.4,
  );

  static const TextStyle metadata = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.neutralTextMuted,
    height: 1.4,
  );

  static const TextStyle metadataSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.neutralTextMuted,
    height: 1.4,
  );

  // Button Text (14-18pt, semi-bold)
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // Badge & Status Text (10-12pt, uppercase, semi-bold)
  static const TextStyle badgeLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle badgeSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Caption & Helper Text
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.neutralTextMuted,
    height: 1.4,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.neutralTextMuted,
    height: 1.4,
  );

  // Monospace (for IDs, network info)
  static const TextStyle monospace = TextStyle(
    fontSize: 13,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w400,
    color: AppColors.neutralTextSecondary,
    height: 1.4,
  );
}
