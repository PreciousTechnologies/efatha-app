import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../widgets/onboarding_progress_indicator.dart';
import '../../widgets/app_button.dart';
import 'onboarding_controller.dart';
import 'pages/personal_info_page.dart';
import 'pages/location_info_page.dart';
import 'pages/contact_info_page.dart';
import 'pages/church_details_page.dart';
import 'pages/confirmation_page.dart';
import '../auth/returning_user_login_screen.dart';
import '../home/home_screen.dart';

/// Main Onboarding Screen with 5 pages
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingController _controller = OnboardingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_controller.isCurrentPageValid || _controller.currentPage == 4) {
      _controller.nextPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.dangerRedPrimary,
        ),
      );
    }
  }

  void _handleBack() {
    if (_controller.currentPage > 0) {
      _controller.previousPage();
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get form data
      final formData = _controller.formData;

      // Supabase-first registration (Django fallback while migrating).
      if (SupabaseConfig.isConfigured) {
        await _registerWithSupabase(formData);
      } else {
        await _registerWithDjango(formData);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlySignUpError(e.message)),
          backgroundColor: AppColors.dangerRedPrimary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: AppColors.dangerRedPrimary,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _friendlySignUpError(String message) {
    final friendly = SupabaseAuthService.friendlyError(message);
    // Preserve the "Registration failed:" prefix for non-friendly fallbacks.
    if (friendly == message) return 'Registration failed: $message';
    return friendly;
  }

  /// Register via Supabase Auth + profiles table.
  /// Throws on failure so _handleSubmit shows the error snackbar.
  Future<void> _registerWithSupabase(Map<String, dynamic> formData) async {
    final auth = SupabaseAuthService();
    final email = (formData['email'] as String).trim();
    final password = formData['password'] as String;

    final profile = {
      'username': email.split('@').first,
      'first_name': formData['firstName'],
      'middle_name': formData['middleName'],
      'last_name': formData['lastName'],
      'gender': formData['gender'],
      'date_of_birth': formData['birthDate']?.toIso8601String().split('T')[0],
      'marital_status': formData['marriageStatus'],
      'phone_number': formData['phone'],
      'postal_address': formData['postalAddress'],
      'country': formData['countryName'],
      'region': formData['regionName'],
      'city': formData['districtName'],
      'residence': formData['residence'],
      'street': formData['street'],
      'house_number': formData['houseNumber'],
      'church_position': formData['churchPosition'],
      'service_region': formData['serviceRegion'],
      'membership_number': formData['membershipNumber'],
    };

    final response = await auth.signUp(
      email: email,
      password: password,
      profile: profile,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Sign-up failed. Please try again.');
    }

    // Upload profile picture to Supabase Storage if one was selected.
    if (formData['profileImage'] != null) {
      try {
        final url = await SupabaseStorageService().uploadProfilePicture(
          user.id,
          File(formData['profileImage'] as String),
        );
        await auth.updateProfile({'profile_picture_url': url});
      } catch (e) {
        // Don't fail registration if the picture upload fails.
        debugPrint('Profile picture upload failed: $e');
      }
    }

    if (!mounted) return;

    // If email confirmation is ON in Supabase, there is no session yet —
    // ask the user to confirm email, then sign in with OTP/password.
    if (response.session == null) {
      await _showCheckEmailDialog(email);
      return;
    }

    await _showWelcomeDialog();
  }

  /// Legacy Django registration (fallback until Supabase cutover).
  Future<void> _registerWithDjango(Map<String, dynamic> formData) async {
    // Submit to backend API
    final apiService = ApiService();
    final storageService = StorageService();

    // Prepare registration data in format backend expects
    final registrationData = {
      'username': formData['email'], // Use email as username
      'email': formData['email'],
      'password': formData['password'],
      'password_confirm': formData['password'],
        // Personal Information
        'first_name': formData['firstName'],
        'middle_name': formData['middleName'],
        'last_name': formData['lastName'],
        'gender': formData['gender'],
        'date_of_birth': formData['birthDate']?.toIso8601String().split(
          'T',
        )[0], // Format: YYYY-MM-DD
        'marital_status': formData['marriageStatus'],
        // Contact Information
        'phone_number': formData['phone'],
        'postal_address': formData['postalAddress'],
        // Location Information
        'country': formData['countryName'],
        'region': formData['regionName'],
        'city': formData['districtName'],
        'residence': formData['residence'],
        'street': formData['street'],
        'house_number': formData['houseNumber'],
        // Church Details
        'church_position': formData['churchPosition'],
        'service_region': formData['serviceRegion'],
        'membership_number': formData['membershipNumber'],
      };

      final response = await apiService.register(registrationData);

      // Check if registration was successful
      if (response['success'] == true) {
        // Save tokens if available
        if (response['data']?['access'] != null) {
          await storageService.setAccessToken(response['data']['access']);
        }
        if (response['data']?['refresh'] != null) {
          await storageService.setRefreshToken(response['data']['refresh']);
        }

        // Save user data if available
        if (response['data']?['user'] != null) {
          await storageService.saveUserData(response['data']['user']);
        }

        // Mark user as logged in
        await storageService.setLoggedIn(true);

        // Upload profile picture if one was selected
        if (formData['profileImage'] != null) {
          try {
            print(
              '🖼️ Profile image found in formData: ${formData['profileImage']}',
            );
            final profileImagePath = formData['profileImage'] as String;
            print('📤 Attempting to upload profile picture from onboarding...');

            final uploadResponse = await apiService.uploadProfilePicture(
              profileImagePath,
            );

            print('📥 Upload response: $uploadResponse');

            if (uploadResponse['success'] == true &&
                uploadResponse['data'] != null) {
              // Update stored user data with new profile picture
              print('✅ Updating user data with profile picture info');
              await storageService.saveUserData(uploadResponse['data']);
            } else {
              print(
                '⚠️ Profile picture upload did not succeed: ${uploadResponse['message']}',
              );
            }
          } catch (e) {
            // Don't fail registration if profile picture upload fails
            print('❌ Profile picture upload exception: $e');
          }
        }
      }

      if (!mounted) return;

      // Show success dialog
      await _showWelcomeDialog();
  }

  /// "Check your email" dialog when Supabase email confirmation is ON.
  Future<void> _showCheckEmailDialog(String email) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentBlueBrand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: AppColors.accentBlueBrand,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Check Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a verification code and a confirmation link to $email. '
              'Enter the code on the sign-in screen, or tap the link, then sign in.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutralTextMuted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Go to Sign In',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const ReturningUserLoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                variant: AppButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Welcome dialog after successful registration + auto sign-in.
  Future<void> _showWelcomeDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successGreenPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 48,
                color: AppColors.successGreenPrimary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Efatha!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your registration was successful. You are now part of our church community!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.neutralTextMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Get Started',
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToHome();
                },
                variant: AppButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.neutralBackgroundSoft,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _controller.currentPage > 0
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppColors.neutralTextPrimary,
                  ),
                  onPressed: _isSubmitting ? null : _handleBack,
                )
              : null,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return OnboardingProgressIndicator(
                    currentPage: _controller.currentPage,
                    totalPages: 5,
                  );
                },
              ),

              // Page Content
              Expanded(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return PageView(
                      controller: _controller.pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) {
                        // Page changes are controlled by the controller
                      },
                      children: [
                        PersonalInfoPage(controller: _controller),
                        LocationInfoPage(controller: _controller),
                        ContactInfoPage(controller: _controller),
                        ChurchDetailsPage(controller: _controller),
                        ConfirmationPage(
                          controller: _controller,
                          onSubmit: _handleSubmit,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Navigation Buttons at Bottom
              if (_controller.currentPage < 4)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous Button (Left)
                          if (_controller.currentPage > 0)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primaryPurpleVibrant,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _handleBack,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.arrow_back_rounded,
                                          color: AppColors.primaryPurpleVibrant,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Previous',
                                          style: const TextStyle(
                                            color:
                                                AppColors.primaryPurpleVibrant,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(), // Empty space when no previous button
                          // Next Button (Right)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryPurpleVibrant,
                                  AppColors.primaryPurpleDeep,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryPurpleVibrant
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _handleNext,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Next',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
