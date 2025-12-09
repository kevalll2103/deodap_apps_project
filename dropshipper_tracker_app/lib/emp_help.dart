import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class emphelp extends StatefulWidget {
  const emphelp({super.key});

  @override
  State<emphelp> createState() => _ContactscreenState();
}

class _ContactscreenState extends State<emphelp> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    messageController.dispose();
    numberController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    FocusScope.of(context).unfocus();

    if (numberController.text.length != 10) {
      _showSnackBar('Please enter a valid 10-digit phone number', Colors.red.shade600);
      return;
    }

    if (messageController.text.isEmpty || numberController.text.isEmpty) {
      _showSnackBar('Please fill all required fields', Colors.red.shade600);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    const url = 'https://customprint.deodap.com/api_amzDD_return/contact_form.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'phone_number': numberController.text,
          'message': messageController.text,
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] != null) {
          messageController.clear();
          numberController.clear();
          _showSnackBar('Thank you for your submission!', Colors.green.shade600);
        } else if (responseBody['error'] != null) {
          _showSnackBar('No internet connection!', Colors.red.shade600);
        }
      } else {
        _showSnackBar('Server Down. Try again', Colors.red.shade600);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('No internet connection!', Colors.red.shade600);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.green.shade600 ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A365D), Color(0xFF2C5AA0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Contact & Help",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header Section with white background
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.support_agent,
                                size: 48,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "We're Here to Help!",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                color: const Color(0xFF1A365D),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Whether you have questions, feedback, or just want to say hi, feel free to reach out to us.',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: const Color(0xFF718096),
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Working Hours Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.access_time,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Support Hours',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A365D),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Monday to Saturday\n9:00 AM to 6:00 PM',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF718096),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // Form Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Form Title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.message,
                                size: 32,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Send us a Message",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A365D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Fill out the form below and we'll get back to you",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF718096),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Phone Number Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          keyboardType: TextInputType.phone,
                          controller: numberController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFF1A365D), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelText: 'Phone Number',
                            labelStyle: GoogleFonts.poppins(color: const Color(0xFF718096)),
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone, color: Colors.blue.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+91',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF1A365D),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                            suffixIcon: numberController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.blue.shade600),
                              onPressed: () {
                                setState(() {
                                  numberController.clear();
                                });
                              },
                            )
                                : null,
                            filled: true,
                            fillColor: Colors.blue.shade50,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Message Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: messageController,
                          maxLines: 5,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFF1A365D), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelText: 'Your Message',
                            labelStyle: GoogleFonts.poppins(color: const Color(0xFF718096)),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(top: 12, left: 12),
                              child: Icon(Icons.message_outlined, color: Colors.blue.shade600, size: 20),
                            ),
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Colors.blue.shade50,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A365D), Color(0xFF2C5AA0)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A365D).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.send, color: Colors.white, size: 20),
                          label: Text(
                            _isLoading ? "Sending..." : "Send Message",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),

          // WhatsApp Floating Action Button
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade300,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.green.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: () async {
                  const contactNumber = '+918866966703';
                  const url = 'whatsapp://send?phone=$contactNumber&text=Hello, Nice to meet you! I\'d love to discuss a few questions I have about the "Deodap Amazon DD return ++  App"..';

                  try {
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    } else {
                      const webUrl = 'https://wa.me/$contactNumber?text=Hello, Nice to meet you! I\'d love to discuss a few questions I have about the "Deodap Amazon DD return ++ App"..';
                      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    _showSnackBar('Could not open WhatsApp', Colors.red.shade600);
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.chat,
                    color: Colors.white,
                    size: 28,
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