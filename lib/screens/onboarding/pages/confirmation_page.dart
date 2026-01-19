import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../onboarding_controller.dart';

/// Page 5: Confirmation and Review
class ConfirmationPage extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onSubmit;

  const ConfirmationPage({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryPurpleDeep,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutralBorderLight),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutralTextMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.neutralTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final data = controller.formData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.successGreenPrimary, AppColors.accentTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Confirm Your Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please review your information before submitting',
            style: TextStyle(fontSize: 14, color: AppColors.neutralTextMuted),
          ),
          const SizedBox(height: 32),

          // Personal Information
          _buildSection('Personal Information', [
            _buildInfoRow('First Name', data['firstName'] ?? ''),
            _buildInfoRow('Middle Name', data['middleName'] ?? ''),
            _buildInfoRow('Last Name', data['lastName'] ?? ''),
            _buildInfoRow('Gender', data['gender'] ?? ''),
            _buildInfoRow('Birth Date', _formatDate(data['birthDate'])),
            _buildInfoRow('Marital Status', data['marriageStatus'] ?? ''),
          ]),
          const SizedBox(height: 24),

          // Location Information
          _buildSection('Location Information', [
            _buildInfoRow('Country', data['countryName'] ?? ''),
            _buildInfoRow('Region', data['regionName'] ?? ''),
            _buildInfoRow('District', data['districtName'] ?? ''),
            _buildInfoRow('Residence', data['residence'] ?? ''),
            _buildInfoRow('Street', data['street'] ?? ''),
            _buildInfoRow('House Number', data['houseNumber'] ?? ''),
          ]),
          const SizedBox(height: 24),

          // Contact Information
          _buildSection('Contact Information', [
            _buildInfoRow('Phone', data['phone'] ?? ''),
            _buildInfoRow('Email', data['email'] ?? ''),
            _buildInfoRow('Postal Address', data['postalAddress'] ?? ''),
          ]),
          const SizedBox(height: 24),

          // Church Details
          _buildSection('Church Details', [
            _buildInfoRow('Church Position', data['churchPosition'] ?? ''),
            _buildInfoRow('Service Region', data['serviceRegion'] ?? ''),
            _buildInfoRow('Membership Number', data['membershipNumber'] ?? ''),
          ]),
          const SizedBox(height: 32),

          // Privacy Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neutralBackgroundMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutralBorderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primaryPurpleDeep,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'By submitting, you agree that this information will be used to create your church member profile.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutralTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Submit & Join Community',
              onPressed: onSubmit,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              icon: Icons.check_circle,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
