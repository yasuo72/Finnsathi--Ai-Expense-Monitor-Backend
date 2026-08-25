import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onThemeChanged, this.isDarkMode});

  final void Function(bool)? onThemeChanged;
  final bool? isDarkMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Example settings state
  bool notifications = true;
  bool biometric = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color:
              Theme.of(context).iconTheme.color ??
              Theme.of(context).colorScheme.onSurface,
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(
              'General',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Enable Notifications'),
                  value: notifications,
                  onChanged: (val) => setState(() => notifications = val),
                  secondary: const Icon(Icons.notifications_active),
                ),
                Divider(height: 0),
                ListTile(
                  title: const Text('Dark Mode'),
                  leading: const Icon(Icons.dark_mode),
                  trailing: Consumer<ThemeService>(
                    builder: (context, themeService, _) {
                      return Switch(
                        value: themeService.isDarkMode,
                        onChanged: (val) {
                          themeService.setDarkMode(val);
                          if (widget.onThemeChanged != null)
                            widget.onThemeChanged!(val);
                        },
                        activeColor: Theme.of(context).colorScheme.secondary,
                      );
                    },
                  ),
                ),
                Divider(height: 0),
                SwitchListTile(
                  title: Text('Use Biometric Login'),
                  value: biometric,
                  onChanged: (val) => setState(() => biometric = val),
                  secondary: const Icon(Icons.fingerprint),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(
              'Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password tapped!')),
                    );
                  },
                ),
                Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Logout'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logout tapped!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
