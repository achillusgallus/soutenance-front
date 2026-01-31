import 'package:flutter/material.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final api = ApiService();
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await api.read("/notifications");
      if (mounted) {
        setState(() {
          final data = res?.data;
          // Handle pagination wrapper if present
          if (data is Map && data.containsKey('data')) {
            notifications = data['data'];
          } else if (data is List) {
            notifications = data;
          } else {
            notifications = [];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    try {
      await api.create("/notifications/$id/read", {});
      setState(() {
        notifications[index]['read'] = true;
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _markAllRead() async {
    try {
      await api.create("/notifications/read-all", {});
      setState(() {
        for (var i = 0; i < notifications.length; i++) {
          notifications[i]['read'] = true;
        }
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.black54),
            onPressed: _markAllRead,
            tooltip: "Tout marquer comme lu",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final isRead = n['read'] == true || n['read'] == 1;
                  return _buildNotificationCard(n, index, isRead);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.bellSlash,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune notification",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic n, int index, bool isRead) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        if (!isRead) _markAsRead(n['id'], index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? theme.cardColor : Colors.white)
              : (isDark
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : const Color(0xFFEEF2FF)),
          borderRadius: BorderRadius.circular(16),
          border: isRead
              ? Border.all(color: theme.dividerColor)
              : Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRead
                    ? (isDark ? Colors.white10 : Colors.grey.shade100)
                    : (isDark ? theme.cardColor : Colors.white),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(n['type']),
                color: _getColor(n['type']),
                size: 18,
              ),
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
                          n['title'] ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n['message'] ?? '',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (n['created_at'] != null)
                    Text(
                      n['created_at'].toString().split(
                        'T',
                      )[0], // Simple date formating
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'warning':
        return FontAwesomeIcons.circleExclamation;
      case 'success':
        return FontAwesomeIcons.circleCheck;
      default:
        return FontAwesomeIcons.bell;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }
}
