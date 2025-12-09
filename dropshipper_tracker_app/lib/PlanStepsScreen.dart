// Flutter imports
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// PlanStep model class - API response ના data ને represent કરે છે
class PlanStep {
  final int id;                    // Step નું unique ID
  final int planId;                // કયા plan નો step છે
  final int stepNumber;            // Step નું number (1, 2, 3...)
  final String stepDescription;    // Step નું description
  final String status;            // Status: 'open', 'in process', 'completed'
  final String? stepImage;        // Optional image for step
  final DateTime createdAt;       // Step બનાવવાની તારીખ

  PlanStep({
    required this.id,
    required this.planId,
    required this.stepNumber,
    required this.stepDescription,
    required this.status,
    this.stepImage,
    required this.createdAt,
  });

  // API response JSON ને PlanStep object માં convert કરે છે
  factory PlanStep.fromJson(Map<String, dynamic> json) {
    return PlanStep(
      id: int.parse(json['id'].toString()),
      planId: int.parse(json['plan_id'].toString()),
      stepNumber: int.parse(json['step_number'].toString()),
      stepDescription: json['step_description'] ?? '',
      status: json['status'] ?? 'open',
      stepImage: json['step_image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Comment model class - Comments API response ના data ને represent કરે છે
class Comment {
  final int id;
  final int planId;
  final int stepNumber;
  final String sellerId;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.planId,
    required this.stepNumber,
    required this.sellerId,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.parse(json['id'].toString()),
      planId: int.parse(json['plan_id'].toString()),
      stepNumber: int.parse(json['step_number'].toString()),
      sellerId: json['seller_id'].toString(),
      text: json['text'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Main screen to display plan steps in a PageView format
class PlanStepsScreen extends StatefulWidget {
  final int planId;       // Plan નું ID જેના steps show કરવાના છે
  final String planName;  // Plan નું name AppBar માં display કરવા માટે

  const PlanStepsScreen({
    Key? key,
    required this.planId,
    required this.planName,
  }) : super(key: key);

  @override
  _PlanStepsScreenState createState() => _PlanStepsScreenState();
}

class _PlanStepsScreenState extends State<PlanStepsScreen> {
  // ✅ Updated Blue-White Theme Colors with Black Text
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color whiteColor = Colors.white;
  static const Color greyLight = Color(0xFFF8F9FA);
  static const Color textBlack = Colors.black87;      // ✅ Primary text color
  static const Color textGrey = Colors.black54;       // ✅ Secondary text color
  static const Color textLight = Colors.black38;      // ✅ Light text color

  // State variables
  List<PlanStep> steps = [];                    // Plan ના બધા steps
  List<Comment> currentUserComments = [];       // Current user's comments for current step
  Map<int, int> stepCommentCounts = {};         // Per-step comment counts
  int totalCommentsCount = 0;                   // Total comments count across all steps
  bool isLoading = true;                        // Loading state
  bool isLoadingComments = false;               // Comments loading state
  bool isSendingComment = false;                // Comment sending state
  bool isRefreshing = false;                    // Refresh state
  String? errorMessage;                         // Error message
  int currentStepIndex = 0;                     // Currently displayed step index
  PageController pageController = PageController(); // PageView ને control કરવા માટે
  TextEditingController commentController = TextEditingController(); // Comment input controller
  ScrollController scrollController = ScrollController(); // Horizontal scroll controller

  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshInterval = Duration(seconds: 30);

  // API configuration
  static const String apiUrl = 'https://customprint.deodap.com/api_dropshipper_tracker/plans_complete.php';
  static const String commentsApiUrl = 'https://customprint.deodap.com/api_dropshipper_tracker/comments.php';

  // User data variables - SharedPreferences માંથી fetch કરાશે
  String? sellerId;                            // Current logged in seller નું ID
  Map<String, dynamic>? userData;              // Complete user data

  @override
  void initState() {
    super.initState();
    // Screen load થતાં જ user data load કરીને steps fetch કરે છે
    loadUserDataAndFetchSteps();
    // Auto-refresh timer start કરે છે
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // Memory leak prevent કરવા માટે controllers dispose કરે છે
    _autoRefreshTimer?.cancel();
    pageController.dispose();
    commentController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // Auto-refresh timer start કરે છે - silent refresh without notifications
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      if (mounted && sellerId != null) {
        _silentRefreshCurrentStepComments();
      }
    });
  }

  // Silent refresh for comments - no loading indicators or notifications
  Future<void> _silentRefreshCurrentStepComments() async {
    if (sellerId == null || steps.isEmpty) return;

    try {
      final currentStep = steps[currentStepIndex];
      final response = await http.get(
        Uri.parse('$commentsApiUrl?action=fetch&seller_id=$sellerId&plan_id=${widget.planId}&step_number=${currentStep.stepNumber}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> commentsData = data['comments'] ?? [];
          final allComments = commentsData.map((commentJson) => Comment.fromJson(commentJson)).toList();

          if (mounted) {
            setState(() {
              // Only show current user's comments
              final newComments = allComments
                  .where((comment) => comment.sellerId == sellerId)
                  .toList();
              newComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              // Update step comment count
              stepCommentCounts[currentStep.stepNumber] = newComments.length;
              currentUserComments = newComments;
            });

            // Update total count
            _updateTotalCommentsCount();
          }
        }
      }
    } catch (e) {
      // Silent fail for auto-refresh
    }
  }

  // SharedPreferences માંથી user data load કરે છે અને પછી steps fetch કરે છે
  Future<void> loadUserDataAndFetchSteps() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');

      if (userJson != null) {
        // JSON string ને Map માં convert કરે છે
        userData = jsonDecode(userJson);
        sellerId = userData!['seller_id']?.toString();

        if (sellerId != null) {
          // Seller ID મળ્યું છે, હવે steps fetch કરે છે
          await fetchPlanSteps();
        } else {
          // Seller ID નથી મળ્યું
          setState(() {
            errorMessage = 'Seller ID not found. Please login again.';
            isLoading = false;
          });
        }
      } else {
        // SharedPreferences માં user data જ નથી
        setState(() {
          errorMessage = 'User data not found. Please login again.';
          isLoading = false;
        });
      }
    } catch (e) {
      // કોઈ error આવ્યું છે
      setState(() {
        errorMessage = 'Error loading user data: $e';
        isLoading = false;
      });
    }
  }

  // API call કરીને plan steps fetch કરે છે
  Future<void> fetchPlanSteps() async {
    // Seller ID available છે કે નહીં check કરે છે
    if (sellerId == null) {
      setState(() {
        errorMessage = 'Seller ID not available. Please login again.';
        isLoading = false;
      });
      return;
    }

    try {
      // Loading state set કરે છે
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // API call - seller_id, plan_id, step_number parameters સાથે
      final response = await http.get(
        Uri.parse('$apiUrl?action=fetch_steps&seller_id=$sellerId&plan_id=${widget.planId}&step_number=1'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // API call successful
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Success response મળ્યો છે
          final List<dynamic> stepsData = data['steps'] ?? [];
          setState(() {
            // JSON data ને PlanStep objects માં convert કરે છે
            steps = stepsData.map((stepJson) => PlanStep.fromJson(stepJson)).toList();
            // Steps ને step number અનુસાર sort કરે છે
            steps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
            isLoading = false;
          });

          // All steps ના comments load કરે છે
          if (steps.isNotEmpty) {
            await fetchAllStepComments();
            await fetchCommentsForCurrentStep();
          }
        } else {
          // API માંથી error message આવ્યો છે
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load plan steps';
            isLoading = false;
          });
        }
      } else {
        // HTTP error (404, 500, etc.)
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      // Network error અથવા parsing error
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  // ✅ Pull-to-refresh functionality
  Future<void> _handleRefresh() async {
    if (sellerId == null) return;

    try {
      // Store current step index to maintain position
      final previousStepIndex = currentStepIndex;

      // Fetch all steps data fresh
      await fetchPlanSteps();

      // Restore current step index if valid
      if (previousStepIndex < steps.length) {
        setState(() {
          currentStepIndex = previousStepIndex;
        });

        // Update page controller to maintain position
        if (pageController.hasClients) {
          pageController.jumpToPage(currentStepIndex);
        }

        // Fetch comments for restored current step
        await fetchCommentsForCurrentStep();
      }

    } catch (e) {
      // Error handling for pull-to-refresh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to refresh. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // બધા steps ના comment counts fetch કરે છે
  Future<void> fetchAllStepComments() async {
    if (sellerId == null || steps.isEmpty) return;

    Map<int, int> counts = {};
    int totalCount = 0;

    for (PlanStep step in steps) {
      try {
        final response = await http.get(
          Uri.parse('$commentsApiUrl?action=fetch&seller_id=$sellerId&plan_id=${widget.planId}&step_number=${step.stepNumber}'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final List<dynamic> commentsData = data['comments'] ?? [];
            // Count only current user's comments
            final userComments = commentsData
                .where((comment) => comment['seller_id'] == sellerId)
                .length;
            counts[step.stepNumber] = userComments;
            totalCount += userComments;
          }
        }
      } catch (e) {
        counts[step.stepNumber] = 0;
      }
    }

    if (mounted) {
      setState(() {
        stepCommentCounts = counts;
        totalCommentsCount = totalCount;
      });
    }
  }

  // Total comments count update કરે છે
  void _updateTotalCommentsCount() {
    int total = 0;
    stepCommentCounts.values.forEach((count) {
      total += count;
    });

    if (mounted) {
      setState(() {
        totalCommentsCount = total;
      });
    }
  }

  // Current step ના current user's comments fetch કરે છે
  Future<void> fetchCommentsForCurrentStep() async {
    if (sellerId == null || steps.isEmpty) return;

    setState(() {
      isLoadingComments = true;
    });

    try {
      final currentStep = steps[currentStepIndex];
      final response = await http.get(
        Uri.parse('$commentsApiUrl?action=fetch&seller_id=$sellerId&plan_id=${widget.planId}&step_number=${currentStep.stepNumber}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> commentsData = data['comments'] ?? [];
          final allComments = commentsData.map((commentJson) => Comment.fromJson(commentJson)).toList();

          setState(() {
            // Only show current user's comments
            currentUserComments = allComments
                .where((comment) => comment.sellerId == sellerId)
                .toList();
            // Comments ને created_at અનુસાર sort કરે છે (newest first)
            currentUserComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Update step comment count
            stepCommentCounts[currentStep.stepNumber] = currentUserComments.length;
            isLoadingComments = false;
          });

          // Update total count
          _updateTotalCommentsCount();
        } else {
          setState(() {
            currentUserComments = [];
            stepCommentCounts[currentStep.stepNumber] = 0;
            isLoadingComments = false;
          });
          _updateTotalCommentsCount();
        }
      } else {
        setState(() {
          currentUserComments = [];
          stepCommentCounts[currentStep.stepNumber] = 0;
          isLoadingComments = false;
        });
        _updateTotalCommentsCount();
      }
    } catch (e) {
      setState(() {
        currentUserComments = [];
        isLoadingComments = false;
      });
      _updateTotalCommentsCount();
    }
  }

  // Comment send કરે છે
  Future<void> sendComment() async {
    if (sellerId == null || steps.isEmpty || commentController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      isSendingComment = true;
    });

    try {
      final currentStep = steps[currentStepIndex];
      final response = await http.post(
        Uri.parse(commentsApiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'comment': commentController.text.trim(),
          'plan_id': widget.planId.toString(),
          'step_number': currentStep.stepNumber.toString(),
          'seller_id': sellerId!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Comment successfully sent
          final commentText = commentController.text.trim();
          commentController.clear();

          // Add comment to current user's comments list immediately
          final newComment = Comment(
            id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
            planId: widget.planId,
            stepNumber: currentStep.stepNumber,
            sellerId: sellerId!,
            text: commentText,
            createdAt: DateTime.now(),
          );

          setState(() {
            currentUserComments.insert(0, newComment);
            // Update step comment count
            stepCommentCounts[currentStep.stepNumber] = (stepCommentCounts[currentStep.stepNumber] ?? 0) + 1;
            totalCommentsCount++;
          });

          // Auto-refresh comments after sending to get updated data
          await Future.delayed(Duration(seconds: 1));
          await fetchCommentsForCurrentStep();

          // Success message show કરે છે
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Comment sent successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          // Error message show કરે છે
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to send comment'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Server error. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        isSendingComment = false;
      });
    }
  }

  // Refresh all steps with user feedback
  Future<void> refreshAllSteps() async {
    if (sellerId == null) return;

    setState(() {
      isRefreshing = true;
    });

    try {
      // Store current step index to maintain position
      final previousStepIndex = currentStepIndex;

      // Fetch all steps data fresh
      await fetchPlanSteps();

      // Restore current step index if valid
      if (previousStepIndex < steps.length) {
        setState(() {
          currentStepIndex = previousStepIndex;
        });

        // Update page controller to maintain position
        if (pageController.hasClients) {
          pageController.jumpToPage(currentStepIndex);
        }

        // Fetch comments for restored current step
        await fetchCommentsForCurrentStep();
      }

      // Success message show કરે છે
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All steps refreshed successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to refresh. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  // Specific step પર jump કરવા માટે
  void _goToStep(int index) {
    setState(() {
      currentStepIndex = index;
    });
    // PageView ને specific page પર animate કરે છે
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // Selected step ના comments load કરે છે
    fetchCommentsForCurrentStep();
  }

  // ✅ Enhanced step status colors with better visibility
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade700;
      case 'in process':
        return primaryBlue;
      case 'open':
      default:
        return Colors.orange.shade700;
    }
  }

  // ✅ Enhanced step status background colors with better contrast
  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade50;
      case 'in process':
        return lightBlue;
      case 'open':
      default:
        return Colors.orange.shade50;
    }
  }

  // Show enhanced zoomable image dialog
  void _showZoomableImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.1,
                maxScale: 10.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Loading image...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Zoom instructions
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pinch to zoom • Drag to pan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greyLight,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryBlue,
        foregroundColor: whiteColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan નું name display કરે છે
            Text(
              widget.planName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: whiteColor,
                fontSize: 18,
              ),
            ),
            // ✅ Fixed: Show actual step number instead of index
            if (steps.isNotEmpty)
              Text(
                'Step ${steps[currentStepIndex].stepNumber} of ${steps.length} • ${steps[currentStepIndex].status.toUpperCase()}',
                style: TextStyle(
                  color: whiteColor.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: Material(
            color: whiteColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, color: whiteColor),
            ),
          ),
        ),
        actions: [
          // Refresh button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Material(
              color: whiteColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: refreshAllSteps,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: isRefreshing
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                    ),
                  )
                      : Icon(Icons.refresh, color: whiteColor, size: 20),
                ),
              ),
            ),
          ),
        ],
        // ✅ Enhanced step navigation bar with dynamic colors
        bottom: steps.isNotEmpty ? PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                final isCurrentStep = index == currentStepIndex;
                final commentCount = stepCommentCounts[step.stepNumber] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    // ✅ Enhanced background color based on current step and status
                    color: isCurrentStep
                        ? whiteColor
                        : _getStatusBackgroundColor(step.status),
                    borderRadius: BorderRadius.circular(12),
                    // ✅ Enhanced elevation for current step
                    elevation: isCurrentStep ? 4 : 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _goToStep(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        // ✅ Enhanced border for current step
                        decoration: isCurrentStep ? BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ) : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${step.stepNumber}',
                                  style: TextStyle(
                                    // ✅ Enhanced text color for better visibility
                                    color: isCurrentStep
                                        ? primaryBlue
                                        : _getStatusColor(step.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (commentCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isCurrentStep
                                          ? primaryBlue
                                          : _getStatusColor(step.status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$commentCount',
                                      style: TextStyle(
                                        color: whiteColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isCurrentStep
                                    ? primaryBlue
                                    : _getStatusColor(step.status),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ) : null,
      ),
      body: _buildBody(), // Main body content
    );
  }

  // Main body content - loading, error, અથવા actual content show કરે છે
  Widget _buildBody() {
    // Loading state
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading steps...',
              style: TextStyle(
                color: textBlack,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Error state - network error, API error, etc.
    if (errorMessage != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkBlue, primaryBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: loadUserDataAndFetchSteps,
                  icon: const Icon(Icons.refresh, color: whiteColor),
                  label: const Text('Try Again', style: TextStyle(color: whiteColor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state - કોઈ steps નથી મળ્યા
    if (steps.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Steps Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This plan doesn\'t have any steps yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkBlue, primaryBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: loadUserDataAndFetchSteps,
                  icon: const Icon(Icons.refresh, color: whiteColor),
                  label: const Text('Refresh', style: TextStyle(color: whiteColor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Main content with RefreshIndicator for pull-to-refresh
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: primaryBlue,
      backgroundColor: whiteColor,
      displacement: 40,
      strokeWidth: 2,
      child: Column(
        children: [
          // Steps Content - PageView માં બધા steps
          Expanded(
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                // ✅ Enhanced step change detection
                setState(() {
                  currentStepIndex = index;
                });

                // New step ના comments load કરે છે
                fetchCommentsForCurrentStep();

                // Auto scroll to current step in AppBar
                if (scrollController.hasClients) {
                  double itemWidth = 80.0; // Approximate width of each step button
                  double targetOffset = (index * itemWidth) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
                  scrollController.animateTo(
                    targetOffset.clamp(0.0, scrollController.position.maxScrollExtent),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                return _buildStepContent(step); // Individual step નું content
              },
            ),
          ),

          // Enhanced Comment Section
          _buildEnhancedCommentSection(),
        ],
      ),
    );
  }

  // Enhanced comment section build કરે છે
  Widget _buildEnhancedCommentSection() {
    final currentStep = steps.isNotEmpty ? steps[currentStepIndex] : null;
    final currentStepCommentCount = currentStep != null
        ? (stepCommentCounts[currentStep.stepNumber] ?? 0)
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Comments stats header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.comment,
                    color: primaryBlue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Comments',
                        style: TextStyle(
                          fontSize: 14,
                          color: textBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: $totalCommentsCount • Step ${steps.isNotEmpty ? steps[currentStepIndex].stepNumber : 0}: $currentStepCommentCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoadingComments)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                    ),
                  ),
              ],
            ),
          ),

          // Recent comments for current step (scrollable)
          if (currentUserComments.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: currentUserComments.length > 3 ? 3 : currentUserComments.length,
                itemBuilder: (context, index) {
                  final comment = currentUserComments[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: index == 0 ? Colors.green : primaryBlue,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              index == 0 ? 'Latest' : 'Previous',
                              style: TextStyle(
                                fontSize: 10,
                                color: textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(comment.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          comment.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: textBlack,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (currentUserComments.length > 3)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '+${currentUserComments.length - 3} more comments',
                  style: TextStyle(
                    fontSize: 11,
                    color: primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],

          const Divider(height: 1),

          // Comment Input Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Add your comment for Step ${steps.isNotEmpty ? steps[currentStepIndex].stepNumber : 0}...',
                          hintStyle: TextStyle(
                            color: textGrey,
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: greyLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: primaryBlue,
                              size: 16,
                            ),
                          ),
                        ),
                        style: TextStyle(color: textBlack),
                        maxLines: 2,
                        enabled: !isSendingComment,
                        onSubmitted: (_) => sendComment(),
                        onChanged: (value) {
                          setState(() {}); // Refresh button state
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: commentController.text.trim().isNotEmpty
                            ? LinearGradient(colors: [darkBlue, primaryBlue])
                            : null,
                        color: commentController.text.trim().isEmpty
                            ? Colors.grey[300]
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: isSendingComment || commentController.text.trim().isEmpty
                            ? null
                            : sendComment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(70, 44),
                        ),
                        child: isSendingComment
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                          ),
                        )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send,
                              size: 16,
                              color: commentController.text.trim().isNotEmpty
                                  ? whiteColor
                                  : textGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Send',
                              style: TextStyle(
                                color: commentController.text.trim().isNotEmpty
                                    ? whiteColor
                                    : textGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Individual step નું content build કરે છે
  Widget _buildStepContent(PlanStep step) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // ✅ Enables pull-to-refresh
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [darkBlue, primaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style: const TextStyle(
                        color: whiteColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                        'Step ${step.stepNumber}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textBlack,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBackgroundColor(step.status),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _getStatusColor(step.status).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          step.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Step Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: greyLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: lightBlue,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.stepDescription,
                    style: TextStyle(
                      fontSize: 15,
                      color: textBlack,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Step Image - Enhanced Zoomable on tap
            if (step.stepImage != null && step.stepImage!.isNotEmpty) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _showZoomableImage(
                  'https://customprint.deodap.com/uploads/${step.stepImage}',
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: primaryBlue,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          'https://customprint.deodap.com/uploads/${step.stepImage}',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading image...',
                                      style: TextStyle(
                                        color: textGrey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: textGrey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: textGrey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Tap to zoom',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Created Date and Step Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: lightBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: lightBlue,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.schedule,
                      size: 16,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step Information',
                          style: TextStyle(
                            color: textBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Created: ${_formatDate(step.createdAt)}',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Comments: ${stepCommentCounts[step.stepNumber] ?? 0}',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  // Date formatting helper function
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}