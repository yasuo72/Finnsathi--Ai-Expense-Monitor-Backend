import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';

class MembershipCard extends StatelessWidget {
  final String level;
  final double progress;
  final String nextLevel;
  final bool isDark;

  const MembershipCard({
    Key? key,
    required this.level,
    required this.progress,
    required this.nextLevel,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? const Color(0xFF2C2C2C) : primaryColor.withOpacity(0.8),
              isDark ? const Color(0xFF1A1A1A) : primaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membership Level',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          level,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildLevelBadge(level),
                      ],
                    ),
                  ],
                ),
                _buildMembershipIcon(level),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress to $nextLevel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          // Background
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          // Progress
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View Benefits',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String level) {
    Color badgeColor;
    
    switch (level.toLowerCase()) {
      case 'bronze':
        badgeColor = Colors.brown[300]!;
        break;
      case 'silver':
        badgeColor = Colors.grey[400]!;
        break;
      case 'gold':
        badgeColor = Colors.amber;
        break;
      case 'platinum':
        badgeColor = Colors.grey[300]!;
        break;
      case 'diamond':
        badgeColor = Colors.lightBlueAccent;
        break;
      default:
        badgeColor = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor,
          width: 1,
        ),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildMembershipIcon(String level) {
    IconData iconData;
    Color iconColor;
    
    switch (level.toLowerCase()) {
      case 'bronze':
        iconData = Icons.workspace_premium;
        iconColor = Colors.brown[300]!;
        break;
      case 'silver':
        iconData = Icons.workspace_premium;
        iconColor = Colors.grey[400]!;
        break;
      case 'gold':
        iconData = Icons.workspace_premium;
        iconColor = Colors.amber;
        break;
      case 'platinum':
        iconData = Icons.diamond;
        iconColor = Colors.grey[300]!;
        break;
      case 'diamond':
        iconData = Icons.diamond;
        iconColor = Colors.lightBlueAccent;
        break;
      default:
        iconData = Icons.star;
        iconColor = Colors.blue;
    }
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating background effect
          Transform.rotate(
            angle: -math.pi / 4,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Icon
          Icon(
            iconData,
            color: iconColor,
            size: 24,
          ),
        ],
      ),
    );
  }
}
