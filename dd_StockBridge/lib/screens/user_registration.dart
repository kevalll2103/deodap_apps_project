import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class UserRegister extends StatefulWidget {
  const UserRegister({Key? key}) : super(key: key);

  @override
  State<UserRegister> createState() => _UserRegisterState();
}

class _UserRegisterState extends State<UserRegister> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _empCodeController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  // Response data
  String? createdUsername;
  bool? emailDelivered;
  String? emailError;

  // API config
  static const String apiBase = 'https://customprint.deodap.com/stockbridge';
  static const bool debugMode = false;

  Future<void> _registerEmployee() async {
    if (!_formKey.currentState!.validate()) {
      _showToast(
        'Please fill all required fields',
        CupertinoColors.systemOrange,
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      createdUsername = null;
      emailDelivered = null;
      emailError = null;
    });

    final uri =
        Uri.parse('$apiBase/emp_register.php${debugMode ? '?debug=1' : ''}');

    final payload = {
      "name": _nameController.text.trim(),
      "emp_code": _empCodeController.text.trim(),
      "contact_number": _contactController.text.trim(),
      "email": _emailController.text.trim(),
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {
              HttpHeaders.contentTypeHeader:
                  'application/json; charset=UTF-8',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));

      final statusCode = response.statusCode;
      Map<String, dynamic> body;
      try {
        body = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = {};
      }

      setState(() => isLoading = false);

      if (statusCode == 200 && (body['status'] == 'success')) {
        final data = (body['data'] ?? {}) as Map<String, dynamic>;
        createdUsername = data['username']?.toString();
        emailDelivered = (data['email_delivered'] == true);
        emailError = data['email_error']?.toString();

        _showToast(
          emailDelivered == true
              ? 'Employee registered. Credentials emailed.'
              : 'Employee registered${(emailError ?? '').isNotEmpty ? ', but email failed.' : '.'}',
          CupertinoColors.systemGreen,
        );
      } else {
        errorMessage = body['message']?.toString();
        if (errorMessage == null || errorMessage!.isEmpty) {
          errorMessage = 'Registration failed';
        }
        _showToast('Error: $errorMessage', CupertinoColors.systemRed);
      }
    } on SocketException {
      setState(() => isLoading = false);
      _showToast(
        'Network error. Check your connection.',
        CupertinoColors.systemRed,
      );
    } on HttpException catch (e) {
      setState(() => isLoading = false);
      _showToast('HTTP error: ${e.message}', CupertinoColors.systemRed);
    } on FormatException {
      setState(() => isLoading = false);
      _showToast('Invalid server response.', CupertinoColors.systemRed);
    } on TimeoutException {
      setState(() => isLoading = false);
      _showToast('Request timed out. Try again.', CupertinoColors.systemRed);
    } catch (e) {
      setState(() => isLoading = false);
      _showToast('Unexpected error: $e', CupertinoColors.systemRed);
    }
  }

  void _showToast(String msg, Color color) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                color == CupertinoColors.systemGreen
                    ? CupertinoIcons.check_mark_circled_solid
                    : color == CupertinoColors.systemRed
                        ? CupertinoIcons.xmark_circle_fill
                        : CupertinoIcons.exclamationmark_triangle_fill,
                color: color,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                msg,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label.resolveFrom(context),
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  void _copySummary() {
    final username = createdUsername ?? '';
    final text = [
      'DeoDap Employee Registration',
      if (_nameController.text.trim().isNotEmpty)
        'Name: ${_nameController.text.trim()}',
      if (_empCodeController.text.trim().isNotEmpty)
        'Employee Code: ${_empCodeController.text.trim()}',
      if (username.isNotEmpty) 'Username: $username',
      'Password: (Sent to registered email)',
    ].join('\n');

    Clipboard.setData(ClipboardData(text: text));
    _showToast('Copied to clipboard', CupertinoColors.systemGrey);
  }

  void _shareSummary() {
    final username = createdUsername ?? '';
    final text = [
      'DeoDap Employee Account Created',
      if (_nameController.text.trim().isNotEmpty)
        'Name: ${_nameController.text.trim()}',
      if (_empCodeController.text.trim().isNotEmpty)
        'Employee Code: ${_empCodeController.text.trim()}',
      if (username.isNotEmpty) 'Username: $username',
      'Temporary password has been emailed to the registered address.',
    ].join('\n');

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.0,
          ),
        ),
        middle: Text(
          'Employee Registration',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
            fontSize: 18,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? _buildLoadingView()
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            _buildHeaderCard(),
                            const SizedBox(height: 20),
                            _buildFormSection(),
                            const SizedBox(height: 20),
                            if (createdUsername != null) _buildResultCard(),
                            const SizedBox(height: 40),
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

  Widget _buildLoadingView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 20),
            const SizedBox(height: 24),
            Text(
              'Creating employee account...',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.person_add,
              size: 36,
              color: CupertinoColors.systemBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create New Employee',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
              letterSpacing: -0.3,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in the details to generate login credentials.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              'Employee Information',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          _buildTextField(
            controller: _nameController,
            placeholder: 'Full Name',
            icon: CupertinoIcons.person,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'This field is required' : null,
          ),
          _buildDivider(),
          _buildTextField(
            controller: _empCodeController,
            placeholder: 'Employee Code',
            icon: CupertinoIcons.number,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'This field is required' : null,
          ),
          _buildDivider(),
          _buildTextField(
            controller: _contactController,
            placeholder: 'Contact Number',
            icon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
            ],
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'This field is required';
              final ok = RegExp(r'^\+?\d{10,15}$').hasMatch(val);
              return ok ? null : 'Enter 10-15 digits, optional + prefix';
            },
          ),
          _buildDivider(),
          _buildTextField(
            controller: _emailController,
            placeholder: 'Email Address',
            icon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'This field is required';
              final ok =
                  RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(val);
              return ok ? null : 'Enter a valid email address';
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _registerEmployee,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.lock_shield,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Generate Credentials',
                      style: GoogleFonts.inter(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.systemGreen,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Successfully Created',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildCredentialRow(
                  'Username',
                  createdUsername ?? '-',
                  CupertinoIcons.person_crop_circle,
                ),
                const SizedBox(height: 12),
                _buildCredentialRow(
                  'Password',
                  'Sent via email',
                  CupertinoIcons.lock_circle,
                  isItalic: true,
                ),
                if (emailDelivered != null) ...[
                  const SizedBox(height: 12),
                  _buildCredentialRow(
                    'Email Status',
                    emailDelivered == true ? 'Delivered' : 'Failed',
                    emailDelivered == true
                        ? CupertinoIcons.checkmark_circle
                        : CupertinoIcons.xmark_circle,
                    statusColor: emailDelivered == true
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemRed,
                  ),
                ],
                if ((emailError ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: CupertinoColors.systemRed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            emailError!,
                            style: GoogleFonts.inter(
                              color: CupertinoColors.systemRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _copySummary,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemBlue,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.doc_on_doc,
                          color: CupertinoColors.systemBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Copy',
                          style: GoogleFonts.inter(
                            color: CupertinoColors.systemBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _shareSummary,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemBlue,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.share,
                          color: CupertinoColors.systemBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Share',
                          style: GoogleFonts.inter(
                            color: CupertinoColors.systemBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(
    String label,
    String value,
    IconData icon, {
    bool isItalic = false,
    Color? statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: statusColor ?? CupertinoColors.systemGrey,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: CupertinoColors.systemBlue,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: CupertinoTextFormFieldRow(
              controller: controller,
              placeholder: placeholder,
              validator: validator,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              padding: EdgeInsets.zero,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.none,
              ),
              placeholderStyle: GoogleFonts.inter(
                fontSize: 16,
                color: CupertinoColors.placeholderText.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
              decoration: const BoxDecoration(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _empCodeController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}