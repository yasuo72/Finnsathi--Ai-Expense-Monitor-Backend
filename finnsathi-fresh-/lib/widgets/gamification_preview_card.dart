import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/profile_service.dart';
import '../services/gamification_service.dart';
import '../screens/gamification/gamification_screen.dart';

class GamificationPreviewCard extends StatefulWidget {
  const GamificationPreviewCard({super.key});

  @override
  State<GamificationPreviewCard> createState() =>
      _GamificationPreviewCardState();
}

class _GamificationPreviewCardState extends State<GamificationPreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Timer _backgroundTimer;
  String _backgroundUrl = '';
  bool _isLoading = true;
  bool _hasError = false;

  // Challenge data
  Map<String, dynamic>? _currentChallenge;
  bool _hasChallenges = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Load initial background
    _loadRandomBackground();

    // Set up timer to change background every 10 minutes
    _backgroundTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _loadRandomBackground();
    });
    
    // Load challenge data from service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChallengeData();
    });
  }
  
  // Load challenge data from the gamification service
  void _loadChallengeData() {
    try {
      final gamificationService = Provider.of<GamificationService>(context, listen: false);
      final challenges = gamificationService.dailyChallenges;
      
      if (challenges.isNotEmpty) {
        // Select a random challenge that isn't completed yet
        final incompleteChallenges = challenges.where((c) => !c.isCompleted).toList();
        
        if (incompleteChallenges.isNotEmpty) {
          final challenge = incompleteChallenges[math.Random().nextInt(incompleteChallenges.length)];
          setState(() {
            _currentChallenge = {
              'title': challenge.title,
              'description': challenge.description,
              'icon': Icons.star, // Default icon
              'color': Theme.of(context).primaryColor,
              'progress': challenge.progress,
            };
            _hasChallenges = true;
            _isLoading = false;
          });
        } else if (challenges.isNotEmpty) {
          // If all challenges are completed, just show one of them
          final challenge = challenges[math.Random().nextInt(challenges.length)];
          setState(() {
            _currentChallenge = {
              'title': challenge.title,
              'description': challenge.description,
              'icon': Icons.check_circle, // Completed icon
              'color': Colors.green,
              'progress': 1.0, // Full progress
            };
            _hasChallenges = true;
            _isLoading = false;
          });
        }
      } else {
      // No challenges available
      setState(() {
        _currentChallenge = null;
        _hasChallenges = false;
        _isLoading = false;
      });
      }
    } catch (e) {
    debugPrint('Error loading challenge data: $e');
    // Set error state without dummy data
    setState(() {
      _currentChallenge = null;
      _hasChallenges = false;
      _isLoading = false;
      _hasError = true;
    });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundTimer.cancel();
    super.dispose();
  }

  Future<void> _loadRandomBackground() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use Unsplash API for random backgrounds
      final response = await http.get(
        Uri.parse(
          'https://source.unsplash.com/random/800x400/?abstract,digital,future',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _backgroundUrl = response.request?.url.toString() ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _navigateToGamificationScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const GamificationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(0.0, 1.0);
          var end = Offset.zero;
          var curve = Curves.easeOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileService = Provider.of<ProfileService>(context);
    final profile = profileService.currentProfile;

    // Animations
    final pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Futuristic section header
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.amber.withOpacity(0.7),
                          Colors.amber.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Finance Quest',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.amber.shade700, Colors.amber.shade500],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToGamificationScreen,
                    borderRadius: BorderRadius.circular(30),
                    splashColor: Colors.white24,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main gamification card
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: pulseAnimation.value,
              child: GestureDetector(
                onTap: _navigateToGamificationScreen,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image with loading state
                        _isLoading
                            ? Container(
                              color:
                                  isDark ? Colors.grey[850] : Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : _hasError
                            ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.purple.shade900,
                                    Colors.indigo.shade900,
                                  ],
                                ),
                              ),
                            )
                            : Image.network(
                              _backgroundUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.purple.shade900,
                                        Colors.indigo.shade900,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Level indicator
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Level ${profile.membershipLevel}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${profile.points} XP',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // Current challenge
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (_currentChallenge != null) 
                                          ? (_currentChallenge!['color'] as Color).withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _currentChallenge != null
                                          ? (_currentChallenge!['icon'] as IconData)
                                          : _hasError ? Icons.error_outline : Icons.notifications_none,
                                      color: _currentChallenge != null
                                          ? (_currentChallenge!['color'] as Color)
                                          : _hasError ? Colors.red : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _currentChallenge != null
                                              ? (_currentChallenge!['title'] as String)
                                              : _hasError
                                                  ? 'Unable to load challenges'
                                                  : _isLoading
                                                      ? 'Loading challenges...'
                                                      : 'No active challenges',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _currentChallenge != null
                                              ? (_currentChallenge!['description'] as String)
                                              : _hasError
                                                  ? 'Please check your connection and try again'
                                                  : _isLoading
                                                      ? 'Please wait while we load your challenges'
                                                      : 'Check back later for new challenges',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (_hasChallenges)
                                          Text(
                                            'Complete this challenge to earn rewards!',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Progress bar
                              Stack(
                                children: [
                                  // Background
                                  Container(
                                    height: 8,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  // Progress
                                  if (_currentChallenge != null)
                                  Container(
                                    height: 8,
                                    width:
                                        MediaQuery.of(context).size.width *
                                        (_currentChallenge!['progress'] as double) *
                                        0.8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          (_currentChallenge!['color'] as Color)
                                              .withOpacity(0.7),
                                          (_currentChallenge!['color'] as Color),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_currentChallenge!['color'] as Color)
                                              .withOpacity(0.5),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Animated particles effect
                        CustomPaint(
                          painter: ParticlesPainter(
                            animation: _animationController,
                            color: _currentChallenge != null
                                ? (_currentChallenge!['color'] as Color)
                                : _hasError ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Custom painter for animated particles
class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final List<Particle> particles = [];

  ParticlesPainter({required this.animation, required this.color})
    : super(repaint: animation) {
    // Generate random particles
    for (int i = 0; i < 20; i++) {
      particles.add(
        Particle(
          position: Offset(
            math.Random().nextDouble() * 400,
            math.Random().nextDouble() * 200,
          ),
          size: 1 + math.Random().nextDouble() * 3,
          speed: 0.5 + math.Random().nextDouble() * 1.5,
        ),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withOpacity(0.6)
          ..style = PaintingStyle.fill;

    for (var particle in particles) {
      // Update position based on animation value
      final offset = Offset(
        (particle.position.dx + animation.value * particle.speed * 50) %
            size.width,
        (particle.position.dy + math.sin(animation.value * math.pi * 2) * 5) %
            size.height,
      );

      // Draw the particle
      canvas.drawCircle(
        offset,
        particle.size * (0.8 + animation.value * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

// Particle class for animation
class Particle {
  Offset position;
  double size;
  double speed;

  Particle({required this.position, required this.size, required this.speed});
}
