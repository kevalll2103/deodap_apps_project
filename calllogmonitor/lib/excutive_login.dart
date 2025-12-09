import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';

class ExecutiveLoginScreen extends StatefulWidget {
  @override
  _ExecutiveLoginScreenState createState() => _ExecutiveLoginScreenState();
}

class _ExecutiveLoginScreenState extends State<ExecutiveLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedWarehouse;
  List<Map<String, dynamic>> _warehouses = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  static const String baseURL = "https://trackship.in";

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
    _initializeWarehouses();
  }

  Future<void> _checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_executive_logged_in') ?? false;
    
    if (isLoggedIn) {
      // User is already logged in, navigate to dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/executive_dashboard');
      });
    }
  }

  Future<void> _initializeWarehouses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== DEBUG: Fetching Warehouses from API ===');
      print('URL: $baseURL/api/lms/warehouse.php');
      
      final response = await http.post(
        Uri.parse('$baseURL/api/lms/warehouse.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'list',
        },
      );

      print('=== DEBUG: Warehouse API Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['status'] == 'ok' && jsonData['data'] != null) {
          final List<dynamic> warehouseData = jsonData['data'];
          final warehouses = warehouseData.map((warehouse) => {
            'id': warehouse['id'].toString(),
            'label': warehouse['label'].toString(),
            'code': warehouse['label'].toString()
          }).toList();

          setState(() {
            _warehouses = warehouses;
            _isLoading = false;
          });

          print('=== DEBUG: Warehouses Loaded Successfully ===');
          print('Total warehouses: ${_warehouses.length}');
        } else {
          print('=== ERROR: Invalid warehouse API response ===');
          print('Status: ${jsonData['status']}');
          _fallbackToHardcodedWarehouses();
        }
      } else {
        print('=== ERROR: Warehouse API request failed ===');
        print('Status Code: ${response.statusCode}');
        _fallbackToHardcodedWarehouses();
      }
    } catch (e) {
      print('=== ERROR: Exception while fetching warehouses ===');
      print('Error: $e');
      _fallbackToHardcodedWarehouses();
    }
  }

  void _fallbackToHardcodedWarehouses() {
    print('=== DEBUG: Using fallback hardcoded warehouses ===');
    final warehouses = List.generate(194, (index) => {
      'id': (index + 1).toString(),
      'label': 'L${(index + 1).toString().padLeft(3, '0')}',
      'code': 'L${(index + 1).toString().padLeft(3, '0')}'
    });

    setState(() {
      _warehouses = warehouses;
      _isLoading = false;
    });

    print('=== DEBUG: Fallback Warehouses Initialized ===');
    print('Total warehouses: ${_warehouses.length}');
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('=== DEBUG: Executive Login Request ===');
      print('URL: $baseURL/api/lms/login.php');
      print('Body: {');
      print('  action: login');
      print('  type: executive_login');
      print('  warehouse: $_selectedWarehouse');
      print('  mobile: ${_mobileController.text.trim()}');
      print('  password: [HIDDEN]');
      print('}');

      final response = await http.post(
        Uri.parse('$baseURL/api/lms/login.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'login',
          'type': 'executive_login',
          'warehouse': _selectedWarehouse!,
          'mobile': _mobileController.text.trim(),
          'password': _passwordController.text.trim(),
        },
      );

      print('=== DEBUG: Login Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('=== DEBUG: Parsed JSON ===');
          print('Status: ${jsonData['status']}');
          print('Message: ${jsonData['msg']}');

          if (jsonData['status'] == 'ok') {
            // Save executive login data
            await _saveExecutiveData(jsonData['data']);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login successful!'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to executive dashboard
            Navigator.pushReplacementNamed(context, '/executive_dashboard');
          } else {
            final errorMsg = jsonData['msg'] ?? 'Login failed';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login failed: $errorMsg'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (jsonError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed: Invalid response format'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: Server error (${response.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed: Network error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _saveExecutiveData(Map<String, dynamic> executiveData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save executive login data
    await prefs.setInt('executive_id', executiveData['id']);
    await prefs.setString('executive_username', _mobileController.text.trim());
    await prefs.setString('executive_name', executiveData['name'] ?? '');
    await prefs.setString('executive_warehouse_id', _selectedWarehouse!);
    await prefs.setString('executive_auth_key', executiveData['executive_auth_key'] ?? '');

    // Find and save warehouse label
    String warehouseLabel = _selectedWarehouse!;
    for (var warehouse in _warehouses) {
      if (warehouse['id'].toString() == _selectedWarehouse) {
        warehouseLabel = warehouse['label'] ?? _selectedWarehouse!;
        break;
      }
    }
    await prefs.setString('executive_warehouse_label', warehouseLabel);

    // Save login status
    await prefs.setBool('is_executive_logged_in', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Login'),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.warmGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Welcome header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.accentGradient,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              size: 40,
                              color: AppTheme.primaryWarm,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Executive Login',
                            style: AppTheme.headingMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please login to access executive dashboard',
                            style: AppTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Form Section
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.login, color: AppTheme.primaryBrown, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Login Credentials',
                                style: AppTheme.headingSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Mobile Number Field
                          TextFormField(
                            controller: _mobileController,
                            decoration: AppTheme.getInputDecoration('Mobile Number', icon: Icons.phone_outlined),
                            style: AppTheme.bodyMedium,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              if (value.length < 10) {
                                return 'Mobile number must be at least 10 digits';
                              }
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return 'Mobile number should contain only digits';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            decoration: AppTheme.getInputDecoration('Password', icon: Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: AppTheme.primaryBrown,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            style: AppTheme.bodyMedium,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Warehouse Selection
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warehouse, color: AppTheme.primaryBrown, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Warehouse Selection',
                                style: AppTheme.headingSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (_isLoading)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.infoWarm.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.infoWarm.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.infoWarm),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Loading warehouses...',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.infoWarm,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: _selectedWarehouse,
                              decoration: AppTheme.getInputDecoration('Select Warehouse', icon: Icons.business),
                              style: AppTheme.bodyMedium,
                              items: _warehouses.map((warehouse) {
                                return DropdownMenuItem<String>(
                                  value: warehouse['id'].toString(),
                                  child: Text(
                                    warehouse['label'],
                                    style: AppTheme.bodyMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedWarehouse = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a warehouse';
                                }
                                return null;
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: _isSubmitting ? null : AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isSubmitting ? null : AppTheme.warmShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || _isLoading) ? null : _submitLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubmitting ? AppTheme.warmDark : Colors.transparent,
                          foregroundColor: AppTheme.primaryWarm,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryWarm),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Logging in...',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.primaryWarm,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : Text(
                          'Login',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.primaryWarm,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration.copyWith(
                        color: AppTheme.warmLight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: AppTheme.infoWarm, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Executive Access:',
                                style: AppTheme.headingSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Login with your executive credentials\n'
                                '• Select the warehouse you want to manage\n'
                                '• Access executive dashboard and reports\n'
                                '• Monitor call logs and device activities\n'
                                '• Manage warehouse operations efficiently',
                            style: AppTheme.bodySmall.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}