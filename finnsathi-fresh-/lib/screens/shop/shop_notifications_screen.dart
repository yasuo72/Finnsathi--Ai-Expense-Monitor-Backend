import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shop_models.dart';
import '../../services/shop_api_service.dart';
import '../../services/auth_state_service.dart';
import '../../services/api_service_manager.dart';
import '../../routing/app_routes.dart';

class ShopNotificationPage extends StatefulWidget {
  const ShopNotificationPage({Key? key}) : super(key: key);

  @override
  _ShopNotificationPageState createState() => _ShopNotificationPageState();
}

class _ShopNotificationPageState extends State<ShopNotificationPage> {
  bool isTodaySelected = true;
  List<ShopNotificationItemData> notifications = [];
  bool isLoading = true;
  static List<ShopNotificationItemData> _cachedNotifications = [];
  static bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    if (_hasLoadedOnce && _cachedNotifications.isNotEmpty) {
      notifications = List<ShopNotificationItemData>.from(_cachedNotifications);
      isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchNotifications(background: true);
      });
    } else {
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications({bool background = false}) async {
    if (!background) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final token = await AuthStateService.getAuthToken();
      if (token == null || token.isEmpty) {
        if (!background) {
          setState(() {
            isLoading = false;
            notifications = [];
          });
        }
        return;
      }

      final rawOrders = await ShopApiService.getUserOrders(token);
      final now = DateTime.now();

      final List<ShopNotificationItemData> items = [];

      for (final o in rawOrders) {
        final order = Order.fromJson(o);

        final bool isToday =
            order.orderTime.year == now.year &&
            order.orderTime.month == now.month &&
            order.orderTime.day == now.day;

        final Duration diff = now.difference(order.orderTime);
        String timeLabel;
        if (diff.inMinutes < 60) {
          final m = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
          timeLabel = '$m min ago';
        } else if (diff.inHours < 24) {
          timeLabel = '${diff.inHours} h ago';
        } else if (diff.inDays == 1) {
          timeLabel = 'Yesterday';
        } else {
          timeLabel = '${diff.inDays} days ago';
        }

        IconData icon;
        Color iconColor;
        Color bgColor;
        String title;

        switch (order.status) {
          case OrderStatus.placed:
            icon = Icons.receipt_long_outlined;
            iconColor = Colors.blue;
            bgColor = const Color(0xFFE3F2FD);
            title = 'Order Placed';
            break;
          case OrderStatus.confirmed:
            icon = Icons.check_circle_outline;
            iconColor = Colors.green;
            bgColor = const Color(0xFFC8E6C9);
            title = 'Order Confirmed';
            break;
          case OrderStatus.preparing:
            icon = Icons.restaurant;
            iconColor = Colors.orange;
            bgColor = const Color(0xFFFFECB3);
            title = 'Order Preparing';
            break;
          case OrderStatus.outForDelivery:
            icon = Icons.local_shipping_outlined;
            iconColor = Colors.purple;
            bgColor = const Color(0xFFF3E5F5);
            title = 'Order Out for Delivery';
            break;
          case OrderStatus.delivered:
            icon = Icons.home_outlined;
            iconColor = Colors.teal;
            bgColor = const Color(0xFFE0F2F1);
            title = 'Order Delivered';
            break;
          case OrderStatus.cancelled:
            icon = Icons.cancel_outlined;
            iconColor = Colors.red;
            bgColor = const Color(0xFFFFCDD2);
            title = 'Order Cancelled';
            break;
        }

        final subtitle =
            'Order #${order.id} is now ${_statusText(order.status)}';

        items.add(
          ShopNotificationItemData(
            icon: icon,
            iconColor: iconColor,
            bgColor: bgColor,
            title: title,
            subtitle: subtitle,
            isToday: isToday,
            time: timeLabel,
            order: order,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        notifications = items;
        isLoading = false;
      });
      _cachedNotifications = items;
      _hasLoadedOnce = true;
    } catch (e) {
      if (!background) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<ShopNotificationItemData> currentList =
        notifications.where((n) => n.isToday == isTodaySelected).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F38) : Colors.black,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Shop Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.notifications_none, color: Colors.white),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isTodaySelected = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isTodaySelected
                                  ? isDark
                                      ? Colors.purpleAccent
                                      : Colors.black
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            color:
                                isTodaySelected
                                    ? Colors.white
                                    : isDark
                                    ? Colors.white70
                                    : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isTodaySelected = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              !isTodaySelected
                                  ? isDark
                                      ? Colors.purpleAccent
                                      : Colors.black
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Earlier',
                          style: TextStyle(
                            color:
                                !isTodaySelected
                                    ? Colors.white
                                    : isDark
                                    ? Colors.white70
                                    : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : currentList.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 80,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: currentList.length,
                      itemBuilder: (context, index) {
                        final item = currentList[index];
                        return ShopNotificationCard(
                          item: item,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              backgroundColor:
                                  isDark
                                      ? const Color(0xFF1A1F38)
                                      : Colors.white,
                              builder: (context) {
                                return ShopNotificationBottomSheet(
                                  icon: item.icon,
                                  iconColor: item.iconColor,
                                  bgColor: item.bgColor,
                                  title: item.title,
                                  subtitle: item.subtitle,
                                  isDark: isDark,
                                  order: item.order,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Mark all notifications as read in the global notification manager
          final apiManager = Provider.of<ApiServiceManager>(
            context,
            listen: false,
          );
          await apiManager.markAllNotificationsAsRead();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: isDark ? Colors.purpleAccent : Colors.black,
        child: const Icon(Icons.done_all),
      ),
    );
  }
}

class ShopNotificationItemData {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final bool isToday;
  final String time;
  final Order order;

  ShopNotificationItemData({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.isToday,
    required this.time,
    required this.order,
  });
}

class ShopNotificationCard extends StatelessWidget {
  final ShopNotificationItemData item;
  final VoidCallback onTap;

  const ShopNotificationCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? const Color(0xFF1A1F38) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: item.bgColor,
                child: Icon(item.icon, color: item.iconColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopNotificationBottomSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final Order order;

  const ShopNotificationBottomSheet({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.drag_handle,
            color: isDark ? Colors.white38 : Colors.grey[400],
          ),
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 30,
            backgroundColor: bgColor,
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Dismiss'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.purpleAccent : Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // For order notifications, navigate to the order tracking screen
                  Navigator.pushNamed(
                    context,
                    AppRoutes.orderTracking,
                    arguments: order,
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
