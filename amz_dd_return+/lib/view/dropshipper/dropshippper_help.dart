import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;


class DropshipperHelp extends StatefulWidget {
  const DropshipperHelp({super.key});

  @override
  State<DropshipperHelp> createState() => _ContactscreenState();
}

class _ContactscreenState extends State<DropshipperHelp> {

  final TextEditingController messageController = TextEditingController();
  final TextEditingController numberController = TextEditingController();


  void initState() {
    super.initState();
  }

  Future<void> SubmitFrom() async {
    FocusScope.of(context).requestFocus(FocusNode()); // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    // Ensure phone number is exactly 10 digits
    if (numberController.text.length != 10) {
      return;
    }
// Check if any field is empty
    if (messageController.text.isEmpty || numberController.text.isEmpty) {
      return;
    }
    // Show loading indicator
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Container(
            color: Colors.black12.withOpacity(0.8),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context)!.insert(overlayEntry);

    final url = 'https://customprint.deodap.com/api_amzDD_return/contact_form.php'; // Replace with your API URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'phone_number': numberController.text,
          'message': messageController.text,
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] != null) {
          overlayEntry.remove();
          messageController.clear();
          numberController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thank you for your submission..!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Color(0xFF001645),
              duration: Duration(seconds: 1),

            ),
          );
        } else if (responseBody['error'] != null) {
          overlayEntry.remove();


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No internet connection..!!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red.shade900,
              duration: Duration(seconds: 1),

            ),
          );
        }
      } else {
        overlayEntry.remove();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server Down..try again',
              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red.shade700,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      overlayEntry.remove();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No internet connection..!!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red.shade900,
          duration: Duration(seconds: 1),

        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white, // White background
        body: Container(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Color(0xFF1565C0), // Specified blue color
                elevation: 0,
                centerTitle: true,
                title: Text(
                  "Contact Us",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(child:
        Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 110, left: 15, right: 15),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'We\'d love to hear from you! Whether you have questions, feedback, or just want to say hi, feel free to reach out to us...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'For Any Question, You Can Easily Contact Us.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    Text(
                      'Monday to Saturday From 9:00 AM to 6:00 PM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      "Form Fill-Out",
                      style: GoogleFonts.oswald(
                        textStyle: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      keyboardType: TextInputType.phone,
                      controller: numberController,

                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(

                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1565C0)),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: 'Phone number',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 10),
                            Text(
                              '+91',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(
                              height: 35,
                              child: VerticalDivider(
                                width: 20,
                                thickness: 1.2,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.cancel_outlined,
                              color: Color(0xFF1565C0)),
                          onPressed: () {
                            numberController.clear();
                          },
                        ),
                        //fillColor: Colors.grey[300],
                      ),
                      style: TextStyle(color: Colors.black87),
                      cursorColor: Color(0xFF1565C0),
                    ),

                    SizedBox(height: 10,),
                    TextFormField(
                      controller: messageController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your message';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1565C0)),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: 'Message',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                      ),
                      maxLines: 5,
                      style: TextStyle(color: Colors.black87),
                      cursorColor: Color(0xFF1565C0),
                    ),
                    SizedBox(height: 40),
                    OutlinedButton(
                      onPressed: () {
                        SubmitFrom();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        side: BorderSide(color: Color(0xFF1565C0)),
                        minimumSize: Size(double.infinity, 45),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Send Message",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Floating Action Button Correctly Positioned
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 20),
                child: FloatingActionButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/whatsapp_image.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  onPressed: () async {
                    String contacnumner = '+918866966703';
                    String url =
                        'whatsapp://send?phone=$contacnumner&text= Hello, Nice to meet you, keval..!!  I’d love to discuss a few questions I have about the "Deodap SampleTracking App"..';
                    await launchUrl(Uri.parse(url));
                  },
                ),
              ),
            ),
          ],
        )
        ),
        ],
        ),
      ),
    );
  }
}
