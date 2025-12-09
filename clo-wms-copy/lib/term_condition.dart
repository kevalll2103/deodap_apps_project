import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DeoDapApp());
}

class DeoDapApp extends StatelessWidget {
  const DeoDapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.blue.shade700;

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: primary,
        scaffoldBackgroundColor: CupertinoColors.white,
        barBackgroundColor: CupertinoColors.white,
        textTheme: const CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 16, // compact iOS title
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
            decoration: TextDecoration.none,
            letterSpacing: -0.3,
          ),
        ),
      ),
      home: const TermsConditionscreenView(),
    );
  }
}

class TermsConditionscreenView extends StatefulWidget {
  const TermsConditionscreenView({super.key});

  @override
  State<TermsConditionscreenView> createState() => _TermsConditionscreenViewState();
}

class _TermsConditionscreenViewState extends State<TermsConditionscreenView> {
  final ScrollController _scrollController = ScrollController();
  late final Color _primaryColor = Colors.blue.shade700;

  // Compact iOS styles
  static const TextStyle _headingStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: CupertinoColors.black,
    decoration: TextDecoration.none,
    height: 1.22,
    letterSpacing: -0.3,
  );

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 13,
    height: 1.30,
    fontWeight: FontWeight.w400,
    color: Color(0xFF3C3C43),
    decoration: TextDecoration.none,
    letterSpacing: -0.08,
  );

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0x1F000000), width: 0.0), // subtle iOS hairline
        ),
        middle: const Text('Terms & Conditions'),
        // Chevron-only back (no text)
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () => Navigator.of(context).maybePop(),
          child: Icon(CupertinoIcons.back, size: 22, color: _primaryColor),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: CupertinoScrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), // clean, compact
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('1. Introduction',
                    'Welcome to DeoDap ("Company", "we", "our", "us")! '
                        'These Terms of Service govern your use of our website at https://deodap.in '
                        '(together or individually "Service") operated by DeoDap International Pvt Ltd.'),
                _section('2. Acceptance of Terms',
                    'By accessing or using our services, you agree to be bound by these terms. '
                        'If you do not agree, please do not use the service. Your continued use signifies your '
                        'agreement to any updates to these terms.'),
                _section('3. Communication',
                    'By using our Service, you consent to receive marketing and promotional materials from us. '
                        'You can opt out at any time by following unsubscribe instructions or emailing us at info@deodap.com.'),
                _section('4. Product & Pricing',
                    'All products listed on our platform are subject to availability. Prices are subject to change without prior notice. '
                        'We reserve the right to cancel or refuse any order for any reason.'),
                _section('5. Refunds & Returns',
                    'Refunds are processed within 7-10 business days upon successful verification. '
                        'All returns must comply with our return policy listed on the website.'),
                _section('6. User Account',
                    'You are responsible for maintaining the confidentiality of your account and password. '
                        'Any activity under your account is your responsibility.'),
                _section('7. Intellectual Property',
                    'All content on the platform, including images, text, logos, and software, '
                        'is the property of DeoDap or licensed to us. Unauthorized use is strictly prohibited.'),
                _section('8. Limitation of Liability',
                    'We are not liable for any indirect, incidental, or consequential damages arising out of your use of our service.'),
                _section('9. Termination',
                    'We reserve the right to terminate or suspend your access to the Service without prior notice for any violation of the Terms.'),
                _section('10. Governing Law',
                    'These Terms shall be governed and construed in accordance with the laws of India. '
                        'Disputes will be subject to jurisdiction in Rajkot, Gujarat.'),
                _section('11. Contact Us',
                    'If you have any questions about these Terms, please contact us at info@deodap.com '
                        'or visit https://deodap.in.'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _headingStyle),
          const SizedBox(height: 6),
          Text(content, style: _bodyStyle),
        ],
      ),
    );
  }
}
