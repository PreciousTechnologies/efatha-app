import 'package:flutter/material.dart';

/// Efatha Church App Color Palette
/// Based on purple-first spiritual palette with blue accents
class AppColors {
  // Primary Purple Colors
  static const Color primaryPurpleDeep = Color(0xFF6B46C1);
  static const Color primaryPurpleLight = Color(0xFF8B5CF6);
  static const Color primaryPurpleVibrant = Color(0xFF7C3AED);

  // Accent Blue Colors
  static const Color accentBlueBrand = Color(0xFF2196F3);
  static const Color accentBlueGoogle = Color(0xFF4285F4);
  static const Color accentBlueFacebook = Color(0xFF1877F2);
  static const Color accentBlueInfo = Color(0xFF3B82F6);
  static const Color accentTeal = Color(0xFF0891B2);
  static const Color accentBlueSky = Color(0xFF007AFF);

  // Success Green Colors
  static const Color successGreenPrimary = Color(0xFF10B981);
  static const Color successGreenDark = Color(0xFF059669);

  // Warning Colors
  static const Color warningAmber = Color(0xFFF59E0B);

  // Danger Red Colors
  static const Color dangerRedPrimary = Color(0xFFEF4444);
  static const Color dangerRedDark = Color(0xFFDC2626);
  static const Color dangerRedDeep = Color(0xFF7C2D12);

  // Neutral Background Colors
  static const Color neutralBackgroundLightest = Color(0xFFFFFFFF);
  static const Color neutralBackgroundSoft = Color(0xFFF9FAFB);
  static const Color neutralBackgroundMuted = Color(0xFFF3F4F6);

  // Neutral Border Colors
  static const Color neutralBorderLight = Color(0xFFE5E7EB);
  static const Color neutralBorderMedium = Color(0xFFD1D5DB);
  static const Color neutralBorderDisabled = Color(0xFFE0E0E0);

  // Neutral Text Colors
  static const Color neutralTextPrimary = Color(0xFF1F2937);
  static const Color neutralTextSecondary = Color(0xFF374151);
  static const Color neutralTextTertiary = Color(0xFF4B5563);
  static const Color neutralTextMuted = Color(0xFF6B7280);
  static const Color neutralTextDisabled = Color(0xFF9CA3AF);
  static const Color neutralTextPlaceholder = Color(0xFF999999);

  // Overlay Colors
  static const Color neutralOverlayLight = Color(0x4D000000); // 30% opacity
  static const Color neutralOverlayMedium = Color(0x66000000); // 40% opacity
  static const Color neutralOverlayDark = Color(0x80000000); // 50% opacity

  // Donation Category Colors
  static const Color donationUpendo = primaryPurpleLight;
  static const Color donationInjili = accentBlueInfo;
  static const Color donationMkuto = dangerRedPrimary;

  // Auth Screen Colors
  static const Color authBackground = Color(0xFFF8F9FA);
  static const Color authHeroCircle = Color(0xFFE3F2FD);

  // Helper method to get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Helper method for badge backgrounds (12% opacity)
  static Color badgeBackground(Color color) {
    return color.withValues(alpha: 0.12);
  }

  // Helper method for chip backgrounds (20% opacity)
  static Color chipBackground(Color color) {
    return color.withValues(alpha: 0.20);
  }
}
