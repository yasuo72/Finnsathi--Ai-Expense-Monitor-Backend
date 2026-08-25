import 'package:flutter/material.dart';
import 'chats/ChatDetailScreen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with TickerProviderStateMixin {
  int selectedTab = 0;

  late final List<List<Map<String, dynamic>>> chatData;

  @override
  void initState() {
    super.initState();

    chatData = [
      [
        // AI Active Conversations
        {
          'icon': Icons.analytics_outlined,
          'color': Color(0xFF4CAF50),
          'title': 'Monthly Budget Analysis',
          'subtitle': 'Let me analyze your spending patterns',
          'badge': 'New',
        },
        {
          'icon': Icons.savings_outlined,
          'color': Color(0xFF3F51B5),
          'title': 'Savings Plan Assistant',
          'subtitle': 'Track your progress towards goals',
        },
        {
          'icon': Icons.account_balance_wallet_outlined,
          'color': Color(0xFFFF9800),
          'title': 'Expense Optimization',
          'subtitle': 'Tips to reduce unnecessary spending',
        },
        {
          'icon': Icons.trending_up,
          'color': Color(0xFF2196F3),
          'title': 'Income vs Expenses',
          'subtitle': 'Comprehensive financial overview',
        },
      ],
      [
        // Archived
        {
          'icon': Icons.bookmark,
          'color': Colors.grey,
          'title': 'Last Month\'s Analysis',
          'subtitle': 'April 2025 financial review',
        },
        {
          'icon': Icons.bookmark,
          'color': Colors.grey,
          'title': 'Tax Planning Advice',
          'subtitle': 'Saved tips for tax season',
        },
      ],
      [
        // Deleted
        {
          'icon': Icons.delete_outline,
          'color': Colors.redAccent,
          'title': 'Old Budget Questions',
          'subtitle': 'Removed on May 15, 2025',
        },
      ],
    ];
  }

  void onTabChange(int index) {
    if (index != selectedTab) {
      setState(() {
        selectedTab = index;
      });
    }
  }

  void onSeeAll() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'See all tapped for ${['AI', 'Archived', 'Deleted'][selectedTab]}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChats = chatData[selectedTab];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color:
                  isDark
                      ? const Color(0xFF1E1E2C)
                      : primaryColor.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'My AI Chats',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TabButton(
                        label: 'AI',
                        selected: selectedTab == 0,
                        onTap: () => onTabChange(0),
                      ),
                      const SizedBox(width: 20),
                      _TabButton(
                        label: 'Archived',
                        selected: selectedTab == 1,
                        onTap: () => onTabChange(1),
                      ),
                      const SizedBox(width: 20),
                      _TabButton(
                        label: 'Deleted',
                        selected: selectedTab == 2,
                        onTap: () => onTabChange(2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    [
                      'Earlier Today',
                      'Archived Chats',
                      'Deleted Chats',
                    ][selectedTab],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: onSeeAll,
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: ListView.builder(
                    key: ValueKey(selectedTab),
                    itemCount: currentChats.length,
                    itemBuilder: (context, index) {
                      final chat = currentChats[index];
                      return _ChatTile(
                        icon: chat['icon'],
                        iconBg: chat['color'],
                        title: chat['title'],
                        subtitle: chat['subtitle'],
                        badge: chat['badge'],
                      );
                    },
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

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(selected ? 1 : 0.7),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? badge;

  const _ChatTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ChatDetailScreen(
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                  iconBg: iconBg,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                if (badge != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Color(0xFFFF7300),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
