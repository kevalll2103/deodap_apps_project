import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/* ---------- Brand Colors ---------- */
const kBlue700 = Color(0xFF1976D2); // Material Blue 700

/// iOS-styled Contact Screen for DeoDap (Cupertino-only)
class ContactCupertinoView extends StatefulWidget {
  const ContactCupertinoView({super.key});
  @override
  State<ContactCupertinoView> createState() => _ContactCupertinoViewState();
}

class _ContactCupertinoViewState extends State<ContactCupertinoView>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  // Validation
  final _emailRe = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
  final _phoneRe = RegExp(r'^[6-9]\d{9}$'); // India mobile 10-digit (6–9 start)

  // WhatsApp target number (digits with country code)
  static const String _waDigits = '+919638666602'; // +91 9889663378

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  /* ---------------- SUBMIT ---------------- */
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    if (_name.text.trim().isEmpty) return _toast('Please enter your full name.');
    if (!_emailRe.hasMatch(_email.text.trim())) return _toast('Please enter a valid email.');
    if (!_phoneRe.hasMatch(_phone.text.trim())) {
      return _toast('Enter a valid 10-digit Indian mobile number (starts 6–9).');
    }
    if (_message.text.trim().isEmpty) return _toast('Please write your message.');

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );

    try {
      final url = Uri.parse('https://customprint.deodap.com/all_app_contact_form.php');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'name': _name.text.trim(),
          'email_address': _email.text.trim(),
          'phone_number': _phone.text.trim(),
          'message': _message.text.trim(),
        },
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if ('${body['status']}'.toLowerCase() == 'success') {
          HapticFeedback.mediumImpact();
          _name.clear();
          _email.clear();
          _phone.clear();
          _message.clear();
          _toast("Thanks! We'll get back to you shortly.', success: true");
          return;
              }
              _toast(body['message']?.toString() ?? 'Submit failed. Please try again.');
    } else {
    _toast('Server error (${res.statusCode}). Please try again later.');
    }
    } catch (_) {
    if (mounted) {
    Navigator.of(context, rootNavigator: true).pop();
    _toast('Request failed. Please check your connection.');
    }
    }
  }

  /* ---------------- TOAST ---------------- */
  void _toast(String msg, {bool success = false}) {
    final bg = success ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final txt = CupertinoColors.white;
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
              ),
              child:               Text(
                msg,
                style: TextStyle(
                  color: txt,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), entry.remove);
  }

  /* ---------------- LAUNCH HELPERS ---------------- */
  Future<bool> _launchFlexible(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    }
    if (uri.scheme.startsWith('http')) {
      return launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
      );
    }
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> _launchTel(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final ok = await _launchFlexible(uri);
    if (!ok) _toast('Unable to open dialer.');
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'care@deodap.com',
      queryParameters: {
        'subject': 'Inquiry from DeoDap App',
        'body': 'Hello,\n\nI have a question regarding...'
      },
    );
    final ok = await _launchFlexible(uri);
    if (!ok) _toast('Could not open email app.');
  }

  Future<void> _launchWhatsApp(String text) async {
    final uri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$_waDigits&text=${Uri.encodeComponent(text)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast('WhatsApp not available.');
  }

  Future<void> _launchUrlHttps(String url) async {
    final ok = await _launchFlexible(Uri.parse(url));
    if (!ok) _toast('Unable to open link.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final sep = CupertinoColors.separator.resolveFrom(context);

    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = viewInsetsBottom > 0;
    final contentBottomPadding = keyboardOpen ? 12.0 : 96.0;

    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        primaryColor: kBlue700,
        primaryContrastingColor: CupertinoColors.white,
        barBackgroundColor: CupertinoColors.systemGrey6.resolveFrom(context),
      ),
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Get In Touch'),
          previousPageTitle: 'Back',
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(decoration: TextDecoration.none),
          child: Stack(
            children: [
              /* ---------------- CONTENT ---------------- */
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  slivers: [
                    // Company card
                    SliverToBoxAdapter(
                      child: _InsetGroup(
                        child: _CardBlock(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          children: const [
                            Center(
                              child: Text(
                                'DeoDap International Private Limited',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.15,
                                  letterSpacing: -0.9,
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _InsetGroup(
                        child: _CardBlock(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          children: [
                            _kv(context, 'GST', '24AAHCD5265C1ZX'),
                            _kv(context, 'CIN', 'U51909GJ2019PTC110919'),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                'Copyright © 2024 DeoDap.',
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                  fontSize: 10,
                                  height: 1.15,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Welcome
                    SliverToBoxAdapter(
                      child: _InsetGroup(
                        child: _CardBlock(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          children: [
                            Text(
                              "We'd love to hear from you! Whether you have questions, feedback, or just want to say hi, feel free to reach out to us.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: CupertinoColors.label.resolveFrom(context),
                                fontSize: 13,
                                height: 1.25,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Contact info
                    const SliverToBoxAdapter(child: _GroupHeader('Contact Information')),
                    SliverToBoxAdapter(
                      child: _GroupedList(
                        rows: [
                          _InfoRow(
                            icon: CupertinoIcons.location_solid,
                            title: 'Address',
                            subtitle:
                            'C/o Rajesh Rasikbhai Chotai Barjar Paint,\nOpp. Rangoli Masala Village, Navagam,\nRajkot-360003, Gujarat, India',
                            onTap: () => _launchUrlHttps(
                              'https://www.google.com/maps/place/DeoDap+DropShipping/@22.330938,70.85004,15z/data=!4m6!3m5!1s0x3959cbd2aaed26d1:0xa8849c4cd98c16b0!8m2!3d22.3299937!4d70.8502628!16s%2Fg%2F11g8w0_vyq?hl=en',
                            ),
                          ),
                          _InfoRow(
                            icon: CupertinoIcons.phone,
                            title: 'Phone',
                            subtitle: '+91 9638666602',
                            trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                            onTap: () => _launchTel('+919638666602'),
                          ),
                          _InfoRow(
                            icon: CupertinoIcons.mail,
                            title: 'Email',
                            subtitle: 'care@deodap.com',
                            trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                            onTap: _launchEmail,
                          ),
                        ],
                      ),
                    ),

                    // Social
                    const SliverToBoxAdapter(child: _GroupHeader('Follow Us')),
                    SliverToBoxAdapter(
                      child: _InsetGroup(
                        child: _CardBlock(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          children: [
                            _SocialRow(
                              items: [
                                _SocialLink(
                                  icon: CupertinoIcons.chat_bubble_2_fill,
                                  label: 'WhatsApp',
                                  onTap: () => _launchWhatsApp(
                                    "Hello! I'd love to discuss some questions about the DeoDap application.",
                                  ),
                                ),
                                _SocialLink(
                                  icon: FontAwesomeIcons.facebookF,
                                  label: 'Facebook',
                                  onTap: () => _launchUrlHttps('https://www.facebook.com/deodapofficial'),
                                ),
                                _SocialLink(
                                  icon: FontAwesomeIcons.instagram,
                                  label: 'Instagram',
                                  onTap: () => _launchUrlHttps('https://www.instagram.com/DeoDap_com/'),
                                ),
                                _SocialLink(
                                  icon: CupertinoIcons.briefcase_fill,
                                  label: 'LinkedIn',
                                  onTap: () => _launchUrlHttps('https://in.linkedin.com/company/deodap'),
                                ),
                                _SocialLink(
                                  icon: CupertinoIcons.video_camera_solid,
                                  label: 'YouTube',
                                  onTap: () =>
                                      _launchUrlHttps('https://www.youtube.com/c/OnlineBusinessIdeasbyDeoDap'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Support hours
                    SliverToBoxAdapter(
                      child: _InsetGroup(
                        child: Container(
                          decoration: BoxDecoration(
                            color: kBlue700.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sep, width: isDark ? 0.4 : 0.6),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'For Any Question, You Can Easily Contact Us.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.15,
                                  letterSpacing: -0.9,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Support: Monday to Saturday • 9:00 AM – 6:00 PM',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 1.15,
                                  letterSpacing: -0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Map preview
                    const SliverToBoxAdapter(child: _GroupHeader('Find Us')),
                    SliverToBoxAdapter(
                      child: _InsetGroup(
                        child: _CardBlock(
                          padding: EdgeInsets.zero,
                          children: [
                            GestureDetector(
                              onTap: () => _launchUrlHttps(
                                  'https://www.google.com/maps/place/DeoDap+DropShipping/@22.330938,70.85004,15z'),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/map.png',
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Form
                    const SliverToBoxAdapter(child: _GroupHeader('Send Message')),
                    SliverToBoxAdapter(
                      child: _InsetGroup(
                        child: CupertinoFormSection.insetGrouped(
                          margin: EdgeInsets.zero,
                          backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
                          decoration: BoxDecoration(
                            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          children: [
                            CupertinoTextFormFieldRow(
                              controller: _name,
                              placeholder: 'Full Name',
                              prefix: const Icon(CupertinoIcons.person, size: 18, color: kBlue700),
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.25,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.3,
                              ),
                            ),
                            CupertinoTextFormFieldRow(
                              controller: _email,
                              placeholder: 'Email Address',
                              prefix: const Icon(CupertinoIcons.mail, size: 18, color: kBlue700),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.25,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.3,
                              ),
                            ),
                            CupertinoTextFormFieldRow(
                              controller: _phone,
                              placeholder: 'Phone Number',
                              prefix: const Icon(CupertinoIcons.phone, size: 18, color: kBlue700),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.25,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.3,
                              ),
                            ),
                            _MultilineField(
                              controller: _message,
                              placeholder: 'Your Message',
                              minLines: 4,
                              maxLines: 6,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Submit
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                        child: CupertinoButton(
                          onPressed: _submit,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: kBlue700,
                          child: const Text(
                            'Send Message',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Thanks
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(14, 0, 14, 0),
                        child: _ThanksNote(),
                      ),
                    ),

                    // Bottom space
                    SliverToBoxAdapter(child: SizedBox(height: contentBottomPadding)),
                  ],
                ),
              ),

              // WhatsApp floating button (auto-hides when keyboard open)
              if (!keyboardOpen)
                Positioned(
                  right: 14,
                  bottom: 20,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final scale = 1 + (_pulse.value * 0.04);
                      return Transform.scale(
                        scale: scale,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: CupertinoButton(
                            padding: const EdgeInsets.all(12),
                            color: const Color(0xFF25D366),
                            onPressed: () =>
                                _launchWhatsApp("Hello! I'd love to discuss some questions about the DeoDap application."),
                            child: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 22, color: CupertinoColors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact key/value line (no underline)
  static Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
            fontSize: 13,
            height: 1.3,
            decoration: TextDecoration.none,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.25,
          ),
          children: [
            TextSpan(
              text: '$k: ',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.0,
              ),
            ),
            TextSpan(
              text: v,
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------------------- Widgets ---------------------------- */

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();
  @override
  Widget build(BuildContext context) {
    return const CupertinoAlertDialog(
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(width: 8),
            Text(
              'Sending...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String text;
  const _GroupHeader(this.text);
  @override
  Widget build(BuildContext context) {
    final color = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          letterSpacing: 0.6,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.0,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _InsetGroup extends StatelessWidget {
  final Widget child;
  const _InsetGroup({required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: child);
  }
}

class _CardBlock extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const _CardBlock({required this.children, this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12)});
  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator.resolveFrom(context), width: 0.6),
      ),
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<_InfoRow> rows;
  const _GroupedList({required this.rows});
  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final sep = CupertinoColors.separator.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: bg,
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) Container(width: double.infinity, height: 0.6, color: sep),
                rows[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _InfoRow({required this.icon, required this.title, required this.subtitle, this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      onPressed: onTap,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 20, color: kBlue700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: label,
                    height: 1.25,
                    decoration: TextDecoration.none,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: secondary,
                    height: 1.3,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.25,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SocialLink {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _SocialLink({required this.icon, required this.label, required this.onTap});
}

class _SocialRow extends StatelessWidget {
  final List<_SocialLink> items;
  const _SocialRow({required this.items});
  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: bg,
              borderRadius: BorderRadius.circular(12),
              onPressed: e.onTap,
              child: Row(
                children: [
                  Icon(e.icon, size: 16, color: kBlue700),
                  const SizedBox(width: 6),
                  Text(
                    e.label,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MultilineField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final int minLines;
  final int maxLines;
  const _MultilineField({required this.controller, required this.placeholder, this.minLines = 3, this.maxLines = 6});
  @override
  Widget build(BuildContext context) {
    return CupertinoFormRow(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 8),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(
          fontSize: 15,
          height: 1.25,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _ThanksNote extends StatelessWidget {
  const _ThanksNote();

  @override
  Widget build(BuildContext context) {
    final sep = CupertinoColors.separator.resolveFrom(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sep, width: 0.6),
      ),
      padding: const EdgeInsets.all(12),
      child: const Row(
          children: [
          Icon(CupertinoIcons.check_mark_circled_solid, size: 20,
          color: kBlue700),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          'Thank you for reaching out! We\'ll get back to you as soon as possible.',
          style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
          decoration: TextDecoration.none,
          letterSpacing: -0.9,
        ),
      ),
    ),]
    ,
    )
    ,
    );
  }
}