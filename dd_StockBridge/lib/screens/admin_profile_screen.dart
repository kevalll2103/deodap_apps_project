import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';

// ===== Theme =====
const Color kBrandColor = CupertinoColors.systemBlue;
const Color kBg = CupertinoColors.white;

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  // Profile data
  String _userName = '';
  String _userPhone = '';
  String _userEmail = '';
  String _userId = '';
  String _lastLoginTime = '';
  String _lastLoginIp = '';
  String _profileImagePath = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('name') ?? 'Admin User';
        _userPhone = prefs.getString('contact_number') ?? '';
        _userEmail = prefs.getString('contact_number') ?? '';
        _userId = prefs.getInt('user_id')?.toString() ?? '';
        _lastLoginTime = prefs.getString('last_login_time') ?? '';
        _lastLoginIp = prefs.getString('last_login_ip') ?? '';
        _profileImagePath = prefs.getString('profileImagePath') ?? '';
      });
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath', pickedFile.path);
        setState(() {
          _profileImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showError('Failed to pick image');
    }
  }

  void _showImagePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            'Change Profile Photo',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
          message: Text(
            'Choose how you want to set your profile photo',
            style: GoogleFonts.inter(),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.camera),
                  const SizedBox(width: 8),
                  Text(
                    'Take Photo',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.photo),
                  const SizedBox(width: 8),
                  Text(
                    'Choose from Gallery',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_profileImagePath.isNotEmpty)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () async {
                  Navigator.of(context).pop();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('profileImagePath');
                  setState(() {
                    _profileImagePath = '';
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.delete),
                    const SizedBox(width: 8),
                    Text(
                      'Remove Photo',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            message,
            style: GoogleFonts.inter(),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Success',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            message,
            style: GoogleFonts.inter(),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Edit profile feature coming soon!',
            style: GoogleFonts.inter(),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.inter(),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (_) => const LoginScreenview()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final hasPhoto = _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImagePicker,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemBlue.withOpacity(0.1),
                border: Border.all(
                  color: CupertinoColors.systemBlue.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: hasPhoto
                  ? ClipOval(
                      child: Image.file(
                        File(_profileImagePath),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  : ClipOval(
                      child: Image.asset(
                        'assets/images/admin_icon.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            CupertinoIcons.person_crop_circle,
                            size: 60,
                            color: CupertinoColors.systemBlue,
                          );
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin User',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('User ID', _userId.isNotEmpty ? 'ID:$_userId' : 'N/A'),
          _buildInfoRow('Phone Number', _userPhone.isNotEmpty ? _userPhone : 'N/A'),
          _buildInfoRow('Email', _userEmail.isNotEmpty ? _userEmail : 'N/A'),
          _buildInfoRow('Last Login', _lastLoginTime.isNotEmpty ? _lastLoginTime : 'N/A'),
          _buildInfoRow('Login IP', _lastLoginIp.isNotEmpty ? _lastLoginIp : 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: GoogleFonts.inter(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: CupertinoActivityIndicator(radius: 20),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: widget.showAppBar
          ? CupertinoNavigationBar(
              middle: Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _showEditProfileDialog();
                },
                child: const Icon(
                  CupertinoIcons.pencil,
                  color: CupertinoColors.systemBlue,
                ),
              ),
              backgroundColor: CupertinoColors.white,
              border: const Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.0,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildProfileInfo(),
              _buildActionButtons(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}