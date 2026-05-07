import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/notification.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final notifs = await _api.getNotifications();
    setState(() {
      _notifications = notifs;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await _api.markAllRead();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return Card(
                  color: n.isRead
                      ? Colors.white
                      : AppTheme.primary.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: n.type == 'success'
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Icon(
                        n.type == 'success' ? Icons.check_circle : Icons.error,
                        color: n.type == 'success' ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      n.message,
                      style: TextStyle(
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(n.timestamp.substring(0, 16)),
                    trailing: !n.isRead
                        ? GestureDetector(
                            onTap: () async {
                              await _api.markRead(n.id);
                              _load();
                            },
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
