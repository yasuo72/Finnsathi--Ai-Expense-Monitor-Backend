import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../services/auth_state_service.dart';
import '../../services/profile_service.dart';
import '../../models/user_profile_model.dart';
import 'widgets/profile_header.dart';
import 'widgets/membership_card.dart';
import 'widgets/stats_card.dart';
import 'widgets/profile_menu_list.dart';
import 'widgets/achievements_section.dart';
import 'widgets/transaction_history.dart' as profile_transaction;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<UserProfile>? _profileFuture;
  ProfileService? _profileService;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Initialize profile service immediately to avoid late initialization errors
    _profileService = Provider.of<ProfileService>(context, listen: false);
    _profileFuture = _profileService?.getUserProfile();
  }
  
  // Load profile data from the profile service
  void _loadProfile() {
    _profileService = Provider.of<ProfileService>(context, listen: false);
    setState(() {
      _profileFuture = _profileService?.getUserProfile();
    });
  }
  
  // Method to refresh profile data
  void _refreshProfile() {
    setState(() {
      _profileFuture = _profileService?.getUserProfile();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      body: FutureBuilder<UserProfile>(
        future: _profileFuture ?? Future.value(UserProfile.mock()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return const Center(child: Text('No profile data found'));
          }
          
          final profile = snapshot.data!;
          
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: ProfileHeader(
                      profile: profile,
                      onProfileUpdated: _refreshProfile,
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.white70 : Colors.white.withOpacity(0.7),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'PROFILE'),
                      Tab(text: 'ACHIEVEMENTS'),
                      Tab(text: 'SETTINGS'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Profile Tab
                _buildProfileTab(profile, isDark),
                
                // Achievements Tab
                AchievementsSection(achievements: profile.achievements),
                
                // Settings Tab
                _buildSettingsTab(profile, isDark),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildProfileTab(UserProfile profile, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MembershipCard(
            level: profile.membershipLevel,
            progress: profile.levelProgress,
            nextLevel: profile.nextLevel,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          StatsCard(
            points: profile.points,
            rank: profile.rank,
            transactions: profile.completedTransactions,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          ProfileMenuList(
            onLogout: _handleLogout,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          const profile_transaction.TransactionHistory(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildSettingsTab(UserProfile profile, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSection(
            'Account Settings',
            [
              _buildSettingsTile(
                'Edit Profile',
                Icons.person_outline,
                () => Navigator.pushNamed(context, '/profile/edit'),
              ),
              _buildSettingsTile(
                'Change Password',
                Icons.lock_outline,
                () => Navigator.pushNamed(context, '/profile/change-password'),
              ),
              _buildSettingsTile(
                'Linked Accounts',
                Icons.link,
                () => Navigator.pushNamed(context, '/profile/linked-accounts'),
              ),
            ],
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            'App Settings',
            [
              _buildSwitchTile(
                'Dark Mode',
                Icons.dark_mode_outlined,
                Provider.of<ThemeService>(context).isDarkMode,
                (value) {
                  Provider.of<ThemeService>(context, listen: false).toggleTheme();
                },
                isDark,
              ),
              _buildSwitchTile(
                'Notifications',
                Icons.notifications_none_outlined,
                profile.preferences['notifications'] ?? false,
                (value) async {
                  // Get profile service
                  final profileService = Provider.of<ProfileService>(context, listen: false);
                  
                  // Update notifications preference
                  await profileService.updateUserPreferences({
                    'notifications': value,
                  });
                  
                  setState(() {
                    _profileFuture = profileService.getUserProfile();
                  });
                },
                isDark,
              ),
              _buildSwitchTile(
                'Biometric Authentication',
                Icons.fingerprint,
                profile.preferences['biometricAuth'] ?? false,
                (value) async {
                  // Get profile service
                  final profileService = Provider.of<ProfileService>(context, listen: false);
                  
                  // Update biometric authentication preference
                  await profileService.updateUserPreferences({
                    'biometricAuth': value,
                  });
                  
                  setState(() {
                    _profileFuture = profileService.getUserProfile();
                  });
                },
                isDark,
              ),
            ],
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            'Support',
            [
              _buildSettingsTile(
                'Help Center',
                Icons.help_outline,
                () => Navigator.pushNamed(context, '/profile/help'),
              ),
              _buildSettingsTile(
                'Report a Problem',
                Icons.report_problem_outlined,
                () => Navigator.pushNamed(context, '/profile/report'),
              ),
              _buildSettingsTile(
                'Privacy Policy',
                Icons.privacy_tip_outlined,
                () => Navigator.pushNamed(context, '/profile/privacy'),
              ),
              _buildSettingsTile(
                'Terms of Service',
                Icons.description_outlined,
                () => Navigator.pushNamed(context, '/profile/terms'),
              ),
            ],
            isDark,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildSettingsSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
  
  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
  
  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    bool isDark,
  ) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
  
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Clear authentication state
              await AuthStateService.clearAuthState();
              
              // Navigate to login screen
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/signin', 
                (route) => false
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
