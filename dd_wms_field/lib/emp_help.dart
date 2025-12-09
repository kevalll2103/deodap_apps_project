// main.dart — Cupertino (iOS) Contact & Help
// - No text decorations/underlines, spell-check off
// - Tight letter spacing
// - All Cupertino icons
// - Brand blue = Colors.blue[700] (#1976D2)
// - WhatsApp FAB = icon only

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const DeoDapApp());
}

class DeoDapApp extends StatelessWidget {
  const DeoDapApp({super.key});

  static const Color primaryBlue = Color(0xFF007E9B); // Blue[700]

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: primaryBlue,
        barBackgroundColor: CupertinoColors.white,
        scaffoldBackgroundColor: CupertinoColors.white,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
            letterSpacing: -0.2,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      home: ContactHelpScreen(),
    );
  }
}

class ContactHelpScreen extends StatefulWidget {
  const ContactHelpScreen({super.key});

  @override
  State<ContactHelpScreen> createState() => _ContactHelpScreenState();
}

class _ContactHelpScreenState extends State<ContactHelpScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final FocusNode _numFocus = FocusNode();

  bool _isLoading = false;
  OverlayEntry? _toast;

  @override
  void dispose() {
    _messageController.dispose();
    _numberController.dispose();
    _msgFocus.dispose();
    _numFocus.dispose();
    _removeToast();
    super.dispose();
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  Future<void> _submitForm() async {
    _dismissKeyboard();
    final phone = _numberController.text.trim();
    final message = _messageController.text.trim();

    if (phone.length != 10) {
      _showToast('Enter a valid 10-digit phone number', isError: true);
      return;
    }
    if (phone.isEmpty || message.isEmpty) {
      _showToast('Please fill all required fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    const url = 'https://customprint.deodap.com/api_amzDD_return/contact_form.php';
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'phone_number': phone, 'message': message},
      );

      setState(() => _isLoading = false);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] != null) {
          _messageController.clear();
          _numberController.clear();
          _showToast('Thank you for your submission!');
        } else {
          _showToast('No internet connection!', isError: true);
        }
      } else {
        _showToast('Server down. Try again', isError: true);
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _showToast('No internet connection!', isError: true);
    }
  }

  // Cupertino-style toast (no underline, no decoration)
  void _showToast(String text, {bool isError = false}) {
    _removeToast();
    _toast = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
        child: _ToastBubble(text: text, isError: isError),
      ),
    );
    Overlay.of(context, rootOverlay: true)?.insert(_toast!);
    Future.delayed(const Duration(seconds: 3), _removeToast);
  }

  void _removeToast() {
    _toast?..remove();
    _toast = null;
  }

  Future<void> _openWhatsApp() async {
    const contactNumber = '+918866966703';
    const encodedText =
        "Hello%2C%20Nice%20to%20meet%20you!%20I'd%20love%20to%20discuss%20a%20few%20questions%20I%20have%20about%20the%20Deodap%20WMS%20DD%20field%20App.";

    final nativeUri = Uri.parse('whatsapp://send?phone=$contactNumber&text=$encodedText');
    final webUri = Uri.parse('https://wa.me/$contactNumber?text=$encodedText');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      _showToast('Could not open WhatsApp', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = DeoDapApp.primaryBlue;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0x1F000000), width: 0.0),
        ),
        middle: Text(
          'Contact & Help',
          style: TextStyle(
            letterSpacing: -0.2,
            decoration: TextDecoration.none,
          ),
        ),
        leading: _BackChevron(),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header with improved spacing
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      _RoundIcon(
                        icon: CupertinoIcons.question_circle_fill,
                        bg: Color(0xFFEFF3FF),
                        fg: primaryBlue,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "We're here to help!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700, // More bold
                          color: CupertinoColors.black,
                          height: 1.15,
                          letterSpacing: -0.5,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Questions, feedback, or just want to say hi — drop us a note.',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                          height: 1.3,
                          letterSpacing: -0.1,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Support Hours with better spacing
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _InsetCard(
                    child: Row(
                      children: const [
                        _RoundIcon(
                          icon: CupertinoIcons.time,
                          bg: Color(0xFFF2F2F7),
                          fg: primaryBlue,
                          size: 40,
                          pad: 10,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Support Hours',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600, // More bold
                                  color: CupertinoColors.black,
                                  letterSpacing: -0.2,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Mon–Sat | 9:00 AM – 6:00 PM',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.systemGrey,
                                  letterSpacing: -0.1,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Form with improved spacing
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Send us a message',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                            letterSpacing: -0.3,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InsetGroup(
                        children: [
                          _CupertinoFormRow(
                            label: 'Phone',
                            child: CupertinoTextField(
                              controller: _numberController,
                              placeholder: '10-digit number',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              enableSuggestions: false,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: CupertinoColors.black,
                                letterSpacing: -0.1,
                                decoration: TextDecoration.none,
                              ),
                              placeholderStyle: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                letterSpacing: -0.1,
                                decoration: TextDecoration.none,
                              ),
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(CupertinoIcons.phone, size: 18, color: CupertinoColors.systemGrey),
                              ),
                              clearButtonMode: OverlayVisibilityMode.editing,
                            ),
                          ),
                          _CupertinoFormRow(
                            label: 'Message',
                            topAligned: true,
                            child: CupertinoTextField(
                              controller: _messageController,
                              placeholder: 'Type your message…',
                              minLines: 4,
                              maxLines: 6,
                              enableSuggestions: false,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: CupertinoColors.black,
                                height: 1.35,
                                letterSpacing: -0.1,
                                decoration: TextDecoration.none,
                              ),
                              placeholderStyle: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                letterSpacing: -0.1,
                                decoration: TextDecoration.none,
                              ),
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 8, top: 4),
                                child: Icon(CupertinoIcons.chat_bubble_2, size: 18, color: CupertinoColors.systemGrey),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          borderRadius: BorderRadius.circular(10),
                          color: primaryBlue, // Blue 700 color
                          onPressed: _isLoading ? null : _submitForm,
                          child: _isLoading
                              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                              : const Text(
                            'Send Message',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: CupertinoColors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // WhatsApp icon-only FAB (circular) with better shadow
          Positioned(
            right: 20,
            bottom: 30,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFF25D366),
                onPressed: _openWhatsApp,
                child: const SizedBox(
                  width: 60,
                  height: 60,
                  child: Center(
                    child: Icon(
                      CupertinoIcons.chat_bubble_text_fill,
                      size: 24,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- Reusable Cupertino Widgets ---------- */

class _BackChevron extends StatelessWidget {
  const _BackChevron();

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: () => Navigator.maybePop(context),
      child: const Icon(
        CupertinoIcons.back,
        size: 22,
        color: DeoDapApp.primaryBlue,
      ),
    );
  }
}

class _InsetGroup extends StatelessWidget {
  final List<Widget> children;
  const _InsetGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          border: Border.all(color: const Color(0xFFE5E5EA)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: children[i],
              ),
              if (i != children.length - 1)
                const Divider(
                  height: 1,
                  color: Color(0xFFE5E5EA),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CupertinoFormRow extends StatelessWidget {
  final String label;
  final Widget child;
  final bool topAligned;
  const _CupertinoFormRow({
    required this.label,
    required this.child,
    this.topAligned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: topAligned ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Padding(
            padding: EdgeInsets.only(top: topAligned ? 8 : 0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGrey,
                letterSpacing: -0.1,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _InsetCard extends StatelessWidget {
  final Widget child;
  const _InsetCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: Border.all(color: const Color(0xFFE5E5EA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final double pad;
  const _RoundIcon({
    required this.icon,
    required this.bg,
    required this.fg,
    this.size = 48,
    this.pad = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Icon(icon, color: fg, size: size - pad * 2),
      ),
    );
  }
}

class _ToastBubble extends StatelessWidget {
  final String text;
  final bool isError;
  const _ToastBubble({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final bg = isError ? const Color(0xFFE53935) : const Color(0xFF34C759);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError
                  ? CupertinoIcons.exclamationmark_circle_fill
                  : CupertinoIcons.check_mark_circled_solid,
              color: CupertinoColors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: -0.1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
