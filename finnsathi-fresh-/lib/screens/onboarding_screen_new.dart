import 'package:flutter/material.dart';
import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Custom classes for futuristic UI elements
class OnboardingParticle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double opacity;

  OnboardingParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.opacity = 1.0,
  });

  void update() {
    position += velocity;
    // Slowly fade out
    opacity = (opacity * 0.99).clamp(0.1, 1.0);
  }
}

class HexagonTile {
  Offset position;
  double size;
  double rotation;
  Color color;
  double opacity;

  HexagonTile({
    required this.position,
    required this.size,
    required this.rotation,
    required this.color,
    this.opacity = 1.0,
  });
}

// Custom painters for onboarding animations
class ChartGridPainter extends CustomPainter {
  final double animValue;

  ChartGridPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    // Draw grid lines
    for (int i = 0; i < 6; i++) {
      double y = size.height * (i / 5.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    for (int i = 0; i < 6; i++) {
      double x = size.width * (i / 5.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Draw animated chart line
    final Paint chartPaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

    final Path path = Path();

    for (int i = 0; i < 20; i++) {
      double x = size.width * (i / 19.0);
      double normalY = sin((i / 19.0 + animValue) * 4 * pi) * 0.4 + 0.5;
      double y = size.height * (1.0 - normalY);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, chartPaint);
  }

  @override
  bool shouldRepaint(ChartGridPainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}

class ShieldPainter extends CustomPainter {
  final double animValue;

  ShieldPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint shieldPaint =
        Paint()
          ..color = Colors.purple.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;

    final Paint glowPaint =
        Paint()
          ..color = Colors.purple.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    // Draw shield shape
    final Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width * 0.9, size.height * 0.2);
    path.quadraticBezierTo(
      size.width,
      size.height * 0.5,
      size.width * 0.5,
      size.height,
    );
    path.quadraticBezierTo(
      0,
      size.height * 0.5,
      size.width * 0.1,
      size.height * 0.2,
    );
    path.close();

    // Animated glow
    final double breathe = (sin(animValue * 2 * pi) + 1) / 2;
    glowPaint.strokeWidth = 6.0 + (breathe * 8.0);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, shieldPaint);
  }

  @override
  bool shouldRepaint(ShieldPainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}

class ParticlePainter extends CustomPainter {
  final List<OnboardingParticle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint =
          Paint()
            ..color = particle.color.withOpacity(particle.opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class HexagonPainter extends CustomPainter {
  final List<HexagonTile> hexTiles;
  final double animValue;

  HexagonPainter(this.hexTiles, this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var tile in hexTiles) {
      final paint =
          Paint()
            ..color = tile.color.withOpacity(
              tile.opacity * (0.3 + (sin(animValue * 2 * pi) + 1) / 4),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;

      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (i * pi / 3) + tile.rotation + (animValue * 0.2);
        final x = tile.position.dx + cos(angle) * tile.size;
        final y = tile.position.dy + sin(angle) * tile.size;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class FuturisticBackgroundPainter extends CustomPainter {
  final double animValue;
  final int pageIndex;

  FuturisticBackgroundPainter(this.animValue, this.pageIndex);

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient background
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Different color schemes based on page index
    List<Color> gradientColors;
    switch (pageIndex % 4) {
      case 0:
        gradientColors = [
          const Color(0xFF1A237E).withOpacity(0.7),
          const Color(0xFF3949AB).withOpacity(0.7),
        ];
        break;
      case 1:
        gradientColors = [
          const Color(0xFF004D40).withOpacity(0.7),
          const Color(0xFF00796B).withOpacity(0.7),
        ];
        break;
      case 2:
        gradientColors = [
          const Color(0xFF880E4F).withOpacity(0.7),
          const Color(0xFFC2185B).withOpacity(0.7),
        ];
        break;
      case 3:
        gradientColors = [
          const Color(0xFF4A148C).withOpacity(0.7),
          const Color(0xFF7B1FA2).withOpacity(0.7),
        ];
        break;
      default:
        gradientColors = [
          const Color(0xFF1A237E).withOpacity(0.7),
          const Color(0xFF3949AB).withOpacity(0.7),
        ];
    }

    final Paint gradientPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);

    // Draw grid lines
    final Paint gridPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 0.5;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical lines
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw animated accent lines
    final Paint accentPaint =
        Paint()
          ..color = Colors.white.withOpacity(
            0.3 + (sin(animValue * 2 * pi) * 0.1),
          )
          ..strokeWidth = 2.0;

    // Horizontal accent line
    double yPos = (size.height * 0.3) + (sin(animValue * 2 * pi) * 20);
    canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), accentPaint);

    // Vertical accent line
    double xPos = (size.width * 0.7) + (cos(animValue * 2 * pi) * 20);
    canvas.drawLine(Offset(xPos, 0), Offset(xPos, size.height), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({Key? key, required this.onFinish}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _particleAnimationController;

  // For particle effects
  final List<OnboardingParticle> _particles = [];
  final int _particleCount = 15;

  // For animated background
  final List<HexagonTile> _hexTiles = [];
  final int _hexTileCount = 20;

  // Colors for futuristic theme
  final Color _primaryColor = Colors.blue.shade800;
  final Color _accentColor = Colors.lightBlueAccent;

  // Dynamic onboarding data
  final List<Map<String, String>> _pages = [
    {
      'title': 'Smart Financial Management',
      'subtitle': 'Take control of your finances with powerful tracking tools',
      'button': 'Get Started',
      'footer': 'Already have an account? Sign in',
    },
    {
      'title': 'Watch Your Savings Grow',
      'subtitle':
          'Set goals and track your progress with beautiful visualizations',
      'button': 'Next',
      'footer': '',
    },
    {
      'title': 'Insightful Analytics',
      'subtitle': 'Understand your spending patterns with AI-powered insights',
      'button': 'Next',
      'footer': '',
    },
    {
      'title': 'Secure and Private',
      'subtitle': 'Your financial data is protected with bank-level security',
      'button': 'Get Started',
      'footer': '',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Set preferred orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });

    // Initialize animation controllers
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _particleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Start animations
    _backgroundAnimationController.repeat(reverse: true);
    _pulseAnimationController.repeat(reverse: true);
    _particleAnimationController.repeat();

    // Initialize particles
    _initializeParticles();

    // Initialize hexagon tiles
    _initializeHexTiles();
  }

  // Initialize particles for background effect
  void _initializeParticles() {
    final random = Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        OnboardingParticle(
          position: Offset(
            random.nextDouble() * 400,
            random.nextDouble() * 800,
          ),
          velocity: Offset(
            (random.nextDouble() - 0.5) * 1.5,
            (random.nextDouble() - 0.5) * 1.5,
          ),
          color: Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.1),
          size: random.nextDouble() * 6 + 1,
        ),
      );
    }
  }

  // Initialize hexagon tiles for futuristic grid effect
  void _initializeHexTiles() {
    final random = Random();
    for (int i = 0; i < _hexTileCount; i++) {
      _hexTiles.add(
        HexagonTile(
          position: Offset(
            random.nextDouble() * 400,
            random.nextDouble() * 800,
          ),
          size: random.nextDouble() * 30 + 20,
          rotation: random.nextDouble() * pi,
          color:
              HSLColor.fromAHSL(
                0.7,
                random.nextDouble() * 360,
                0.7,
                0.5,
              ).toColor(),
          opacity: random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimationController.dispose();
    _contentAnimationController.dispose();
    _pulseAnimationController.dispose();
    _particleAnimationController.dispose();

    // Reset orientation settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  void _onNext() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page, mark onboarding as completed and navigate to login
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_onboarding', true);
        debugPrint(
          '⚠️ Onboarding completed - setting has_seen_onboarding flag to true',
        );

        if (mounted) {
          try {
            widget.onFinish();
          } catch (e) {
            debugPrint('⚠️ Error in onFinish callback: $e');
            // Fallback navigation if the callback fails
            if (mounted && context.mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/signin', (route) => false);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error completing onboarding: $e');
        // Try to navigate to sign-in even if saving preferences fails
        if (mounted && context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (route) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final primaryColor = const Color(0xFF4866FF);

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 72, 102, 255),
                      Color.fromARGB(255, 94, 124, 255),
                      Color.fromARGB(255, 123, 148, 255),
                    ],
                    stops: [
                      0.0 + (_backgroundAnimationController.value * 0.2),
                      0.5 + (_backgroundAnimationController.value * 0.1),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating financial icons (animated)
          ...List.generate(10, (index) {
            final random = index * 0.1;
            return Positioned(
              top: size.height * (0.1 + random * 0.8),
              left:
                  size.width *
                  ((index % 2 == 0) ? 0.1 + random * 0.3 : 0.6 + random * 0.3),
              child: AnimatedBuilder(
                animation: _backgroundAnimationController,
                builder: (context, child) {
                  final offset =
                      sin(
                        _backgroundAnimationController.value * 2 * 3.14 + index,
                      ) *
                      10;
                  return Transform.translate(
                    offset: Offset(offset, offset * 0.5),
                    child: Opacity(
                      opacity: 0.1 + random * 0.2,
                      child: Icon(
                        _getFinancialIcon(index),
                        size: 20 + random * 30,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            );
          }),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
                    child: TextButton(
                      onPressed:
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/signin',
                          ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _contentAnimationController.reset();
                      _contentAnimationController.forward();
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SafeArea(
                          bottom: true,
                          minimum: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated Icon
                              FadeIn(
                                duration: const Duration(milliseconds: 800),
                                child: SizedBox(
                                  height: size.height * 0.35,
                                  child: AnimatedBuilder(
                                    animation: _backgroundAnimationController,
                                    builder: (context, child) {
                                      return _buildAnimatedVisual(
                                        index,
                                        context,
                                        size,
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Title
                              FadeInUp(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 300),
                                from: 30,
                                child: Text(
                                  _pages[index]['title']!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Subtitle
                              FadeInUp(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 500),
                                from: 30,
                                child: Text(
                                  _pages[index]['subtitle']!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Page indicators
                              FadeInUp(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 700),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _pages.length,
                                    (i) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: _currentPage == i ? 24 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color:
                                            _currentPage == i
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow:
                                            _currentPage == i
                                                ? [
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                                : [],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Next button
                              FadeInUp(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 900),
                                child: Container(
                                  width: double.infinity,
                                  height: 56,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _onNext,
                                    child: Text(
                                      index == _pages.length - 1
                                          ? 'Get Started'
                                          : 'Next',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Footer text (Sign in link)
                              if (_pages[index]['footer']!.isNotEmpty)
                                FadeInUp(
                                  duration: const Duration(milliseconds: 800),
                                  delay: const Duration(milliseconds: 1100),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 16,
                                      bottom: 24,
                                    ),
                                    child: TextButton(
                                      onPressed:
                                          () => Navigator.pushReplacementNamed(
                                            context,
                                            '/signin',
                                          ),
                                      child: Text(
                                        _pages[index]['footer']!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get financial icons
  IconData _getFinancialIcon(int index) {
    final icons = [
      Icons.account_balance_wallet,
      Icons.monetization_on,
      Icons.savings,
      Icons.credit_card,
      Icons.currency_exchange,
      Icons.attach_money,
      Icons.pie_chart,
      Icons.trending_up,
      Icons.account_balance,
      Icons.payments,
    ];
    return icons[index % icons.length];
  }

  // Build unique animated visuals for each onboarding page
  Widget _buildAnimatedVisual(int index, BuildContext context, Size size) {
    final animValue = _backgroundAnimationController.value;
    final breathValue = (sin(animValue * 2 * pi) + 1) / 2;

    switch (index) {
      case 0: // Smart Financial Management
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating ring
            Transform.rotate(
              angle: animValue * 2 * pi,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.amber.withOpacity(0.1),
                      Colors.amber.withOpacity(0.5),
                      Colors.amber.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
            // Middle pulsing ring
            Transform.scale(
              scale: 0.8 + (breathValue * 0.1),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white24, width: 8),
                ),
              ),
            ),
            // Floating coins
            ...List.generate(6, (i) {
              return Transform.translate(
                offset: Offset(
                  sin((animValue * 2 * pi) + (i * pi / 3)) * 60,
                  cos((animValue * 2 * pi) + (i * pi / 3)) * 60,
                ),
                child: Transform.rotate(
                  angle: animValue * 4 * pi,
                  child: Icon(
                    Icons.monetization_on,
                    size: 25 + (i % 3) * 5.0,
                    color: Colors.amber,
                  ),
                ),
              );
            }),
            // Center wallet icon
            Icon(Icons.account_balance_wallet, size: 70, color: Colors.white),
          ],
        );

      case 1: // Watch Your Savings Grow
        return Stack(
          alignment: Alignment.center,
          children: [
            // Growth circle with animated size
            Transform.scale(
              scale: 0.7 + (breathValue * 0.3),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.15),
                ),
              ),
            ),
            // Growth bars
            ...List.generate(5, (i) {
              final barHeight =
                  20.0 + (i * 15) + (i == 4 ? (30 * breathValue) : 0);
              final xOffset = (i - 2) * 30.0;
              return Positioned(
                bottom: 70,
                left: size.width * 0.5 - 15 + xOffset,
                child: Container(
                  width: 20,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.4 + (i * 0.1)),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                ),
              );
            }),
            // Animated coin stack
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, -20 - (10 * breathValue)),
                  child: Icon(
                    Icons.monetization_on,
                    size: 40,
                    color: Colors.amber,
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -15 - (5 * breathValue)),
                  child: Icon(
                    Icons.monetization_on,
                    size: 40,
                    color: Colors.amber.shade600,
                  ),
                ),
                Icon(
                  Icons.monetization_on,
                  size: 40,
                  color: Colors.amber.shade800,
                ),
              ],
            ),
          ],
        );

      case 2: // Insightful Analytics
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background chart grid
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CustomPaint(painter: ChartGridPainter(animValue)),
            ),
            // Floating data points
            ...List.generate(8, (i) {
              final angle = (i / 8.0) * 2 * pi;
              final radius =
                  70.0 + (sin(angle * 3 + (animValue * 2 * pi)) * 20.0);
              return Positioned(
                left: 100.0 + cos(angle) * radius,
                top: 100.0 + sin(angle) * radius,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
            // Central analytics icon
            Icon(Icons.analytics, size: 60, color: Colors.white),
          ],
        );

      case 3: // Secure and Private
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer security shield
            Transform.scale(
              scale: 0.9 + (breathValue * 0.1),
              child: Container(
                width: 180,
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100).copyWith(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Center lock icon
            const Icon(Icons.lock, size: 50, color: Colors.white),
            // Orbiting security elements
            ...List.generate(3, (i) {
              final angle = animValue * 2 * pi + (i * (2 * pi / 3));
              return Transform.translate(
                offset: Offset(cos(angle) * 80.0, sin(angle) * 80.0),
                child: Icon(
                  [Icons.security, Icons.verified_user, Icons.shield][i],
                  size: 25,
                  color: Colors.white70,
                ),
              );
            }),
          ],
        );

      default:
        return Container(); // Fallback
    }
  }

  // End of _buildAnimatedVisual method
}
