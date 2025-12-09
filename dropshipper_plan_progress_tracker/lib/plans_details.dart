import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'PlanStepsScreen.dart';


class Plan {
  final int id;
  final String name;
  final String? description;
  final double price;
  final bool isActive;
  final DateTime createdAt;

  Plan({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.isActive,
    required this.createdAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      description: json['description'],
      price: double.parse(json['price'].toString()),
      isActive: json['is_active'].toString() == '1',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PlansScreen extends StatefulWidget {
  @override
  _PlansScreenState createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<Plan> plans = [];
  bool isLoading = true;
  String? errorMessage;
  static const String apiUrl = 'https://customprint.deodap.com/api_dropshipper_tracker/plans_complete.php';

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http.get(
        Uri.parse('$apiUrl?action=fetch'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> plansData = data['plans'] ?? [];
          setState(() {
            plans = plansData.map((planJson) => Plan.fromJson(planJson)).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load plans';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Subscription Plans',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchPlans,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchPlans,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
              'Loading plans...',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

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
              onPressed: fetchPlans,
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

    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Plans Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no subscription plans available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchPlans,
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(Plan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToPlanSteps(plan),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      child: const Icon(
                        Icons.assignment,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
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
                              color: plan.isActive
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              plan.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: plan.isActive
                                    ? const Color(0xFF166534)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${plan.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ],
                ),
                if (plan.description != null && plan.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    plan.description!,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Created: ${_formatDate(plan.createdAt)}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View Steps',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToPlanSteps(Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanStepsScreen(
          planId: plan.id,
          planName: plan.name,
        ),
      ),
    );
  }
}