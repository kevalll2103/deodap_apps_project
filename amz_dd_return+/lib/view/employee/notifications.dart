import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? errorMessage;
  int unseenCount = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      // Check internet connection
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection');
      }

      await _markAllSeen();
      await _fetchNotifications();
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = _getErrorMessage(e);
          isLoading = false;
        });
      }
      debugPrint("Error loading notifications: $e");
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('formatexception')) {
      return 'Server returned invalid data. Please try again later.';
    } else if (errorString.contains('socketexception') || errorString.contains('no internet')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout. Please try again.';
    } else if (errorString.contains('http')) {
      return 'Server error. Please try again later.';
    }
    return 'Failed to load notifications. Please try again.';
  }

  Future<void> _fetchNotifications() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse("https://customprint.deodap.com/api_amzDD_return/get_notification.php"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint("API Response: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw const FormatException('Empty response body');
        }

        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
              unseenCount = data['unseen_count'] ?? 0;
              isLoading = false;
            });
          }
          return;
        }
        throw Exception(data['message'] ?? 'API returned success=false');
      }
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } on FormatException catch (e) {
      debugPrint("Format exception: $e");
      throw Exception('Invalid server response format');
    } catch (e) {
      debugPrint("Fetch error: $e");
      rethrow;
    }
  }

  Future<void> _markAllSeen() async {
    try {
      final response = await http.post(
        Uri.parse("https://customprint.deodap.com/api_amzDD_return/mark_all_notifications_read.php"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      debugPrint("Mark seen status: ${response.statusCode}");
      debugPrint("Mark seen response: ${response.body}");
    } catch (e) {
      debugPrint("Error marking notifications as seen: $e");
    }
  }

  Future<void> _onRefresh() async {
    await _loadNotifications();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF1A365D),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A365D),
                Color(0xFF2C5AA0),
              ],
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (unseenCount > 0)
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unseenCount',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Color(0xFFF8FAFC),
      body: _buildBody(),
    );
  }



  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF1A365D),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading notifications...',
                style: GoogleFonts.poppins(
                  color: Color(0xFF2D3748),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: GoogleFonts.poppins(
                  color: Color(0xFF2D3748),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A365D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh),
                label: Text(
                  "Retry",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF1A365D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 48,
                  color: Color(0xFF1A365D),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "No notifications found",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Pull down to refresh",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _onRefresh,
      color: const Color(0xFF1A365D),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification, index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final bool isUnseen = notification['seen_by_admin'] == 0;
    final String message = notification['message']?.toString() ?? 'No message';
    final String sellerName = notification['seller_name']?.toString() ?? '';
    final String createdAt = notification['created_at']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnseen ? Color(0xFF1A365D) : Color(0xFFE2E8F0),
          width: isUnseen ? 2 : 1,
        ),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          debugPrint("Notification tapped: $message");
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUnseen 
                          ? Color(0xFF1A365D).withOpacity(0.1)
                          : Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: isUnseen ? Color(0xFF1A365D) : Color(0xFF718096),
                      size: 24,
                    ),
                  ),
                  if (isUnseen)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        color: Color(0xFF2D3748),
                        fontSize: 16,
                        fontWeight: isUnseen ? FontWeight.w600 : FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Seller name
                    if (sellerName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A365D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Color(0xFF1A365D),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sellerName,
                              style: GoogleFonts.poppins(
                                color: Color(0xFF1A365D),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (sellerName.isNotEmpty) const SizedBox(height: 12),

                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF718096),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(createdAt),
                          style: GoogleFonts.poppins(
                            color: Color(0xFF718096),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF718096),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}