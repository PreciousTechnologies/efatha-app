import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../widgets/app_button.dart';
import '../home/home_screen.dart';
import 'dart:async';

/// Screen for entering and verifying the 4-digit code sent to email
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // Supabase email OTP length (default 8); legacy Django codes were 4.
  late final int _codeLength =
      SupabaseConfig.isConfigured ? SupabaseConfig.emailOtpLength : 4;
  late final List<TextEditingController> _controllers = List.generate(
    _codeLength,
    (index) => TextEditingController(),
  );
  late final List<FocusNode> _focusNodes = List.generate(
    _codeLength,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Touch late fields before first build.
    _controllers;
    _focusNodes;
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String _getEnteredCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  /// Try sign-in OTP first, then signup-confirmation OTP.
  /// (The Confirm-signup template issues `signup`-type codes when it
  /// contains `{{ .Token }}`; the OTP screen issues `email`-type codes.)
  Future<void> _verifySupabaseCode(
    SupabaseAuthService auth,
    String code,
  ) async {
    try {
      await auth.verifyOtp(email: widget.email, token: code);
    } on AuthException {
      await auth.verifyOtp(
        email: widget.email,
        token: code,
        type: OtpType.signup,
      );
    }
  }

  void _goHome() {
    // Navigate to Home immediately
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );

    // Show success message after navigation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification successful!'),
            backgroundColor: AppColors.successGreenPrimary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showVerifyError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerRedPrimary,
        action: SnackBarAction(
          label: 'Try Again',
          textColor: Colors.white,
          onPressed: _clearCode,
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    final enteredCode = _getEnteredCode();

    if (enteredCode.length != _codeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter all $_codeLength digits'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Supabase-first (Django fallback while migrating).
      if (SupabaseConfig.isConfigured) {
        try {
          final auth = SupabaseAuthService();
          await _verifySupabaseCode(auth, enteredCode);
          // Apply any profile stashed at sign-up (confirmation-pending flow).
          try {
            await auth.completePendingProfile();
          } catch (_) {}
        } on AuthException catch (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showVerifyError(
            'Invalid or expired code: ${SupabaseAuthService.friendlyError(e.message)}',
          );
          return;
        }
        if (!mounted) return;
        setState(() => _isLoading = false);
        _goHome();
        return;
      }

      final apiService = ApiService();

      // Verify code via API
      final response = await apiService.verifyCodeAndLogin(
        email: widget.email,
        code: enteredCode,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response['success']) {
        _goHome();
      } else {
        // Show error message
        _showVerifyError(
          response['message'] ?? 'Invalid verification code',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showVerifyError('Error: ${e.toString()}');
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Supabase-first (Django fallback while migrating).
      if (SupabaseConfig.isConfigured) {
        try {
          await SupabaseAuthService().sendOtp(
            email: widget.email,
            shouldCreateUser: false,
          );
        } on AuthException catch (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not resend code: ${SupabaseAuthService.friendlyError(e.message)}',
              ),
              backgroundColor: AppColors.dangerRedPrimary,
            ),
          );
          return;
        }
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent to your email'),
            backgroundColor: AppColors.successGreenPrimary,
          ),
        );
        _startResendTimer();
        return;
      }

      final apiService = ApiService();

      // Resend verification code
      final response = await apiService.sendVerificationCode(
        email: widget.email,
        purpose: 'login',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Verification code resent to your email',
            ),
            backgroundColor: AppColors.successGreenPrimary,
          ),
        );
        _startResendTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to resend code'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.successGreenPrimary,
                      AppColors.accentTeal,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a $_codeLength-digit code to',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.neutralTextMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurpleDeep,
                ),
              ),
              const SizedBox(height: 40),

              // Code Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_codeLength, (index) {
                  return Flexible(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 4,
                        right: index == _codeLength - 1 ? 0 : 4,
                      ),
                      child: _buildCodeField(index),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _isLoading ? 'Verifying...' : 'Verify Code',
                  onPressed: _isLoading ? null : _verifyCode,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(height: 24),

              // Resend Code
              if (_canResend)
                TextButton(
                  onPressed: _isLoading ? null : _resendCode,
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      color: AppColors.primaryPurpleDeep,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Text(
                  'Resend code in $_resendTimer seconds',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.neutralTextMuted,
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField(int index) {
    // Size boxes to fit any phone: total width minus padding/margins,
    // divided by box count. Keeps digits large and fully visible.
    final screenWidth = MediaQuery.of(context).size.width;
    final boxSize =
        ((screenWidth - 48 - ((_codeLength - 1) * 8)) / _codeLength).clamp(
      34.0,
      64.0,
    );
    final fontSize = boxSize >= 52 ? 24.0 : 19.0;
    return Container(
      width: boxSize,
      height: boxSize + 8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _controllers[index].text.isEmpty
              ? AppColors.neutralBorderLight
              : AppColors.primaryPurpleDeep,
          width: 2,
        ),
        boxShadow: _controllers[index].text.isNotEmpty
            ? [
                BoxShadow(
                  color: AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          cursorColor: AppColors.primaryPurpleDeep,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralTextPrimary,
            height: 1.0,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Move to next field
            if (index < _codeLength - 1) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // All fields filled, auto-verify
              _focusNodes[index].unfocus();
              _verifyCode();
            }
          } else {
            // Move to previous field if backspace
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {});
          },
        ),
      ),
    );
  }
}
