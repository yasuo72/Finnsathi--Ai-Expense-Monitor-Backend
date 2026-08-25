import 'package:flutter/material.dart';

class QuickActions extends StatefulWidget {
  const QuickActions({Key? key}) : super(key: key);

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  final List<Map<String, dynamic>> _actions = [
    {
      'title': 'Send',
      'icon': Icons.send_rounded,
      'color': const Color(0xFF6C63FF),
    },
    {
      'title': 'Request',
      'icon': Icons.call_received_rounded,
      'color': const Color(0xFF23C16B),
    },
    {
      'title': 'Scan',
      'icon': Icons.qr_code_scanner_rounded,
      'color': const Color(0xFF3551A2),
    },
    {
      'title': 'Pay Bills',
      'icon': Icons.receipt_long_rounded,
      'color': const Color(0xFFFF7A50),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_actions.length, (index) {
              return _buildActionButton(
                context,
                _actions[index]['title'],
                _actions[index]['icon'],
                _actions[index]['color'],
                () {
                  _handleActionTap(index);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: color,
                      size: 30,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleActionTap(int index) {
    switch (index) {
      case 0: // Send Money
        Navigator.of(context).pushNamed('/send-money');
        break;
      case 1: // Request Money
        Navigator.of(context).pushNamed('/request-money');
        break;
      case 2: // Scan QR Code
        Navigator.of(context).pushNamed('/receipt-scanner');
        break;
      case 3: // Pay Bills
        Navigator.of(context).pushNamed('/pay-bills');
        break;
    }
  }

  void _showTransferDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalContent(
        title: 'Send Money',
        icon: Icons.send_rounded,
        iconColor: const Color(0xFF6C63FF),
        child: Column(
          children: [
            _buildRecentContacts(),
            const SizedBox(height: 20),
            _buildAmountInput('Enter Amount to Send'),
            const SizedBox(height: 20),
            _buildModalActionButton('Send Now', const Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }

  void _showRequestMoneyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalContent(
        title: 'Request Money',
        icon: Icons.call_received_rounded,
        iconColor: const Color(0xFF23C16B),
        child: Column(
          children: [
            _buildRecentContacts(),
            const SizedBox(height: 20),
            _buildAmountInput('Enter Amount to Request'),
            const SizedBox(height: 20),
            _buildModalActionButton('Request Now', const Color(0xFF23C16B)),
          ],
        ),
      ),
    );
  }

  void _showQRCodeScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalContent(
        title: 'Scan QR Code',
        icon: Icons.qr_code_scanner_rounded,
        iconColor: const Color(0xFF3551A2),
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 100,
                  color: Colors.black45,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildModalActionButton('Open Camera', const Color(0xFF3551A2)),
          ],
        ),
      ),
    );
  }

  void _showBillPaymentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalContent(
        title: 'Pay Bills',
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFFFF7A50),
        child: Column(
          children: [
            _buildBillCategories(),
            const SizedBox(height: 20),
            _buildModalActionButton('Continue', const Color(0xFFFF7A50)),
          ],
        ),
      ),
    );
  }

  Widget _buildModalContent({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecentContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Contacts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.primaries[index % Colors.primaries.length],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          ['A', 'S', 'D', 'F', 'G'][index],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ['Amy', 'Sam', 'David', 'Frank', 'Grace'][index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput(String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            prefixText: '₹ ',
            prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildBillCategories() {
    final categories = [
      {'title': 'Electricity', 'icon': Icons.electric_bolt},
      {'title': 'Water', 'icon': Icons.water_drop},
      {'title': 'Internet', 'icon': Icons.wifi},
      {'title': 'Mobile', 'icon': Icons.phone_android},
      {'title': 'Gas', 'icon': Icons.local_fire_department},
      {'title': 'TV', 'icon': Icons.tv},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    categories[index]['icon'] as IconData,
                    color: const Color(0xFFFF7A50),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categories[index]['title'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildModalActionButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        minimumSize: const Size(double.infinity, 54),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
