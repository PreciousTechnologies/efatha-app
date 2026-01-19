import 'package:flutter/material.dart';

/// Efatha Church App Spacing System
/// Consistent spacing values used throughout the app
class AppSpacing {
  // Base spacing units
  static const double spaceXS = 6.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double space2XL = 24.0;
  static const double space3XL = 32.0;
  static const double space4XL = 40.0;

  // Screen padding (horizontal)
  static const double screenPaddingHorizontal = 16.0;
  static const double screenPaddingHorizontalLarge = 20.0;

  // Card spacing
  static const double cardPadding = 16.0;
  static const double cardMarginVertical = 8.0;
  static const double cardMarginVerticalLarge = 12.0;
  static const double cardBorderRadius = 12.0;

  // Button spacing
  static const double buttonBorderRadius = 8.0;
  static const double buttonPaddingHorizontal = 16.0;
  static const double buttonPaddingVertical = 12.0;
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;

  // Input spacing
  static const double inputBorderRadius = 12.0;
  static const double inputPaddingHorizontal = 16.0;
  static const double inputPaddingVertical = 12.0;

  // Chip & Badge spacing
  static const double chipBorderRadius = 20.0;
  static const double chipPaddingHorizontal = 12.0;
  static const double chipPaddingVertical = 8.0;
  static const double badgeBorderRadius = 16.0;

  // Modal spacing
  static const double modalBorderRadius = 16.0;
  static const double modalPadding = 16.0;

  // FAB positioning
  static const double fabBottom = 180.0;
  static const double fabRight = 20.0;
  static const double fabMainRadius = 28.0;
  static const double fabActionSize = 48.0;
  static const double fabActionSpacing = 60.0;

  // Section spacing
  static const double sectionSpacingSmall = 12.0;
  static const double sectionSpacingMedium = 16.0;
  static const double sectionSpacingLarge = 24.0;

  // EdgeInsets helpers
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingHorizontal,
  );

  static const EdgeInsets screenPaddingAll = EdgeInsets.all(spaceLG);

  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);

  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    vertical: cardMarginVertical,
    horizontal: screenPaddingHorizontal,
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: buttonPaddingHorizontal,
    vertical: buttonPaddingVertical,
  );

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: inputPaddingHorizontal,
    vertical: inputPaddingVertical,
  );

  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: chipPaddingHorizontal,
    vertical: chipPaddingVertical,
  );
}
