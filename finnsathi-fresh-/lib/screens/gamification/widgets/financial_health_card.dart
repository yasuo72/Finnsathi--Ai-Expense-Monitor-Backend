import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class FinancialHealthCard extends StatelessWidget {
  final double savingsRate;
  final int totalTransactions;
  final AnimationController animationController;

  const FinancialHealthCard({
    Key? key,
    required this.savingsRate,
    required this.totalTransactions,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final progressAnimation = Tween<double>(
      begin: 0.0,
      end: savingsRate / 100,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade800,
                Colors.indigo.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Transform.rotate(
                    angle: rotateAnimation.value,
                    child: const Icon(
                      Icons.insights,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Health Score',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularProgress(context, progressAnimation.value),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScoreItem(
                          'Savings Rate',
                          '${savingsRate.toStringAsFixed(1)}%',
                          _getSavingsRateColor(savingsRate),
                          _getSavingsRateText(savingsRate),
                        ),
                        const SizedBox(height: 16),
                        _buildScoreItem(
                          'Transactions',
                          '$totalTransactions',
                          Colors.blue,
                          'Active',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getFinancialAdvice(savingsRate),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCircularProgress(BuildContext context, double progress) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(progress * 100)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Score',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(
    String title,
    String value,
    Color valueColor,
    String status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: valueColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.lightGreen;
    } else if (score >= 40) {
      return Colors.amber;
    } else if (score >= 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getSavingsRateColor(double rate) {
    if (rate >= 30) {
      return Colors.green;
    } else if (rate >= 20) {
      return Colors.lightGreen;
    } else if (rate >= 10) {
      return Colors.amber;
    } else if (rate >= 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getSavingsRateText(double rate) {
    if (rate >= 30) {
      return 'Excellent';
    } else if (rate >= 20) {
      return 'Very Good';
    } else if (rate >= 10) {
      return 'Good';
    } else if (rate >= 5) {
      return 'Fair';
    } else {
      return 'Needs Work';
    }
  }

  String _getFinancialAdvice(double savingsRate) {
    if (savingsRate >= 30) {
      return 'Great job! Consider investing more of your savings for long-term growth.';
    } else if (savingsRate >= 20) {
      return 'You\'re doing well! Try to increase your savings rate by 5% for better financial security.';
    } else if (savingsRate >= 10) {
      return 'Good start! Look for ways to reduce non-essential expenses to boost your savings.';
    } else if (savingsRate >= 5) {
      return 'Try creating a budget to track your spending and find opportunities to save more.';
    } else {
      return 'Focus on building an emergency fund first, then work on reducing expenses.';
    }
  }
}
