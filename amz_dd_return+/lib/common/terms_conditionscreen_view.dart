import 'package:flutter/material.dart';

class TermsConditionscreenView extends StatefulWidget {
  const TermsConditionscreenView({super.key});

  @override
  State<TermsConditionscreenView> createState() => _TermsConditionscreenViewState();
}

class _TermsConditionscreenViewState extends State<TermsConditionscreenView> {
  final ScrollController _scrollController = ScrollController();
  bool _isChecked = false;

  final Color _primaryColor = Color(0xFF1565C0); // Dark Blue

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
      color: _primaryColor.withOpacity(0.9),
      height: 1.5,
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
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Introduction', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "Welcome to DeoDap (“Company”, “we”, “our”, “us”)! These Terms of Service govern your use of our website at https://deodap.in (together or individually “Service”) operated by DeoDap International Pvt Ltd.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('2. Acceptance of Terms', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "By accessing or using our services, you agree to be bound by these terms. If you do not agree, please do not use the service. Your continued use signifies your agreement to any updates to these terms.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('3. Communication', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "By using our Service, you consent to receive marketing and promotional materials from us. You can opt out at any time by following unsubscribe instructions or emailing us at info@deodap.com.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('4. Product & Pricing', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "All products listed on our platform are subject to availability. Prices are subject to change without prior notice. We reserve the right to cancel or refuse any order for any reason.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('5. Refunds & Returns', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "Refunds are processed within 7-10 business days upon successful verification. All returns must comply with our return policy listed on the website.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('6. User Account', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "You are responsible for maintaining the confidentiality of your account and password. Any activity under your account is your responsibility.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('7. Intellectual Property', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "All content on the platform, including images, text, logos, and software, is the property of DeoDap or licensed to us. Unauthorized use is strictly prohibited.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('8. Limitation of Liability', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "We are not liable for any indirect, incidental, or consequential damages arising out of your use of our service.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('9. Termination', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "We reserve the right to terminate or suspend your access to the Service without prior notice for any violation of the Terms.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('10. Governing Law', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "These Terms shall be governed and construed in accordance with the laws of India. Disputes will be subject to jurisdiction in Rajkot, Gujarat.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    Text('11. Contact Us', style: headingStyle),
                    const SizedBox(height: 8),
                    Text(
                      "If you have any questions about these Terms, please contact us at info@deodap.com or visit https://deodap.in.",
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 24),

                    // Agree checkbox (optional)
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
                              color: _primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Agree button (optional)
                    ElevatedButton(
                      onPressed: _isChecked ? () {
                        Navigator.pop(context);
                      } : null,
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
                    duration: const Duration(milliseconds: 300),
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
}
