// Flutter imports
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  // State variables
  List<PlanStep> steps = [];                    // Plan ના બધા steps
  List<Comment> comments = [];                  // Current step ના comments
  bool isLoading = true;                        // Loading state
  bool isLoadingComments = false;               // Comments loading state
  bool isSendingComment = false;                // Comment sending state
  String? errorMessage;                         // Error message
  int currentStepIndex = 0;                     // Currently displayed step index
  PageController pageController = PageController(); // PageView ને control કરવા માટે
  TextEditingController commentController = TextEditingController(); // Comment input controller

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
  }

  @override
  void dispose() {
    // Memory leak prevent કરવા માટે controllers dispose કરે છે
    pageController.dispose();
    commentController.dispose();
    super.dispose();
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
            currentStepIndex = 0; // પહેલા step પર જાય છે
          });

          // First step ના comments load કરે છે
          if (steps.isNotEmpty) {
            fetchCommentsForCurrentStep();
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

  // Current step ના comments fetch કરે છે
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
          setState(() {
            comments = commentsData.map((commentJson) => Comment.fromJson(commentJson)).toList();
            // Comments ને created_at અનુસાર sort કરે છે (newest first)
            comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            isLoadingComments = false;
          });
        } else {
          setState(() {
            comments = [];
            isLoadingComments = false;
          });
        }
      } else {
        setState(() {
          comments = [];
          isLoadingComments = false;
        });
      }
    } catch (e) {
      setState(() {
        comments = [];
        isLoadingComments = false;
      });
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
          commentController.clear();
          // Comments refresh કરે છે
          await fetchCommentsForCurrentStep();

          // Success message show કરે છે
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment sent successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Error message show કરે છે
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to send comment'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isSendingComment = false;
      });
    }
  }

  // Next step પર જવા માટે
  void _nextStep() {
    if (currentStepIndex < steps.length - 1) {
      setState(() {
        currentStepIndex++;
      });
      // PageView ને next page પર animate કરે છે
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // New step ના comments load કરે છે
      fetchCommentsForCurrentStep();
    }
  }

  // Previous step પર જવા માટે
  void _previousStep() {
    if (currentStepIndex > 0) {
      setState(() {
        currentStepIndex--;
      });
      // PageView ને previous page પર animate કરે છે
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Previous step ના comments load કરે છે
      fetchCommentsForCurrentStep();
    }
  }

  // Specific step પર jump કરવા માટે (overview modal માંથી)
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

  // Step status આધારે text color return કરે છે
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF166534);
      case 'in process':
        return const Color(0xFF2563EB);
      case 'open':
      default:
        return const Color(0xFFD97706);
    }
  }

  // Step status આધારે background color return કરે છે
  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'in process':
        return const Color(0xFFDBEAFE);
      case 'open':
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light gray background
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan નું name display કરે છે
            Text(
              widget.planName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            // Current step progress show કરે છે
            if (steps.isNotEmpty)
              Text(
                'Step ${currentStepIndex + 1} of ${steps.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1), // Indigo color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Refresh button - data reload કરવા માટે
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadUserDataAndFetchSteps,
          ),
          // Steps overview button - બધા steps ની list જોવા માટે
          if (steps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list, color: Colors.white),
              onPressed: () => _showStepsOverview(),
            ),
        ],
      ),
      body: _buildBody(), // Main body content
    );
  }

  // Main body content - loading, error, અથવા actual content show કરે છે
  Widget _buildBody() {
    // Loading state
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading steps...',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Error state - network error, API error, etc.
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loadUserDataAndFetchSteps,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state - કોઈ steps નથી મળ્યા
    if (steps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Steps Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This plan doesn\'t have any steps yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loadUserDataAndFetchSteps,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Main content - steps show કરે છે
    return Column(
      children: [
        // Progress Indicator - current progress show કરે છે
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Text(
                    '${currentStepIndex + 1}/${steps.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (currentStepIndex + 1) / steps.length,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ],
          ),
        ),

        // Steps Content - PageView માં બધા steps
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: (index) {
              // User swipe કરે તો current step index update કરે છે
              setState(() {
                currentStepIndex = index;
              });
              // New step ના comments load કરે છે
              fetchCommentsForCurrentStep();
            },
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return _buildStepContent(step); // Individual step નું content
            },
          ),
        ),

        // Comment Input Section
        _buildCommentSection(),

        // Navigation Buttons - Previous/Next buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentStepIndex > 0 ? _previousStep : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7280),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentStepIndex < steps.length - 1 ? _nextStep : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    currentStepIndex < steps.length - 1 ? 'Next' : 'Finished',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Comment section build કરે છે
  Widget _buildCommentSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.comment,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comments (${comments.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                if (isLoadingComments)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  ),
              ],
            ),
          ),

          // Comments List
          if (comments.isNotEmpty)
            Container(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(comment.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 1,
                    enabled: !isSendingComment,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isSendingComment || commentController.text.trim().isEmpty
                      ? null
                      : sendComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSendingComment
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Send'),
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
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBackgroundColor(step.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          step.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(step.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Step Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    step.stepDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // Step Image
            if (step.stepImage != null && step.stepImage!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://customprint.deodap.com/uploads/${step.stepImage}',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Color(0xFF6B7280),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
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
              ),
            ],

            const SizedBox(height: 24),

            // Created Date
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Text(
                  'Created: ${_formatDate(step.createdAt)}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Date formatting helper function
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // બધા steps નું overview modal બતાવે છે
  void _showStepsOverview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.list,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'All Steps',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${steps.length} steps',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final isCurrentStep = index == currentStepIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isCurrentStep ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentStep ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                        width: isCurrentStep ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrentStep ? const Color(0xFF6366F1) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${step.stepNumber}',
                            style: TextStyle(
                              color: isCurrentStep ? Colors.white : const Color(0xFF6B7280),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        step.stepDescription,
                        style: TextStyle(
                          fontWeight: isCurrentStep ? FontWeight.w600 : FontWeight.w500,
                          color: isCurrentStep ? const Color(0xFF111827) : const Color(0xFF374151),
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusBackgroundColor(step.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                step.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(step.status),
                                ),
                              ),
                            ),
                            if (step.stepImage != null && step.stepImage!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: const Icon(
                                  Icons.image,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                          ],
                        ),
                      ),
                      trailing: isCurrentStep
                          ? const Icon(
                        Icons.play_arrow,
                        color: Color(0xFF6366F1),
                        size: 24,
                      )
                          : const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF6B7280),
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _goToStep(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}