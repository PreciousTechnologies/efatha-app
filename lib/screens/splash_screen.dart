import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/config/supabase_config.dart';
import '../core/services/api_service.dart';
import '../core/services/supabase_auth_service.dart';
import 'welcome/welcome_screen.dart';
import 'home/home_screen.dart';

/// Enhanced Animated Splash Screen with Efatha Church branding
/// Features multiple smooth animations, shimmer effects, and particle animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main animation controller
  late AnimationController _controller;

  // Logo animations
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  // Individual animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _logoGlowAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo bounce controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse controller (continuous)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Shimmer effect controller
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Scale animation with elastic bounce
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Slide animation
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Pulse animation (subtle breathing effect)
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer animation
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Glow animation
    _logoGlowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start all animations
    _controller.forward();
    _logoController.forward();

    // Check authentication status and navigate after animation
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for minimum splash duration (for better UX)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      // Supabase-first: active session wins. Django JWT is the fallback
      // until all screens are migrated (see SUPABASE_MIGRATION_GUIDE.md).
      bool isAuthenticated = false;
      if (SupabaseConfig.isConfigured) {
        try {
          final auth = SupabaseAuthService();
          isAuthenticated = auth.isSignedIn;
          if (isAuthenticated) {
            // Covers confirm-via-email-link then reopen: stash applied now.
            try {
              await auth.completePendingProfile();
            } catch (_) {}
          }
        } catch (_) {
          isAuthenticated = false;
        }
      }
      if (!isAuthenticated) {
        final apiService = ApiService();
        // Check if user is authenticated (validates token and refreshes if needed)
        isAuthenticated = await apiService.isAuthenticated();
      }

      if (!mounted) return;

      // Navigate based on authentication status
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isAuthenticated ? const HomeScreen() : const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      // On error, navigate to welcome screen
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBackground(controller: _shimmerController),

          // Floating particles
          ...List.generate(
            15,
            (index) =>
                FloatingParticle(delay: index * 0.2, controller: _controller),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Enhanced Animated Logo
                _buildEnhancedLogo(),

                const SizedBox(height: 40),

                // Animated App Name with Shimmer
                _buildAnimatedText(),

                const SizedBox(height: 60),

                // Loading Indicator with Glow
                _buildLoadingIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedBuilder(
                animation: _logoGlowAnimation,
                builder: (context, logoChild) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(
                            alpha: _logoGlowAnimation.value * 0.5,
                          ),
                          blurRadius: 30 * _logoGlowAnimation.value,
                          spreadRadius: 10 * _logoGlowAnimation.value,
                        ),
                        BoxShadow(
                          color: AppColors.primaryPurpleLight.withValues(alpha: 0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Stack(
                        children: [
                          // Logo image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(70),
                            child: Image.asset(
                              'assets/images/efathalogo.jpeg',
                              fit: BoxFit.cover,
                            ),
                          ),

                          // Shimmer overlay
                          ClipRRect(
                            borderRadius: BorderRadius.circular(70),
                            child: AnimatedBuilder(
                              animation: _shimmerAnimation,
                              builder: (context, child) {
                                return ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      stops: [
                                        0.0,
                                        _shimmerAnimation.value - 0.3,
                                        _shimmerAnimation.value,
                                        _shimmerAnimation.value + 0.3,
                                        1.0,
                                      ],
                                      colors: [
                                        Colors.transparent,
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.6),
                                        Colors.transparent,
                                        Colors.transparent,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Container(color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedText() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Main title with shimmer
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [
                        0.0,
                        _shimmerAnimation.value - 0.1,
                        _shimmerAnimation.value,
                        _shimmerAnimation.value + 0.1,
                        1.0,
                      ],
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white,
                        Colors.white,
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'EFATHA',
                    style: AppTextStyles.headlineXLarge.copyWith(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              'Church Community',
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                letterSpacing: 2,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Connect • Worship • Grow',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _logoGlowAnimation,
        builder: (context, child) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(
                    alpha: _logoGlowAnimation.value * 0.3,
                  ),
                  blurRadius: 20 * _logoGlowAnimation.value,
                  spreadRadius: 5 * _logoGlowAnimation.value,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.8),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated gradient background
class AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const AnimatedBackground({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPurpleDeep,
                AppColors.primaryPurpleVibrant,
                AppColors.primaryPurpleLight,
                AppColors.primaryPurpleDeep,
              ],
              stops: [
                0.0,
                0.3 + (controller.value * 0.2),
                0.7 + (controller.value * 0.2),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

// Floating particle effect
class FloatingParticle extends StatefulWidget {
  final double delay;
  final AnimationController controller;

  const FloatingParticle({
    super.key,
    required this.delay,
    required this.controller,
  });

  @override
  State<FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  late Animation<Offset> _animation;
  late double xPosition;
  late double size;

  @override
  void initState() {
    super.initState();

    final random = math.Random();
    xPosition = random.nextDouble();
    size = 2 + random.nextDouble() * 4;

    _particleController = AnimationController(
      duration: Duration(milliseconds: 3000 + random.nextInt(2000)),
      vsync: this,
    )..repeat();

    _animation =
        Tween<Offset>(
          begin: Offset(xPosition, 1.2),
          end: Offset(xPosition + (random.nextDouble() - 0.5) * 0.3, -0.2),
        ).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
        );

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _particleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _animation.value.dx,
          top: MediaQuery.of(context).size.height * _animation.value.dy,
          child: FadeTransition(
            opacity: widget.controller,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
