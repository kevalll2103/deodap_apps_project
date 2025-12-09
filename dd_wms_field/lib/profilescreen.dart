import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userProfile = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // API Configuration
  static const String baseUrl = 'https://api.vacalvers.com/api-wms-field-app';
  static const String appId = '1';
  static const String apiKey = 'd5e61e52-fd9d-4ac9-a953-fde5fe5f6e5e';

  // iOS palette
  static const _iosBlue = Color(0xFF007E9B);
  static const _bg = Color(0xFFF8FAFC);
  static const _card = Colors.white;
  static const _green = Color(0xFF34C759);
  static const _orange = Color(0xFFFF9500);
  static const _red = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse('$baseUrl/auth/user').replace(
        queryParameters: {
          'app_id': appId,
          'api_key': apiKey,
          'token': authToken,
        },
      );

      final response = await http.get(
        url,
        headers: const {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status_flag'] == 1) {
          setState(() {
            _userProfile = body['data'] ?? {};
            _isLoading = false;
          });
        } else {
          throw Exception(
            (body['status_messages'] is List && body['status_messages'].isNotEmpty)
                ? body['status_messages'].join(', ')
                : 'Failed to load profile',
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async => _fetchUserProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: _iosBlue, size: 22),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: _iosBlue,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _refresh,
            icon: _isLoading
                ? const CupertinoActivityIndicator()
                : const Icon(CupertinoIcons.refresh_bold, color: _iosBlue, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _loadingState();
    if (_hasError) return _errorState();

    return RefreshIndicator.adaptive(
      color: _iosBlue,
      onRefresh: _refresh,
      child: _profileContent(),
    );
  }

  // ====== States ======
  Widget _loadingState() {
    return const Center(
      child: CupertinoActivityIndicator(radius: 14),
    );
  }

  Widget _errorState() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                    color: _red, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 18),
              CupertinoButton.filled(
                onPressed: _fetchUserProfile,
                borderRadius: BorderRadius.circular(12),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ====== Content ======
  Widget _profileContent() {
    final user = _userProfile['user'] ?? {};
    final stockLocations =
    List<String>.from(_userProfile['stock_physical_locations'] ?? []);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _headerCard(user),
        const SizedBox(height: 16),
        _accountDetailsCard(user),
        const SizedBox(height: 16),
        if (stockLocations.isNotEmpty) ...[
          _stockLocationsCard(stockLocations),
          const SizedBox(height: 16),
        ],
        _accountStatusCard(user),
        const SizedBox(height: 8),
      ],
    );
  }

  // ====== Cards ======
  Widget _headerCard(Map<String, dynamic> user) {
    final name = (user['name'] ?? 'User').toString();
    final email = (user['email'] ?? '').toString();
    final isActive = user['is_active'] == 1;
    final isRW = user['is_readonly'] == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: _card,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Glassy header strip
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Container(
                  height: 96,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x1A007AFF), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(height: 96, color: Colors.white.withOpacity(0.25)),
                ),
                Align(
                  alignment: Alignment.center,
                  child: _avatar(name),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              email,
              style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusPill(
                isActive ? 'Active' : 'Inactive',
                isActive ? _green : _red,
                isActive ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
              ),
              _statusPill(
                isRW ? 'Read/Write' : 'Read Only',
                isRW ? _green : _orange,
                isRW ? CupertinoIcons.pencil_circle_fill : CupertinoIcons.eye_fill,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_iosBlue, Color(0xFF4DA3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _iosBlue.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountDetailsCard(Map<String, dynamic> user) {
    return _cardShell(
      title: 'Account Details',
      icon: CupertinoIcons.person_crop_circle,
      child: Column(
        children: [
          _detailRow('Warehouse ID', (user['warehouse_id'] ?? 'N/A').toString(), CupertinoIcons.house_alt),
          _divider(),
          _detailRow('Phone', (user['phone'] ?? 'Not provided').toString(), CupertinoIcons.phone),
        ],
      ),
    );
  }

  Widget _stockLocationsCard(List<String> locations) {
    return _cardShell(
      title: 'Stock Physical Locations',
      icon: CupertinoIcons.location_solid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${locations.length} locations assigned',
            style: const TextStyle(fontSize: 13.5, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: locations
                .map(
                  (l) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _iosBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _iosBlue.withOpacity(0.20)),
                ),
                child: Text(
                  l,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _iosBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _accountStatusCard(Map<String, dynamic> user) {
    final isActive = user['is_active'] == 1;
    final isRW = user['is_readonly'] == 0;

    return _cardShell(
      title: 'Account Status',
      icon: CupertinoIcons.lock_rotation,
      child: Column(
        children: [
          _statusRow(
            'Account Status',
            isActive ? 'Active' : 'Inactive',
            isActive ? _green : _red,
            isActive ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
          ),
          _divider(),
          _statusRow(
            'Access Level',
            isRW ? 'Full Access' : 'Read Only',
            isRW ? _green : _orange,
            isRW ? CupertinoIcons.person_crop_circle_badge_checkmark : CupertinoIcons.eye_fill,
          ),
        ],
      ),
    );
  }

  // ====== Helpers (UI) ======
  Widget _cardShell({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _iosBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _iosBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black54, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusRow(String label, String value, Color color, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.30)),
                ),
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Divider(color: Colors.grey.shade200, height: 20, thickness: 1);
}