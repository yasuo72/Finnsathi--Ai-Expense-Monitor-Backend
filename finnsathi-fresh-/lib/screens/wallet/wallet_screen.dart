import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'animated_card.dart';
import 'quick_actions.dart';
import 'transaction_list.dart';
import 'wallet_password_screen.dart';
import '../../services/wallet_service.dart';

class ModernWalletScreen extends StatefulWidget {
  const ModernWalletScreen({Key? key}) : super(key: key);

  @override
  State<ModernWalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<ModernWalletScreen>
    with TickerProviderStateMixin {
  int selectedCard = 0;
  bool showRemoveDialog = false;
  bool showAddCard = false;
  bool showCashInputDialog = false;
  TextEditingController cashAmountController = TextEditingController();

  // Modern add card form state
  int _currentStep = 0;
  final _cardFormKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardBalanceController = TextEditingController();
  String _cardType = 'debit';
  Color _selectedCardColor = const Color(0xFF3551A2);
  bool _cardHover = false;

  // Card colors
  final List<Color> _cardColors = [
    const Color(0xFF3551A2), // Blue
    const Color(0xFF7928CA), // Purple
    const Color(0xFFFF0080), // Pink
    const Color(0xFF23C16B), // Green
    const Color(0xFFFF7A50), // Orange
  ];

  // Add card form animations
  late AnimationController _cardFormAnimationController;
  late AnimationController _cardStepAnimationController;

  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    // Initialize card form animations
    _cardFormAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _cardStepAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Check authentication and navigate to password screen if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final walletService = Provider.of<WalletService>(context, listen: false);

    // If not authenticated, show password screen
    if (!walletService.isAuthenticated) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const WalletPasswordScreen()),
      );

      // If authentication failed, navigate back to home
      if (result != true) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    cashAmountController.dispose();
    _cardFormAnimationController.dispose();
    _cardStepAnimationController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardNameController.dispose();
    _cardBalanceController.dispose();
    super.dispose();
  }

  void removeCard() {
    final walletService = Provider.of<WalletService>(context, listen: false);
    // Remove the card from the service
    walletService.removeCard(selectedCard);

    setState(() {
      if (selectedCard >= walletService.cards.length) {
        selectedCard =
            walletService.cards.isEmpty ? 0 : walletService.cards.length - 1;
      }
      showRemoveDialog = false;
    });

    // SnackBar removed
  }

  void addCard(Map<String, dynamic> cardData) {
    final walletService = Provider.of<WalletService>(context, listen: false);
    walletService.addCard(cardData);

    setState(() {
      showAddCard = false;
      // Reset form state
      _currentStep = 0;
      _cardNumberController.clear();
      _cardExpiryController.clear();
      _cardCvvController.clear();
      _cardNameController.clear();
      _cardBalanceController.clear();
      _cardType = 'debit';
      _selectedCardColor = const Color(0xFF3551A2);
    });

    // SnackBar removed
  }

  void _updateCashAmount() {
    final cashAmountStr = cashAmountController.text.trim();
    if (cashAmountStr.isEmpty) return;

    final walletService = Provider.of<WalletService>(context, listen: false);
    try {
      final amount = double.parse(cashAmountStr);
      walletService.updateCashAmount(amount);

      setState(() {
        showCashInputDialog = false;
      });

      // SnackBar removed
    } catch (e) {
      // SnackBar removed
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!walletService.isAuthenticated) {
      return Container(color: theme.scaffoldBackgroundColor);
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: isDark ? 0.3 : 0.1,
                  child: CustomPaint(
                    painter: BackgroundPainter(
                      animation: _backgroundAnimation.value,
                      isDark: isDark,
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance Summary (Cash + Cards)
                        _buildBalanceSummary(),
                        const SizedBox(height: 24),
                        // Cards Section
                        _buildCardsSection(),
                        const SizedBox(height: 24),
                        // Quick Actions
                        const QuickActions(),
                        const SizedBox(height: 24),
                        // Recent Transactions
                        const TransactionList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Add Card Form - Modern UI with animations
          if (showAddCard)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => showAddCard = false),
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap through
                    child: _buildModernAddCardForm(),
                  ),
                ),
              ),
            ),

          // Cash Input Dialog
          if (showCashInputDialog) _buildCashInputDialog(),

          // Remove Card Dialog
          if (showRemoveDialog)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => showRemoveDialog = false),
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap through
                    child: _buildRemoveDialog(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary() {
    final walletService = Provider.of<WalletService>(context);
    final cashAmount = walletService.cashAmount;
    final cardsTotalAmount = walletService.cardsTotalAmount;
    final totalBalance = walletService.totalBalance;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [Colors.indigo.shade800, Colors.purple.shade900]
                  : [Colors.indigo.shade500, Colors.purple.shade500],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Balance
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Cash and Cards breakdown
          Row(
            children: [
              // Cash Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cash',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${cashAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Cards Total
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cards',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${cardsTotalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Update Cash Button
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                cashAmountController.text = cashAmount.toString();
                setState(() => showCashInputDialog = true);
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Update Cash Amount'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.indigo.shade700,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashInputDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => showCashInputDialog = false),
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {}, // Prevent tap through
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update Cash Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cashAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cash Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            () => setState(() => showCashInputDialog = false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _updateCashAmount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'My Wallet',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            // Show notifications
          },
        ),
        IconButton(
          icon: Icon(
            Icons.settings_outlined,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            // Navigate to settings
          },
        ),
      ],
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  Widget _buildCardsSection() {
    final walletService = Provider.of<WalletService>(context);
    final cards = walletService.cards;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Cards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() => showAddCard = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        cards.isEmpty ? _buildEmptyCardsState() : _buildCardsList(),
      ],
    );
  }

  Widget _buildEmptyCardsState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card,
            size: 48,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Cards Added Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first card to manage your finances better',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => showAddCard = true),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Your First Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList() {
    final walletService = Provider.of<WalletService>(context);
    final cards = walletService.cards;

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return GestureDetector(
            onTap: () => setState(() => selectedCard = index),
            onLongPress: () {
              setState(() {
                selectedCard = index;
                showRemoveDialog = true;
              });
            },
            child: AnimatedCard(
              isSelected: selectedCard == index,
              cardData: card,
              onTap: () => setState(() => selectedCard = index),
              onRemove: () => setState(() => showRemoveDialog = true),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernAddCardForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fadeAnimation = CurvedAnimation(
      parent: _cardFormAnimationController,
      curve: Curves.easeInOut,
    );
    
    if (_cardFormAnimationController.status == AnimationStatus.dismissed) {
      _cardFormAnimationController.forward();
    }
    
    return FadeTransition(
      opacity: fadeAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        margin: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _cardFormAnimationController.reverse().then((_) {
                        setState(() {
                          showAddCard = false;
                          _currentStep = 0;
                        });
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Form content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _cardFormKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildCardTypeStep();
      case 1:
        return _buildCardDetailsStep();
      case 2:
        return _buildCardPreviewStep();
      default:
        return _buildCardTypeStep();
    }
  }

  Widget _buildCardTypeStep() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Card Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildCardTypeOption('Debit Card', 'debit', Icons.credit_card),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCardTypeOption('Credit Card', 'credit', Icons.credit_score),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Select Card Color',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _cardColors.map((color) => _buildColorOption(color)).toList(),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Next', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildCardTypeOption(String label, String value, IconData icon) {
    final isSelected = _cardType == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _cardType = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : isDark
                  ? Colors.grey[800]
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : isDark
                      ? Colors.grey[400]
                      : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isDark
                        ? Colors.grey[300]
                        : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedCardColor == color;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardColor = color;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 48 : 36,
        height: isSelected ? 48 : 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }

  Widget _buildCardDetailsStep() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _cardNumberController,
          label: 'Card Number',
          hint: '1234 5678 9012 3456',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            } else if (value.length < 16) {
              return 'Card number must be 16 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _cardExpiryController,
                label: 'Expiry Date',
                hint: 'MM/YY',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _cardCvvController,
                label: 'CVV',
                hint: '123',
                icon: Icons.security,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _cardNameController,
          label: 'Cardholder Name',
          hint: 'John Doe',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _cardBalanceController,
          label: 'Card Balance',
          hint: '10000',
          icon: Icons.account_balance_wallet,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card balance';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_cardFormKey.currentState!.validate()) {
                    setState(() {
                      _currentStep = 2;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Next', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardPreviewStep() {
    final formattedNumber = _cardNumberController.text.isEmpty
        ? '1234 5678 9012 3456'
        : _formatCardNumber(_cardNumberController.text);
    final formattedExpiry = _cardExpiryController.text.isEmpty
        ? 'MM/YY'
        : _formatExpiryDate(_cardExpiryController.text);
    final cardholderName = _cardNameController.text.isEmpty
        ? 'YOUR NAME'
        : _cardNameController.text.toUpperCase();
    
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview Card',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 24),
        // Card Preview
        MouseRegion(
          onEnter: (_) => setState(() => _cardHover = true),
          onExit: (_) => setState(() => _cardHover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _selectedCardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _selectedCardColor.withOpacity(_cardHover ? 0.6 : 0.3),
                  blurRadius: _cardHover ? 20 : 10,
                  spreadRadius: _cardHover ? 5 : 0,
                  offset: _cardHover ? const Offset(0, 10) : const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      painter: CardPatternPainter(),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _cardType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            _cardType == 'credit'
                                ? Icons.credit_score
                                : Icons.credit_card,
                            color: Colors.white,
                            size: 30,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        formattedNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VALID THRU',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formattedExpiry,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CVV',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '***',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cardholderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_cardFormKey.currentState!.validate()) {
                    final cardData = {
                      'balance': '₹${_cardBalanceController.text}',
                      'number': _formatCardNumber(_cardNumberController.text),
                      'expiry': _formatExpiryDate(_cardExpiryController.text),
                      'cvv': _cardCvvController.text,
                      'name': _cardNameController.text,
                      'type': _cardType,
                      'color': _selectedCardColor,
                    };
                    
                    _cardFormAnimationController.reverse().then((_) {
                      addCard(cardData);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Card', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCardNumber(String number) {
    // Format as **** **** **** 1234 (showing only last 4 digits)
    if (number.length >= 4) {
      final lastFour = number.substring(number.length - 4);
      return '**** **** **** $lastFour';
    }
    return number;
  }

  String _formatExpiryDate(String value) {
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRemoveDialog() {
    final walletService = Provider.of<WalletService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (selectedCard >= walletService.cards.length) {
      return Container();
    }

    final cardData = walletService.cards[selectedCard];

    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.red.shade900.withOpacity(0.2)
                      : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline,
              color: isDark ? Colors.red.shade300 : Colors.red.shade700,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Remove Card',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Are you sure you want to remove the ${cardData['type']} card ending with ${cardData['number'].toString().substring(cardData['number'].toString().length - 4)}?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => showRemoveDialog = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                    ),
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: removeCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animation;
  final bool isDark;

  BackgroundPainter({required this.animation, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isDark ? const Color(0xFF4A4A8F) : const Color(0xFF6C63FF)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80.0);

    // Draw animated shapes
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw multiple circles with different sizes and positions
    for (int i = 0; i < 5; i++) {
      final radius = (100 + i * 50) + (animation * 20);
      final offset = 10 * i * animation;

      canvas.drawCircle(
        Offset(centerX + offset, centerY - offset),
        radius,
        paint,
      );
    }

    // Draw some rectangles
    for (int i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(
        i * 100 + (animation * 30),
        i * 150 + (animation * 20),
        200,
        200,
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw decorative patterns
    final path = Path();
    
    // Draw circles
    for (int i = 0; i < 5; i++) {
      final radius = 10.0 + i * 15.0;
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.2),
        radius,
        paint,
      );
    }
    
    // Draw curved lines
    path.moveTo(0, size.height * 0.65);
    path.quadraticBezierTo(
      size.width * 0.3, size.height * 0.9,
      size.width * 0.6, size.height * 0.75,
    );
    path.quadraticBezierTo(
      size.width * 0.85, size.height * 0.65,
      size.width, size.height * 0.8,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw some dots
    for (int i = 0; i < 20; i++) {
      final x = Random().nextDouble() * size.width;
      final y = Random().nextDouble() * size.height;
      final radius = 1.0 + Random().nextDouble() * 2.0;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
