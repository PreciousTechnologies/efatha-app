import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_text_field.dart';
import 'email_verification_screen.dart';

/// Screen for returning users to login with their email
class ReturningUserLoginScreen extends StatefulWidget {
  const ReturningUserLoginScreen({super.key});

  @override
  State<ReturningUserLoginScreen> createState() =>
      _ReturningUserLoginScreenState();
}

class _ReturningUserLoginScreenState extends State<ReturningUserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();

      // Send verification code via API
      final response = await apiService.sendVerificationCode(
        email: _emailController.text.trim(),
        purpose: 'login',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response['success']) {
        // Navigate to verification screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                EmailVerificationScreen(email: _emailController.text.trim()),
          ),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Verification code sent to your email',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send code'),
            backgroundColor: AppColors.dangerRedPrimary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.dangerRedPrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBackgroundSoft,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.neutralTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryPurpleDeep,
                          AppColors.primaryPurpleLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your registered email to receive a verification code',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.neutralTextMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                CustomTextField(
                  label: 'Email Address',
                  isRequired: true,
                  prefixIcon: Icons.email_outlined,
                  hint: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 32),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlueInfo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentBlueInfo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlueInfo.withValues(
                            alpha: 0.2,
                          ),
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
                          'We\'ll send a 4-digit verification code to your email. Please check your inbox.',
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

                // Send Code Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _isLoading
                        ? 'Sending Code...'
                        : 'Send Verification Code',
                    onPressed: _isLoading ? null : _sendVerificationCode,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    icon: Icons.send_rounded,
                  ),
                ),
                const SizedBox(height: 24),

                // Help Text
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to help/support
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Need Help?'),
                          content: const Text(
                            'If you don\'t remember your email or need assistance, please contact your church administrator or visit the church office.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got It'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Don\'t remember your email?',
                      style: TextStyle(
                        color: AppColors.primaryPurpleDeep,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
