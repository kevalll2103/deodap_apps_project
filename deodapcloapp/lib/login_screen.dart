import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _warehouseCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _warehouseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');
    final savedWarehouse = prefs.getString('warehouse');
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe && savedUsername != null) {
      setState(() {
        _usernameCtrl.text = savedUsername;
        _warehouseCtrl.text = savedWarehouse ?? '';
        _rememberMe = rememberMe;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setString('username', _usernameCtrl.text);
      await prefs.setString('warehouse', _warehouseCtrl.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('username');
      await prefs.remove('warehouse');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _saveLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('currentUser', _usernameCtrl.text);
    await prefs.setString('currentWarehouse', _warehouseCtrl.text);
    await prefs.setString('loginTime', DateTime.now().toIso8601String());
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO: Replace this with your real auth call.
    await Future.delayed(const Duration(seconds: 1));

    await _saveCredentials();
    await _saveLoginSession();

    setState(() => _loading = false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final base = size.width;
    final isTablet = base >= 720;

    final titleSize = (isTablet ? base * 0.035 : base * 0.075).clamp(20, 34).toDouble();
    final labelSize = (isTablet ? base * 0.018 : base * 0.040).clamp(12, 18).toDouble();
    final horizontal = (base * 0.08).clamp(18, 36).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Warehouse Login',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.oswald(
                          textStyle: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your credentials to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: labelSize,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usernameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  label: 'Username',
                                  hint: 'Enter username',
                                  icon: Icons.person_outline,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Username is required';
                                  }
                                  if (v.trim().length < 3) {
                                    return 'Minimum 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  label: 'Password',
                                  hint: 'Enter password',
                                  icon: Icons.lock_outline,
                                  suffix: IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (v.length < 6) return 'Minimum 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _warehouseCtrl,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                decoration: _inputDecoration(
                                  label: 'Warehouse No',
                                  hint: 'e.g. 101',
                                  icon: Icons.warehouse_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Warehouse number is required';
                                  }
                                  if (!RegExp(r'^\d{1,6}$').hasMatch(v.trim())) {
                                    return 'Only digits (max 6)';
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
                                    onChanged: (value) {
                                      setState(() => _rememberMe = value ?? false);
                                    },
                                    activeColor: Colors.black,
                                  ),
                                  Text(
                                    'Remember Me',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: labelSize,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Text(
                                    'Login',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '© ${DateTime.now().year} WMS',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F7F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black87, width: 1),
      ),
    );
  }
}