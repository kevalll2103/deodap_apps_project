import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ContactScreenView extends StatefulWidget {
  const ContactScreenView({super.key});

  @override
  State<ContactScreenView> createState() => _ContactScreenViewState();
}

class _ContactScreenViewState extends State<ContactScreenView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _controller;

  final double latitude = 22.31324422174691;
  final double longitude = 70.86542217812068;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    numberController.dispose();
    messageController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  void _submitForm() async {
    FocusScope.of(context).unfocus();

    if (_validateForm()) {
      OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black12.withOpacity(0.8),
          body: Center(
            child: Container(
              width: 300,
              height: 300,
              child: LoadingIndicator(
                indicatorType: Indicator.ballClipRotatePulse,
                colors: [Colors.white],
                strokeWidth: 4,
              ),
            ),
          ),
        ),
      );

      if (Overlay.of(context) != null) {
        Overlay.of(context)!.insert(overlayEntry);
      }

      await registerUser();

      overlayEntry.remove();

      nameController.clear();
      emailController.clear();
      numberController.clear();
      messageController.clear();

      FocusScope.of(context).unfocus();
    }
  }

  bool _validateForm() {
    bool isValid = true;

    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        numberController.text.isEmpty ||
        messageController.text.isEmpty) {
      isValid = false;
      return isValid;
    }

    if (emailController.text.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(emailController.text)) {
      isValid = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid email.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade900,
          duration: Duration(seconds: 2),
        ),
      );
      return isValid;
    }

    if (numberController.text.isEmpty || numberController.text.length != 10) {
      isValid = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter valid phone number',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade900,
          duration: Duration(seconds: 2),
        ),
      );
      return isValid;
    }

    if (messageController.text.isEmpty) {
      isValid = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a message.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade900,
          duration: Duration(seconds: 2),
        ),
      );
      return isValid;
    }

    return isValid;
  }

  Future<void> registerUser() async {
    final url =
        'https://customprint.deodap.com/api_amzDD_return/contact_form.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'name': nameController.text,
          'email': emailController.text,
          'number': numberController.text,
          'message': messageController.text,
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thank you for your submission..!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF25253c),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (responseBody['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No Internet.. Please try again',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade700,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server Down..try again',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        title: const Text(
          "Get In Touch",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Scrollbar(
              thumbVisibility: true,
              thickness: 1.4,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Info Section
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'DeoDap International Private Limited',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "GST: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                                TextSpan(
                                  text: "24AAHCD5265C1ZX",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "CIN: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                                TextSpan(
                                  text: "U51909GJ2019PTC110919",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Copyright © 2024 DeoDap.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Welcome Message
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'We\'d love to hear from you! Whether you have questions, feedback, or just want to say hi, feel free to reach out to us.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Contact Information Section
                    Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.location_on,
                      title: "Address:",
                      content:
                      'C/o Rajesh Rasikbhai Chotai Barjar Paint,\nOpp. Rangoli Masala Village, Navagam,\nRajkot-360003, Gujarat, India',
                    ),
                    _buildInfoCard(
                      icon: Icons.phone,
                      title: "Phone No.:",
                      content: '+91 9638666602',
                      isPhone: true,
                    ),
                    _buildInfoCard(
                      icon: Icons.email,
                      title: "Email:",
                      content: 'care@deodap.com',
                      isEmail: true,
                    ),

                    SizedBox(height: 16),

                    // Social Media Section
                    Text(
                      "Follow us:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSocialIcon('assets/whatsapp_image.png',
                              'whatsapp://send?phone="+919638666602"&text= Hello Sir,'),
                          _buildSocialIcon(
                              'assets/facebook_image.png',
                              'https://deodap.in/pages/privacy-policy'),
                          _buildSocialIcon(
                              'assets/instagram_image.png',
                              'https://www.instagram.com/DeoDap_com/'),
                          _buildSocialIcon('assets/linkdin_image.png',
                              'https://in.linkedin.com/company/deodap'),
                          _buildSocialIcon('assets/snapchat_image.png',
                              'https://www.snapchat.com/add/deodap'),
                          _buildSocialIcon('assets/youtube_image.png',
                              'https://www.youtube.com/c/OnlineBusinessIdeasbyDeoDap'),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Support Hours
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'For Any Question, You Can Easily Contact Us.',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Support: Monday to Saturday From 9:00 AM to 6:00 PM',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Map Section
                    Text(
                      'Tap to Find Us',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        await launchUrl(Uri.parse(
                            "https://www.google.com/maps/place/DeoDap+DropShipping/@22.330938,70.85004,15z/data=!4m6!3m5!1s0x3959cbd2aaed26d1:0xa8849c4cd98c16b0!8m2!3d22.3299937!4d70.8502628!16s%2Fg%2F11g8w0_vyq?hl=en&entry=ttu&g_ep=EgoyMDI0MTAyMy4wIKXMDSoASAFQAw%3D%3D"));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/map.png',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Contact Form Section
                    Text(
                      'Send Message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: nameController,
                            hintText: 'Username',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          _buildTextField(
                            controller: emailController,
                            hintText: 'Email',
                            icon: Icons.email,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex =
                              RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          _buildPhoneField(),
                          SizedBox(height: 12),
                          _buildTextField(
                            controller: messageController,
                            hintText: 'Message',
                            icon: null,
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your message';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: Size(double.infinity, 50),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              "Send Message",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Thank You Message
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Thank you for reaching out! We\'ll get back to you as soon as possible.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, right: 10.0),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.1 + (_controller.value * 0.1),
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/whatsapp_image.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                onPressed: () async {
                  String contacnumner = '+919638666602';
                  String url =
                      'whatsapp://send?phone="$contacnumner"&text= Hello, Nice to meet you, .!!  I\'d love to discuss a few questions I have about the DeoDap application..';
                  await launchUrl(Uri.parse(url));
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    bool isPhone = false,
    bool isEmail = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue.shade900,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: isPhone
                      ? () async {
                    String contactNumber = '+919638666602';
                    String url = 'tel:$contactNumber';

                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Could not launch the dialer')),
                      );
                    }
                  }
                      : isEmail
                      ? () async {
                    try {
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'care@deodap.com',
                        queryParameters: {
                          'subject':
                          'Inquiry from DeoDap CustomPrint App',
                          'body':
                          'Hello,\n\nI have a question regarding...',
                        },
                      );

                      if (await canLaunchUrl(emailLaunchUri)) {
                        await launchUrl(
                          emailLaunchUri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No email app found'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Error opening email: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                      : null,
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isPhone || isEmail
                          ? Colors.blue.shade800
                          : Colors.black,
                      decoration: isPhone || isEmail
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(String imagePath, String url) {
    return GestureDetector(
      onTap: () async {
        await launchUrl(Uri.parse(url));
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(imagePath),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData? icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue[800]!, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: icon != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 12),
            Icon(
              icon,
              color: Colors.grey.shade600,
            ),
            SizedBox(
              height: 35,
              child: VerticalDivider(
                width: 20,
                thickness: 1.2,
                color: Colors.grey.shade400,
              ),
            )
          ],
        )
            : null,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.cancel, color: Colors.grey.shade600),
          onPressed: () {
            controller.clear();
            setState(() {});
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white,
      ),
      style: TextStyle(color: Colors.black),
      cursorColor: Colors.blue[800]!,
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      keyboardType: TextInputType.phone,
      controller: numberController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your Number';
        } else if (value.length != 10) {
          return 'Phone number must be 10 digits';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue[800]!, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Phone Number',
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 12),
            Text(
              '+91',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(
              height: 35,
              child: VerticalDivider(
                width: 20,
                thickness: 1.2,
                color: Colors.grey.shade400,
              ),
            )
          ],
        ),
        suffixIcon: numberController.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.cancel, color: Colors.grey.shade600),
          onPressed: () {
            numberController.clear();
            setState(() {});
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white,
      ),
      style: TextStyle(color: Colors.black),
      cursorColor: Colors.blue[800]!,
      onChanged: (value) {
        setState(() {});
      },
    );
  }
}