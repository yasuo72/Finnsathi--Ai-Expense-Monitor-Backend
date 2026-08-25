import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 36,
                color: Colors.blueGrey,
              ),
            ),
            accountName: Text(
              'FinSathi User',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              'user@example.com',
              style: GoogleFonts.poppins(),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home',
            route: '/',
            isSelected: currentRoute == '/',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.wallet,
            title: 'Wallet',
            route: '/wallet',
            isSelected: currentRoute == '/wallet',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bar_chart,
            title: 'Statistics',
            route: '/statistics',
            isSelected: currentRoute == '/statistics',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.savings,
            title: 'Savings Goals',
            route: '/savings-goals',
            isSelected: currentRoute == '/savings-goals',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Budget',
            route: '/budget',
            isSelected: currentRoute == '/budget',
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            route: '/settings',
            isSelected: currentRoute == '/settings',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            route: '/help',
            isSelected: currentRoute == '/help',
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'FinSathi v1.0.0',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? theme.primaryColor
            : isDark
                ? Colors.white70
                : Colors.black87,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected
              ? theme.primaryColor
              : isDark
                  ? Colors.white
                  : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.primaryColor.withOpacity(0.1),
      onTap: () {
        if (route != currentRoute) {
          Navigator.pushReplacementNamed(context, route);
        } else {
          Navigator.pop(context);
        }
      },
    );
  }
}
