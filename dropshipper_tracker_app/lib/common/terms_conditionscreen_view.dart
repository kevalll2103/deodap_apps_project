import 'package:flutter/material.dart';

class TermsConditionscreenView extends StatefulWidget {
  const TermsConditionscreenView({super.key});

  @override
  State<TermsConditionscreenView> createState() =>
      _TermsConditionscreenViewState();
}

class _TermsConditionscreenViewState extends State<TermsConditionscreenView> {
  final ScrollController _scrollController = ScrollController();
  bool _isChecked = false;

  final Color _primaryColor = const Color(0xFF1565C0); // Dark Blue
  final Color _textColor = Colors.black; // Main text color

  void _toggleCheckbox(bool? value) {
    setState(() {
      _isChecked = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle headingStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: _primaryColor,
    );

    final TextStyle bodyStyle = TextStyle(
      fontSize: 15,
      color: _textColor,
      height: 1.6,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _primaryColor,
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Stack(
          children: [
            Scrollbar(
              thumbVisibility: true,
              radius: const Radius.circular(8),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      "1. Introduction",
                      "Welcome to DeoDap (“Company”, “we”, “our”, “us”)! These Terms of Service govern your use of our website at https://deodap.in (together or individually “Service”) operated by DeoDap International Pvt Ltd.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "2. Acceptance of Terms",
                      "By accessing or using our services, you agree to be bound by these terms. If you do not agree, please do not use the service. Your continued use signifies your agreement to any updates to these terms.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "3. Communication",
                      "By using our Service, you consent to receive marketing and promotional materials from us. You can opt out at any time by following unsubscribe instructions or emailing us at info@deodap.com.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "4. Product & Pricing",
                      "All products listed on our platform are subject to availability. Prices are subject to change without prior notice. We reserve the right to cancel or refuse any order for any reason.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "5. Refunds & Returns",
                      "Refunds are processed within 7-10 business days upon successful verification. All returns must comply with our return policy listed on the website.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "6. User Account",
                      "You are responsible for maintaining the confidentiality of your account and password. Any activity under your account is your responsibility.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "7. Intellectual Property",
                      "All content on the platform, including images, text, logos, and software, is the property of DeoDap or licensed to us. Unauthorized use is strictly prohibited.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "8. Limitation of Liability",
                      "We are not liable for any indirect, incidental, or consequential damages arising out of your use of our service.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "9. Termination",
                      "We reserve the right to terminate or suspend your access to the Service without prior notice for any violation of the Terms.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "10. Governing Law",
                      "These Terms shall be governed and construed in accordance with the laws of India. Disputes will be subject to jurisdiction in Rajkot, Gujarat.",
                      headingStyle,
                      bodyStyle,
                    ),
                    _buildSection(
                      "11. Contact Us",
                      "If you have any questions about these Terms, please contact us at info@deodap.com or visit https://deodap.in.",
                      headingStyle,
                      bodyStyle,
                    ),
                    const SizedBox(height: 20),

                    // Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _isChecked,
                          onChanged: _toggleCheckbox,
                          activeColor: _primaryColor,
                        ),
                        Expanded(
                          child: Text(
                            "I agree to the Terms and Conditions.",
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Agree button
                    ElevatedButton(
                      onPressed: _isChecked
                          ? () {
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Agree & Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating action button to scroll to top
            Positioned(
              right: 5,
              bottom: 10,
              child: FloatingActionButton(
                backgroundColor: _primaryColor,
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to keep layout consistent
  Widget _buildSection(String title, String content,
      TextStyle headingStyle, TextStyle bodyStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: headingStyle),
          const SizedBox(height: 6),
          Text(content, style: bodyStyle),
        ],
      ),
    );
  }
}
