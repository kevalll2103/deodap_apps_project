import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_homescreen.dart';
import 'home_screen.dart';

class LoginScreenview extends StatefulWidget {
  const LoginScreenview({super.key});

  @override
  State<LoginScreenview> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenview> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false; // default OFF

  // --- API endpoints (POST, JSON body) ---
  static const String _base = 'https://customprint.deodap.com/stockbridge';
  static const String _adminLogin = '$_base/admin_login.php';
  static const String _empLogin = '$_base/emp_login.php';

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPhone() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('saved_phone');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _rememberMe = true;
        _phoneCtrl.text = saved;
      });
    }
  }

  // ===== NETWORK CALLS =====
  Future<Map<String, dynamic>?> _postJson(
      String url, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': false, 'message': 'Invalid server response'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  Map<String, dynamic>? _extractData(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first as Map);
      }
    }
    return null;
  }

  Future<void> _saveSession({
    required String role, // 'admin' or 'employee'
    required Map<String, dynamic> data,
  }) async {
    final p = await SharedPreferences.getInstance();

    final token = data['token']?.toString() ?? '';
    final tokenExpires = data['token_expires']?.toString() ?? '';

    await p.setBool('isLoggedIn', true);
    await p.setString('role', role);
    await p.setString('token', token);
    await p.setString('token_expires', tokenExpires);

    // Common user data
    await p.setString(
      'contact_number',
      (data['contact_number'] ?? data['username'] ?? '').toString(),
    );
    await p.setString('name', (data['name'] ?? '').toString());
    await p.setInt('user_id', _asInt(data['id']));
    await p.setString(
        'last_login_time', (data['last_login_time'] ?? '').toString());
    await p.setString(
        'last_login_ip', (data['last_login_ip'] ?? '').toString());

    // Admin specific
    if (role == 'admin') {
      await p.setString('admin_contact', data['contact_number'] ?? '');
      await p.setString('admin_name', data['name'] ?? '');
      await p.setString('admin_id', data['id']?.toString() ?? '');
      await p.setString('admin_role', data['role']?.toString() ?? 'admin');
    }

    // Employee specific
    if (role == 'employee') {
      await p.setString('employee_email', data['email'] ?? '');
      await p.setString('employee_emp_code', data['emp_code']?.toString() ?? '');
      await p.setString('employee_id', data['id']?.toString() ?? '');
    }

    if (_rememberMe) {
      await p.setString('saved_phone', _phoneCtrl.text.trim());
    } else {
      await p.remove('saved_phone');
    }
  }

  int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  // ===== UI HELPERS =====
  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'Login Failed',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(msg, style: GoogleFonts.inter()),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'OK',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      ),
    );
  }

  // ===== FLOW =====
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final payload = {
      'contact_number': _phoneCtrl.text.trim(),
      'password': _passCtrl.text,
    };

    // 1) Try ADMIN
    final adminRes = await _postJson(_adminLogin, payload);
    final adminData = _extractData(adminRes?['data']);
    if (adminRes?['success'] == true && adminData != null) {
      await _saveSession(role: 'admin', data: adminData);
      if (!mounted) return;
      _navigate(const empHomeScreen());
      return;
    }

    // 2) Try EMPLOYEE
    final empRes = await _postJson(_empLogin, payload);
    final empData = _extractData(empRes?['data']);
    if (empRes?['success'] == true && empData != null) {
      await _saveSession(role: 'employee', data: empData);
      if (!mounted) return;
      _navigate(const empHomeScreen());
      return;
    }

    // 3) Both failed
    setState(() => _loading = false);
    final msg = empRes?['message']?.toString() ??
        adminRes?['message']?.toString() ??
        'Invalid mobile or password';
    _showError(msg);
  }

  void _navigate(Widget screen) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'Welcome',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Login successful', style: GoogleFonts.inter()),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close dialog
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (_) => screen),
        (route) => false,
      );
    });
  }

  // ===== WIDGETS =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Image.asset(
                      'assets/images/forgot_password_image.png',
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'DeoDap MM System',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in with your mobile number',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'Phone Number',
                              hint: 'Enter phone number',
                              icon: CupertinoIcons.phone,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: CupertinoColors.label,
                            ),
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return 'Phone number is required';
                              if (!RegExp(r'^\d{10,15}$').hasMatch(t)) {
                                return 'Enter valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration(
                              label: 'Password',
                              hint: 'Enter password',
                              icon: CupertinoIcons.lock,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                ),
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: CupertinoColors.label,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (v.length < 6) {
                                return 'Minimum 6 characters';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                                activeColor: CupertinoColors.systemBlue,
                              ),
                              Text(
                                'Remember Me',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: CupertinoColors.label,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              onPressed: _loading ? null : _submit,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              color: CupertinoColors.systemBlue,
                              borderRadius: BorderRadius.circular(12),
                              disabledColor: CupertinoColors.systemGrey4,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CupertinoActivityIndicator(
                                        color: CupertinoColors.white,
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '© ${DateTime.now().year} DeoDap • MM system',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: CupertinoColors.systemBlue,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: CupertinoColors.systemGrey6,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: CupertinoColors.label,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: CupertinoColors.placeholderText,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CupertinoColors.systemGrey4,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CupertinoColors.systemGrey5,
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CupertinoColors.systemBlue,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CupertinoColors.systemRed,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CupertinoColors.systemRed,
          width: 1.5,
        ),
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 12,
        color: CupertinoColors.systemRed,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
