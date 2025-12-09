import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dashboard_salespeople.dart';

class Login_salespeople extends StatefulWidget {
  const Login_salespeople({super.key});

  @override
  State<Login_salespeople> createState() => _LoginScreenDropshipperViewState();
}

class _LoginScreenDropshipperViewState extends State<Login_salespeople>
    with TickerProviderStateMixin {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _crnController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool rememberMe = false;
  bool _isLoading = false;
  String errorMessage = '';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _errorController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _errorAnimation;

  // Updated Keys - consistent with splash screen and login.dart
  static const String KEY_LOGIN = 'isLoggedIn';
  static const String KEY_LOGIN_TYPE = 'loginType';

  // Modern color palette - White theme with green accents for salespeople
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color secondaryGreen = Color(0xFF15803D);
  static const Color lightGreen = Color(0xFFDCFCE7);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _autoLoginIfRemembered();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _errorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _errorController.dispose();
    _mobileController.dispose();
    _crnController.dispose();
    super.dispose();
  }

  Future<void> _autoLoginIfRemembered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool(KEY_LOGIN) ?? false;
      final String? loginType = prefs.getString(KEY_LOGIN_TYPE);
      final String? savedVersion = prefs.getString('appVersion');
      final String currentVersion = (await PackageInfo.fromPlatform()).version;

      // Clear data if app version changed
      if (savedVersion != currentVersion) {
        await prefs.clear();
        await prefs.setString('appVersion', currentVersion);
        return;
      }

      // Navigate to dashboard if user is logged in as sales
      if (isLoggedIn && loginType == 'sales') {
        // Add a small delay to ensure widgets are ready
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SalespersonDashboard()),
          );
        }
      }
    } catch (e) {
      // Handle error silently and let user login normally
      debugPrint('Auto-login error: $e');
    }
  }

  // Mobile number validation
  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }

    // Remove any spaces or special characters
    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check for valid Indian mobile number (10 digits starting with 6,7,8,9)
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleaned)) {
      return 'Enter valid 10-digit mobile number';
    }

    return null;
  }

  // CRN validation
  String? _validateCRN(String? value) {
    if (value == null || value.isEmpty) {
      return 'CRN number is required';
    }
    if (value.length < 3) {
      return 'CRN must be at least 3 characters';
    }
    return null;
  }

  void _showError(String message) {
    setState(() => errorMessage = message);
    _errorController.forward().then((_) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          _errorController.reverse();
          setState(() => errorMessage = '');
        }
      });
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final mobile = _mobileController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final crn = _crnController.text.trim();

    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse('https://customprint.deodap.com/api_dropshipper_tracker/login_sales.php');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "mobile": mobile,
          "crn": crn,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final user = data['data'];
          final prefs = await SharedPreferences.getInstance();
          final version = (await PackageInfo.fromPlatform()).version;

          // CRITICAL FIX: Set login status to true
          await prefs.setBool(KEY_LOGIN, true); // This was missing!

          // Set other login data
          await prefs.setString('appVersion', version);
          await prefs.setString(KEY_LOGIN_TYPE, 'sales');
          await prefs.setString('seller_id', user['seller_id']?.toString() ?? '');
          await prefs.setString('seller_name', user['seller_name']?.toString() ?? '');
          await prefs.setString('store_name', user['store_name']?.toString() ?? '');
          await prefs.setString('contact_number', user['contact_number']?.toString() ?? '');
          await prefs.setString('email', user['email']?.toString() ?? '');
          await prefs.setString('crn', user['crn']?.toString() ?? '');
          await prefs.setString('username', user['username']?.toString() ?? '');
          await prefs.setString('user_data', jsonEncode(user));

          if (rememberMe) {
            await prefs.setBool('rememberMe', true);
          } else {
            await prefs.remove('rememberMe');
          }

          // Show success message briefly
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login successful! Welcome ${user['seller_name'] ?? 'User'}'),
              backgroundColor: successColor,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to SalespersonDashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SalespersonDashboard()),
                (route) => false,
          );
        } else {
          _showError(data['message']?.toString() ?? 'Invalid credentials');
        }
      } else {
        _showError('Server error (${response.statusCode}). Please try again.');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _showError('Connection timeout. Please check your internet connection.');
      } else {
        _showError('Connection failed. Please check your internet connection.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Logout functionality
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_LOGIN, false);
    await prefs.remove(KEY_LOGIN_TYPE);
    await prefs.remove('user_data');
    await prefs.remove('seller_id');
    await prefs.remove('seller_name');
    await prefs.remove('rememberMe');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildLoginCard(),
                        const SizedBox(height: 32),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated logo container
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryGreen, secondaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // Company name
        Text(
          "Deodap Sales Team",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Sales Portal",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 16),
        // Sales team badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: primaryGreen.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cases_outlined, color: primaryGreen, size: 16),
              const SizedBox(width: 8),
              Text(
                "Sales Team Access",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome text
            Text(
              "Sales Login",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Access your sales dashboard",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Mobile number field
            _buildInputField(
              "Mobile Number",
              Icons.phone_outlined,
              _mobileController,
              keyboardType: TextInputType.phone,
              validator: _validateMobile,
            ),
            const SizedBox(height: 20),

            // CRN field
            _buildInputField(
              "CRN Number",
              Icons.confirmation_number_outlined,
              _crnController,
              validator: _validateCRN,
            ),
            const SizedBox(height: 24),

            // Remember me checkbox
            _buildRememberMeCheckbox(),

            // Error message
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildErrorMessage(),
            ],

            const SizedBox(height: 32),

            // Login button
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      String hint,
      IconData icon,
      TextEditingController controller, {
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: "Enter your ${hint.toLowerCase()}",
              hintStyle: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: primaryGreen, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              errorStyle: GoogleFonts.inter(
                color: errorColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: rememberMe,
            activeColor: primaryGreen,
            checkColor: Colors.white,
            side: BorderSide(color: borderColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) => setState(() => rememberMe = val ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "Remember me",
          style: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return ScaleTransition(
      scale: _errorAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: errorColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: errorColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: GoogleFonts.inter(
                  color: errorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Add retry button for network errors
            if (errorMessage.contains('Connection') || errorMessage.contains('timeout'))
              IconButton(
                onPressed: _login,
                icon: Icon(Icons.refresh, color: errorColor, size: 20),
                tooltip: 'Retry',
                splashRadius: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
                  : const LinearGradient(
                colors: [primaryGreen, secondaryGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isLoading ? [] : [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Verifying...",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
                  : Text(
                "Verify & Login",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Copyright
          Text(
            "© 2025 Deodap International Pvt Ltd",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Sales team info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_outlined, color: primaryGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                "Authorized Sales Team",
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Support info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.support_agent_outlined, color: textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                "Sales Support: sales@deodap.com",
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
