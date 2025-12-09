// profilescreen.dart (UPDATED)
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_filter_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar; // NEW
  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userProfile = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _profileImagePath = ''; // NEW
  String _employeeCode = ''; // NEW
  final TextEditingController _employeeCodeController = TextEditingController(); // NEW
  String _selectedLocation = ''; // NEW - for location filter

  // API Configuration
  static const String baseUrl = 'https://api.vacalvers.com/api-wms-app';
  static const String appId = '1';
  static const String apiKey = 'd80fc360-f2ed-4cbd-a65d-761d14660ea4';

  // iOS Purple palette
  static const _iosPurple = Color(0xFF6B52A3);
  static const _iosPurpleLight = Color(0xFF9F7AEA);
  static const _iosPurpleDark = Color(0xFF6B52A3);
  static const _bg = Color(0xFFF7F8FA);
  static const _card = Colors.white;
  static const _green = Color(0xFF34C759);
  static const _orange = Color(0xFFFF9500);
  static const _red = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImagePath = prefs.getString('profileImagePath') ?? '';
    _employeeCode = prefs.getString('employeeCode') ?? '';
    _employeeCodeController.text = _employeeCode;

    // Load selected location from shared service
    _selectedLocation = await LocationFilterService.getSelectedLocation();

    await _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      setState(() { _isLoading = true; _hasError = false; _errorMessage = ''; });

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) throw Exception('Authentication token not found');

      final url = Uri.parse('$baseUrl/auth/user').replace(queryParameters: {'app_id': appId, 'api_key': apiKey, 'token': authToken});
      final response = await http.get(url, headers: const {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status_flag'] == 1) {
          // Debug: Print the actual API response structure
          print('API Response Data: ${body['data']}');
          final userData = body['data'] ?? {};

          // Save available locations to shared service
          final locations = List<String>.from(userData['stock_physical_locations'] ?? []);
          await LocationFilterService.saveAvailableLocations(locations);
          print('ProfileScreen: Saved ${locations.length} locations to shared service');

          setState(() { _userProfile = userData; _isLoading = false; });
        } else {
          throw Exception((body['status_messages'] is List && body['status_messages'].isNotEmpty) ? body['status_messages'].join(', ') : 'Failed to load profile');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { _hasError = true; _errorMessage = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _refresh() async => _fetchUserProfile();

  // ===== Photo pick/remove =====
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (x == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', x.path);
    setState(() => _profileImagePath = x.path);
  }

  Future<void> _removePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileImagePath');
    setState(() => _profileImagePath = '');
  }

  Future<void> _saveEmployeeCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newCode = _employeeCodeController.text.trim();

      if (newCode.isEmpty) {
        _showMessage('Error', 'Please enter an employee code');
        return;
      }

      await prefs.setString('employeeCode', newCode);
      setState(() {
        _employeeCode = newCode;
      });

      _showMessage('Success', 'Employee code saved successfully');
    } catch (e) {
      _showMessage('Error', 'Failed to save employee code: $e');
    }
  }

  void _showMessage(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Location picker method
  Future<void> _showLocationPicker() async {
    final locations = List<String>.from(_userProfile['stock_physical_locations'] ?? []);
    if (locations.isEmpty) {
      _showMessage('No Locations', 'No physical locations available');
      return;
    }

    final allOption = 'All Locations';
    final items = [allOption, ...locations];
    int selectedIndex = _selectedLocation.isEmpty ? 0 : locations.indexOf(_selectedLocation) + 1;
    if (selectedIndex < 0) selectedIndex = 0;

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: _iosPurple)),
                    ),
                    const Spacer(),
                    const Text('Select Location Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        final selected = items[selectedIndex];
                        if (selected == allOption) {
                          await LocationFilterService.clearSelectedLocation();
                          setState(() => _selectedLocation = '');
                        } else {
                          await LocationFilterService.saveSelectedLocation(selected);
                          setState(() => _selectedLocation = selected);
                        }
                        Navigator.pop(context);
                        _showMessage('Success', 'Location filter updated successfully');
                      },
                      child: const Text('Done', style: TextStyle(color: _iosPurple, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (i) => selectedIndex = i,
                  children: items.map((item) => Center(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 16),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(child: _buildBody());
    if (!widget.showAppBar) {
      // Tab context (no AppBar/Drawer)
      return Scaffold(backgroundColor: _bg, body: content);
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(CupertinoIcons.back, color: _iosPurple, size: 22), onPressed: () => Navigator.pop(context), tooltip: 'Back'),
        centerTitle: true,
        title: const Text('Profile', style: TextStyle(color: _iosPurple, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _refresh,
            icon: _isLoading ? const CupertinoActivityIndicator() : const Icon(CupertinoIcons.refresh_bold, color: _iosPurple, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: content,
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CupertinoActivityIndicator(radius: 14));
    if (_hasError) return _errorState();

    return RefreshIndicator.adaptive(
      color: _iosPurple,
      onRefresh: _refresh,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _headerCard(_userProfile['user'] ?? {}),
          const SizedBox(height: 16),
          _photoActionsCard(),
          const SizedBox(height: 16),
          _accountDetailsCard(_userProfile['user'] ?? {}),
          const SizedBox(height: 16),
          if ((_userProfile['stock_physical_locations'] ?? []).isNotEmpty)
            _stockLocationsCard(List<String>.from(_userProfile['stock_physical_locations'])),
          const SizedBox(height: 16),
          _accountStatusCard(_userProfile['user'] ?? {}),
        ],
      ),
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
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8))]),
          child: Column(
            children: [
              Container(width: 76, height: 76, decoration: BoxDecoration(color: _red.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: _red, size: 36)),
              const SizedBox(height: 16),
              const Text('Unable to load profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 18),
              CupertinoButton.filled(onPressed: _fetchUserProfile, borderRadius: BorderRadius.circular(12), child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Cards =====
  Widget _headerCard(Map<String, dynamic> user) {
    final name = (user['name'] ?? 'User').toString();
    final email = (user['email'] ?? '').toString();
    final hasPhoto = _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: _card, boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10))]),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Container(height: 96, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0x1A6B52A3), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight))),
                BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(height: 96, color: Colors.white.withOpacity(0.25))),
                Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 43,
                    backgroundColor: const Color(0xFF6B52A3),
                    backgroundImage: hasPhoto ? FileImage(File(_profileImagePath)) : null,
                    child: hasPhoto ? null : Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(email, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  Widget _photoActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8))]),
      child: Row(
        children: [
          const Icon(CupertinoIcons.photo, color: _iosPurple),
          const SizedBox(width: 10),
          const Expanded(child: Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.w700))),
          CupertinoButton(onPressed: _pickPhoto, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: const Text('Pick')),
          if (_profileImagePath.isNotEmpty) CupertinoButton(onPressed: _removePhoto, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: const Text('Remove')),
        ],
      ),
    );
  }

  // — rest (Account details / locations / status) unchanged from your version —
  Widget _accountDetailsCard(Map<String, dynamic> user) { /* same as your code */
    return _cardShell(
      title: 'Account Details',
      icon: CupertinoIcons.person_crop_circle,
      child: Column(
        children: [
          _detailRow('User ID', (user['id'] ?? 'N/A').toString(), CupertinoIcons.number),
          _divider(),
          _detailRow('Warehouse ID', (user['warehouse_id'] ?? 'N/A').toString(), CupertinoIcons.house_alt),
          _divider(),
          _detailRow('Phone', (user['phone'] ?? 'Not provided').toString(), CupertinoIcons.phone),
          _divider(),
          _detailRow('Email', (user['email'] ?? 'Not provided').toString(), CupertinoIcons.envelope),
          _divider(),
          // Employee Code Section
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _iosPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _iosPurple.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.creditcard,
                      size: 16,
                      color: _iosPurple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Employee Code',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _iosPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _employeeCodeController,
                        placeholder: 'Enter your employee code',
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        style: const TextStyle(fontSize: 16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: CupertinoColors.separator, width: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: _iosPurple,
                      borderRadius: BorderRadius.circular(6),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _saveEmployeeCode,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          // Location filter section
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _iosPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _iosPurple.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.slider_horizontal_3, size: 16, color: _iosPurple),
                    const SizedBox(width: 8),
                    Text(
                      'Location Filter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _iosPurple,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minSize: 0,
                      color: _iosPurple,
                      borderRadius: BorderRadius.circular(8),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _showLocationPicker,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CupertinoColors.separator, width: 0.5),
                  ),
                  child: Text(
                    _selectedLocation.isEmpty ? 'All Locations' : _selectedLocation,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _selectedLocation.isEmpty ? CupertinoColors.systemGrey : _iosPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Available locations
          Text(
            'Available Locations:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: locations.map((l) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: l == _selectedLocation
                    ? _iosPurple
                    : _iosPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: l == _selectedLocation
                      ? _iosPurple
                      : _iosPurple.withOpacity(0.20),
                  width: l == _selectedLocation ? 2 : 1,
                ),
              ),
              child: Text(
                l,
                style: TextStyle(
                  fontSize: 13.5,
                  color: l == _selectedLocation
                      ? CupertinoColors.white
                      : _iosPurple,
                  fontWeight: FontWeight.w600
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _accountStatusCard(Map<String, dynamic> user) { /* same as yours */
    final isActive = user['is_active'] == 1; final isRW = user['is_readonly'] == 0;
    return _cardShell(
      title: 'Account Status', icon: CupertinoIcons.lock_rotation,
      child: Column(children: [
        _statusRow('Account Status', isActive ? 'Active' : 'Inactive', isActive ? _green : _red, isActive ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill),
        _divider(),
        _statusRow('Access Level', isRW ? 'Full Access' : 'Read Only', isRW ? _green : _orange, isRW ? CupertinoIcons.person_crop_circle_badge_checkmark : CupertinoIcons.eye_fill),
      ]),
    );
  }

  // Shared UI helpers (same as yours)
  Widget _cardShell({required String title, required IconData icon, required Widget child}) { /* ... */
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _iosPurple.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _iosPurple, size: 20)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
  Widget _detailRow(String label, String value, IconData icon) { /* ... */
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.black54, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }
  Widget _statusRow(String label, String value, Color color, IconData icon) { /* ... */
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.30))), child: Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700))),
      ])),
    ]);
  }
  Widget _divider() => Divider(color: Colors.grey.shade200, height: 20, thickness: 1);
}
