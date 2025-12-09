import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:amz/view/employee/homescreen_employee_view.dart';

class LoginScreenAdminView extends StatefulWidget {
  const LoginScreenAdminView({super.key});

  @override
  State<LoginScreenAdminView> createState() => _LoginScreenAdminViewState();
}

class _LoginScreenAdminViewState extends State<LoginScreenAdminView>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscured = true;
  bool rememberMe = false;
  bool acceptTerms = false;
  String errorMessage = '';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Keys used in SplashscreenView
  static const String KEY_LOGIN = 'isLoggedIn';
  static const String KEY_USER_ROLE = 'userRole';

  // Modern color palette - White theme with blue accents
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color secondaryBlue = Color(0xFF1E40AF);
  static const Color lightBlue = Color(0xFFEFF6FF);
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
    _checkAutoLogin();
    _initializeAnimations();
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

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(KEY_LOGIN) ?? false;
    final String? role = prefs.getString(KEY_USER_ROLE);

    if (isLoggedIn && role == 'employee') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomescreenEmployeeView()),
      );
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please enter both email and password.');
      return;
    }

    if (!acceptTerms) {
      setState(() => errorMessage = 'Please accept Terms & Conditions to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    final url = Uri.parse('https://customprint.deodap.com/api_amzDD_return/admin_login.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        final user = data['data'];
        final prefs = await SharedPreferences.getInstance();

        // Save session info
        await prefs.setBool(KEY_LOGIN, true);
        await prefs.setString(KEY_USER_ROLE, 'employee');
        await prefs.setString('admin_email', user['email']);
        await prefs.setString('admin_password', password);

        if (rememberMe) {
          await prefs.setBool('rememberMe', true);
        } else {
          await prefs.remove('rememberMe');
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomescreenEmployeeView()),
              (route) => false,
        );
      } else {
        setState(() => errorMessage = data['message'] ?? 'Invalid login credentials.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Connection failed. Please check your internet connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
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
                    colors: [primaryBlue, secondaryBlue],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business_center_outlined,
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
          "Deodap International",
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
          "Private Limited",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 16),
        // Employee portal badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: primaryBlue.withOpacity(0.2)),
          ),
          child: Text(
            "Employee Portal",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
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
              "Welcome Back",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sign in to your employee account",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Email field
            _buildInputField(
              "Email Address",
              Icons.mail_outline_rounded,
              _emailController,
              TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Password field
            _buildPasswordField(),
            const SizedBox(height: 24),

            // Checkboxes
            _buildCheckboxSection(),

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

  Widget _buildInputField(String hint, IconData icon, TextEditingController controller, TextInputType keyboardType) {
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
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: "Enter your $hint",
              hintStyle: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: primaryBlue, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
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
          child: TextField(
            controller: _passwordController,
            obscureText: _isObscured,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: "Enter your password",
              hintStyle: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryBlue, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxSection() {
    return Column(
      children: [
        _buildCheckbox("Remember me", rememberMe, (val) => setState(() => rememberMe = val ?? false)),
        const SizedBox(height: 12),
        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildCheckbox(String text, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            activeColor: primaryBlue,
            checkColor: Colors.white,
            side: BorderSide(color: borderColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: acceptTerms,
            activeColor: primaryBlue,
            checkColor: Colors.white,
            side: BorderSide(color: borderColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) => setState(() => acceptTerms = val ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: "I agree to the ",
              style: GoogleFonts.inter(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              children: [
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _launchURL('https://deodap.in/pages/terms-conditions'),
                    child: Text(
                      "Terms & Conditions",
                      style: GoogleFonts.inter(
                        color: primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
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
        ],
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
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isLoading ? [] : [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
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
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Text(
                "Sign In",
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

          // Support info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.support_agent_outlined, color: textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                "Support: care@deodap.com",
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _launchURL('https://deodap.in/pages/about-us'),
                child: Text(
                  "About Us",
                  style: GoogleFonts.inter(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "•",
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _launchURL('https://deodap.in/pages/terms-conditions'),
                child: Text(
                  "Terms & Conditions",
                  style: GoogleFonts.inter(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}