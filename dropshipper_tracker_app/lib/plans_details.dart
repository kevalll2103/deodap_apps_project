import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'step_chat_screen.dart'; // Import the chat screen

class PlanStep {
  final int stepId;
  final int stepNumber;
  final String stepDescription;
  final String? stepImage;
  final String status;
  final String? customDescription;
  final String? customImage;
  final DateTime updatedAt;

  PlanStep({
    required this.stepId,
    required this.stepNumber,
    required this.stepDescription,
    this.stepImage,
    required this.status,
    this.customDescription,
    this.customImage,
    required this.updatedAt,
  });

  factory PlanStep.fromJson(Map<String, dynamic> json) {
    return PlanStep(
      stepId: int.parse(json['step_id'].toString()),
      stepNumber: int.parse(json['step_number'].toString()),
      stepDescription: json['step_description'] ?? '',
      stepImage: json['step_image'],
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      customDescription: json['custom_description'],
      customImage: json['custom_image'],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isInProcess => status == 'in process' || status == 'inprocess';
  bool get isCompleted => status == 'completed';
}

class PlanDetails {
  final int planId;
  final String planName;
  final String planDescription;
  final double planPrice;
  final List<PlanStep> steps;

  PlanDetails({
    required this.planId,
    required this.planName,
    required this.planDescription,
    required this.planPrice,
    required this.steps,
  });

  factory PlanDetails.fromJson(Map<String, dynamic> json) {
    final List<dynamic> stepsData = json['steps'] ?? [];
    return PlanDetails(
      planId: int.parse(json['plan_id'].toString()),
      planName: json['plan_name'] ?? '',
      planDescription: json['plan_description'] ?? '',
      planPrice: double.tryParse(json['plan_price']?.toString() ?? '0') ?? 0.0,
      steps: stepsData.map((stepJson) => PlanStep.fromJson(stepJson)).toList(),
    );
  }
}

class PlanScreen extends StatefulWidget {
  final int? planId;
  final String? planName;
  final int? dropshipperId;

  const PlanScreen({
    super.key,
    this.planId,
    this.planName,
    this.dropshipperId,
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> with WidgetsBindingObserver {
  PlanDetails? planDetails;
  bool isLoading = true;
  String? errorMessage;
  Timer? _autoRefreshTimer;
  DateTime? _lastRefresh;
  int? _dropshipperId;
  List<PlanDetails> allPlans = [];

  // Theme colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color whiteColor = Colors.white;
  static const Color greyLight = Color(0xFFF8F9FA);
  static const Color textBlack = Colors.black87;
  static const Color textGrey = Colors.black54;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDropshipperIdAndFetchData();
  }

  Future<void> _loadDropshipperIdAndFetchData() async {
    try {
      if (widget.dropshipperId != null) {
        _dropshipperId = widget.dropshipperId;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user_data');
        if (userJson != null) {
          final userData = jsonDecode(userJson);
          _dropshipperId = int.tryParse(userData['id']?.toString() ?? '');
        }
      }

      if (_dropshipperId == null) {
        setState(() {
          errorMessage = 'User not authenticated. Please login again.';
          isLoading = false;
        });
        return;
      }

      await fetchPlanSteps();
      _startAutoRefresh();
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading user data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_lastRefresh == null ||
          DateTime.now().difference(_lastRefresh!).inMinutes > 2) {
        fetchPlanSteps();
      }
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted && !isLoading) {
        fetchPlanSteps(silent: true);
      }
    });
  }

  Future<void> fetchPlanSteps({bool silent = false}) async {
    if (_dropshipperId == null) {
      if (mounted) {
        setState(() {
          errorMessage = 'User not authenticated';
          isLoading = false;
        });
      }
      return;
    }

    try {
      if (!silent) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final response = await http.get(
        Uri.parse('https://customprint.deodap.com/api_dropshipper_tracker/get_one_dropshipper_plan.php?dropshipper_id=$_dropshipperId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> plansData = data['plans'] ?? [];

          if (plansData.isNotEmpty && mounted) {
            // Convert all plans
            allPlans = plansData
                .map((planJson) => PlanDetails.fromJson(planJson))
                .toList();

            // If specific plan ID is provided, find that plan
            if (widget.planId != null) {
              planDetails = allPlans.firstWhere(
                    (plan) => plan.planId == widget.planId,
                orElse: () => allPlans.first,
              );
            } else {
              // Show first plan if no specific plan ID
              planDetails = allPlans.first;
            }

            setState(() {
              isLoading = false;
              _lastRefresh = DateTime.now();
            });
            return;
          }

          if (mounted) {
            setState(() {
              errorMessage = 'No plans found';
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              errorMessage = data['message'] ?? 'Failed to load plan steps';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Server error: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  void _switchPlan(PlanDetails newPlan) {
    setState(() {
      planDetails = newPlan;
    });
  }

  void _openStepChat(PlanStep step) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StepChatScreen(
          stepId: step.stepId,
          stepNumber: step.stepNumber,
          stepDescription: step.customDescription?.isNotEmpty == true
              ? step.customDescription!
              : step.stepDescription,
          dropshipperId: _dropshipperId!,
          planName: planDetails!.planName, stepStatus: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greyLight,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () => fetchPlanSteps(),
        color: primaryBlue,
        backgroundColor: whiteColor,
        strokeWidth: 3,
        child: _buildBody(),
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
        icon: const Icon(Icons.arrow_back_rounded, color: whiteColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: whiteColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              size: 22,
              color: whiteColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Plans',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: whiteColor,
                    letterSpacing: 0.5,
                  ),
                ),
                if (planDetails != null)
                  Text(
                    planDetails!.planName,
                    style: TextStyle(
                      fontSize: 12,
                      color: whiteColor.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Plan selector dropdown if multiple plans
        if (allPlans.length > 1)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: whiteColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<PlanDetails>(
              icon: const Icon(Icons.swap_horiz_rounded, color: whiteColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => allPlans
                  .map(
                    (plan) => PopupMenuItem<PlanDetails>(
                  value: plan,
                  child: Row(
                    children: [
                      Icon(
                        plan.planId == planDetails?.planId
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: plan.planId == planDetails?.planId
                            ? primaryBlue
                            : textGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.planName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'ID: ${plan.planId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
              onSelected: _switchPlan,
            ),
          ),
        // Refresh button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: whiteColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isLoading ? null : () => fetchPlanSteps(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                  ),
                )
                    : const Icon(Icons.refresh_rounded, color: whiteColor, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoading && planDetails == null) {
      return _buildLoadingState();
    }

    if (errorMessage != null && planDetails == null) {
      return _buildErrorState();
    }

    if (allPlans.isEmpty) {
      return _buildEmptyPlansState();
    }

    if (planDetails == null || planDetails!.steps.isEmpty) {
      return _buildEmptyStepsState();
    }

    return _buildStepsList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Loading Plans...',
            style: TextStyle(
              color: textBlack,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we fetch your plans',
            style: TextStyle(
              color: textGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Plans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => fetchPlanSteps(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlansState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: primaryBlue,
            ),
            SizedBox(height: 16),
            Text(
              'No Plans Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You don\'t have any plans yet. Contact your administrator to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStepsState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.list_alt_outlined,
              size: 64,
              color: primaryBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'No Steps in ${planDetails?.planName ?? "This Plan"}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This plan doesn\'t have any steps yet. They will appear here once added.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsList() {
    final steps = planDetails!.steps;
    final completedSteps = steps.where((step) => step.isCompleted).length;
    final inProcessSteps = steps.where((step) => step.isInProcess).length;
    final pendingSteps = steps.where((step) => step.isPending).length;
    final totalSteps = steps.length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Plan header card
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [darkBlue, primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 10,
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: whiteColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: whiteColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planDetails!.planName,
                            style: const TextStyle(
                              color: whiteColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Progress: $completedSteps of $totalSteps completed',
                            style: TextStyle(
                              color: whiteColor.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: whiteColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: whiteColor.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(whiteColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                // Status chips
                Wrap(
                  spacing: 8,
                  children: [
                    _buildStatusChip('Completed', completedSteps, Colors.green),
                    _buildStatusChip('In Process', inProcessSteps, Colors.blue),
                    _buildStatusChip('Pending', pendingSteps, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Steps list
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final step = steps[index];
                return _buildStepCard(step, index);
              },
              childCount: steps.length,
            ),
          ),
        ),
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: whiteColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(
          color: whiteColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStepCard(PlanStep step, int index) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (step.isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Completed';
    } else if (step.isInProcess) {
      statusColor = primaryBlue;
      statusIcon = Icons.play_circle_rounded;
      statusText = 'In Process';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending_rounded;
      statusText = 'Pending';
    }

    return GestureDetector(
      onTap: () => _openStepChat(step),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.customDescription?.isNotEmpty == true
                            ? step.customDescription!
                            : step.stepDescription,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Chat indicator icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(step.updatedAt),
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Tap to chat hint
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 12,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tap to Chat',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (step.stepImage != null || step.customImage != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_rounded,
                          size: 12,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Image',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    }
  }
}
