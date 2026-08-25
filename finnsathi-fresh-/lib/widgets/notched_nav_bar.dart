import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class NotchedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NotchedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedNotchedNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}

class AnimatedNotchedNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AnimatedNotchedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AnimatedNotchedNavBar> createState() => _AnimatedNotchedNavBarState();
}

class _AnimatedNotchedNavBarState extends State<AnimatedNotchedNavBar> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Track which button is being pressed (if any)
  int? _pressedButtonIndex;
  bool get _isButtonPressed => _pressedButtonIndex != null;
  
  // Define tab icons and labels
  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.insert_chart_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.shopping_bag_rounded,
    Icons.person_rounded,
  ];
  
  // Not used in this design but keeping for future reference
  final List<String> _labels = [
    'Home',
    'Stats',
    'Wallet',
    'Shop',
    'Profile',
  ];
  
  // Colors for the floating button
  final List<Color> _activeColors = [
    const Color(0xFFFFAA00), // Orange/amber for home
    const Color(0xFF9747FF), // Purple for stats
    const Color(0xFF00C9FF), // Blue for wallet
    const Color(0xFFFF6B8B), // Pink for shop
    const Color(0xFF4CAF50), // Green for profile
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedNotchedNavBar oldWidget) {
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.reset();
      _animationController.forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2D2D2D) : const Color(0xFF333333);
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width / 5;
    
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main navigation bar
        Container(
          height: 70,
          margin: const EdgeInsets.only(top: 15), // Space for the floating button
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background with curved top
              CustomPaint(
                size: Size(width, 70),
                painter: NotchedNavBarPainter(
                  position: widget.currentIndex,
                  color: _activeColors[widget.currentIndex],
                  animationValue: _animation.value,
                  isDark: isDark,
                  bgColor: bgColor,
                  isButtonPressed: _isButtonPressed,
                  pressedButtonIndex: _pressedButtonIndex,
                ),
              ),
              
              // Nav items
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_icons.length, (index) {
                      return _buildNavItem(index, isDark);
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Floating circular button
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: _pressedButtonIndex == widget.currentIndex ? -15 : 0, // Move up when pressed
          left: (itemWidth * widget.currentIndex) + (itemWidth / 2) - 25,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() {
                _pressedButtonIndex = widget.currentIndex;
              });
            },
            onTapUp: (_) {
              setState(() {
                _pressedButtonIndex = null;
              });
              // Handle the tap
              widget.onTap(widget.currentIndex);
            },
            onTapCancel: () {
              setState(() {
                _pressedButtonIndex = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _activeColors[widget.currentIndex],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _activeColors[widget.currentIndex].withOpacity(0.3),
                    blurRadius: _isButtonPressed ? 12 : 8,
                    spreadRadius: _isButtonPressed ? 3 : 2,
                    offset: Offset(0, _isButtonPressed ? 1 : 2),
                  ),
                ],
              ),
              child: Icon(
                _icons[widget.currentIndex],
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        
        // Center indicator
        Positioned(
          bottom: 10,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 1.0,
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final bool isSelected = widget.currentIndex == index;
    final bool isPressed = _pressedButtonIndex == index;
    final Color iconColor = isSelected 
        ? Colors.white 
        : Colors.white.withOpacity(0.7);
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressedButtonIndex = index;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressedButtonIndex = null;
        });
        // Handle the tap
        widget.onTap(index);
      },
      onTapCancel: () {
        setState(() {
          _pressedButtonIndex = null;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Only show icon if not selected (selected shows in floating button)
            AnimatedOpacity(
              opacity: isSelected ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected 
                      ? Colors.transparent 
                      : Colors.white.withOpacity(isPressed ? 0.2 : 0.1),
                ),
                child: Icon(
                  _icons[index],
                  color: iconColor,
                  size: isPressed ? 20 : 18,
                ),
              ),
            ),
            
            // Don't show any text - cleaner look like in the image
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class NotchedNavBarPainter extends CustomPainter {
  final int position;
  final Color color;
  final double animationValue;
  final bool isDark;
  final Color bgColor;
  final bool isButtonPressed;
  final int? pressedButtonIndex;

  NotchedNavBarPainter({
    required this.position,
    required this.color,
    required this.animationValue,
    required this.isDark,
    required this.bgColor,
    required this.isButtonPressed,
    this.pressedButtonIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double itemWidth = width / 5;
    final double centerX = itemWidth * (position + 0.5);
    
    // Create a path for the navbar with curved top
    final path = Path();
    
    // Constants for the curved top
    final double curveHeight = 15.0;
    final double circleRadius = 25.0;
    
    // Start from bottom-left
    path.moveTo(0, curveHeight);
    
    // Draw left side with rounded corner
    path.quadraticBezierTo(0, 0, 15, 0);
    
    // Draw top edge with curves for each item
    for (int i = 0; i < 5; i++) {
      final double itemCenterX = itemWidth * (i + 0.5);
      
      // If this is the selected item, create a bigger curve for the floating button
      if (i == position) {
        // Draw line to the start of the curve
        path.lineTo(itemCenterX - circleRadius, 0);
        
        // Draw the curve for the floating button - make it deeper when pressed
        final double notchDepth = isButtonPressed ? -curveHeight * 4 : -curveHeight * 2 * animationValue;
        path.quadraticBezierTo(
          itemCenterX, 
          notchDepth, 
          itemCenterX + circleRadius, 
          0
        );
      } else if (pressedButtonIndex == i) {
        // Draw a deeper curve for pressed non-selected items
        final double smallCurveWidth = itemWidth * 0.4;
        path.lineTo(itemCenterX - smallCurveWidth/2, 0);
        path.quadraticBezierTo(
          itemCenterX, 
          -curveHeight * 1.5, // Deeper curve when pressed
          itemCenterX + smallCurveWidth/2, 
          0
        );
      } else {
        // Draw a small curve for non-selected, non-pressed items
        final double smallCurveWidth = itemWidth * 0.4;
        path.lineTo(itemCenterX - smallCurveWidth/2, 0);
        path.quadraticBezierTo(
          itemCenterX, 
          curveHeight/2, 
          itemCenterX + smallCurveWidth/2, 
          0
        );
      }
    }
    
    // Draw right side with rounded corner
    path.lineTo(width - 15, 0);
    path.quadraticBezierTo(width, 0, width, curveHeight);
    
    // Draw bottom edge
    path.lineTo(width, size.height);
    path.lineTo(0, size.height);
    
    // Close the path
    path.close();
    
    // Fill the navbar
    final Paint navPaint = Paint()
      ..color = isDark ? const Color(0xFF2D2D2D) : const Color(0xFF333333)
      ..style = PaintingStyle.fill;
    
    // Add shadow
    canvas.drawShadow(path, Colors.black, 8, true);
    
    // Draw the navbar
    canvas.drawPath(path, navPaint);
    
    // Draw a subtle glow at the selected position
    final Paint glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(centerX, 0),
        30 * animationValue,
        [
          color.withOpacity(0.3 * animationValue),
          color.withOpacity(0.0),
        ],
      );
    
    canvas.drawCircle(
      Offset(centerX, 0),
      30 * animationValue,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant NotchedNavBarPainter oldDelegate) {
    return oldDelegate.position != position || 
           oldDelegate.color != color ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.isDark != isDark ||
           oldDelegate.isButtonPressed != isButtonPressed ||
           oldDelegate.pressedButtonIndex != pressedButtonIndex;
  }
}
