import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_spacing.dart';

enum StatusBadgeType { success, warning, danger, info, pending, approved }

/// Status Badge Widget
/// Colored pill with semantic meaning (success, warning, danger, etc.)
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final bool isUppercase;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.isUppercase = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(AppSpacing.badgeBorderRadius),
      ),
      child: Text(
        isUppercase ? label.toUpperCase() : label,
        style: AppTextStyles.badge.copyWith(color: colors['text']),
      ),
    );
  }

  Map<String, Color> _getColors() {
    switch (type) {
      case StatusBadgeType.success:
      case StatusBadgeType.approved:
        return {
          'background': AppColors.badgeBackground(
            AppColors.successGreenPrimary,
          ),
          'text': AppColors.successGreenDark,
        };
      case StatusBadgeType.warning:
      case StatusBadgeType.pending:
        return {
          'background': AppColors.badgeBackground(AppColors.warningAmber),
          'text': AppColors.warningAmber,
        };
      case StatusBadgeType.danger:
        return {
          'background': AppColors.badgeBackground(AppColors.dangerRedPrimary),
          'text': AppColors.dangerRedDark,
        };
      case StatusBadgeType.info:
        return {
          'background': AppColors.badgeBackground(AppColors.accentBlueInfo),
          'text': AppColors.accentBlueInfo,
        };
    }
  }
}

/// Priority Badge for Prayers
class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final type = _getPriorityType();
    return StatusBadge(label: priority, type: type);
  }

  StatusBadgeType _getPriorityType() {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return StatusBadgeType.danger;
      case 'high':
        return StatusBadgeType.warning;
      case 'normal':
        return StatusBadgeType.info;
      default:
        return StatusBadgeType.info;
    }
  }
}
