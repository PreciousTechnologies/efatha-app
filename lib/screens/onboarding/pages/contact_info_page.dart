import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../core/theme/app_colors.dart';
import '../onboarding_controller.dart';

/// Page 3: Contact Information
class ContactInfoPage extends StatefulWidget {
  final OnboardingController controller;

  const ContactInfoPage({super.key, required this.controller});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page icon and title
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.successGreenPrimary,
                      AppColors.successGreenDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.contact_phone_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How can we reach you? Share your contact details',
              style: TextStyle(fontSize: 14, color: AppColors.neutralTextMuted),
            ),
            const SizedBox(height: 32),

            // Phone Number
            CustomTextField(
              label: 'Phone Number',
              isRequired: true,
              prefixIcon: Icons.phone,
              hint: '+255 XXX XXX XXX',
              keyboardType: TextInputType.phone,
              initialValue: widget.controller.formData['phone'],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              validator: _validatePhone,
              onChanged: (value) {
                widget.controller.updateFormData('phone', value);
              },
            ),
            const SizedBox(height: 20),

            // Email
            CustomTextField(
              label: 'Email Address',
              isRequired: true,
              prefixIcon: Icons.email_outlined,
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              initialValue: widget.controller.formData['email'],
              validator: _validateEmail,
              onChanged: (value) {
                widget.controller.updateFormData('email', value);
              },
            ),
            const SizedBox(height: 20),

            // Postal Address
            CustomTextField(
              label: 'Postal Address',
              prefixIcon: Icons.mail_outline,
              hint: 'P.O. Box 12345, Dar es Salaam',
              maxLines: 2,
              initialValue: widget.controller.formData['postalAddress'],
              onChanged: (value) {
                widget.controller.updateFormData('postalAddress', value);
              },
            ),
            const SizedBox(height: 20),

            // Password (used for Supabase Auth sign-in)
            CustomTextField(
              label: 'Password',
              isRequired: true,
              prefixIcon: Icons.lock_outline,
              hint: 'Min. 6 characters',
              obscureText: !_isPasswordVisible,
              initialValue: widget.controller.formData['password'],
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 20,
                  color: AppColors.neutralTextMuted,
                ),
                onPressed: () => setState(
                  () => _isPasswordVisible = !_isPasswordVisible,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              onChanged: (value) {
                widget.controller.updateFormData('password', value);
              },
            ),
            const SizedBox(height: 20),

            // Confirm Password
            CustomTextField(
              label: 'Confirm Password',
              isRequired: true,
              prefixIcon: Icons.lock_outline,
              hint: 'Repeat your password',
              obscureText: !_isConfirmVisible,
              initialValue: widget.controller.formData['confirmPassword'],
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 20,
                  color: AppColors.neutralTextMuted,
                ),
                onPressed: () =>
                    setState(() => _isConfirmVisible = !_isConfirmVisible),
              ),
              validator: (value) {
                if (value != widget.controller.formData['password']) {
                  return 'Passwords do not match';
                }
                return null;
              },
              onChanged: (value) {
                widget.controller.updateFormData('confirmPassword', value);
              },
            ),

            const SizedBox(height: 32),

            // Info card
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
                      color: AppColors.accentBlueInfo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.accentBlueInfo,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your contact information will be kept confidential and used only for church communications.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutralTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
