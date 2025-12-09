import 'package:Deodap_Customprint/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isObscured = true;
  bool _isConfirmObscured = true;
  bool _isChecked = false;
  bool _isLoginMode = true;
  bool _isLoading = false;

  String _emailError = '';
  String _passwordError = '';
  String _fullNameError = '';
  String _confirmPasswordError = '';

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupFocusListeners();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _setupFocusListeners() {
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        setState(() => _emailError = '');
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() => _passwordError = '');
      }
    });

    _fullNameFocusNode.addListener(() {
      if (_fullNameFocusNode.hasFocus) {
        setState(() => _fullNameError = '');
      }
    });

    _confirmPasswordFocusNode.addListener(() {
      if (_confirmPasswordFocusNode.hasFocus) {
        setState(() => _confirmPasswordError = '');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _fullNameFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _clearErrors();
      _clearControllers();
      _isChecked = false;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _clearErrors() {
    setState(() {
      _emailError = '';
      _passwordError = '';
      _fullNameError = '';
      _confirmPasswordError = '';
    });
  }

  void _clearControllers() {
    _emailController.clear();
    _passwordController.clear();
    _fullNameController.clear();
    _confirmPasswordController.clear();
  }

  bool _validateFields() {
    bool isValid = true;

    // Clear previous errors
    _clearErrors();

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      setState(() => _emailError = 'Please enter a valid email');
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      isValid = false;
    }

    if (!_isLoginMode) {
      if (_fullNameController.text.trim().isEmpty) {
        setState(() => _fullNameError = 'Full name is required');
        isValid = false;
      } else if (_fullNameController.text.trim().length < 2) {
        setState(() => _fullNameError = 'Full name must be at least 2 characters');
        isValid = false;
      }

      if (_confirmPasswordController.text.isEmpty) {
        setState(() => _confirmPasswordError = 'Please confirm your password');
        isValid = false;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _confirmPasswordError = 'Passwords do not match');
        isValid = false;
      }
    }

    if (!_isChecked) {
      _showSnackBar('Please accept the terms and conditions', isError: true);
      isValid = false;
    }

    return isValid;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Unfocus any active text fields
    FocusScope.of(context).unfocus();

    // Validate fields before proceeding
    if (!_validateFields()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await _performLogin();
      } else {
        await _performSignup();
      }
    } catch (e) {
      print('Error during ${_isLoginMode ? 'login' : 'signup'}: $e');
      _showSnackBar('Network error. Please check your connection.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performLogin() async {
    try {
      final response = await http.post(
        Uri.parse('https://customprint.deodap.com/api_customprint/new_user_login.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login response: $data'); // Debug log

        if (data['message'] == 'Login successful.') {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', data['data']['id'].toString());
          await prefs.setString('fullname', data['data']['fullname'].toString());
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userEmail', _emailController.text.trim());

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomescreenCupertinoIOS()),
              (route) => false,
            );
          }
        } else if (data['message'] == 'Email Incorrect.') {
          setState(() => _emailError = 'Email not found');
        } else if (data['message'] == 'Incorrect password.') {
          setState(() => _passwordError = 'Incorrect password');
        } else {
          _showSnackBar(data['message'] ?? 'Login failed', isError: true);
        }
      } else {
        _showSnackBar('Server error. Please try again later.', isError: true);
      }
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('TimeoutException')) {
        _showSnackBar('Request timeout. Please check your connection.', isError: true);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _performSignup() async {
    try {
      final response = await http.post(
        Uri.parse('https://customprint.deodap.com/api_customprint/register_user.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'fullname': _fullNameController.text.trim(),
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Signup response: $data'); // Debug log

        if (data['message'] == 'User registered successfully.' || 
            data['status'] == 'success') {
          _showSnackBar('Account created successfully! Please login.');
          _toggleMode();
        } else if (data['message'] == 'Email already exists.' ||
            data['message'] == 'User already exists.') {
          setState(() => _emailError = 'Email already registered');
        } else {
          _showSnackBar(data['message'] ?? 'Registration failed', isError: true);
        }
      } else {
        _showSnackBar('Server error. Please try again later.', isError: true);
      }
    } catch (e) {
      print('Signup error: $e');
      if (e.toString().contains('TimeoutException')) {
        _showSnackBar('Request timeout. Please check your connection.', isError: true);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showSnackBar('Could not launch URL', isError: true);
      }
    } catch (e) {
      print('URL launch error: $e');
      _showSnackBar('Could not launch URL', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBody(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildHeader(),
            const SizedBox(height: 50),
            _buildForm(),
            const SizedBox(height: 30),
            _buildTermsCheckbox(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
            const SizedBox(height: 30),
            _buildToggleButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLoginMode ? "Welcome Back!" : "Create Account",
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLoginMode
              ? "Sign in to your account to continue"
              : "Create your account to get started",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        if (!_isLoginMode) ...[
          _buildTextField(
            controller: _fullNameController,
            focusNode: _fullNameFocusNode,
            label: "Full Name",
            hint: "Enter your full name",
            icon: Icons.person_outline_rounded,
            error: _fullNameError,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
        ],
        _buildTextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: "Email Address",
          hint: "Enter your email",
          icon: Icons.email_outlined,
          error: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: _isLoginMode ? TextInputAction.next : TextInputAction.next,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: "Password",
          hint: "Enter your password",
          icon: Icons.lock_outline_rounded,
          error: _passwordError,
          isPassword: true,
          isObscured: _isObscured,
          onToggleVisibility: () => setState(() => _isObscured = !_isObscured),
          textInputAction: _isLoginMode ? TextInputAction.done : TextInputAction.next,
        ),
        if (!_isLoginMode) ...[
          const SizedBox(height: 20),
          _buildTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: "Confirm Password",
            hint: "Confirm your password",
            icon: Icons.lock_outline_rounded,
            error: _confirmPasswordError,
            isPassword: true,
            isObscured: _isConfirmObscured,
            onToggleVisibility: () => setState(() => _isConfirmObscured = !_isConfirmObscured),
            textInputAction: TextInputAction.done,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required String error,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword ? isObscured : false,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            onFieldSubmitted: (_) {
              if (textInputAction == TextInputAction.done) {
                _handleSubmit();
              } else {
                FocusScope.of(context).nextFocus();
              }
            },
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF9CA3AF),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF6B7280),
                size: 22,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      onPressed: onToggleVisibility,
                      icon: Icon(
                        isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF6B7280),
                        size: 22,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: error.isNotEmpty ? Colors.red.shade300 : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: error.isNotEmpty ? Colors.red.shade300 : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: error.isNotEmpty ? Colors.red.shade400 : const Color(0xFF0B90A1),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error,
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isChecked ? const Color(0xFF0B90A1) : const Color(0xFFD1D5DB),
              width: 2,
            ),
          ),
          child: Checkbox(
            value: _isChecked,
            onChanged: (value) => setState(() => _isChecked = value ?? false),
            activeColor: const Color(0xFF0B90A1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide.none,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: _isLoginMode
                      ? 'By signing in, you agree to our '
                      : 'By creating an account, you agree to our ',
                ),
                TextSpan(
                  text: 'Terms and Conditions',
                  style: const TextStyle(
                    color: Color(0xFF0B90A1),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchURL(
                        "https://deodap.in/pages/terms-conditions?srsltid=AfmBOorlAFTcquWvmnM1Sq0E-P9PNHaRzkroAj-rYWhRHhkFoQ8KxU3h"),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: Color(0xFF0B90A1),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchURL(
                        "https://deodap.in/pages/privacy-policy#:~:text=We%20aim%20to%20take%20reasonable,at%20care%40deodap.com."),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B90A1), Color(0xFF0EA5E9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B90A1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
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
                _isLoginMode ? "Sign In" : "Create Account",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Center(
      child: TextButton(
        onPressed: _toggleMode,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 15),
            children: [
              TextSpan(
                text: _isLoginMode
                    ? "Don't have an account? "
                    : "Already have an account? ",
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: _isLoginMode ? "Sign Up" : "Sign In",
                style: const TextStyle(
                  color: Color(0xFF0B90A1),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}