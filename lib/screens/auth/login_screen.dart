import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/services/api_service.dart';
import '../../widgets/app_button.dart';
import '../home/home_screen.dart';

/// Login Screen with spiritual aesthetic
/// Features email/password login and social authentication options
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final apiService = ApiService();

        // Call login API
        final response = await apiService.login(
          username: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        setState(() => _isLoading = false);

        if (response['success']) {
          // Navigate to home and clear stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Login successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Hero Logo Section
              _buildHeroSection(),

              const SizedBox(height: 48),

              // Login Form
              _buildLoginForm(),

              const SizedBox(height: 24),

              // Social Login Options
              _buildSocialLogin(),

              const SizedBox(height: 24),

              // Sign Up Link
              _buildSignUpLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              'assets/images/efathalogo.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome to Efatha',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.accentBlueBrand,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with your church community',
          style: AppTextStyles.bodyRegular.copyWith(
            color: AppColors.neutralTextMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: AppSpacing.cardPaddingAll,
      decoration: BoxDecoration(
        color: AppColors.neutralBackgroundLightest,
        borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutralTextMuted.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign In',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.inputBorderRadius,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.inputBorderRadius,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 8),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Navigate to forgot password
                },
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: AppColors.accentBlueBrand,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Login Button
            AppButton(
              label: 'Sign In',
              onPressed: _isLoading ? null : _handleLogin,
              isLoading: _isLoading,
              isFullWidth: true,
              size: AppButtonSize.large,
              customColor: AppColors.accentBlueBrand,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.neutralTextMuted,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SocialLoginButton(
                icon: Icons.g_mobiledata,
                label: 'Google',
                color: AppColors.accentBlueGoogle,
                onPressed: _isLoading
                    ? null
                    : () => _handleSocialLogin('Google'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialLoginButton(
                icon: Icons.facebook,
                label: 'Facebook',
                color: AppColors.accentBlueFacebook,
                onPressed: _isLoading
                    ? null
                    : () => _handleSocialLogin('Facebook'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Don\'t have an account? ', style: AppTextStyles.bodyRegular),
        TextButton(
          onPressed: () {
            // Navigate to sign up
          },
          child: Text(
            'Sign Up',
            style: AppTextStyles.bodyMediumWeight.copyWith(
              color: AppColors.accentBlueBrand,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.buttonSmall),
        ],
      ),
    );
  }
}
