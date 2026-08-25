import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Create fade-in animation
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    
    // Start animation immediately
    _controller.forward();
    
    // Navigate to loading screen after animation completes
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        try {
          Navigator.pushReplacementNamed(context, '/loading');
        } catch (e) {
          debugPrint('Error navigating to loading screen: $e');
          // Fallback to sign-in screen if there's any error
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/signin');
          }
        }
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon could be added here
              Text(
                'Finsaathi',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4866FF),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your AI Expense Monitor',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4866FF).withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
