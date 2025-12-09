import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'New Update',
      body: json['body'] ?? 'You have a new notification',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      
      setState(() {
        _notifications = notificationsJson
            .map((json) => NotificationItem.fromJson(
                  Map<String, dynamic>.from(jsonDecode(json)),
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    setState(() {
      notification.isRead = true;
    });
    await _saveNotifications();
  }

  Future<void> _deleteNotification(String id) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    await _saveNotifications();
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((n) => jsonEncode(n.toJson()))
          .toList();
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n.isRead = true;
                  }
                });
                _saveNotifications();
              },
              child: const Text(
                'Mark all as read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Dismissible(
                      key: Key(notification.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteNotification(notification.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Notification deleted'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () {
                                setState(() {
                                  _notifications.insert(index, notification);
                                });
                                _saveNotifications();
                              },
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notification.isRead
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.body),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, y • hh:mm a')
                                  .format(notification.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _markAsRead(notification);
                          // Handle notification tap (e.g., navigate to relevant screen)
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// Helper function to add a new notification
Future<void> addNewNotification({
  required String title,
  required String body,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList('notifications') ?? [];
    
    final newNotification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    
    notificationsJson.insert(0, jsonEncode(newNotification.toJson()));
    await prefs.setStringList('notifications', notificationsJson);
    
    // You can also trigger a local notification here if needed
  } catch (e) {
    debugPrint('Error adding notification: $e');
  }
}