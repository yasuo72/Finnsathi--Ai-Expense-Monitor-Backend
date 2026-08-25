import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/gamification_service.dart';

class DailyChallengesCard extends StatefulWidget {
  final AnimationController animationController;

  const DailyChallengesCard({Key? key, required this.animationController})
    : super(key: key);

  @override
  State<DailyChallengesCard> createState() => _DailyChallengesCardState();
}

class _DailyChallengesCardState extends State<DailyChallengesCard> {
  Timer? _countdownTimer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    // Update countdown every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTimeRemaining();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    _timeRemaining = _getTimeUntilTomorrow();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Animation setup
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: const Interval(0.3, 0.5, curve: Curves.easeOut),
      ),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: const Interval(0.3, 0.5, curve: Curves.easeOut),
      ),
    );

    return Consumer<GamificationService>(
      builder: (context, gamificationService, child) {
        // Safely access daily challenges, handling potential null or uninitialized state
        final challenges = gamificationService.dailyChallenges;

        return AnimatedBuilder(
          animation: widget.animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDark
                            ? Colors.indigo.shade900
                            : Colors.indigo.shade100,
                        isDark
                            ? Colors.purple.shade900
                            : Colors.purple.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                color:
                                    isDark
                                        ? Colors.amber
                                        : Colors.amber.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Daily Challenges',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Refreshes in $_timeRemaining',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      size: 12,
                                      color:
                                          isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _timeRemaining,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Challenge list
                      if (challenges.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.hourglass_empty,
                                  size: 48,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No challenges available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check back later for new challenges',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? Colors.white60
                                            : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: challenges.length,
                          itemBuilder: (context, index) {
                            final challenge = challenges[index];
                            return _buildChallengeItem(context, challenge);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChallengeItem(BuildContext context, Challenge challenge) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get icon based on challenge type
    IconData challengeIcon = _getChallengeIcon(challenge.type);
    Color challengeColor = _getChallengeColor(challenge.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                challenge.isCompleted
                    ? Colors.green.withOpacity(0.5)
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: challengeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(challengeIcon, color: challengeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          challenge.description,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (challenge.isCompleted)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: challenge.progress,
                        backgroundColor:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                        color:
                            challenge.isCompleted
                                ? Colors.green
                                : challengeColor,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${challenge.currentValue}/${challenge.targetValue}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${challenge.rewardCoins}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.amber : Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.purple, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+${challenge.rewardPoints} XP',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? Colors.purple.shade300
                                  : Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!challenge.isCompleted)
                    ElevatedButton(
                      onPressed: () => _onChallengeAction(context, challenge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: challengeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(80, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _getChallengeActionText(challenge.type),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get the time until 5 AM for challenge refresh
  String _getTimeUntilTomorrow() {
    final now = DateTime.now();

    // Calculate next 5 AM
    DateTime nextReset;
    if (now.hour < 5) {
      // If it's before 5 AM, reset is today at 5 AM
      nextReset = DateTime(now.year, now.month, now.day, 5, 0, 0);
    } else {
      // If it's after 5 AM, reset is tomorrow at 5 AM
      nextReset = DateTime(now.year, now.month, now.day + 1, 5, 0, 0);
    }

    final difference = nextReset.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  // Get icon based on challenge type
  IconData _getChallengeIcon(String type) {
    switch (type) {
      case 'transaction':
        return Icons.receipt_long;
      case 'budget':
        return Icons.account_balance_wallet;
      case 'saving':
        return Icons.savings;
      case 'streak':
        return Icons.calendar_today;
      case 'education':
        return Icons.school;
      default:
        return Icons.emoji_events;
    }
  }

  // Get color based on challenge type
  Color _getChallengeColor(String type) {
    switch (type) {
      case 'transaction':
        return Colors.blue;
      case 'budget':
        return Colors.green;
      case 'saving':
        return Colors.purple;
      case 'streak':
        return Colors.orange;
      case 'education':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }

  // Get action text based on challenge type
  String _getChallengeActionText(String type) {
    switch (type) {
      case 'transaction':
        return 'Add';
      case 'budget':
        return 'Check';
      case 'saving':
        return 'Save';
      case 'streak':
        return 'Done';
      case 'education':
        return 'Learn';
      default:
        return 'Go';
    }
  }

  // Handle challenge action button tap - Navigate to relevant screen
  void _onChallengeAction(BuildContext context, Challenge challenge) {
    // Get category from challenge (backend uses category field)
    final category = (challenge.category ?? challenge.type).toLowerCase();

    // Navigate DIRECTLY to the screen where user can complete the challenge
    switch (category) {
      case 'tracking':
      case 'transaction':
      case 'spending':
        // Navigate directly to add transaction screen
        Navigator.pushNamed(context, '/add-transaction');
        break;

      case 'budgeting':
      case 'budget':
        // Navigate directly to budget management screen
        Navigator.pushNamed(context, '/budget');
        break;

      case 'savings':
      case 'saving':
        // Navigate directly to savings goals screen
        Navigator.pushNamed(context, '/savings-goals');
        break;

      default:
        // For other types (streak, education, etc.), keep user in app and show hint
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Complete: ${challenge.title}')));
    }
  }
}
