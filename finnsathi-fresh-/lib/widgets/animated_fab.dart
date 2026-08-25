import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

class AnimatedFAB extends StatefulWidget {
  final void Function()? onAddExpense;
  final void Function()? onAddIncome;
  final void Function()? onAiChat;
  final void Function()? onReceiptScanner;

  const AnimatedFAB({
    super.key,
    this.onAddExpense,
    this.onAddIncome,
    this.onAiChat,
    this.onReceiptScanner,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animateIcon;
  bool isOpened = false;
  final double _distance = 72.0; // Distance between each FAB vertically

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animateIcon = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (isOpened) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      isOpened = !isOpened;
    });
  }

  void _navigateToReceiptScanner() {
    if (widget.onReceiptScanner != null) {
      widget.onReceiptScanner!();
    } else {
      // Use NavigationService for consistent routing
      NavigationService().navigateTo('/receipt-scanner');
    }
  }

  Widget _buildVerticalFAB({
    required int index,
    required IconData icon,
    required Color color,
    required String tooltip,
    required void Function()? onTap,
    required String label,
    required Color shadowColor,
    required Animation<double> animation,
    Widget? trailing,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final offset = _distance * (index + 1) * animation.value;
        return Positioned(
          right: 0,
          bottom: 0 + offset,
          width: 240, // Ensure consistent width for the row
          height: 48, // Fixed height for the row
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: '${tooltip}_${UniqueKey()}',
                    mini: true,
                    backgroundColor: color,
                    elevation: 6,
                    onPressed: () {
                      _toggle();
                      if (tooltip == 'Receipt Scanner') {
                        _navigateToReceiptScanner();
                      } else if (onTap != null) {
                        onTap();
                      }
                    },
                    tooltip: tooltip,
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> expenseAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    final Animation<double> incomeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.7, curve: Curves.easeOutBack),
    );
    final Animation<double> receiptAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOutBack),
    );
    final Animation<double> aiChatAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutBack),
    );

    // Use a LayoutBuilder to ensure the widget is properly sized
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.only(right: 12.0, bottom: 12.0),
          child: Container(
            width: 260, // Enough for label+FAB
            height: _distance * 5,
            constraints: const BoxConstraints.tightFor(
              width: 260,
              height: 350, // 5 buttons * distance
            ),
            child: Stack(
                      clipBehavior: Clip.none,
              fit: StackFit.passthrough,
              alignment: Alignment.bottomRight,
              children: [
                if (widget.onAiChat != null)
              _buildVerticalFAB(
                index: 0,
                icon: Icons.chat_bubble_outline,
                color: Colors.deepPurple.shade400,
                shadowColor: Colors.deepPurple,
                tooltip: 'AI Chat',
                label: 'AI Chat',
                onTap: widget.onAiChat,
                animation: aiChatAnim,
              ),
            _buildVerticalFAB(
                index: widget.onAiChat != null ? 1 : 0,
                icon: Icons.receipt_long,
                color: Colors.blue.shade600,
                shadowColor: Colors.blue,
                tooltip: 'Receipt Scanner',
                label: 'Receipt Scanner',
                onTap: _navigateToReceiptScanner,
                animation: receiptAnim,
              ),
            _buildVerticalFAB(
                index: widget.onAiChat != null ? 2 : 1,
                icon: Icons.add_circle_outline,
                color: Colors.green.shade600,
                shadowColor: Colors.green,
                tooltip: 'Add Income',
                label: 'Add Income',
                onTap: widget.onAddIncome,
                animation: incomeAnim,
              ),
            _buildVerticalFAB(
                index: widget.onAiChat != null ? 3 : 2,
                icon: Icons.remove_circle_outline,
                color: Colors.red.shade600,
                shadowColor: Colors.red,
                tooltip: 'Add Expense',
                label: 'Add Expense',
                onTap: widget.onAddExpense,
                animation: expenseAnim,
              ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: 56, // Standard FAB size
                  height: 56,
                  child: FloatingActionButton(
                    heroTag: 'mainFAB_${UniqueKey()}',
                    onPressed: _toggle,
                    tooltip: isOpened ? 'Close' : 'Actions',
                    backgroundColor: Colors.white,
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
                    ),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isOpened
                            ? LinearGradient(colors: [Colors.purple, Colors.blue])
                            : LinearGradient(colors: [Theme.of(context).colorScheme.primary, Colors.blueAccent]),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AnimatedIcon(
                          icon: AnimatedIcons.menu_close,
                          progress: _animateIcon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}