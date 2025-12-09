import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DropshipperGeneratedDetailsScreen extends StatefulWidget {
  const DropshipperGeneratedDetailsScreen({super.key});

  @override
  State<DropshipperGeneratedDetailsScreen> createState() =>
      _DropshipperGeneratedDetailsScreenState();
}

class _DropshipperGeneratedDetailsScreenState
    extends State<DropshipperGeneratedDetailsScreen> {
  List<dynamic> dropshippers = [];
  List<dynamic> filteredDropshippers = [];
  bool isLoading = true;
  String searchText = "";
  String? errorMessage;

  // OTP related variables
  bool isOtpLoading = false;
  String currentDeletingSellerId = "";

  // User role for delete authorization
  String userRole = "employee"; // Default role, can be "developer", "administrator", or "employee"

  @override
  void initState() {
    super.initState();
    fetchDropshipperData();
    _loadUserRole();
  }

  // Load user role from SharedPreferences or API
  Future<void> _loadUserRole() async {
    // TODO: Load user role from SharedPreferences or API
    // Example implementation:
    // final prefs = await SharedPreferences.getInstance();
    // final role = prefs.getString('user_role') ?? 'employee';
    // setState(() {
    //   userRole = role; // Possible values: "developer", "administrator", "employee"
    // });

    // For testing purposes, uncomment one of the lines below:
    // setState(() {
    //   userRole = "developer";     // Enable delete functionality
    //   userRole = "administrator"; // Enable delete functionality
    // });
  }

  // Check if user is authorized to delete
  bool _isAuthorizedToDelete() {
    return userRole == "developer" || userRole == "administrator";
  }

  // Show unauthorized access dialog
  void _showUnauthorizedDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Access Restricted",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Delete functionality is restricted to authorized personnel only.",
                  style: TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 20,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Authorized Roles",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "• Developer",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "• Administrator",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Contact your administrator for delete permissions",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4A5568),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Understood",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> fetchDropshipperData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            "https://customprint.deodap.com/api_amzDD_return/get_all_dropshippers.php"),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            dropshippers = data['dropshippers'] ?? [];
            filteredDropshippers = dropshippers;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = data['error'] ?? 'Unknown error occurred';
          });
          _showErrorSnackbar("Error: ${data['error']}");
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Server error: ${response.statusCode}';
        });
        _showErrorSnackbar("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        isLoading = false;
        errorMessage = 'Network error: Unable to connect to server';
      });
      _showErrorSnackbar("Network error: Unable to connect to server");
    }
  }

  void filterSearch(String query) {
    final results = dropshippers.where((item) {
      final id = (item['seller_id'] ?? '').toString().toLowerCase();
      final name = (item['store_name'] ?? '').toString().toLowerCase();
      final crn = (item['crn'] ?? '').toString().toLowerCase();
      final email = (item['email'] ?? '').toString().toLowerCase();
      final contact = (item['contact_number'] ?? '').toString().toLowerCase();

      return id.contains(query.toLowerCase()) ||
          name.contains(query.toLowerCase()) ||
          crn.contains(query.toLowerCase()) ||
          email.contains(query.toLowerCase()) ||
          contact.contains(query.toLowerCase());
    }).toList();

    setState(() {
      searchText = query;
      filteredDropshippers = results;
    });
  }

  // Send OTP to admin email
  Future<bool> sendOtpToAdmin(String sellerId) async {
    setState(() {
      isOtpLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            "https://customprint.deodap.com/api_amzDD_return/send_delete_otp.php"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'seller_id': sellerId,
          'admin_email': 'kevalkateshiya.deodap@gmail.com',
          'action': 'delete_dropshipper'
        },
      ).timeout(const Duration(seconds: 30));

      setState(() {
        isOtpLoading = false;
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          return true;
        } else {
          _showErrorSnackbar("Failed to send OTP: ${result['error']}");
          return false;
        }
      } else {
        _showErrorSnackbar("Server error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      setState(() {
        isOtpLoading = false;
      });
      _showErrorSnackbar("Network error: Unable to send OTP");
      return false;
    }
  }

  // Verify OTP and delete dropshipper
  Future<bool> verifyOtpAndDelete(String sellerId, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(
            "https://customprint.deodap.com/api_amzDD_return/verify_otp_and_delete.php"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'seller_id': sellerId,
          'otp': otp,
          'admin_email': 'kevalkateshiya.deodap@gmail.com',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['success'] == true) {
          setState(() {
            dropshippers.removeWhere((d) => d['seller_id'] == sellerId);
            filteredDropshippers.removeWhere((d) => d['seller_id'] == sellerId);
          });
          _showSuccessSnackbar('Dropshipper deleted successfully');
          return true;
        } else {
          _showErrorSnackbar('Delete failed: ${result['error']}');
          return false;
        }
      } else {
        _showErrorSnackbar('Server error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _showErrorSnackbar('Network error: Unable to delete dropshipper');
      return false;
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 8,
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 8,
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void confirmDelete(String sellerId, String storeName) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Confirm Delete",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Are you sure you want to delete this dropshipper account?",
                  style: TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.store_rounded,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Store Details",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: $sellerId",
                        style: const TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "OTP will be sent to admin email for verification",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4A5568),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: isOtpLoading ? null : () {
                  Navigator.pop(context);
                  initiateDeleteWithOtp(sellerId, storeName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  elevation: 2,
                  shadowColor: Colors.red.withOpacity(0.3),
                ),
                child: isOtpLoading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  "Send OTP",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }

  void initiateDeleteWithOtp(String sellerId, String storeName) async {
    currentDeletingSellerId = sellerId;

    bool otpSent = await sendOtpToAdmin(sellerId);
    if (otpSent) {
      showOtpDialog(sellerId, storeName);
    }
  }

  void showOtpDialog(String sellerId, String storeName) {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setDialogState) =>
                AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Enter OTP",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "OTP Sent Successfully",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "kevalkateshiya.deodap@gmail.com",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Deleting Account",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ID: $sellerId",
                              style: const TextStyle(
                                color: Color(0xFF4A5568),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        enabled: !isVerifying,
                        style: const TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: "Enter 6-digit OTP",
                          labelStyle: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontWeight: FontWeight.w600,
                          ),
                          hintText: "000000",
                          hintStyle: const TextStyle(
                            color: Color(0xFFA0AEC0),
                            letterSpacing: 3,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.blue,
                          ),
                          counterText: "",
                          filled: true,
                          fillColor: const Color(0xFFF7FAFC),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isVerifying ? null : () {
                        Navigator.pop(context);
                        otpController.dispose();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4A5568),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isVerifying ? null : () async {
                        if (otpController.text.length == 6) {
                          setDialogState(() {
                            isVerifying = true;
                          });

                          bool success = await verifyOtpAndDelete(
                              sellerId, otpController.text);

                          if (success) {
                            Navigator.pop(context);
                          } else {
                            setDialogState(() {
                              isVerifying = false;
                            });
                          }
                          otpController.clear();
                        } else {
                          _showErrorSnackbar("Please enter valid 6-digit OTP");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        elevation: 2,
                        shadowColor: Colors.red.withOpacity(0.3),
                      ),
                      child: isVerifying
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : const Text(
                        "Verify & Delete",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void showDetailsDialog(Map item) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Dropshipper Details",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 500),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard("Basic Information", [
                      _buildDetailRow("Seller ID", item['seller_id']),
                      _buildDetailRow("Store Name", item['store_name']),
                      _buildDetailRow("Seller Name", item['seller_name']),
                      _buildDetailRow("CRN", item['crn']),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailCard("Account Details", [
                      _buildDetailRow("Username", item['username']),
                      _buildDetailRow("Password", item['password']),
                      _buildDetailRow("plain password",item ['plain_password']),
                      _buildDetailRow("Contact", item['contact_number']),
                      _buildDetailRow("Email", item['email']),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailCard("Activity", [
                      _buildDetailRow("Created At", item['created_at']),
                      _buildDetailRow(
                          "Last Login", item['last_login'] ?? 'Never'),
                      _buildDetailRow(
                          "Last Logout", item['last_logout'] ?? 'Never'),
                    ]),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4A5568),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (_isAuthorizedToDelete()) {
                    confirmDelete(item['seller_id'], item['store_name']);
                  } else {
                    _showUnauthorizedDialog();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAuthorizedToDelete()
                      ? Colors.red[600]
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  elevation: _isAuthorizedToDelete() ? 2 : 0,
                  shadowColor: _isAuthorizedToDelete() ? Colors.red.withOpacity(
                      0.3) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isAuthorizedToDelete()) ...[
                      const Icon(Icons.lock_rounded, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isAuthorizedToDelete() ? "Delete" : "Restricted",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (value ?? 'N/A').toString(),
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Error Loading Data",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "An unexpected error occurred",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: fetchDropshipperData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                  "Try Again", style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 2,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: "Search by ID, Store Name, CRN, Email, or Contact...",
              hintStyle: const TextStyle(
                color: Color(0xFFA0AEC0),
                fontSize: 16,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF7FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            onChanged: filterSearch,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${filteredDropshippers
                          .length} dropshipper${filteredDropshippers.length != 1
                          ? 's'
                          : ''}",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (searchText.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      searchText = "";
                      filteredDropshippers = dropshippers;
                    });
                  },
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: Colors.blue,
                  ),
                  label: const Text(
                    "Clear Filter",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropshipperCard(Map item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showDetailsDialog(item),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade600,
                            Colors.blue.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          ((item['store_name'] ?? '')
                              .toString()
                              .isNotEmpty)
                              ? item['store_name'].toString()[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (item['store_name'] ?? 'Unknown Store').toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (item['seller_name'] ?? 'N/A').toString(),
                            style: const TextStyle(
                              color: Color(0xFF4A5568),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        "ID: ${item['seller_id'] ?? 'N/A'}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.badge_outlined,
                        "CRN",
                        item['crn'] ?? 'N/A',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        "Contact",
                        item['contact_number'] ?? 'N/A',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.email_outlined,
                        "Email",
                        item['email'] ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A5568),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                searchText.isNotEmpty ? Icons.search_off_rounded : Icons
                    .people_outline_rounded,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchText.isNotEmpty
                  ? "No dropshippers found"
                  : "No dropshippers available",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searchText.isNotEmpty
                  ? "Try adjusting your search criteria"
                  : "Dropshippers will appear here once added",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Loading Dropshippers",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Please wait while we fetch the data...",
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 16,
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
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.blue[800],
          elevation: 0,
          title: const Text(
            "Dropshipper Management",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: fetchDropshipperData,
              tooltip: 'Refresh Data',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : errorMessage != null
                    ? _buildErrorWidget()
                    : Column(
                  children: [
                    _buildSearchHeader(),
                    Expanded(
                      child: filteredDropshippers.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredDropshippers.length,
                        itemBuilder: (context, index) {
                          final item = filteredDropshippers[index];
                          return _buildDropshipperCard(item, index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}