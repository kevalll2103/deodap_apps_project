import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// ====== CHAT MESSAGE MODEL ======
class ChatMessage {
  final int id;
  final int planStepId;
  final int dropshipperId;
  final int? empId;
  final String senderType;
  final String message;
  final DateTime createdAt;
  final String stepStatus;

  ChatMessage({
    required this.id,
    required this.planStepId,
    required this.dropshipperId,
    this.empId,
    required this.senderType,
    required this.message,
    required this.stepStatus,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      planStepId: int.tryParse(json['plan_step_id']?.toString() ?? '0') ?? 0,
      dropshipperId: int.tryParse(json['dropshipper_id']?.toString() ?? '0') ?? 0,
      empId: json['emp_id'] != null ? int.tryParse(json['emp_id'].toString()) : null,
      senderType: json['sender_type']?.toString().toLowerCase() ?? 'dropshipper',
      message: json['message']?.toString() ?? '',
      stepStatus: json['step_status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isFromDropshipper => senderType == 'dropshipper';
  bool get isFromAdmin => senderType == 'admin';
  bool get isFromEmployee => senderType == 'employee';
}

// ====== STEP INFO MODEL ======
class StepInfo {
  final String stepStatus;
  final int stepNumber;
  final String stepDescription;
  final String planName;

  StepInfo({
    required this.stepStatus,
    required this.stepNumber,
    required this.stepDescription,
    required this.planName,
  });

  factory StepInfo.fromJson(Map<String, dynamic> json) {
    return StepInfo(
      stepStatus: json['step_status']?.toString() ?? 'pending',
      stepNumber: int.tryParse(json['step_number']?.toString() ?? '1') ?? 1,
      stepDescription: json['step_description']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? 'Unknown Plan',
    );
  }
}

// ====== CHAT API SERVICE ======
class ChatApiService {
  static const String baseUrl = 'https://customprint.deodap.com/api_dropshipper_tracker';

  static Future<Map<String, dynamic>> loadMessages({
    required int planStepId,
    required int dropshipperId,
    int limit = 50,
    int offset = 0,
    int? lastMessageId,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'plan_step_id': planStepId.toString(),
        'dropshipper_id': dropshipperId.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (lastMessageId != null) {
        queryParams['last_message_id'] = lastMessageId.toString();
      }

      final uri = Uri.parse('$baseUrl/get_chat_history.php').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int planStepId,
    required int dropshipperId,
    required String message,
    String senderType = 'dropshipper',
    int? empId,
  }) async {
    try {
      final requestBody = {
        'plan_step_id': planStepId,
        'dropshipper_id': dropshipperId,
        'sender_type': senderType,
        'message': message,
        if (empId != null) 'emp_id': empId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chatt.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteMessage({
    required int messageId,
    required int planStepId,
    required int dropshipperId,
    String senderType = 'dropshipper',
  }) async {
    try {
      final requestBody = {
        'message_id': messageId,
        'plan_step_id': planStepId,
        'dropshipper_id': dropshipperId,
        'sender_type': senderType,
      };

      final response = await http.delete(
        Uri.parse('$baseUrl/chatt.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}

// ====== MAIN CHAT SCREEN ======
class StepChatScreen extends StatefulWidget {
  final int stepId;
  final int stepNumber;
  final String stepDescription;
  final int dropshipperId;
  final String planName;
  final String stepStatus;
  final void Function(String status)? onStatusUpdated;

  const StepChatScreen({
    super.key,
    required this.stepId,
    required this.stepNumber,
    required this.stepDescription,
    required this.dropshipperId,
    required this.planName,
    required this.stepStatus,
    this.onStatusUpdated,
  });

  @override
  State<StepChatScreen> createState() => _StepChatScreenState();
}

class _StepChatScreenState extends State<StepChatScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {

  // ====== CONTROLLERS ======
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  // ====== STATE VARIABLES ======
  List<ChatMessage> messages = [];
  StepInfo? stepInfo;
  bool isLoading = true;
  bool isSending = false;
  bool isLoadingMore = false;
  bool hasMoreMessages = false;
  String? errorMessage;
  Timer? _refreshTimer;
  int _currentPage = 1;
  final int _messagesPerPage = 50;

  // ====== ANIMATION CONTROLLERS ======
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  // ====== THEME COLORS ======
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color whiteColor = Colors.white;
  static const Color greyLight = Color(0xFFF8F9FA);
  static const Color greyMedium = Color(0xFFE0E0E0);
  static const Color textBlack = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _setupScrollListener();
    _messageController.addListener(_onMessageChanged);
    _loadInitialMessages();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _sendButtonController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ====== INITIALIZATION METHODS ======
  void _initializeAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= 100 && !isLoadingMore && hasMoreMessages) {
        _loadMoreMessages();
      }
    });
  }

  void _onMessageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadMessages(silent: true);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !isLoading && !isSending && !isLoadingMore) {
        _loadMessages(silent: true);
      }
    });
  }

  // ====== MESSAGE LOADING METHODS ======
  Future<void> _loadInitialMessages() async {
    await _loadMessages();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!mounted) return;

    try {
      if (!silent) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final response = await ChatApiService.loadMessages(
        planStepId: widget.stepId,
        dropshipperId: widget.dropshipperId,
        limit: _messagesPerPage,
        offset: 0,
      );

      if (mounted) {
        if (response['success'] == true) {
          final List<dynamic> messagesData = response['messages'] ?? [];
          final Map<String, dynamic>? stepInfoData = response['step_info'];

          final newMessages = messagesData
              .map((messageJson) => ChatMessage.fromJson(messageJson))
              .toList();

          // Sort messages by creation time
          newMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

          setState(() {
            messages = newMessages;
            if (stepInfoData != null) {
              stepInfo = StepInfo.fromJson(stepInfoData);
            }

            // Handle pagination info
            final pagination = response['pagination'];
            if (pagination != null) {
              hasMoreMessages = pagination['has_more'] ?? false;
              _currentPage = pagination['current_page'] ?? 1;
            }

            isLoading = false;
            errorMessage = null;
          });

          if (!silent) {
            _scrollToBottom();
          }
        } else {
          if (!silent) {
            setState(() {
              errorMessage = response['message'] ?? 'Failed to load messages';
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted && !silent) {
        setState(() {
          errorMessage = 'Connection error. Please check your internet connection.';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (isLoadingMore || !hasMoreMessages) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final response = await ChatApiService.loadMessages(
        planStepId: widget.stepId,
        dropshipperId: widget.dropshipperId,
        limit: _messagesPerPage,
        offset: messages.length,
      );

      if (mounted && response['success'] == true) {
        final List<dynamic> messagesData = response['messages'] ?? [];

        final newMessages = messagesData
            .map((messageJson) => ChatMessage.fromJson(messageJson))
            .toList();

        setState(() {
          // Insert new messages at the beginning (older messages)
          messages.insertAll(0, newMessages);

          // Update pagination info
          final pagination = response['pagination'];
          if (pagination != null) {
            hasMoreMessages = pagination['has_more'] ?? false;
          }

          isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
        _showErrorSnackBar('Failed to load more messages');
      }
    }
  }

  Future<void> _refreshMessages() async {
    _currentPage = 1;
    await _loadMessages();
  }

  // ====== MESSAGE SENDING METHOD ======
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || isSending) return;

    // Check if step is in process
    final currentStepStatus = stepInfo?.stepStatus ?? widget.stepStatus;
    if (currentStepStatus.toLowerCase() != 'in process') {
      _showErrorSnackBar('Messaging is only available when step is in process');
      return;
    }

    // Animate send button
    _sendButtonController.forward().then((_) {
      _sendButtonController.reverse();
    });

    final messageToSend = message;
    _messageController.clear();

    setState(() {
      isSending = true;
    });

    try {
      final response = await ChatApiService.sendMessage(
        planStepId: widget.stepId,
        dropshipperId: widget.dropshipperId,
        message: messageToSend,
      );

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            isSending = false;
          });

          _messageFocusNode.unfocus();
          _showSuccessSnackBar('Message sent successfully');
          await _loadMessages(silent: true);
        } else {
          setState(() {
            isSending = false;
          });
          _messageController.text = messageToSend;
          _showErrorSnackBar(response['message'] ?? 'Failed to send message');
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() {
          isSending = false;
        });
        _messageController.text = messageToSend;
        _showErrorSnackBar('Failed to send message. Please check your connection.');
      }
    }
  }

  // ====== MESSAGE DELETION METHOD ======
  Future<void> _deleteMessage(int messageId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await ChatApiService.deleteMessage(
        messageId: messageId,
        planStepId: widget.stepId,
        dropshipperId: widget.dropshipperId,
      );

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            messages.removeWhere((msg) => msg.id == messageId);
          });
          _showSuccessSnackBar('Message deleted successfully');
        } else {
          _showErrorSnackBar(response['message'] ?? 'Failed to delete message');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting message: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ====== UTILITY METHODS ======
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: whiteColor, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: whiteColor, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _getStatusDisplay() {
    final currentStatus = stepInfo?.stepStatus ?? widget.stepStatus;
    switch (currentStatus.toLowerCase()) {
      case 'in process':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      default:
        return currentStatus;
    }
  }

  // ====== UI BUILD METHODS ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greyLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStepInfo(),
          Expanded(child: _buildChatBody()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkBlue, primaryBlue],
          ),
        ),
      ),
      foregroundColor: whiteColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: whiteColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: whiteColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              size: 22,
              color: whiteColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Step Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: whiteColor,
                  ),
                ),
                Text(
                  'Step ${stepInfo?.stepNumber ?? widget.stepNumber} • ${_getStatusDisplay()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: whiteColor.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: whiteColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isLoading ? null : _refreshMessages,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                  ),
                )
                    : const Icon(Icons.refresh_rounded, color: whiteColor, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepInfo() {
    final currentStepInfo = stepInfo;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue.withOpacity(0.1), primaryBlue.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${currentStepInfo?.stepNumber ?? widget.stepNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStepInfo?.stepDescription ?? widget.stepDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textBlack,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentStepInfo?.planName ?? widget.planName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final currentStatus = stepInfo?.stepStatus ?? widget.stepStatus;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (currentStatus.toLowerCase()) {
      case 'in process':
        statusColor = successGreen;
        statusIcon = Icons.play_circle_outline_rounded;
        statusText = 'Active';
        break;
      case 'completed':
        statusColor = primaryBlue;
        statusIcon = Icons.check_circle_outline_rounded;
        statusText = 'Done';
        break;
      case 'pending':
        statusColor = warningOrange;
        statusIcon = Icons.schedule_rounded;
        statusText = 'Pending';
        break;
      default:
        statusColor = textGrey;
        statusIcon = Icons.help_outline_rounded;
        statusText = currentStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody() {
    if (isLoading && messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading messages...',
              style: TextStyle(
                color: textGrey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null && messages.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: errorRed,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                errorMessage ?? 'Failed to load messages',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your connection and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshMessages,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: whiteColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a conversation with the support team',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGrey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            if (isLoadingMore)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(message, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isFromMe = message.isFromDropshipper;
    final showDateHeader = index == 0 ||
        !_isSameDay(messages[index - 1].createdAt, message.createdAt);

    Color bubbleColor;
    IconData avatarIcon;
    String senderLabel;

    if (message.isFromDropshipper) {
      bubbleColor = primaryBlue;
      avatarIcon = Icons.person_rounded;
      senderLabel = 'You';
    } else if (message.isFromAdmin) {
      bubbleColor = successGreen;
      avatarIcon = Icons.admin_panel_settings_rounded;
      senderLabel = 'Admin';
    } else {
      bubbleColor = warningOrange;
      avatarIcon = Icons.support_agent_rounded;
      senderLabel = 'Support';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDateHeader) _buildDateHeader(message.createdAt),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isFromMe) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: bubbleColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    avatarIcon,
                    size: 20,
                    color: whiteColor,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: isFromMe ? () => _showDeleteDialog(message) : null,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isFromMe ? bubbleColor : whiteColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isFromMe ? 20 : 6),
                        bottomRight: Radius.circular(isFromMe ? 6 : 20),
                      ),
                      border: !isFromMe ? Border.all(color: greyMedium.withOpacity(0.3)) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isFromMe ? 0.1 : 0.04),
                          blurRadius: isFromMe ? 8 : 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isFromMe)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  senderLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: bubbleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          message.message,
                          style: TextStyle(
                            color: isFromMe ? whiteColor : textBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatMessageTime(message.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isFromMe
                                    ? whiteColor.withOpacity(0.8)
                                    : textGrey.withOpacity(0.8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (isFromMe) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.done_rounded,
                                size: 14,
                                color: whiteColor.withOpacity(0.8),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isFromMe) ...[
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: bubbleColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    avatarIcon,
                    size: 20,
                    color: whiteColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: errorRed),
              SizedBox(width: 12),
              Text('Delete Message'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this message? This action cannot be undone.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: errorRed,
                foregroundColor: whiteColor,
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage(message.id);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: greyMedium.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _formatDateHeader(date),
            style: const TextStyle(
              fontSize: 13,
              color: textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final currentStepStatus = stepInfo?.stepStatus ?? widget.stepStatus;
    final isStepInProcess = currentStepStatus.toLowerCase() == 'in process';
    final hasText = _messageController.text.trim().isNotEmpty;
    final canSend = hasText && !isSending && isStepInProcess;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: greyLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _messageFocusNode.hasFocus && isStepInProcess
                        ? primaryBlue.withOpacity(0.5)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  enabled: isStepInProcess,
                  maxLines: null,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: canSend ? (_) => _sendMessage() : null,
                  decoration: InputDecoration(
                    hintText: isStepInProcess
                        ? 'Type your message...'
                        : 'Messaging disabled (step not in process)',
                    hintStyle: TextStyle(
                      color: isStepInProcess ? textGrey : textGrey.withOpacity(0.6),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: isStepInProcess ? textBlack : textGrey,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedBuilder(
              animation: _sendButtonAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendButtonAnimation.value,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: canSend
                          ? const LinearGradient(
                        colors: [darkBlue, primaryBlue],
                      )
                          : null,
                      color: !canSend ? greyMedium : null,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: canSend
                          ? [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: canSend ? _sendMessage : null,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: isSending
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                            ),
                          )
                              : Icon(
                            Icons.send_rounded,
                            color: canSend ? whiteColor : textGrey.withOpacity(0.6),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ====== UTILITY FORMATTING METHODS ======
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatMessageTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return weekdays[date.weekday % 7];
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    }
  }
}
