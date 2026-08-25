// This file contains the Sign In (Login) screen for the Finsaathi Multi app.
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/custom_text_field.dart';
import 'signup_screen_new.dart';
import '../../services/auth_service.dart';
import '../../services/auth_state_service.dart';
import '../../services/google_auth_service.dart';
import 'dart:convert';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF4866FF);
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            child: Column(
              children: [
                // Header with animation
                Container(
                  width: double.infinity,
                  height: size.height * 0.35,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Animated circles for futuristic effect
                      Positioned(
                        top: 50,
                        left: 20,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 90,
                        right: 40,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),

                      // Main header content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Financial security icon - replaced network animation with local icon
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FadeIn(
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                'Welcome Back',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            FadeIn(
                              delay: const Duration(milliseconds: 300),
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                'Login to continue your journey',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Form fields with glassmorphism effect
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: 280,
                    borderRadius: 20,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderGradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.3),
                        primaryColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            child: CustomTextField(
                              hint: 'Email / Phone',
                              icon: Icons.person_outline,
                              controller: _emailController,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: const Duration(milliseconds: 700),
                            child: CustomTextField(
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              obscure: true,
                              controller: _passwordController,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'English',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/forgot-password',
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.poppins(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeInUp(
                            duration: const Duration(milliseconds: 900),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_emailController.text.isEmpty ||
                                      _passwordController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please fill all fields'),
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  // Show loading indicator
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  
                                  try {
                                    print('Attempting login with: Email=${_emailController.text}');
                                    
                                    // Call authentication service
                                    final response = await AuthService.signin(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    );
                                    
                                    print('Received login response with status code: ${response.statusCode}');
                                    
                                    // Hide loading indicator
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    
                                    // Parse the response
                                    Map<String, dynamic> responseData;
                                    try {
                                      responseData = jsonDecode(response.body);
                                      print('Parsed response data: $responseData');
                                    } catch (e) {
                                      print('Error parsing response: $e');
                                      responseData = {'success': false, 'message': 'Invalid response from server'};
                                    }
                                    
                                    if (response.statusCode >= 200 && response.statusCode < 300 && 
                                        (responseData['success'] == true || responseData['token'] != null)) {
                                      
                                      // Save authentication state if not already saved by AuthService
                                      if (responseData['token'] != null) {
                                        await AuthStateService.saveAuthState(
                                          token: responseData['token'],
                                          userData: responseData['user'] ?? {'email': _emailController.text},
                                        );
                                      }
                                      
                                      print('Login successful, navigating to home screen');
                                      
                                      // Trigger immediate data refresh by setting the login flag
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('login_successful', true);
                                      await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
                                      print('🔄 Set login_successful flag to trigger data refresh');
                                      
                                      // Authentication successful, navigate to home screen
                                      // Clear the entire navigation stack to prevent back navigation
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/',
                                        (route) => false,
                                      );
                                    } else {
                                      // Try to parse the error response for more details
                                      String errorMessage = 'Authentication failed';
                                      if (responseData['message'] != null) {
                                        errorMessage = responseData['message'];
                                      } else if (responseData['error'] != null) {
                                        errorMessage = responseData['error'];
                                      }
                                      
                                      print('Login failed: $errorMessage');
                                      
                                      // Authentication failed, show error message
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.red.shade700,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // Hide loading indicator
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    
                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  shadowColor: primaryColor.withOpacity(0.5),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          'Sign In',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Divider(color: textColor.withOpacity(0.3)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: GoogleFonts.poppins(
                            color: textColor.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Divider(color: textColor.withOpacity(0.3)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 1100),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: InkWell(
                        onTap: () async {
                          if (_isLoading) return; // Prevent multiple taps
                          
                          debugPrint('🔘 Google Sign-In button pressed');
                          setState(() {
                            _isLoading = true;
                          });
                          
                          try {
                            // Use the GoogleAuthService singleton instead of creating a new instance
                            final googleAuthService = GoogleAuthService();
                            
                            // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );
                            
                            // Use the signInWithGoogle method from GoogleAuthService
                            final success = await googleAuthService.signInWithGoogle(
                              context,
                              onSuccess: () {
                                debugPrint('✅ Google Sign-In successful');
                                // Navigate to home screen on successful authentication
                                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                              },
                            );
                            
                            // Close loading dialog
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Authentication failed. Please try again.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('❌ Error during Google Sign-In: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Sign-in error: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 28,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sign in with Google',
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Use MaterialPageRoute instead of named route to avoid crashes
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign up',
                          style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
