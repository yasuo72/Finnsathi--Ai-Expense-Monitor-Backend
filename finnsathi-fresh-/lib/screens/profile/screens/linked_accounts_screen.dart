import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../services/wallet_service.dart';

class LinkedAccountsScreen extends StatefulWidget {
  const LinkedAccountsScreen({Key? key}) : super(key: key);

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  // Available accounts to link
  final List<Map<String, dynamic>> _availableAccounts = [
    {
      'type': 'bank',
      'name': 'SBI Bank',
      'icon': Icons.account_balance,
      'color': Colors.blue,
    },
    {
      'type': 'bank',
      'name': 'Axis Bank',
      'icon': Icons.account_balance,
      'color': Colors.purple,
    },
    {
      'type': 'wallet',
      'name': 'Google Pay',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
    },
    {
      'type': 'wallet',
      'name': 'PhonePe',
      'icon': Icons.account_balance_wallet,
      'color': Colors.indigo,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Linked Accounts'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLinkedAccountsSection(isDark),
            const SizedBox(height: 24),
            _buildAvailableAccountsSection(isDark),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddAccountBottomSheet();
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  Widget _buildLinkedAccountsSection(bool isDark) {
    final walletService = Provider.of<WalletService>(context);
    final linkedCards = walletService.cards;
    
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Your Linked Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (linkedCards.isEmpty)
            _buildEmptyState(
              'No accounts linked yet',
              'Link your bank accounts, cards, or wallets to track your finances in one place.',
              isDark,
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: linkedCards.length,
              itemBuilder: (context, index) {
                final card = linkedCards[index];
                final account = {
                  'type': card['type'] ?? 'card',
                  'name': card['name'] ?? 'Card',
                  'accountNumber': card['number'] ?? '**** **** **** ****',
                  'isConnected': true,
                  'color': card['color'] ?? Colors.blue,
                };
                return _buildAccountCard(account, isDark, isLinked: true);
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildAvailableAccountsSection(bool isDark) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Available to Link',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableAccounts.length,
            itemBuilder: (context, index) {
              final account = _availableAccounts[index];
              return _buildAccountCard(account, isDark, isLinked: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account, bool isDark, {required bool isLinked}) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: InkWell(
          onTap: () {
            if (isLinked) {
              _showAccountOptionsBottomSheet(account);
            } else {
              _showLinkAccountDialog(account);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Account Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (account['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForAccountType(account['type']),
                    color: account['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Account Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isLinked)
                        Text(
                          account['accountNumber'],
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Action Button
                if (isLinked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: account['isConnected'] ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      account['isConnected'] ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: account['isConnected'] ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: 48,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _showAddAccountBottomSheet();
            },
            icon: const Icon(Icons.add),
            label: const Text('Link Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAccountType(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance;
      case 'card':
      case 'credit':
      case 'debit':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.account_circle;
    }
  }

  void _showAddAccountBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAccountTypeOption(
                  icon: Icons.account_balance,
                  title: 'Bank Account',
                  subtitle: 'Link your bank account',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    // Show bank account linking flow
                  },
                ),
                _buildAccountTypeOption(
                  icon: Icons.credit_card,
                  title: 'Credit/Debit Card',
                  subtitle: 'Link your card',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    // Show card linking flow
                  },
                ),
                _buildAccountTypeOption(
                  icon: Icons.account_balance_wallet,
                  title: 'E-Wallet',
                  subtitle: 'Link your digital wallet',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    // Show wallet linking flow
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAccountTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? Colors.white60 : Colors.black54,
      ),
      onTap: onTap,
    );
  }
  
  void _showAccountOptionsBottomSheet(Map<String, dynamic> account) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Refresh Connection'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing connection...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility, color: Colors.blue),
                  title: const Text('View Transactions'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to transactions screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link_off, color: Colors.orange),
                  title: const Text('Disconnect'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDisconnectConfirmationDialog(account);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRemoveConfirmationDialog(account);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLinkAccountDialog(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Link ${account['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your credentials to link ${account['name']}',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
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
            onPressed: () {
              Navigator.pop(context);

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${account['name']} linked successfully'),
                  backgroundColor: Colors.green,
                ),
              );

              // Add to wallet service
              final walletService = Provider.of<WalletService>(context, listen: false);
              walletService.addCard({
                'name': account['name'],
                'number': '****1234',
                'expiry': '12/28',
                'cvv': '***',
                'type': account['type'],
                'balance': '₹10,000',
                'balanceValue': 10000.0,
                'color': account['color'],
              });

              setState(() {
                _availableAccounts.removeWhere((a) => a['name'] == account['name']);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }
  
  void _showDisconnectConfirmationDialog(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Account'),
        content: Text(
          'Are you sure you want to disconnect ${account['name']}? You can reconnect it later.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // For now we just show a success message as the wallet service doesn't have a disconnect method
              // In a real app, we would update the account status in the wallet service
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${account['name']} disconnected'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
  
  void _showRemoveConfirmationDialog(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text(
          'Are you sure you want to remove ${account['name']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Get the wallet service and find the card index
              final walletService = Provider.of<WalletService>(context, listen: false);
              final cards = walletService.cards;
              final index = cards.indexWhere((card) => card['name'] == account['name']);
              
              // Remove the card if found
              if (index != -1) {
                walletService.removeCard(index);
              }
              
              // Add to available accounts
              setState(() {
                _availableAccounts.add({
                  'type': account['type'],
                  'name': account['name'],
                  'icon': Icons.account_balance,
                  'color': account['color'],
                });
              });
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${account['name']} removed'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
