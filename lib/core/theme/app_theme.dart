import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Main App Theme Configuration
/// Purple-first spiritual palette with comprehensive theming
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryPurpleDeep,
        primaryContainer: AppColors.primaryPurpleLight,
        secondary: AppColors.accentBlueBrand,
        secondaryContainer: AppColors.accentBlueInfo,
        tertiary: AppColors.accentTeal,
        error: AppColors.dangerRedPrimary,
        surface: AppColors.neutralBackgroundLightest,
        surfaceContainerHighest: AppColors.neutralBackgroundSoft,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.neutralTextPrimary,
        onError: Colors.white,
        outline: AppColors.neutralBorderLight,
        outlineVariant: AppColors.neutralBorderMedium,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.neutralBackgroundSoft,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.neutralBackgroundLightest,
        foregroundColor: AppColors.neutralTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineMedium,
        iconTheme: IconThemeData(color: AppColors.neutralTextPrimary, size: 24),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.neutralBackgroundLightest,
        elevation: 4,
        shadowColor: AppColors.neutralTextMuted.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurpleDeep,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryPurpleDeep.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.5),
          elevation: 2,
          shadowColor: AppColors.primaryPurpleDeep.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 40),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPurpleDeep,
          disabledForegroundColor: AppColors.neutralTextDisabled,
          side: const BorderSide(
            color: AppColors.primaryPurpleDeep,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 40),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPurpleDeep,
          disabledForegroundColor: AppColors.neutralTextDisabled,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryPurpleLight,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutralBackgroundLightest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.neutralBorderLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.neutralBorderLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryPurpleDeep,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.dangerRedPrimary,
            width: 1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.neutralBorderDisabled,
            width: 1,
          ),
        ),
        hintStyle: AppTextStyles.bodyRegular.copyWith(
          color: AppColors.neutralTextPlaceholder,
        ),
        labelStyle: AppTextStyles.bodyRegular.copyWith(
          color: AppColors.neutralTextMuted,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutralBackgroundMuted,
        selectedColor: AppColors.primaryPurpleDeep,
        disabledColor: AppColors.neutralBackgroundMuted.withOpacity(0.5),
        labelStyle: AppTextStyles.bodyMediumWeight,
        secondaryLabelStyle: AppTextStyles.bodyMediumWeight.copyWith(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        pressElevation: 2,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.neutralBackgroundLightest,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.titleLarge,
        contentTextStyle: AppTextStyles.bodyRegular,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.neutralBackgroundLightest,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.neutralBorderLight,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.neutralTextMuted,
        size: 24,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.headlineXLarge,
        displayMedium: AppTextStyles.headlineLarge,
        displaySmall: AppTextStyles.headlineMedium,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.titleLarge,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.bodyMediumWeight,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyRegular,
        bodySmall: AppTextStyles.metadata,
        labelLarge: AppTextStyles.buttonMedium,
        labelMedium: AppTextStyles.buttonSmall,
        labelSmall: AppTextStyles.caption,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentBlueSky,
        circularTrackColor: AppColors.neutralBackgroundMuted,
      ),
    );
  }
}
