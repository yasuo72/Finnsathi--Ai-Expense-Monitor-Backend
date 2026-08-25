import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service_manager.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool isTodaySelected = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final apiManager = Provider.of<ApiServiceManager>(context, listen: false);
      if (apiManager.notifications.isEmpty) {
        await _refreshNotifications(showFullScreenLoader: true);
      } else {
        await _refreshNotifications(showFullScreenLoader: false);
      }
    });
  }

  Future<void> _refreshNotifications({
    bool showFullScreenLoader = false,
  }) async {
    if (showFullScreenLoader) {
      setState(() {
        _isRefreshing = true;
      });
    }

    final apiManager = Provider.of<ApiServiceManager>(context, listen: false);
    await apiManager.refreshNotificationsOnly();

    if (!mounted) return;

    if (showFullScreenLoader) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
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
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.notifications_none, color: Colors.white),
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
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isTodaySelected = true;
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isTodaySelected
                                  ? Colors.white
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            color:
                                isTodaySelected ? Colors.black : Colors.white,
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
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              !isTodaySelected
                                  ? Colors.white
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Past',
                          style: TextStyle(
                            color:
                                !isTodaySelected ? Colors.black : Colors.white,
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
            child: Consumer<ApiServiceManager>(
              builder: (context, apiManager, _) {
                final now = DateTime.now();

                final notifications =
                    apiManager.notifications.map((n) {
                      final createdRaw =
                          n['createdAt']?.toString() ??
                          DateTime.now().toString();
                      DateTime createdAt;
                      try {
                        createdAt = DateTime.parse(createdRaw).toLocal();
                      } catch (_) {
                        createdAt = now;
                      }

                      final isToday =
                          createdAt.year == now.year &&
                          createdAt.month == now.month &&
                          createdAt.day == now.day;

                      final isRead = n['isRead'] == true;

                      return NotificationItemData(
                        id: (n['_id'] ?? '').toString(),
                        icon: Icons.notifications_outlined,
                        iconColor: isRead ? Colors.grey : Colors.blueAccent,
                        bgColor:
                            isRead
                                ? Colors.grey.shade200
                                : const Color(0xFFE3F2FD),
                        title: n['title']?.toString() ?? 'Notification',
                        subtitle: n['message']?.toString() ?? '',
                        isToday: isToday,
                        isRead: isRead,
                        createdAt: createdAt,
                      );
                    }).toList();

                final currentList =
                    notifications
                        .where((n) => n.isToday == isTodaySelected)
                        .toList();

                final isLoading =
                    notifications.isEmpty &&
                    (apiManager.isLoading || _isRefreshing);

                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (currentList.isEmpty) {
                  return const Center(child: Text('No notifications'));
                }

                return ListView.builder(
                  itemCount: currentList.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = currentList[index];
                    return NotificationCard(
                      item: item,
                      onTap: () async {
                        final apiManager = Provider.of<ApiServiceManager>(
                          context,
                          listen: false,
                        );
                        if (item.id.isNotEmpty) {
                          await apiManager.markNotificationAsRead(item.id);
                        }

                        if (!context.mounted) return;

                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          backgroundColor: Colors.white,
                          builder: (context) {
                            return NotificationBottomSheet(
                              icon: item.icon,
                              iconColor: item.iconColor,
                              bgColor: item.bgColor,
                              title: item.title,
                              subtitle: item.subtitle,
                            );
                          },
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
    );
  }
}

class NotificationItemData {
  final String id;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final bool isToday;
  final bool isRead;
  final DateTime createdAt;

  NotificationItemData({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.isToday,
    required this.isRead,
    required this.createdAt,
  });
}

class NotificationCard extends StatelessWidget {
  final NotificationItemData item;
  final VoidCallback onTap;

  NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: item.bgColor,
          child: Icon(item.icon, color: item.iconColor, size: 30),
        ),
        title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item.subtitle),
        onTap: onTap,
      ),
    );
  }
}

class NotificationBottomSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;

  const NotificationBottomSheet({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_handle, color: Colors.grey[400]),
          SizedBox(height: 12),
          CircleAvatar(
            radius: 30,
            backgroundColor: bgColor,
            child: Icon(icon, color: iconColor, size: 30),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
            label: Text('Close'),
          ),
        ],
      ),
    );
  }
}
