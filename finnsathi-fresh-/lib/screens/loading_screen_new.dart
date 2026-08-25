import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_state_service.dart';
import '../services/finance_service.dart';

// Particle class for animated floating particles
class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  });

  void update() {
    position += velocity;
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  // For particle effects
  final List<Particle> _particles = [];
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();

    // Set preferred orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize main animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Initialize pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialize particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Setup rotation animation
    _rotationAnimation = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutBack,
      ),
    );

    // Setup opacity animation
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Setup scale animation for pulsing effect
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize particles
    _initializeParticles();

    // Start animations
    _animationController.forward();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    _pulseController.repeat(reverse: true);

    // Add listener to update particles on each animation frame
    _particleController.addListener(_updateParticles);
    _particleController.repeat();

    // Check authentication state and navigate accordingly
    _checkAuthAndNavigate();
  }

  // Initialize floating particles
  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          position: Offset(
            random.nextDouble() * 400,
            random.nextDouble() * 800,
          ),
          velocity: Offset(
            (random.nextDouble() - 0.5) * 2,
            (random.nextDouble() - 0.5) * 2,
          ),
          color: Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.1),
          size: random.nextDouble() * 8 + 2,
        ),
      );
    }
  }

  // Update particles position on each animation frame
  void _updateParticles() {
    if (!mounted) return;

    setState(() {
      for (var particle in _particles) {
        particle.update();

        // Reset particle position if it goes off screen
        final screenSize = MediaQuery.of(context).size;
        if (particle.position.dx < 0 ||
            particle.position.dx > screenSize.width ||
            particle.position.dy < 0 ||
            particle.position.dy > screenSize.height) {
          final random = math.Random();
          particle.position = Offset(
            random.nextDouble() * screenSize.width,
            random.nextDouble() * screenSize.height,
          );
        }
      }
    });
  }

  // Check if user is logged in and navigate to the appropriate screen
  Future<void> _checkAuthAndNavigate() async {
    // Ensure loading animation is visible for at least 2 seconds
    final minDisplayFuture = Future.delayed(const Duration(seconds: 3));

    try {
      // Get shared preferences to check if this is first launch
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      // Check all possible auth token keys to handle inconsistencies
      final token = prefs.getString('auth_token');
      final altToken = prefs.getString('token'); // Check alternative token key
      final userData = prefs.getString('user_data');
      final userProfile = prefs.getString(
        'user_profile',
      ); // Check alternative user data key
      final loginTimestamp = prefs.getInt('login_timestamp');
      final isLoggedInFlag = prefs.getBool('is_logged_in') ?? false;
      final loginSuccessful = prefs.getBool('login_successful') ?? false;
      final authStateValid = prefs.getBool('auth_state_valid') ?? false;

      // Detailed debug logging of all auth-related data
      debugPrint('🔍 Auth check on app start:');
      debugPrint(
        '  - auth_token: ${token != null ? 'exists (${token.length} chars)' : 'null'}',
      );
      debugPrint(
        '  - token: ${altToken != null ? 'exists (${altToken.length} chars)' : 'null'}',
      );
      debugPrint(
        '  - user_data: ${userData != null ? 'exists (${userData.length} chars)' : 'null'}',
      );
      debugPrint(
        '  - user_profile: ${userProfile != null ? 'exists (${userProfile.length} chars)' : 'null'}',
      );
      debugPrint('  - login_timestamp: $loginTimestamp');
      debugPrint('  - is_logged_in flag: $isLoggedInFlag');
      debugPrint('  - login_successful flag: $loginSuccessful');
      debugPrint('  - auth_state_valid flag: $authStateValid');

      // Start auth check immediately without artificial delay
      final isLoggedIn = await AuthStateService.isLoggedIn();

      debugPrint('🔐 Auth state check result: isLoggedIn=$isLoggedIn');

      // Safety check to ensure we're still mounted before navigating
      if (!mounted) {
        debugPrint('⚠️ LoadingScreen no longer mounted, aborting navigation');
        return;
      }

      // CRITICAL: Check for valid auth tokens and user data FIRST
      // This ensures that authentication takes priority over onboarding
      // Define these variables once at the top level
      final effectiveToken = token ?? altToken;
      final effectiveUserData = userData ?? userProfile;
      final hasValidToken = effectiveToken != null && effectiveToken.isNotEmpty;
      final hasValidUserData =
          effectiveUserData != null && effectiveUserData.isNotEmpty;

      debugPrint(
        '🔑 Auth validation: hasValidToken=$hasValidToken, hasValidUserData=$hasValidUserData',
      );

      // If user is already logged in, skip onboarding check completely
      if (hasValidToken && hasValidUserData) {
        // User has valid credentials - skip onboarding check entirely
        debugPrint('🔓 Valid auth detected - skipping onboarding check');

        // Also mark onboarding as seen to prevent future redirects
        if (!hasSeenOnboarding) {
          debugPrint(
            '📝 Setting has_seen_onboarding=true since user is already logged in',
          );
          await prefs.setBool('has_seen_onboarding', true);
        }
      }
      // Only check onboarding if user is NOT logged in
      else if (!hasSeenOnboarding) {
        debugPrint(
          '🆕 First launch detected and no valid auth - showing onboarding',
        );
        await minDisplayFuture;
        if (mounted)
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/onboarding',
            (route) => false,
          );
        return; // Important: Return here to avoid further checks
      }

      // Now proceed with authentication checks and navigation
      // We already have effectiveToken, effectiveUserData, hasValidToken, and hasValidUserData defined above

      debugPrint('🔓 Proceeding with authentication and navigation');

      // If we have both token and user data, force login state
      if (hasValidToken && hasValidUserData) {
        debugPrint(
          '✅ Found valid token and user data - ensuring login state and navigating to home',
        );

        try {
          // Parse user data
          Map<String, dynamic> userDataMap;
          try {
            userDataMap = jsonDecode(effectiveUserData);
          } catch (e) {
            // Create minimal user data if parsing fails
            userDataMap = {
              'id': 'recovered_user_${DateTime.now().millisecondsSinceEpoch}',
              'email': '',
              'name': 'User',
            };
            debugPrint('⚠️ Created minimal user data due to parsing error: $e');
          }

          // Save auth state to ensure all flags are properly set
          await AuthStateService.saveAuthState(
            token: effectiveToken,
            userData: userDataMap,
          );

          // Set all login flags directly to ensure consistency
          await prefs.setBool('is_logged_in', true);
          await prefs.setBool('login_successful', true);
          await prefs.setBool('auth_state_valid', true);

          // Set login timestamp
          await prefs.setInt(
            'login_timestamp',
            DateTime.now().millisecondsSinceEpoch,
          );

          // Ensure data refresh happens before navigation
          debugPrint('🔄 Refreshing all financial data before navigation');
          try {
            // Set login timestamp to trigger data refresh in services
            await prefs.setInt(
              'login_timestamp',
              DateTime.now().millisecondsSinceEpoch,
            );
            await prefs.setBool('has_seen_onboarding', true);

            // Force refresh data in finance service
            if (mounted) {
              Provider.of<FinanceService>(
                context,
                listen: false,
              ).forceRefreshData();
              debugPrint('✅ Successfully triggered finance data refresh');
            }
          } catch (e) {
            debugPrint('❌ Error refreshing finance data: $e');
          }

          // Navigate to home screen
          if (mounted) {
            await minDisplayFuture;
            debugPrint(
              '🏠 Navigating to home screen after successful auth recovery',
            );
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
          return; // Important: Return here to avoid further navigation
        } catch (e) {
          debugPrint('❌ Error while forcing login state: $e');
          // Continue to sign-in screen if we can't recover the session
        }
      } else if (isLoggedIn) {
        // AuthStateService says user is logged in
        debugPrint(
          '✅ AuthStateService confirms user is logged in - navigating to home screen',
        );

        // Ensure login flags are set
        await prefs.setBool('login_successful', true);
        await prefs.setBool('auth_state_valid', true);
        await prefs.setBool('is_logged_in', true);

        // Ensure data refresh happens before navigation
        debugPrint('🔄 Refreshing all financial data before navigation');
        try {
          // Set login timestamp to trigger data refresh in services
          await prefs.setInt(
            'login_timestamp',
            DateTime.now().millisecondsSinceEpoch,
          );
          await prefs.setBool('force_data_refresh', true);

          // Force refresh data in finance service
          if (mounted) {
            Provider.of<FinanceService>(
              context,
              listen: false,
            ).forceRefreshData();
            debugPrint('✅ Successfully triggered finance data refresh');
          }
        } catch (e) {
          debugPrint('❌ Error refreshing finance data: $e');
        }

        // Navigate to home screen
        if (mounted) {
          await minDisplayFuture;
          debugPrint('🏠 Navigating to home screen');
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
        return; // Important: Return here to avoid further navigation
      } else {
        // Debug which pieces are missing
        if (!hasValidToken) {
          debugPrint('⚠️ Auth check failed: No valid token found');
        }
        if (!hasValidUserData) {
          debugPrint('⚠️ Auth check failed: No valid user data found');
        }

        // User has seen onboarding but is not logged in, navigate to sign-in
        debugPrint(
          '🔑 User has seen onboarding but not logged in - navigating to sign-in',
        );
        await minDisplayFuture;
        if (mounted)
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/signin',
            (route) => false,
          );
      }
    } catch (e) {
      debugPrint('❌ Error in _checkAuthAndNavigate: $e');
      // Fallback to sign-in screen if there's any error
      if (mounted) {
        await minDisplayFuture;
        Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _particleController.removeListener(_updateParticles);
    _particleController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E), // Dark background
      body: Stack(
        children: [
          // Particles
          CustomPaint(
            painter: ParticlePainter(_particles),
            size: MediaQuery.of(context).size,
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.5,
                colors: [
                  const Color(0xFF6C63FF).withOpacity(0.3),
                  const Color(0xFF1E1E2E),
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),

          // Background glow effect
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(0.2),
                          const Color(0xFF6C63FF).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Secondary glow
          Center(
            child: AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value * 0.3,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated coin or money icon
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 3.14,
                      child: SizedBox(
                        height: 150,
                        width: 150,
                        child: Lottie.network(
                          'https://assets9.lottiefiles.com/packages/lf20_06a6pf9i.json', // Animated coin
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                // App name with fade in animation
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  from: 30,
                  child: Text(
                    'FinSaathi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline with fade in animation
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  from: 30,
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'Your Financial Companion',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Loading indicator
                FadeIn(
                  duration: const Duration(milliseconds: 1200),
                  delay: const Duration(milliseconds: 500),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Version number
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 1000),
              delay: const Duration(milliseconds: 800),
              child: Center(
                child: Text(
                  'Version 1.0.0',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for drawing particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()..color = particle.color;
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
