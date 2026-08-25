import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile_model.dart';
import '../../../services/profile_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  late Future<UserProfile> _profileFuture;
  late ProfileService _profileService;
  bool _isChangingPassword = false;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Security settings
  bool _biometricAuth = true;
  bool _twoFactorAuth = false;
  bool _transactionPin = true;
  bool _loginNotifications = true;
  
  @override
  void initState() {
    super.initState();
    // Get profile service after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }
  
  void _loadProfile() {
    _profileService = Provider.of<ProfileService>(context, listen: false);
    setState(() {
      _profileFuture = _profileService.getUserProfile();
    });
  }
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return const Center(child: Text('No profile data found'));
          }
          
          final profile = snapshot.data!;
          
          // Initialize security settings from profile preferences
          _biometricAuth = profile.preferences['biometricAuth'] as bool? ?? true;
          _twoFactorAuth = profile.preferences['twoFactorAuth'] as bool? ?? false;
          _transactionPin = profile.preferences['transactionPin'] as bool? ?? true;
          _loginNotifications = profile.preferences['loginNotifications'] as bool? ?? true;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSecurityOverview(isDark),
                const SizedBox(height: 24),
                _buildSecuritySettings(isDark, profile),
                const SizedBox(height: 24),
                if (_isChangingPassword) _buildChangePasswordForm(isDark),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSecurityOverview(bool isDark) {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? const Color(0xFF2C2C2C) : Theme.of(context).colorScheme.primary.withOpacity(0.8),
              isDark ? const Color(0xFF1A1A1A) : Theme.of(context).colorScheme.primary,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Security Center',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Protect your account with additional security measures.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSecurityStatusItem(
                  icon: Icons.lock,
                  title: 'Password',
                  status: 'Strong',
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildSecurityStatusItem(
                  icon: Icons.fingerprint,
                  title: 'Biometric',
                  status: _biometricAuth ? 'Enabled' : 'Disabled',
                  color: _biometricAuth ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 16),
                _buildSecurityStatusItem(
                  icon: Icons.phone_android,
                  title: '2FA',
                  status: _twoFactorAuth ? 'Enabled' : 'Disabled',
                  color: _twoFactorAuth ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecurityStatusItem({
    required IconData icon,
    required String title,
    required String status,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecuritySettings(bool isDark, UserProfile profile) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Password section
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'Change Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Last changed 30 days ago',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              trailing: Icon(
                _isChangingPassword ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_right,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              onTap: () {
                setState(() {
                  _isChangingPassword = !_isChangingPassword;
                });
              },
            ),
            
            const Divider(),
            
            // Biometric Authentication
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              title: Text(
                'Biometric Authentication',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Use fingerprint or face ID to login',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              value: _biometricAuth,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                setState(() {
                  _biometricAuth = value;
                });
                
                // Enable biometric authentication
                await _profileService.updateUserPreferences({
                  'biometricAuth': value,
                });
              },
            ),
            
            const Divider(),
            
            // Two-Factor Authentication
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              title: Text(
                'Two-Factor Authentication',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Receive a verification code on your phone',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              value: _twoFactorAuth,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                if (value) {
                  // Show setup dialog for 2FA
                  _showTwoFactorSetupDialog();
                } else {
                  setState(() {
                    _twoFactorAuth = value;
                  });
                  
                  // Update user preferences
                  await _profileService.updateUserPreferences({
                    'twoFactorAuth': value,
                  });
                }
              },
            ),
            
            const Divider(),
            
            // Transaction PIN
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dialpad,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              title: Text(
                'Transaction PIN',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Require PIN for all transactions',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              value: _transactionPin,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                setState(() {
                  _transactionPin = value;
                });
                
                // Update user preferences
                await _profileService.updateUserPreferences({
                  'transactionPin': value,
                });
              },
            ),
            
            const Divider(),
            
            // Login Notifications
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              title: Text(
                'Login Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Get notified of new logins to your account',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              value: _loginNotifications,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                setState(() {
                  _loginNotifications = value;
                });
                
                // Update user preferences
                await _profileService.updateUserPreferences({
                  'loginNotifications': value,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChangePasswordForm(bool isDark) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Current password
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Current Password',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // New password
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'New Password',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirm password
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Password strength indicator
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 24),
              
              // Submit button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isChangingPassword = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black54,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Update Password'),
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
  
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      ),
    );
  }
  
  Widget _buildPasswordStrengthIndicator() {
    final password = _newPasswordController.text;
    double strength = 0.0;
    String strengthText = 'Very Weak';
    Color strengthColor = Colors.red;
    
    if (password.isNotEmpty) {
      // Calculate password strength
      if (password.length >= 8) strength += 0.2;
      if (password.length >= 12) strength += 0.2;
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;
      
      // Set strength text and color
      if (strength <= 0.2) {
        strengthText = 'Very Weak';
        strengthColor = Colors.red;
      } else if (strength <= 0.4) {
        strengthText = 'Weak';
        strengthColor = Colors.orange;
      } else if (strength <= 0.6) {
        strengthText = 'Medium';
        strengthColor = Colors.yellow;
      } else if (strength <= 0.8) {
        strengthText = 'Strong';
        strengthColor = Colors.lightGreen;
      } else {
        strengthText = 'Very Strong';
        strengthColor = Colors.green;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password Strength',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              strengthText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: strengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        const Text(
          'Use at least 8 characters, including uppercase letters, numbers, and symbols.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
  
  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      // In a real app, you would implement password changing here
      // For now, we'll just show a snackbar
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _isChangingPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    }
  }
  
  void _showTwoFactorSetupDialog() {
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Up Two-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'We will send a verification code to your phone number to enable two-factor authentication.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Enable 2FA
              setState(() {
                _twoFactorAuth = true;
              });
              
              // Update user preferences
              await _profileService.updateUserPreferences({
                'twoFactorAuth': true,
              });
              
              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Two-factor authentication enabled'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}
