import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/curved_nav_bar.dart';
import 'home_actions.dart';
import 'notification_screen.dart';
import 'shop/shops_screen.dart';
import 'profile/profile_main.dart';
import 'statistics_screen.dart';
import 'wallet/wallet_password_screen.dart';
import 'gamification/gamification_screen.dart';
import '../widgets/animated_fab.dart';
import '../services/finance_service.dart';
import '../services/wallet_service.dart';
import '../services/profile_service.dart';
import '../services/api_service_manager.dart';
import '../models/finance_models.dart';
import '../models/user_profile_model.dart';
import 'dart:io';
import 'dart:convert';
import 'add_transaction_screen.dart';
import 'receipt_scanner_screen.dart';
import 'ai_chat_screen.dart';
import 'voice_assistant_screen.dart';
import '../widgets/budget_savings_widget.dart';
import '../widgets/glass_container.dart';
import '../widgets/gamification_preview_card.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _balanceVisible = false;
  ProfileService? _profileService;
  Future<UserProfile>? _profileFuture;

  @override
  void initState() {
    super.initState();
    // Initialize profile service immediately to avoid late initialization errors
    _profileService = Provider.of<ProfileService>(context, listen: false);

    // Force refresh the profile data to ensure it's up-to-date with signup/login information
    _profileService?.refreshProfile();

    // Initialize profile future
    _profileFuture = _profileService?.getUserProfile();

    // Force refresh finance data immediately after login to ensure transactions are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh finance data
      final financeService = Provider.of<FinanceService>(
        context,
        listen: false,
      );
      print('🔄 Home screen loaded - forcing finance data refresh');
      financeService.forceRefreshData();

      // Force refresh profile data again after a short delay
      // This ensures we get the latest profile data including any profile picture updates
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _refreshProfile();
          print('🔄 Refreshing profile data after delay');
        }
      });
    });

    // Listen for shared preferences changes that indicate login success
    // This helps us refresh the profile when the user logs in
    SharedPreferences.getInstance().then((prefs) {
      final loginSuccessful = prefs.getBool('login_successful') ?? false;
      if (loginSuccessful) {
        print('🔑 Login detected - refreshing profile data');
        _refreshProfile();
        // Reset the flag
        prefs.setBool('login_successful', false);
      }
    });
  }

  // Refresh profile data if needed
  void _refreshProfile() {
    if (_profileService == null) {
      // Initialize profile service if it's not already initialized
      _profileService = Provider.of<ProfileService>(context, listen: false);
    }

    // Force refresh the profile data from the service
    _profileService?.refreshProfile();

    // Update the future to trigger UI refresh
    setState(() {
      _profileFuture = _profileService?.getUserProfile();
      print('🔄 Profile data refreshed in home screen');
    });
  }

  // Helper method to build profile image with proper handling of different URL formats
  Widget _buildProfileImage(String imageUrl) {
    // Default image to show if URL is empty or invalid
    if (imageUrl.isEmpty) {
      print('Empty profile image URL, showing default avatar');
      return Image.asset(
        'assets/default_avatar.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading default avatar: $error');
          return const Icon(Icons.person, color: Colors.white);
        },
      );
    }

    print('Loading profile image from URL: $imageUrl');

    // Handle base64 encoded images
    if (imageUrl.startsWith('data:image')) {
      try {
        // Split the string to get the base64 part
        final parts = imageUrl.split(',');

        // More robust check for valid base64 data
        if (parts.length < 2) {
          print('❌ Invalid base64 image format: missing comma separator');
          return Image.asset(
            'assets/default_avatar.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.person, color: Colors.white);
            },
          );
        }

        // Extract and validate the base64 string
        final base64String = parts[1].trim();
        if (base64String.isEmpty) {
          print('❌ Base64 image data is empty');
          return Image.asset(
            'assets/default_avatar.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.person, color: Colors.white);
            },
          );
        }

        print('📏 Base64 string length: ${base64String.length}');

        // Additional validation for base64 string
        if (base64String.length < 10) {
          // Arbitrary minimum length for valid image
          print('❌ Base64 string too short to be valid image data');
          return Image.asset(
            'assets/default_avatar.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.person, color: Colors.white);
            },
          );
        }

        final imageBytes = base64Decode(base64String);
        if (imageBytes.isEmpty) {
          print('❌ Decoded base64 image has zero bytes');
          return Image.asset(
            'assets/default_avatar.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.person, color: Colors.white);
            },
          );
        }

        print(
          '✅ Displaying base64 encoded image, bytes length: ${imageBytes.length}',
        );
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading base64 image: $error');
            return Image.asset(
              'assets/default_avatar.png',
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => const Icon(Icons.person, color: Colors.white),
            );
          },
        );
      } catch (e, stackTrace) {
        print('❌ Error decoding base64 image: $e');
        print('📜 Stack trace: $stackTrace');
        return Image.asset(
          'assets/default_avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, color: Colors.white);
          },
        );
      }
    }

    // Handle local file paths
    if (imageUrl.startsWith('file://')) {
      final filePath = imageUrl.replaceFirst('file://', '');
      print('Displaying local file image from: $filePath');
      return Image.file(
        File(filePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading local image: $error');
          return const Icon(Icons.person, color: Colors.white);
        },
      );
    }

    // Handle backend server paths that start with /uploads/
    if (imageUrl.startsWith('/uploads/')) {
      final baseUrl =
          'https://finnsathi-ai-expense-monitor-backend-production.up.railway.app';
      final fullUrl = '$baseUrl$imageUrl';
      print('Loading profile image from backend server: $fullUrl');

      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        headers: const {'Accept': 'image/*'},
        cacheWidth: 300, // Optimize image loading
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image from backend: $error');
          return const Icon(Icons.person, color: Colors.white);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    // Check if it's just a filename without path, assume it's in uploads directory
    if (!imageUrl.contains('/') &&
        (imageUrl.toLowerCase().endsWith('.jpg') ||
            imageUrl.toLowerCase().endsWith('.jpeg') ||
            imageUrl.toLowerCase().endsWith('.png') ||
            imageUrl.toLowerCase().endsWith('.gif'))) {
      final baseUrl =
          'https://finnsathi-ai-expense-monitor-backend-production.up.railway.app';
      final fullUrl = '$baseUrl/uploads/$imageUrl';
      print('Loading profile image from filename: $fullUrl');

      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        headers: const {'Accept': 'image/*'},
        cacheWidth: 300, // Optimize image loading
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image from filename: $error');
          return const Icon(Icons.person, color: Colors.white);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    // Handle full URLs (http:// or https://)
    print('Loading profile image from full URL: $imageUrl');
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      headers: const {'Accept': 'image/*'},
      cacheWidth: 300, // Optimize image loading
      errorBuilder: (context, error, stackTrace) {
        print('Error loading network image from URL: $error');
        // Show fallback icon but don’t auto-refresh profile to prevent infinite loop
        return const Icon(Icons.person, color: Colors.white);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value:
                loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  // Removed dummy data - using data from FinanceService instead

  void _toggleBalance() => setState(() => _balanceVisible = !_balanceVisible);

  void _onItemTapped(int index) {
    // Clear any back stack when switching tabs to prevent app from closing
    // when backing from a tab
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: null,
      body: _getSelectedPage(),
      bottomNavigationBar: SafeArea(
        child: CurvedNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped),
      ),
      floatingActionButton:
          (_selectedIndex == 0 || _selectedIndex == 1)
              ? AnimatedFAB(
                onAddExpense: () {
                  _navigateToAddTransaction(TransactionType.expense);
                },
                onAddIncome: () {
                  _navigateToAddTransaction(TransactionType.income);
                },
                onReceiptScanner: () {
                  _navigateToReceiptScanner();
                },
                onAiChat: () {
                  _navigateToAiChat();
                },
              )
              : null,
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return StatisticsScreen(
          onAddExpense: () {
            _navigateToAddTransaction(TransactionType.expense);
          },
          onAddIncome: () {
            _navigateToAddTransaction(TransactionType.income);
          },
          onReceiptScanner: () {
            _navigateToReceiptScanner();
          },
        );
      case 2:
        return const WalletPasswordScreen();
      case 3:
        return const GamificationScreen(); // New gamification screen
      case 4:
        return const ShopsScreen();
      case 5:
        return const ProfileMain();
      default:
        return const Center(child: Text('Page coming soon...'));
    }
  }

  // API Test navigation removed

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Settings button removed
            _buildHeader(),
            const SizedBox(height: 20),
            _buildBalanceCard(),
            const SizedBox(height: 20),
            _buildIncomeOutcome(),
            const SizedBox(height: 20),
            _buildBudgetCard(),
            const SizedBox(height: 20),
            const BudgetSavingsWidget(),
            const SizedBox(height: 20),
            _buildSavings(),
            const SizedBox(height: 20),
            const GamificationPreviewCard(),
            const SizedBox(height: 20),
            _buildTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF4866FF);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [Color(0xFF2C3E50), Color(0xFF1A1A2E)]
                  : [primaryColor.withOpacity(0.8), primaryColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User info section with futuristic styling
          Consumer<ProfileService>(
            builder: (context, profileService, _) {
              final profile = profileService.currentProfile;
              final String userName =
                  profile.name.isNotEmpty ? profile.name : 'User';
              final String avatarUrl =
                  profile.avatarUrl.isNotEmpty
                      ? profile.avatarUrl
                      : 'https://randomuser.me/api/portraits/lego/1.jpg';

              return GestureDetector(
                onTap: () => _onItemTapped(5),
                child: Row(
                  children: [
                    // Futuristic avatar container
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glowing circle
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.5),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                        // Avatar with border
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: _buildProfileImage(avatarUrl),
                          ),
                        ),
                        // Status indicator
                        Positioned(
                          right: 0,
                          bottom: 5,
                          child: Container(
                            height: 12,
                            width: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.greenAccent,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          // Futuristic action buttons
          Row(
            children: [
              // Statistics button with glow effect
              GlassContainer(
                borderRadius: 15,
                blur: 10,
                opacity: 0.15,
                child: SizedBox(
                  height: 42,
                  width: 42,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.insert_chart_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _navigateToStatistics,
                    tooltip: 'Statistics',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GlassContainer(
                borderRadius: 15,
                blur: 10,
                opacity: 0.15,
                child: SizedBox(
                  height: 42,
                  width: 42,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.mic_none,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _navigateToVoiceAssistant,
                    tooltip: 'Voice Assistant',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Notification button with notification badge
              Consumer<ApiServiceManager>(
                builder: (context, apiManager, _) {
                  final unread = apiManager.unreadNotificationsCount;
                  return Stack(
                    children: [
                      GlassContainer(
                        borderRadius: 15,
                        blur: 10,
                        opacity: 0.15,
                        child: SizedBox(
                          height: 42,
                          width: 42,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NotificationPage(),
                                  ),
                                ),
                            tooltip: 'Notifications',
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddTransaction(TransactionType type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTransactionScreen(type: type)),
    );

    if (result == true) {
      // Transaction was added or updated, refresh the UI
      setState(() {});
    }
  }

  Future<void> _navigateToReceiptScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReceiptScannerScreen()),
    );

    if (result == true) {
      // Receipt was processed, refresh the UI
      setState(() {});
    }
  }

  Future<void> _navigateToAiChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AiChatScreen()),
    );
  }

  Future<void> _navigateToVoiceAssistant() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoiceAssistantScreen()),
    );
  }

  Future<void> _navigateToStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
    );
  }

  Widget _buildBalanceCard() {
    final financeService = Provider.of<FinanceService>(context);
    final walletService = Provider.of<WalletService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate total balance including wallet (cards + cash)
    final totalFinanceBalance = financeService.balance;
    final totalWalletBalance =
        walletService.totalBalance; // This includes all card balances + cash
    final combinedBalance = totalFinanceBalance + totalWalletBalance;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
                  : [const Color(0xFF4066FF), const Color(0xFF2949c8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4066FF).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -15,
            left: -15,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GlassContainer(
                    borderRadius: 12,
                    blur: 5,
                    opacity: 0.1,
                    padding: const EdgeInsets.all(6),
                    child: GestureDetector(
                      onTap:
                          () => HomeActions.onBalanceEyeTap(
                            context,
                            _toggleBalance,
                          ),
                      child: Icon(
                        _balanceVisible
                            ? Icons.remove_red_eye_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _balanceVisible
                      ? '₹${combinedBalance.toStringAsFixed(2)}'
                      : '••••••••',
                  key: ValueKey(_balanceVisible),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Card-style wallet access button
              GlassContainer(
                borderRadius: 16,
                blur: 10,
                opacity: 0.15,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                child: InkWell(
                  onTap: () => HomeActions.onWalletTap(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'My Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeOutcome() {
    final financeService = Provider.of<FinanceService>(context);
    return Row(
      children: [
        _buildFinanceCard(
          icon: Icons.arrow_downward,
          color: Colors.green,
          label: 'Income',
          value: financeService.totalIncome,
          onTap: () => _navigateToAddTransaction(TransactionType.income),
        ),
        const SizedBox(width: 12),
        _buildFinanceCard(
          icon: Icons.arrow_upward,
          color: Colors.redAccent,
          label: 'Outcome',
          value: financeService.totalExpense,
          onTap: () => _navigateToAddTransaction(TransactionType.expense),
        ),
      ],
    );
  }

  Widget _buildFinanceCard({
    required IconData icon,
    required Color color,
    required String label,
    required double value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GlassContainer(
        borderRadius: 20,
        blur: 12,
        opacity: isDark ? 0.12 : 0.08,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0.5,
          ),
        ],
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card header with icon
                Row(
                  children: [
                    // Gradient icon container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.7),
                            color.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    // Label with improved typography
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.9)
                                : Colors.black87,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Value display with currency
                Row(
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Growth indicator
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        label == 'Income'
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: color,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label == 'Income'
                            ? '+10%'
                            : '-5%', // Example percentages
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard() {
    final financeService = Provider.of<FinanceService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get current month's budget data
    final now = DateTime.now();
    final currentMonthBudgets =
        financeService.budgets.where((b) => b.isActive).toList();

    final monthlyBudget = currentMonthBudgets.fold(
      0.0,
      (sum, b) => sum + b.limit,
    );
    final monthlyExpense = financeService.totalExpense;
    final budgetProgress =
        monthlyBudget > 0
            ? (monthlyExpense / monthlyBudget).clamp(0.0, 1.0)
            : 0.0;

    // Calculate days left in the month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;

    // Determine budget status color
    final budgetStatusColor =
        budgetProgress > 0.8
            ? Colors.redAccent
            : budgetProgress > 0.6
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return GlassContainer(
      borderRadius: 24,
      blur: 12,
      opacity: isDark ? 0.12 : 0.08,
      boxShadow: [
        BoxShadow(
          color: budgetStatusColor.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
          spreadRadius: 0.5,
        ),
      ],
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget header with icon and title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Budget icon with gradient
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          budgetStatusColor.withOpacity(0.7),
                          budgetStatusColor.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: budgetStatusColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${DateFormat('MMMM').format(DateTime.now())} Budget',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              // More options button
              GlassContainer(
                borderRadius: 12,
                blur: 5,
                opacity: 0.1,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: InkWell(
                  onTap: () => HomeActions.onBudgetMoreTap(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          color:
                              isDark
                                  ? Colors.white.withOpacity(0.9)
                                  : budgetStatusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.9)
                                : budgetStatusColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Budget amount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${monthlyExpense.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        ' / ₹${monthlyBudget.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: budgetStatusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: budgetStatusColor,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$daysLeft days left',
                      style: TextStyle(
                        color: budgetStatusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Budget progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(budgetProgress * 100).toStringAsFixed(0)}% used',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    budgetProgress > 0.8
                        ? 'Over Budget'
                        : budgetProgress > 0.6
                        ? 'Warning'
                        : 'On Track',
                    style: TextStyle(
                      fontSize: 13,
                      color: budgetStatusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Elevated progress bar with rounded edges
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        Container(
                          width: constraints.maxWidth * budgetProgress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                budgetStatusColor.withOpacity(0.7),
                                budgetStatusColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: budgetStatusColor.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavings() {
    final financeService = Provider.of<FinanceService>(context);
    final savingsGoals = financeService.savingsGoals;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Savings',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            if (savingsGoals.isNotEmpty)
              TextButton(
                onPressed: () => HomeActions.onSavingsMoreTap(context),
                child: Text(
                  'View All',
                  style: TextStyle(color: theme.colorScheme.secondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        savingsGoals.isEmpty
            ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 48,
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No savings goals yet',
                      style: TextStyle(
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => HomeActions.onAddSavingsTap(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Savings Goal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            : SizedBox(
              height: 206, // Increased height to fix bottom overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: savingsGoals.length,
                itemBuilder: (context, index) {
                  final goal = savingsGoals[index];

                  // Theme-aware colors
                  final cardColor = isDark ? Colors.grey[850] : Colors.white;
                  final textColor = isDark ? Colors.white : Colors.black87;
                  final subtitleColor =
                      isDark ? Colors.grey[400] : Colors.grey[600];

                  // Calculate time remaining
                  String timeRemaining = '';
                  if (goal.targetDate != null) {
                    final daysLeft =
                        goal.targetDate!.difference(DateTime.now()).inDays;
                    timeRemaining =
                        daysLeft > 0 ? '$daysLeft days left' : 'Due today';
                  }

                  return Container(
                    width:
                        280, // Increased width for better display and visibility
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: goal.color.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            () => HomeActions.onSavingsTap(context, goal.title),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [cardColor!, cardColor],
                            ),
                            border: Border.all(
                              color: goal.color.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                // Decorative elements
                                Positioned(
                                  top: -20,
                                  right: -20,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: goal.color.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -30,
                                  left: -30,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: goal.color.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header with icon
                                      Row(
                                        children: [
                                          // Icon with gradient background
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  goal.color.withOpacity(0.7),
                                                  goal.color.withOpacity(0.3),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: goal.color.withOpacity(
                                                    0.3,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.savings,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Title with improved typography
                                          Expanded(
                                            child: Text(
                                              goal.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                                letterSpacing: 0.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Amount display with modern styling
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Saved',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: subtitleColor,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₹${goal.currentAmount.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Target',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: subtitleColor,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₹${goal.targetAmount.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Progress section
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Progress percentage with pill background
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: goal.color.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${(goal.progress * 100).toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: goal.color,
                                              ),
                                            ),
                                          ),
                                          // Time remaining badge
                                          if (goal.targetDate != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isDark
                                                        ? Colors.black12
                                                        : Colors.white10,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: goal.color.withOpacity(
                                                    0.2,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .calendar_today_outlined,
                                                    size: 10,
                                                    color: subtitleColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    timeRemaining,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: subtitleColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Enhanced progress bar
                                      Stack(
                                        children: [
                                          // Background
                                          Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color:
                                                  isDark
                                                      ? Colors.grey[700]
                                                      : Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          // Progress
                                          Container(
                                            height: 8,
                                            width:
                                                (280 - 40) *
                                                goal.progress.clamp(
                                                  0.0,
                                                  1.0,
                                                ), // Account for padding
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  goal.color.withOpacity(0.7),
                                                  goal.color,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: goal.color.withOpacity(
                                                    0.3,
                                                  ),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }

  Widget _buildTransactions() {
    final financeService = Provider.of<FinanceService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF4066FF);

    // Debug logging for transaction counts
    final incomeCount =
        financeService.transactions
            .where((t) => t.type == TransactionType.income)
            .length;
    final expenseCount =
        financeService.transactions
            .where((t) => t.type == TransactionType.expense)
            .length;
    print(
      '📊 Transactions in UI: ${financeService.transactions.length} (Income: $incomeCount, Expense: $expenseCount)',
    );

    // Sort transactions by date (newest first)
    final recentTransactions =
        financeService.transactions.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Futuristic section header
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.7),
                          primaryColor.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor.withOpacity(0.8), primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    splashColor: Colors.white24,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Transactions container
        Container(
          height: 320,
          decoration: BoxDecoration(
            color:
                isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child:
              recentTransactions.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 60,
                            color:
                                isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GlassContainer(
                            borderRadius: 12,
                            blur: 5,
                            opacity: 0.15,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            child: InkWell(
                              onTap:
                                  () => _navigateToAddTransaction(
                                    TransactionType.expense,
                                  ),
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: isDark ? Colors.white : primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Transaction',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDark ? Colors.white : primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: recentTransactions.length,
                    itemBuilder:
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: _buildTransactionTile(
                            recentTransactions[index],
                          ),
                        ),
                  ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green.shade500 : Colors.redAccent.shade400;
    final amountText =
        isIncome
            ? '+₹${transaction.amount.toStringAsFixed(2)}'
            : '-₹${transaction.amount.toStringAsFixed(2)}';

    // Format date in a more user-friendly way
    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    final formattedDate = dateFormatter.format(transaction.date);
    final formattedTime = timeFormatter.format(transaction.date);

    return GlassContainer(
      borderRadius: 16,
      blur: 10,
      opacity: 0.1,
      boxShadow: [
        BoxShadow(
          color: transaction.category.color.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      child: InkWell(
        onTap: () {
          // Show transaction details
          HomeActions.onTransactionTap(context, transaction.title);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          child: Row(
            children: [
              // Category icon with modern styling
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      transaction.category.color.withOpacity(0.7),
                      transaction.category.color.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: transaction.category.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  transaction.category.icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              // Transaction details with improved typography
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            formattedTime,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount with modern styling
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  amountText,
                  style: TextStyle(
                    color: isDark ? color.withOpacity(0.9) : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
