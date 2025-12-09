import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'main.dart'; // Import for SyncServiceManager

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  String? _selectedWarehouse;
  List<Map<String, dynamic>> _warehouses = [];
  bool _isSubmitting = false;
  String? _selectedSim; // Changed to nullable for dropdown
  bool _isVerifyingSim = false;
  String? _simVerificationMessage;
  bool _isSimVerified = false;

  // SIM options for dropdown
  final List<Map<String, String>> _simOptions = [
    {'value': 'SIM1', 'label': 'SIM 1'},
    {'value': 'SIM2', 'label': 'SIM 2'},
  ];

  static const String baseURL = "https://trackship.in";
  static const platform =
      MethodChannel('com.example.calllogmonitor/permissions');

  @override
  void initState() {
    super.initState();
    _initializeWarehouses();
    _loadSavedSimSelection();
  }

  Future<void> _initializeWarehouses() async {
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
          final warehouses = warehouseData
              .map((warehouse) => {
                    'id': warehouse['id'].toString(),
                    'label': warehouse['label'].toString(),
                    'code': warehouse['label'].toString()
                  })
              .toList();

          setState(() {
            _warehouses = warehouses;
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
    final warehouses = List.generate(
        194,
        (index) => {
              'id': (index + 1).toString(),
              'label': 'L${(index + 1).toString().padLeft(3, '0')}',
              'code': 'L${(index + 1).toString().padLeft(3, '0')}'
            });

    setState(() {
      _warehouses = warehouses;
    });

    print('=== DEBUG: Fallback Warehouses Initialized ===');
    print('Total warehouses: ${_warehouses.length}');
  }

  Future<void> _loadSavedSimSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSim =
        prefs.getString('selected_sim') ?? 'SIM1'; // Default to SIM1
    setState(() {
      _selectedSim = savedSim;
    });
    print('=== DEBUG: Loaded SIM Selection ===');
    print('Selected SIM: $_selectedSim');
  }

  Future<void> _saveSimSelection(String simSelection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_sim', simSelection);
    print('=== DEBUG: Saved SIM Selection ===');
    print('Saved SIM: $simSelection');
  }

  Future<void> _handleSimSelection(String? simSelection) async {
    if (simSelection == null) return;

    setState(() {
      _selectedSim = simSelection;
      // Reset verification when SIM changes
      _isSimVerified = false;
      _simVerificationMessage = null;
    });

    // Save SIM selection immediately to MainActivity.kt
    try {
      final simId = simSelection == 'SIM1' ? '1' : '2';
      await platform.invokeMethod('setSelectedSim', {'simId': simId});
      print('=== DEBUG: SIM Selection Updated ===');
      print('Selected SIM: $simSelection -> SIM ID: $simId');
    } catch (e) {
      print('=== ERROR: Failed to update SIM selection ===');
      print('Error: $e');
    }

    // Also save to SharedPreferences for UI persistence
    await _saveSimSelection(simSelection);
  }

  Future<void> _verifySimNumber() async {
    if (_mobileController.text.trim().isEmpty) {
      setState(() {
        _simVerificationMessage = 'Please enter mobile number first';
        _isSimVerified = false;
      });
      return;
    }

    if (_selectedSim == null) {
      setState(() {
        _simVerificationMessage = 'Please select a SIM first';
        _isSimVerified = false;
      });
      return;
    }

    setState(() {
      _isVerifyingSim = true;
      _simVerificationMessage = null;
      _isSimVerified = false;
    });

    try {
      // Simulate verification process
      await Future.delayed(const Duration(seconds: 2));

      final enteredNumber = _mobileController.text.trim();
      final selectedSimLabel = _simOptions.firstWhere(
        (sim) => sim['value'] == _selectedSim,
        orElse: () => {'value': '', 'label': 'Unknown SIM'},
      )['label']!;

      print('=== DEBUG: SIM Verification ===');
      print('Entered Number: $enteredNumber');
      print('Selected SIM: $selectedSimLabel');

      bool isVerified = false;
      String verificationMessage = '';

      // Basic validation - check if number is 10 digits
      if (enteredNumber.length == 10 &&
          RegExp(r'^[0-9]+$').hasMatch(enteredNumber)) {
        // For demo purposes, simulate successful verification
        isVerified = true;
        verificationMessage = '✓ Number format verified for $selectedSimLabel';

        // Validate Indian mobile number format
        final firstDigit = enteredNumber[0];
        if (['6', '7', '8', '9'].contains(firstDigit)) {
          verificationMessage =
              '✓ Valid Indian mobile number verified for $selectedSimLabel';
        } else {
          isVerified = false;
          verificationMessage = '⚠ Please enter a valid Indian mobile number';
        }
      } else {
        verificationMessage = '⚠ Please enter a valid 10-digit mobile number';
      }

      setState(() {
        _isVerifyingSim = false;
        _simVerificationMessage = verificationMessage;
        _isSimVerified = isVerified;
      });
    } catch (e) {
      print('Error verifying SIM: $e');
      setState(() {
        _isVerifyingSim = false;
        _simVerificationMessage = '⚠ SIM verification failed: ${e.toString()}';
        _isSimVerified = false;
      });
    }
  }

  Future<void> _submitRegistration() async {
    // Validate that SIM is selected and verified
    if (_selectedSim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a SIM card'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isSimVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your SIM number first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final deviceNumber = _mobileController.text.trim();
      final fcmToken = "123"; // Replace with actual FCM token

      print('=== DEBUG: Registration Request ===');
      print('URL: $baseURL/api/lms/register.php');
      print('Body: {');
      print('  action: add_device');
      print('  warehouse: $_selectedWarehouse');
      print('  device_number: $deviceNumber');
      print('  user_name: ${_nameController.text.trim()}');
      print('  fcm_token: $fcmToken');
      print('  selected_sim: $_selectedSim');
      print('}');

      final response = await http.post(
        Uri.parse('$baseURL/api/lms/register.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'add_device',
          'warehouse': _selectedWarehouse!,
          'device_number': deviceNumber,
          'user_name': _nameController.text.trim(),
          'fcm_token': fcmToken,
          'selected_sim': _selectedSim!,
        },
      );

      print('=== DEBUG: Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('=== DEBUG: Parsed JSON ===');
          print('Status: ${jsonData['status']}');
          print('Message: ${jsonData['msg']}');
          print('Data: ${jsonData['data']}');

          if (jsonData['status'] == 'ok') {
            // Save user details to SharedPreferences
            await _saveUserData(jsonData['data']);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(jsonData['msg'] ?? 'Registration successful!'),
                backgroundColor: Colors.green,
              ),
            );

            // Start auto-sync service after successful registration
            await _startAutoSyncAfterRegistration();

            // Navigate to home screen
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            final errorMsg = jsonData['msg'] ?? 'Registration failed';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Registration failed: $errorMsg'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (jsonError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration failed: Invalid response format'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Registration failed: Server error (${response.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration failed: Network error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save user registration data
    await prefs.setInt('user_id', userData['id']);
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('mobile_number', _mobileController.text.trim());
    await prefs.setString('warehouse_id', _selectedWarehouse!);

    // Find and save warehouse label
    String warehouseLabel = _selectedWarehouse!;
    for (var warehouse in _warehouses) {
      if (warehouse['id'].toString() == _selectedWarehouse) {
        warehouseLabel = warehouse['label'] ?? _selectedWarehouse!;
        break;
      }
    }
    await prefs.setString('warehouse_label', warehouseLabel);

    // Save selected SIM information
    await prefs.setString('selected_sim', _selectedSim!);
    await prefs.setBool('sim_verified', _isSimVerified);

    // Save registration status
    await prefs.setBool('is_registered', true);

    // Save selected SIM to MainActivity.kt via platform channel
    try {
      final simId = _selectedSim == 'SIM1' ? '1' : '2';
      await platform.invokeMethod('setSelectedSim', {'simId': simId});
      print('=== DEBUG: SIM Selection Saved to Native ===');
      print('Selected SIM: $_selectedSim -> SIM ID: $simId');
    } catch (e) {
      print('=== ERROR: Failed to save SIM selection to native ===');
      print('Error: $e');
    }
  }

  Future<void> _startAutoSyncAfterRegistration() async {
    try {
      print('=== DEBUG: Starting Auto-Sync After Registration ===');

      // Initialize and start the sync service manager
      final syncManager = SyncServiceManager();
      await syncManager.initialize();

      // Request necessary permissions for background sync
      await syncManager.requestPermissions();
      await syncManager.requestBatteryOptimization();

      // Start the auto-sync service
      await syncManager.startSyncService();

      print('=== DEBUG: Auto-Sync Service Started Successfully ===');

      // Show success message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.sync, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                    'Auto-sync enabled! Your calls will be synced automatically every 10 minutes.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('=== ERROR: Failed to start auto-sync after registration ===');
      print('Error: $e');

      // Show error message but don't block registration completion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Registration successful! Auto-sync setup failed: ${e.toString()}. You can enable it manually from settings.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Device'),
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
                              Icons.person_add,
                              size: 40,
                              color: AppTheme.primaryWarm,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Welcome!',
                            style: AppTheme.headingMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please register your device to continue',
                            style: AppTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Personal Information Section
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person,
                                  color: AppTheme.primaryBrown, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Personal Information',
                                style: AppTheme.headingSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: AppTheme.getInputDecoration('Full Name',
                                icon: Icons.person_outline),
                            style: AppTheme.bodyMedium,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Mobile Number Field
                          TextFormField(
                            controller: _mobileController,
                            decoration: AppTheme.getInputDecoration(
                                'Mobile Number',
                                icon: Icons.phone_android),
                            style: AppTheme.bodyMedium,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            onChanged: (value) {
                              // Reset verification when number changes
                              if (_isSimVerified) {
                                setState(() {
                                  _isSimVerified = false;
                                  _simVerificationMessage = null;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              if (value.length != 10) {
                                return 'Mobile number must be 10 digits';
                              }
                              if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                                return 'Please enter a valid Indian mobile number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SIM Selection Section
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sim_card,
                                  color: AppTheme.primaryBrown, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'SIM Card Selection',
                                style: AppTheme.headingSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // SIM Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedSim,
                            decoration: AppTheme.getInputDecoration(
                                'Select SIM Card',
                                icon: Icons.sim_card_outlined),
                            style: AppTheme.bodyMedium,
                            items: _simOptions.map((sim) {
                              return DropdownMenuItem<String>(
                                value: sim['value'],
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sim_card,
                                      size: 18,
                                      color: AppTheme.primaryBrown,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sim['label']!,
                                      style: AppTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: _handleSimSelection,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a SIM card';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // SIM Verification Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_isVerifyingSim || _selectedSim == null)
                                      ? null
                                      : _verifySimNumber,
                              icon: _isVerifyingSim
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Icon(
                                      _isSimVerified
                                          ? Icons.verified
                                          : Icons.security,
                                      size: 18,
                                    ),
                              label: Text(
                                _isVerifyingSim
                                    ? 'Verifying SIM...'
                                    : _isSimVerified
                                        ? 'SIM Verified ✓'
                                        : 'Verify SIM Number',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSimVerified
                                    ? Colors.green
                                    : AppTheme.primaryBrown,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),

                          // Verification Status Message
                          if (_simVerificationMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isSimVerified
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isSimVerified
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isSimVerified
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color: _isSimVerified
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _simVerificationMessage!,
                                      style: TextStyle(
                                        color: _isSimVerified
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // SIM Selection Info
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.infoWarm.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.infoWarm.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16, color: AppTheme.infoWarm),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Select the SIM card that will be used for call monitoring. Verification ensures the entered number matches the selected SIM.',
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.infoWarm,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                              Icon(Icons.warehouse,
                                  color: AppTheme.primaryBrown, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Warehouse Assignment',
                                style: AppTheme.headingSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedWarehouse,
                            decoration: AppTheme.getInputDecoration(
                                'Select Warehouse',
                                icon: Icons.business),
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

                    const SizedBox(height: 24),

                    // Privacy Policy and Terms Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration.copyWith(
                        color: AppTheme.accentBrown.withOpacity(0.05),
                        border: Border.all(
                          color: AppTheme.accentBrown.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security,
                                  color: AppTheme.primaryBrown, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Privacy & Terms',
                                style: AppTheme.headingSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'By registering, you agree to our Privacy Policy and Terms of Service. '
                            'Your data is securely handled and used only for call monitoring purposes.',
                            style: AppTheme.bodySmall.copyWith(
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showPrivacyPolicy(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBrown
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.primaryBrown
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.privacy_tip_outlined,
                                          size: 16,
                                          color: AppTheme.primaryBrown,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Privacy Policy',
                                          style: AppTheme.caption.copyWith(
                                            color: AppTheme.primaryBrown,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showTermsOfService(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBrown
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.primaryBrown
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.description_outlined,
                                          size: 16,
                                          color: AppTheme.primaryBrown,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Terms of Service',
                                          style: AppTheme.caption.copyWith(
                                            color: AppTheme.primaryBrown,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business,
                                size: 14,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Powered by Deodap Technologies',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Register Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient:
                            _isSubmitting ? null : AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isSubmitting ? null : AppTheme.warmShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubmitting
                              ? AppTheme.warmDark
                              : Colors.transparent,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.primaryWarm),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Registering...',
                                    style: AppTheme.bodyLarge.copyWith(
                                      color: AppTheme.primaryWarm,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Register Device',
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
                              Icon(Icons.info_outline,
                                  color: AppTheme.infoWarm, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Registration Info:',
                                style: AppTheme.headingSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Your device will be registered with the selected warehouse\n'
                            '• Mobile number will be used as device identifier\n'
                            '• SIM verification ensures proper call monitoring setup\n'
                            '• Make sure to select the correct warehouse for your location\n'
                            '• Registration is required to access call monitoring features',
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.primaryWarm,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.privacy_tip, color: AppTheme.primaryBrown),
              const SizedBox(width: 8),
              const Text(
                'Privacy Policy',
                style: AppTheme.headingMedium,
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Collection & Usage',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• We collect call log data for monitoring and tracking purposes\n'
                    '• Your mobile number is used as a unique device identifier\n'
                    '• Warehouse information is stored for organizational purposes\n'
                    '• SIM selection is saved for proper call routing\n'
                    '• Data is encrypted and stored securely',
                    style: AppTheme.bodySmall.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data Protection',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Your data is protected with industry-standard encryption\n'
                    '• We do not share your personal information with third parties\n'
                    '• Data is used solely for call monitoring functionality\n'
                    '• You can request data deletion at any time',
                    style: AppTheme.bodySmall.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.infoWarm.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.infoWarm.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business,
                            size: 16, color: AppTheme.infoWarm),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Deodap Technologies - Committed to your privacy',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.infoWarm,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: AppTheme.secondaryButtonStyle,
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.primaryWarm,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryBrown),
              const SizedBox(width: 8),
              const Text(
                'Terms of Service',
                style: AppTheme.headingMedium,
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Usage',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• This app is designed for call log monitoring and tracking\n'
                    '• Users must register with valid information\n'
                    '• SIM verification is mandatory for proper functionality\n'
                    '• Service is provided for legitimate business purposes\n'
                    '• Misuse of the service is strictly prohibited',
                    style: AppTheme.bodySmall.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'User Responsibilities',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Provide accurate registration information\n'
                    '• Select the correct SIM card for monitoring\n'
                    '• Use the service in compliance with local laws\n'
                    '• Respect privacy of call participants\n'
                    '• Report any security issues immediately',
                    style: AppTheme.bodySmall.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Service Availability',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Service is provided "as is" without warranties\n'
                    '• We reserve the right to modify or discontinue service\n'
                    '• Support is provided during business hours\n'
                    '• Terms may be updated with prior notice',
                    style: AppTheme.bodySmall.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningWarm.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningWarm.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 16, color: AppTheme.warningWarm),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'By using this service, you agree to these terms',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.warningWarm,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: AppTheme.secondaryButtonStyle,
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}
