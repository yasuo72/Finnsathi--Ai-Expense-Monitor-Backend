import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../services/finance_service.dart';
import '../../../models/finance_models.dart';

class FinancialHealthScoreCard extends StatelessWidget {
  final AnimationController animationController;

  const FinancialHealthScoreCard({Key? key, required this.animationController})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Animation setup
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
      ),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
      ),
    );

    return Consumer<FinanceService>(
      builder: (context, financeService, child) {
        // Calculate financial health score
        final score = _calculateFinancialHealthScore(financeService);
        final scoreCategory = _getScoreCategory(score);
        final scoreColor = _getScoreColor(score);
        final advice = _getFinancialAdvice(score, financeService);

        return AnimatedBuilder(
          animation: animationController,
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
                        scoreColor.withOpacity(isDark ? 0.8 : 0.2),
                        scoreColor.withOpacity(isDark ? 0.6 : 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: scoreColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.health_and_safety,
                                color: scoreColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Financial Health Score',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Score display
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            _buildScoreIndicator(context, score, scoreColor),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scoreCategory,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: scoreColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your financial health is ${_getScoreDescription(score)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color:
                                          isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Advice section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Financial Tip',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                advice,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 16.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to a detailed financial overview
                                  Navigator.pushNamed(context, '/statistics');
                                },
                                icon: const Icon(Icons.analytics, size: 18),
                                label: const Text('View Details'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scoreColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Navigate to budgets screen to help improve score
                                  Navigator.pushNamed(context, '/budget');
                                },
                                icon: const Icon(Icons.trending_up, size: 18),
                                label: const Text('Improve Score'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: scoreColor,
                                  side: BorderSide(color: scoreColor),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildScoreIndicator(
    BuildContext context,
    int score,
    Color scoreColor,
  ) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          // Background circle
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 10,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.grey.withOpacity(0.1),
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          // Center text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  '/100',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Calculate financial health score based on various factors
  int _calculateFinancialHealthScore(FinanceService financeService) {
    // Start with a base score
    int score = 40;

    // Factor 1: Savings rate (weight: 30%)
    final savingsRate = financeService.savingsRate;
    if (savingsRate >= 20) {
      score += 30;
    } else if (savingsRate >= 10) {
      score += 20;
    } else if (savingsRate > 0) {
      score += 10;
    }

    // Factor 2: Budget adherence (weight: 15%)
    // Check if user has budgets and if spending is within those budgets
    final budgets = financeService.budgets;
    if (budgets.isNotEmpty) {
      int budgetsWithinLimit = 0;
      for (final budget in budgets) {
        // Calculate current spending for this budget's category
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        final transactions =
            financeService
                .getTransactionsForDateRange(startOfMonth, endOfMonth)
                .where(
                  (t) =>
                      t.type == TransactionType.expense &&
                      t.category == budget.category,
                )
                .toList();

        final spent = transactions.fold(0.0, (sum, t) => sum + t.amount);

        // Check if within budget
        if (spent <= budget.limit) {
          budgetsWithinLimit++;
        }
      }

      // Add points based on percentage of budgets within limit
      final adherenceRate =
          budgets.isEmpty ? 0 : budgetsWithinLimit / budgets.length;
      if (adherenceRate >= 0.8) {
        score += 15;
      } else if (adherenceRate >= 0.5) {
        score += 10;
      } else if (adherenceRate > 0) {
        score += 5;
      }
    }

    // Factor 3: Transaction consistency (weight: 15%)
    // Check if user is consistently tracking transactions
    final transactions = financeService.transactions;
    if (transactions.isNotEmpty) {
      // Get transactions from the last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final recentTransactions = financeService.getTransactionsForDateRange(
        thirtyDaysAgo,
        now,
      );

      // Calculate how many days had at least one transaction
      final daysWithTransactions =
          recentTransactions
              .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
              .toSet()
              .length;

      // Add points based on consistency
      if (daysWithTransactions >= 20) {
        score += 15; // Very consistent
      } else if (daysWithTransactions >= 10) {
        score += 10; // Moderately consistent
      } else if (daysWithTransactions > 0) {
        score += 5; // Somewhat consistent
      }
    }

    // Factor 4: Savings goals progress (weight: 15%)
    final savingsGoals = financeService.savingsGoals;
    if (savingsGoals.isNotEmpty) {
      int goalsOnTrack = 0;
      for (final goal in savingsGoals) {
        if (goal.targetDate != null) {
          // Calculate expected progress based on time elapsed
          final now = DateTime.now();
          final totalDuration =
              goal.targetDate!.difference(goal.createdDate).inDays;
          final elapsedDuration = now.difference(goal.createdDate).inDays;

          if (totalDuration > 0) {
            final expectedProgress = elapsedDuration / totalDuration;
            final actualProgress = goal.currentAmount / goal.targetAmount;

            // If actual progress is at least 80% of expected progress, consider on track
            if (actualProgress >= expectedProgress * 0.8) {
              goalsOnTrack++;
            }
          }
        }
      }

      // Add points based on goals on track
      final onTrackRate =
          savingsGoals.isEmpty ? 0 : goalsOnTrack / savingsGoals.length;
      if (onTrackRate >= 0.8) {
        score += 15;
      } else if (onTrackRate >= 0.5) {
        score += 10;
      } else if (onTrackRate > 0) {
        score += 5;
      }
    }

    // Ensure score is between 0-100
    return score.clamp(0, 100);
  }

  // Get score category based on score value
  String _getScoreCategory(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Very Good';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Needs Improvement';
    return 'Poor';
  }

  // Get score description
  String _getScoreDescription(int score) {
    if (score >= 90) return 'excellent! You\'re a financial master!';
    if (score >= 75) return 'very good. You\'re on the right track!';
    if (score >= 60) return 'good, but there\'s room for improvement.';
    if (score >= 40) return 'fair. Consider making some changes.';
    if (score >= 20) return 'in need of attention. Let\'s work on it!';
    return 'concerning. Time for a financial reset!';
  }

  // Get score color
  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.lime;
    if (score >= 40) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  // Get personalized financial advice based on score and financial data
  String _getFinancialAdvice(int score, FinanceService financeService) {
    // Get specific advice based on financial data
    final savingsRate = financeService.savingsRate;
    final hasBudgets = financeService.budgets.isNotEmpty;
    final hasSavingsGoals = financeService.savingsGoals.isNotEmpty;
    final transactions = financeService.transactions;
    final hasRecentTransactions =
        transactions.isNotEmpty &&
        transactions.any(
          (t) =>
              t.date.isAfter(DateTime.now().subtract(const Duration(days: 7))),
        );

    if (score >= 80) {
      if (savingsRate < 20) {
        return "You're doing great! Consider increasing your savings rate to 20% or more for long-term financial security.";
      } else if (!hasSavingsGoals) {
        return "Excellent financial health! Consider setting up specific savings goals for future major purchases or investments.";
      } else {
        return "Outstanding financial management! You might want to explore investment opportunities to grow your wealth further.";
      }
    } else if (score >= 60) {
      if (!hasBudgets) {
        return "You're on the right track. Creating budgets for your major expense categories could help you improve further.";
      } else if (savingsRate < 10) {
        return "Good progress! Try to increase your savings rate to at least 10% to build more financial security.";
      } else {
        return "Solid financial foundation! Consider reviewing your expenses to find areas where you could save more.";
      }
    } else if (score >= 40) {
      if (!hasRecentTransactions) {
        return "Start by consistently tracking all your transactions to get a clear picture of your spending habits.";
      } else if (!hasBudgets) {
        return "Creating a budget for your major expense categories would help you manage your finances better.";
      } else {
        return "Focus on sticking to your budgets and finding ways to reduce unnecessary expenses.";
      }
    } else {
      if (!hasRecentTransactions) {
        return "Begin tracking all your income and expenses to understand where your money is going.";
      } else if (savingsRate <= 0) {
        return "Work on reducing expenses to ensure your income exceeds your spending, even by a small amount.";
      } else {
        return "Focus on building an emergency fund and reducing unnecessary expenses to improve your financial stability.";
      }
    }
  }
}
