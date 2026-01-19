import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              final isActive = index == currentPage;
              final isCompleted = index < currentPage;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isCompleted || isActive
                      ? AppColors.primaryPurpleDeep
                      : AppColors.neutralBorderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentPage + 1) / totalPages,
              backgroundColor: AppColors.neutralBackgroundMuted,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryPurpleDeep,
              ),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 8),

          // Progress text
          Text(
            'Step ${currentPage + 1} of $totalPages',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.neutralTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
