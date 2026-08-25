import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../services/navigation_service.dart';

class ProfileMenuList extends StatelessWidget {
  final VoidCallback onLogout;
  final bool isDark;

  const ProfileMenuList({
    Key? key,
    required this.onLogout,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.receipt_long,
        'title': 'All Transactions',
        'subtitle': 'View your complete transaction history',
        'route': '/transactions',
        'color': Colors.blue,
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'Linked Accounts',
        'subtitle': 'Manage your linked bank accounts and cards',
        'route': '/linked-accounts',
        'color': Colors.green,
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Security',
        'subtitle': 'Manage your security settings and privacy',
        'route': '/security',
        'color': Colors.orange,
      },
      {
        'icon': Icons.support_agent_outlined,
        'title': 'Help & Support',
        'subtitle': 'Get help with any issues or questions',
        'route': '/support',
        'color': Colors.purple,
      },
      {
        'icon': Icons.info_outline,
        'title': 'About',
        'subtitle': 'Learn more about the app and its features',
        'route': '/about',
        'color': Colors.teal,
      },
      {
        'icon': Icons.logout,
        'title': 'Logout',
        'subtitle': 'Sign out from your account',
        'isLogout': true,
        'color': Colors.red,
      },
    ];

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 400),
      child: Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: menuItems.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.black12,
                indent: 70,
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final bool isLogout = item['isLogout'] == true;
                
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'],
                      color: item['color'],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isLogout
                          ? Colors.red
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  subtitle: Text(
                    item['subtitle'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  onTap: () {
                    if (isLogout) {
                      onLogout();
                    } else {
                      // Use NavigationService for consistent navigation
                      NavigationService.navigate(context, item['route']);
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
