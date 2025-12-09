// lib/login_screen.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Controllers ---
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // --- UI State ---
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = true;

  // --- Warehouse data/state ---
  List<Map<String, dynamic>> _warehouses = []; // [{id,label}, ...]
  bool _loadingWarehouses = false;
  String? _selectedWarehouseId;    // stored internally
  String? _selectedWarehouseLabel; // user-facing

  // --- API Config ---
  static const String baseUrl = 'https://api.vacalvers.com/api-wms-field-app';
  static const String appId = '1';
  static const String apiKey = 'd5e61e52-fd9d-4ac9-a953-fde5fe5f6e5e';

  // --- Theme bits ---
  static const Color _blue700 = Color(0xFF007E9B);
  Color get _iosBlue => _blue700;

  // guard to prevent duplicate navigations
  bool _navigatingAway = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromPrefs();
    _restoreCachedWarehouses();
    _fetchWarehouses();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ========== PERSISTENCE ==========

  Future<void> _hydrateFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    final savedPhone = p.getString('username');
    final savedWarehouseId = p.getString('warehouse');
    final remember = p.getBool('rememberMe') ?? true;

    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember && savedPhone != null) _phoneCtrl.text = savedPhone;
      if (remember && savedWarehouseId != null && savedWarehouseId.isNotEmpty) {
        _selectedWarehouseId = savedWarehouseId;
      }
    });
  }

  Future<void> _restoreCachedWarehouses() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('cached_warehouses');
    if (raw != null && raw.isNotEmpty) {
      try {
        final cached = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (!mounted) return;
        setState(() => _warehouses = cached);
        _syncSelectedWarehouseLabel();
      } catch (_) {}
    }
  }

  Future<void> _cacheWarehouses(List<Map<String, dynamic>> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cached_warehouses', jsonEncode(list));
  }

  Future<void> _saveRememberMe() async {
    final p = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await p.setString('username', _phoneCtrl.text.trim());
      await p.setString('warehouse', _selectedWarehouseId ?? '');
      await p.setBool('rememberMe', true);
    } else {
      await p.remove('username');
      await p.remove('warehouse');
      await p.setBool('rememberMe', false);
    }
  }

  Future<void> _saveLoginSession(Map<String, dynamic> res) async {
    final p = await SharedPreferences.getInstance();
    final data = res['data'] ?? {};
    final user = data['user'] ?? {};
    final token = data['token'];

    await p.setBool('isLoggedIn', true);
    await p.setString('authToken', token?.toString() ?? '');
    await p.setString('currentUser', _phoneCtrl.text.trim());
    await p.setString('currentWarehouse', _selectedWarehouseId ?? '');
    await p.setString('loginTime', DateTime.now().toIso8601String());

    int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

    await p.setInt('userId', _asInt(user['id']));
    await p.setString('userName', '${user['name'] ?? ''}');
    await p.setString('userPhone', '${user['phone'] ?? ''}');
    await p.setInt('warehouseId', _asInt(user['warehouse_id']));
    await p.setInt('isReadonly', _asInt(user['is_readonly']));

    if (data['stock_physical_locations'] != null) {
      await p.setString('stockLocations', jsonEncode(data['stock_physical_locations']));
    }
  }

  // ========== NETWORK ==========

  Future<void> _fetchWarehouses() async {
    if (mounted) setState(() => _loadingWarehouses = true);
    try {
      final uri = Uri.parse('$baseUrl/app_info/warehouse_list').replace(
        queryParameters: {'app_id': appId, 'api_key': apiKey},
      );

      final res = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['status_flag'] == 1 && j['data'] != null) {
          final list = (j['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
            ..sort((a, b) => a['label'].toString().compareTo(b['label'].toString()));
          if (mounted) {
            setState(() => _warehouses = list);
            await _cacheWarehouses(list);
            _syncSelectedWarehouseLabel();
          }
        } else {
          _toast('Unable to load warehouses');
        }
      } else {
        _toast('Warehouse API error (${res.statusCode})');
      }
    } catch (e) {
      debugPrint('Warehouse fetch error: $e');
      _toast('Network error while fetching warehouses');
    } finally {
      if (mounted) setState(() => _loadingWarehouses = false);
    }
  }

  void _syncSelectedWarehouseLabel() {
    if (_selectedWarehouseId == null) return;
    final m = _warehouses.where((e) => e['id'].toString() == _selectedWarehouseId);
    if (m.isNotEmpty) {
      _selectedWarehouseLabel = m.first['label']?.toString();
    }
  }

  Future<Map<String, dynamic>?> _performLogin() async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final payload = {
        'app_id': appId,
        'api_key': apiKey,
        'phone': _phoneCtrl.text.trim(),
        'password': _passCtrl.text,
        'warehouse': _selectedWarehouseId ?? '',
      };

      final res = await http.post(
        url,
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      );

      Map<String, dynamic> j = {};
      try {
        j = Map<String, dynamic>.from(jsonDecode(res.body));
      } catch (_) {}

      if (res.statusCode == 200 && (j['status_flag'] == 1)) return j;

      final msg = (j['status_messages'] is List && j['status_messages'].isNotEmpty)
          ? j['status_messages'][0].toString()
          : (res.statusCode != 200
          ? 'Server error (${res.statusCode}). Try again.'
          : 'Login failed. Please try again.');
      _showError(msg);
      return null;
    } catch (e) {
      _showError('Network error. Please check your connection.');
      return null;
    }
  }

  // ========== DIALOGS / TOASTS ==========

  void _toast(String msg) {
    if (!mounted) return;
    final fctx = ScaffoldMessenger.of(context);
    fctx.hideCurrentSnackBar();
    fctx.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(msg),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Login Failed'),
        content: Padding(padding: const EdgeInsets.only(top: 6), child: Text(msg)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          )
        ],
      ),
    );
  }

  /// SUCCESS dialog -> auto close + navigate on the root navigator.
  void _welcomeAutoGo() {
    if (!mounted || _navigatingAway) return;
    _navigatingAway = true;

    // show on ROOT navigator so it doesn't block the following navigation
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Welcome back 👋'),
        content: Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('DeoDap employee • WMS field System'),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      // 1) Close the dialog on the ROOT navigator
      Navigator.of(context, rootNavigator: true).pop();

      // 2) Navigate on the ROOT navigator and clear the stack.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      });
    });
  }

  // ========== ACTIONS ==========

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarehouseId == null) {
      _showError('Please select a warehouse.');
      return;
    }

    setState(() => _loading = true);
    final res = await _performLogin();
    if (!mounted) return;

    if (res != null) {
      await _saveRememberMe();
      await _saveLoginSession(res);
      if (!mounted) return;
      setState(() => _loading = false);
      _welcomeAutoGo(); // auto dialog + navigation (fixed)
    } else {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ========== UI ==========

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
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo (top-center)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Image.asset(
                        'assets/login.png',
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'WMS Field Management',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(
                      textStyle: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your credentials to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87, fontSize: labelSize),
                  ),
                  const SizedBox(height: 24),

                  // Card
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
                          // Phone
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'Phone Number',
                              hint: 'Enter phone number',
                              icon: CupertinoIcons.phone,
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

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration(
                              label: 'Password',
                              hint: 'Enter password',
                              icon: CupertinoIcons.lock,
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 14),

                          // Warehouse picker
                          _warehouseSelector(context),

                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                activeColor: Colors.black,
                              ),
                              const Text('Remember Me'),
                              const Spacer(),
                              if (_loadingWarehouses)
                                const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CupertinoActivityIndicator(radius: 8),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Login button — iOS look (Blue 700)
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              onPressed: _loading ? null : _submit,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              color: _iosBlue,
                              borderRadius: BorderRadius.circular(12),
                              child: _loading
                                  ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CupertinoActivityIndicator())
                                  : const Text(
                                'Login',
                                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    '© ${DateTime.now().year} DeoDap wms field app',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Warehouse selector (Cupertino popup dialog with search) ----------
  Widget _warehouseSelector(BuildContext context) {
    final chosen = _selectedWarehouseLabel ?? 'Select warehouse';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openWarehouseDialog(context),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Warehouse',
          hint: 'Choose from list',
          icon: CupertinoIcons.house,
          suffix: const Icon(CupertinoIcons.chevron_down),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            chosen,
            style: TextStyle(
              color: _selectedWarehouseLabel == null ? Colors.black45 : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWarehouseDialog(BuildContext context) async {
    if (_warehouses.isEmpty && !_loadingWarehouses) {
      _fetchWarehouses();
    }

    String filter = '';

    await showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final items = _warehouses
                .where((w) {
              if (filter.isEmpty) return true;
              final label = (w['label'] ?? '').toString();
              return label.toLowerCase().contains(filter.toLowerCase());
            })
                .toList()
              ..sort((a, b) => a['label'].toString().compareTo(b['label'].toString()));

            return CupertinoAlertDialog(
              title: const Text('Select Warehouse'),
              content: Column(
                children: [
                  const SizedBox(height: 10),
                  _CupertinoSearchField(
                    hintText: 'Search by warehouse name',
                    onChanged: (v) => setSheet(() => filter = v.trim()),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 260,
                    child: _loadingWarehouses && _warehouses.isEmpty
                        ? const Center(child: CupertinoActivityIndicator())
                        : (items.isEmpty
                        ? const Center(
                      child: Text(
                        'No results',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CupertinoPopupSurface(
                        isSurfacePainted: true,
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          itemBuilder: (_, i) {
                            final w = items[i];
                            final id = w['id'].toString();
                            final label = w['label'].toString();
                            final selected = _selectedWarehouseId == id;

                            return _CupertinoListTile(
                              title: label,
                              selected: selected,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: _iosBlue.withOpacity(0.10),
                                child: Icon(CupertinoIcons.house_fill, color: _iosBlue, size: 18),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedWarehouseId = id;
                                  _selectedWarehouseLabel = label;
                                });
                                Navigator.of(ctx, rootNavigator: true).pop();
                                _toast('Warehouse set: $label');
                              },
                            );
                          },
                        ),
                      ),
                    )),
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  onPressed: () async {
                    await _fetchWarehouses();
                    setSheet(() {});
                  },
                  isDefaultAction: true,
                  child: const Text('Refresh'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- Input decoration (iOS-like) ----------
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
        borderSide: BorderSide(color: _iosBlue, width: 1),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}

/// --- Lightweight iOS search box ---
class _CupertinoSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _CupertinoSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      placeholder: hintText,
      prefix: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Icon(CupertinoIcons.search, size: 18, color: Color(0xFF6B7280)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      onChanged: onChanged,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      clearButtonMode: OverlayVisibilityMode.editing,
    );
  }
}

/// --- Minimal iOS list tile for the popup ---
class _CupertinoListTile extends StatelessWidget {
  final String title;
  final bool selected;
  final Widget? leading;
  final VoidCallback? onTap;

  const _CupertinoListTile({
    super.key,
    required this.title,
    this.selected = false,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material( // using Material Ink for subtle tap feedback inside popup
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              if (leading != null) leading!,
              if (leading != null) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(anim), child: child),
                child: selected
                    ? const Icon(CupertinoIcons.check_mark_circled_solid, color: Color(0xFF34C759), key: ValueKey('sel'))
                    : const SizedBox.shrink(key: ValueKey('nosel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
