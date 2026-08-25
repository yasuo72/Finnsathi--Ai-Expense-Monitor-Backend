import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How do I add a new transaction?',
      'answer': 'To add a new transaction, tap on the "+" button at the bottom of the home screen, then select "Income" or "Expense" and fill in the details.',
      'isExpanded': false,
    },
    {
      'question': 'How do I link my bank account?',
      'answer': 'Go to Profile > Linked Accounts and tap on "Link Account". Select your bank from the list and follow the instructions to securely link your account.',
      'isExpanded': false,
    },
    {
      'question': 'Is my financial data secure?',
      'answer': 'Yes, we use industry-standard encryption to protect your data. We never store your bank credentials, and all connections are made through secure APIs.',
      'isExpanded': false,
    },
    {
      'question': 'How do I set up a budget?',
      'answer': 'Go to the Budget tab, tap on "Create Budget", select a category, set your budget amount, and choose the time period (weekly, monthly, etc.).',
      'isExpanded': false,
    },
    {
      'question': 'Can I export my financial data?',
      'answer': 'Yes, go to Settings > Data Management > Export Data. You can export your data in CSV or PDF format.',
      'isExpanded': false,
    },
    {
      'question': 'How do I change my password?',
      'answer': 'Go to Profile > Security > Change Password. Enter your current password and your new password, then confirm the new password.',
      'isExpanded': false,
    },
  ];

  final List<Map<String, dynamic>> _supportOptions = [
    {
      'title': 'Chat with Support',
      'icon': Icons.chat_bubble_outline,
      'color': Colors.blue,
    },
    {
      'title': 'Email Support',
      'icon': Icons.email_outlined,
      'color': Colors.green,
    },
    {
      'title': 'Call Support',
      'icon': Icons.phone_outlined,
      'color': Colors.orange,
    },
    {
      'title': 'Video Call',
      'icon': Icons.video_call_outlined,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSupportHeader(isDark),
            const SizedBox(height: 24),
            _buildSupportOptions(isDark),
            const SizedBox(height: 24),
            _buildFaqSection(isDark),
            const SizedBox(height: 24),
            _buildContactSection(isDark),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSupportHeader(bool isDark) {
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
                    Icons.support_agent,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for help',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSupportOptions(bool isDark) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: _supportOptions.length,
            itemBuilder: (context, index) {
              final option = _supportOptions[index];
              return _buildSupportOptionCard(
                title: option['title'],
                icon: option['icon'],
                color: option['color'],
                isDark: isDark,
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSupportOptionCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        _handleSupportOptionTap(title);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFaqSection(bool isDark) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Container(
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
            child: ExpansionPanelList(
              elevation: 0,
              expandedHeaderPadding: EdgeInsets.zero,
              dividerColor: isDark ? Colors.white12 : Colors.black12,
              expansionCallback: (index, isExpanded) {
                setState(() {
                  _faqItems[index]['isExpanded'] = !isExpanded;
                });
              },
              children: _faqItems.map<ExpansionPanel>((item) {
                return ExpansionPanel(
                  headerBuilder: (context, isExpanded) {
                    return ListTile(
                      title: Text(
                        item['question'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      item['answer'],
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  isExpanded: item['isExpanded'],
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  canTapOnHeader: true,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Navigate to full FAQ page
              },
              icon: Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                'View All FAQs',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactSection(bool isDark) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Still Need Help?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.email_outlined,
              title: 'Email Us',
              subtitle: 'support@finnsathi.com',
              isDark: isDark,
              onTap: () {
                // Open email app
              },
            ),
            const Divider(),
            _buildContactItem(
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+91 98765 43210',
              isDark: isDark,
              onTap: () {
                // Open phone app
              },
            ),
            const Divider(),
            _buildContactItem(
              icon: Icons.location_on_outlined,
              title: 'Visit Us',
              subtitle: '123 Finance Street, Mumbai, India',
              isDark: isDark,
              onTap: () {
                // Open maps app
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
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
  
  void _handleSupportOptionTap(String option) {
    // In a real app, you would implement the actual support options
    // For now, we'll just show a snackbar
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$option will be available soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
