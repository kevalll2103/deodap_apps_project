import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpState extends State<Help> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final numberController = TextEditingController();
  final messageController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    numberController.dispose();
    messageController.dispose();
    super.dispose();
  }

  // --- Helpers ---------------------------------------------------------------

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack('Could not open link', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1976D2),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final url = 'https://customprint.deodap.com/contact_form.php';
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'number': numberController.text.trim(),
          'message': messageController.text.trim(),
        },
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] != null) {
          _snack('Thank you for your submission..!');
          nameController.clear();
          emailController.clear();
          numberController.clear();
          messageController.clear();
        } else {
          _snack('No Internet.. Please try again', isError: true);
        }
      } else {
        _snack('Server Down.. try again', isError: true);
      }
    } catch (e) {
      _snack('Request failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    const brand = Color(0xFF1976D2);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black),
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: brand, width: 1.6),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _prefixIcon(IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 10),
        Icon(icon, color: Colors.black),
        const SizedBox(
          height: 35,
          child: VerticalDivider(width: 20, thickness: 1.2, color: Colors.black),
        ),
      ],
    );
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.6,
        title: const Text(
          'Help',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          Scrollbar(
            thickness: 1.4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "We'd love to hear from you! Whether you have questions, feedback, or just want to say hi, feel free to reach out to us.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Social row
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _socialIcon(
                        asset: 'assets/whatsapp_image.png',
                        onTap: () async {
                          final phone = '6353344542';
                          final text = Uri.encodeComponent('Hello Sir,');
                          // Correct WhatsApp URI (no quotes around the number)
                          await _launchUrl('whatsapp://send?phone=+91$phone&text=$text');
                        },
                      ),
                      _socialIcon(
                        asset: 'assets/facebook_image.png',
                        onTap: () => _launchUrl(
                          'https://deodap.in/pages/privacy-policy#:~:text=We%20aim%20to%20take%20reasonable,at%20care%40deodap.com.',
                        ),
                      ),
                      _socialIcon(
                        asset: 'assets/images/instagram_image.png',
                        onTap: () => _launchUrl('https://www.instagram.com/DeoDap_com/'),
                      ),
                      _socialIcon(
                        asset: 'assets/linkdin_image.png',
                        onTap: () => _launchUrl('https://in.linkedin.com/company/deodap'),
                      ),
                      _socialIcon(
                        asset: 'assets/snapchat_image.png',
                        onTap: () => _launchUrl(
                          'https://www.snapchat.com/add/deodap?share_id=GDJYM08iUfI&locale=en-US',
                        ),
                      ),
                      _socialIcon(
                        asset: 'assets/youtube_image.png',
                        onTap: () => _launchUrl('https://www.youtube.com/c/OnlineBusinessIdeasbyDeoDap'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text('For Any Question, You Can Easily Contact Us.'),
                  Text(
                    'Support: Monday to Saturday From 9:00 AM to 7:00 PM',
                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Send Message',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name
                        TextFormField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                          decoration: _inputDecoration(
                            hint: 'Username',
                            prefix: _prefixIcon(Icons.person),
                            suffix: IconButton(
                              onPressed: nameController.clear,
                              icon: const Icon(Icons.cancel, color: Colors.black),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          cursorColor: Colors.black,
                        ),
                        const SizedBox(height: 10),

                        // Email
                        TextFormField(
                          controller: emailController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter your email';
                            final re = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            return re.hasMatch(v.trim()) ? null : 'Please enter a valid email';
                          },
                          decoration: _inputDecoration(
                            hint: 'Email',
                            prefix: _prefixIcon(Icons.email),
                            suffix: IconButton(
                              onPressed: emailController.clear,
                              icon: const Icon(Icons.cancel, color: Colors.black),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          cursorColor: Colors.black,
                        ),
                        const SizedBox(height: 10),

                        // Phone
                        TextFormField(
                          controller: numberController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter your number';
                            return v.trim().length == 10 ? null : 'Phone number must be 10 digits';
                          },
                          decoration: _inputDecoration(
                            hint: 'Phone Number',
                            prefix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(width: 10),
                                Text('+91',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                SizedBox(
                                  height: 35,
                                  child: VerticalDivider(
                                      width: 20, thickness: 1.2, color: Colors.black),
                                )
                              ],
                            ),
                            suffix: IconButton(
                              onPressed: numberController.clear,
                              icon: const Icon(Icons.cancel, color: Colors.black),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          cursorColor: Colors.black,
                        ),
                        const SizedBox(height: 10),

                        // Message
                        TextFormField(
                          controller: messageController,
                          maxLines: 5,
                          textInputAction: TextInputAction.done,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your message' : null,
                          decoration: _inputDecoration(hint: 'Message'),
                          style: const TextStyle(color: Colors.black),
                          cursorColor: Colors.black,
                        ),
                        const SizedBox(height: 20),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brand,
                              disabledBackgroundColor: brand.withOpacity(0.6),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                                : const Text('Send Message',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon({required String asset, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 24,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}
