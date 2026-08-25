import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CurvedNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CurvedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CurvedNavBar> createState() => _CurvedNavBarState();
}

class _CurvedNavBarState extends State<CurvedNavBar> {
  final GlobalKey<CurvedNavigationBarState> _navBarKey = GlobalKey();
  
  // Define tab icons
  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.insert_chart_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.emoji_events_rounded, // Gamification icon
    Icons.shopping_bag_rounded,
    Icons.person_rounded,
  ];
  
  // Colors for the icons
  final List<Color> _activeColors = [
    const Color(0xFFFFAA00), // Orange/amber for home
    const Color(0xFF9747FF), // Purple for stats
    const Color(0xFF00C9FF), // Blue for wallet
    const Color(0xFFFFD700), // Gold for gamification
    const Color(0xFFFF6B8B), // Pink for shop
    const Color(0xFF4CAF50), // Green for profile
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-dependent colors to match the dark theme of the app
    final navBarColor = isDarkMode ? const Color(0xFF1E2126) : Colors.white;
    final backgroundColor = Colors.transparent; // Always transparent background
    final inactiveIconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Container(
      decoration: BoxDecoration(
        // Add a subtle gradient to make the nav bar blend with the background
        gradient: isDarkMode ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF1E2126).withOpacity(0.9),
          ],
        ) : null,
      ),
      child: CurvedNavigationBar(
        key: _navBarKey,
        index: widget.currentIndex,
        height: 60.0, // Slightly smaller height
        items: List.generate(_icons.length, (index) {
          return Icon(
            _icons[index],
            size: 28, // Slightly smaller icons
            color: widget.currentIndex == index 
                ? _activeColors[index]
                : inactiveIconColor,
          );
        }),
        color: navBarColor.withOpacity(isDarkMode ? 0.85 : 1.0), // More transparent in dark mode
        buttonBackgroundColor: navBarColor.withOpacity(isDarkMode ? 0.95 : 1.0),
        backgroundColor: backgroundColor,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          widget.onTap(index);
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
