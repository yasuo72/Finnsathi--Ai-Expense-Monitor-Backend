import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/profile_service.dart';
import '../../services/gamification_service.dart';
import '../../services/finance_service.dart';
import '../../models/finance_models.dart';
import 'widgets/level_progress_card.dart';
import 'widgets/savings_challenge_card.dart';
import 'widgets/achievement_card.dart';
import 'widgets/daily_challenges_card.dart';
import 'widgets/financial_health_score_card.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({Key? key}) : super(key: key);

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ProfileService _profileService;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Get profile service immediately to avoid late initialization errors
    _profileService = Provider.of<ProfileService>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final gamificationService = Provider.of<GamificationService>(
        context,
        listen: false,
      );
      // If the service is already initialized, use cached data immediately
      if (gamificationService.isInitialized) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _errorMessage = '';
        });

        // Light background refresh for newer data
        gamificationService.refreshFromBackend();
        return;
      }

      // First-time load: show loader and record activity
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Record activity in gamification service to update streak and local data
      await gamificationService.recordActivity();

      if (!mounted) return;

      // Show UI as soon as local data is ready
      setState(() {
        _isLoading = false;
      });

      // Refresh from backend in the background so we don't block screen opening
      // Any updated data will automatically rebuild via the providers
      gamificationService.refreshFromBackend();
    } catch (e) {
      debugPrint('Error in gamification screen: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Finance Quest',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            ),
          ),
        ),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? _buildErrorWidget()
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildUserLevelSection(),
            const SizedBox(height: 24),
            _buildDailyChallengesSection(),
            const SizedBox(height: 24),
            _buildChallengesSection(),
            const SizedBox(height: 24),
            _buildAchievementsSection(),
            const SizedBox(height: 24),
            _buildFinancialHealthScoreSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLevelSection() {
    return Consumer<GamificationService>(
      builder: (context, gamificationService, child) {
        // Use GamificationService for XP/Level (syncs with backend)
        final currentXP = gamificationService.currentXP;
        final currentLevel = gamificationService.currentLevel;
        final nextLevel = currentLevel + 1;
        final levelProgress = gamificationService.getLevelProgress();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Financial Journey',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            LevelProgressCard(
              level: 'Level $currentLevel',
              nextLevel: 'Level $nextLevel',
              progress: levelProgress,
              points: currentXP,
              animationController: _animationController,
            ),
          ],
        );
      },
    );
  }

  // Message to show when no savings goals exist
  Widget _buildNoSavingsGoalsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 48,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'No Savings Challenges',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a savings goal to start a new challenge',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection() {
    final financeService = Provider.of<FinanceService>(context, listen: false);
    final savingsGoals = financeService.savingsGoals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Challenges',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        savingsGoals.isEmpty
            ? _buildNoSavingsGoalsMessage()
            : Column(
              children: [
                ...savingsGoals.take(2).map((goal) {
                  // Calculate days left based on target date
                  final now = DateTime.now();
                  final daysLeft =
                      goal.targetDate != null
                          ? goal.targetDate!
                              .difference(now)
                              .inDays
                              .clamp(0, 999)
                          : 30; // Default to 30 days if no target date

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SavingsChallengeCard(
                      title: goal.title,
                      targetAmount: goal.targetAmount,
                      currentAmount: goal.currentAmount,
                      daysLeft: daysLeft,
                      animationController: _animationController,
                    ),
                  );
                }).toList(),
              ],
            ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final profile = _profileService.currentProfile;

    // Safety check to ensure profile and achievements are available
    if (profile.achievements.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No achievements yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete challenges to unlock achievements',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: profile.achievements.length,
            itemBuilder: (context, index) {
              final achievement = profile.achievements[index];
              final delay = index * 0.2;

              return AchievementCard(
                achievement: achievement,
                animationController: _animationController,
                delay: delay,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? 'Error: $_errorMessage'
                  : 'There was an error loading the gamification data',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Challenges',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        DailyChallengesCard(animationController: _animationController),
      ],
    );
  }

  Widget _buildFinancialHealthScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Health',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        FinancialHealthScoreCard(animationController: _animationController),
      ],
    );
  }
}
