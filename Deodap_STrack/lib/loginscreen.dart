import 'package:Deodap_STrack/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isObscured = true;
  String passwordError = '';
  String nameError = '';
  FocusNode _passwordFocusNode = FocusNode();
  FocusNode _nameFocusNode = FocusNode();

  bool _isChecked = false;

  void _toggleCheckbox(bool? value) {
    setState(() {
      _isChecked = value ?? false;
    });
  }

  void _clearName() {
    _nameController.clear();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _login() async {
    FocusScope.of(context).requestFocus(FocusNode()); // Dismiss the keyboard

    // Reset the error messages
    setState(() {
      passwordError = '';
      nameError = '';
    });

    // Remove focus from text fields
    FocusScope.of(context).unfocus();

    // Check if any field is empty
    if (_passwordController.text.isEmpty || _nameController.text.isEmpty) {
      return;
    }

    // Validate the form using the existing form key
    if (_formKey.currentState!.validate()) {
      // Check if terms and conditions checkbox is not checked
      if (!_isChecked) {
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

      try {
        // API call
        final response = await http.post(
          Uri.parse('https://customprint.deodap.com/api_sampleTrack/user_login.php'),
          body: {
            'email': _nameController.text,
            'password': _passwordController.text,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("API Response: $data");

          if (data['success'] == 'Login successful') {
            SharedPreferences prefs = await SharedPreferences.getInstance();

            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('userRole', 'employee'); // Role store karo
            await prefs.setString('userEmail', _nameController.text); // Email store karo

            // Remove the loading indicator
            overlayEntry.remove();

            // Navigate to the home screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Homescreen()),
                  (Route<dynamic> route) => false, // Removes all previous routes
            );
          } else if (data['message'] == 'Invalid email!') {
            setState(() {
              nameError = 'Invalid Email!';
            });
          } else if (data['message'] == 'Invalid password!') {
            setState(() {
              passwordError = 'Invalid Password!';
            });
          }

        }

      } catch (e) {


        print("Exception: $e");

        overlayEntry.remove();
        // Handle exceptions (like no internet)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No Internet Connection..!',
              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red.shade900,
            duration: Duration(seconds: 2),
          ),
        );
      } finally {
        overlayEntry.remove(); // Ensure loading indicator is removed in all cases
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Add listeners to reset error messages when the user interacts with the fields


    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        // Reset the error message under the password field when the password field gains focus
        setState(() {
          passwordError = '';
        });
      }
    });

    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        // Reset the error message under the password field when the password field gains focus
        setState(() {
          nameError = '';
        });
      }
    });



  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,

      body:
      SafeArea(
            child: Form(
              key: _formKey,
              child: Center(
                child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, left: 17, right: 17),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Let's, Sign-in",
                            style: GoogleFonts.oswald(
                              textStyle: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B90A1) // Optional: You can add color or other styles
                              ),
                            ),
                          ),
                          Text(
                            "Hello Admin, sign in to continue..!",
                            style: GoogleFonts.oswald(
                              textStyle: TextStyle(
                                  fontSize: 15,
                                  color: Colors
                                      .black // Optional: You can add color or other styles
                              ),
                            ),
                          ),

                          SizedBox(
                            height: 70,
                          ),
                          TextFormField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            style: TextStyle(
                              fontWeight: FontWeight.bold, // User ke input text ko bold karne ke liye
                              color: Colors.black, // Input text ka color
                            ),
                            cursorColor: Colors.black, // Cursor ka color black set karne ke liye

                            decoration: InputDecoration(
                              hintText: "Enter Email",
                              hintStyle: TextStyle(color: Colors.grey),
                              errorText: nameError.isEmpty ? null : nameError,
                              suffixIcon: IconButton(
                                icon: Icon(Icons.cancel_outlined,
                                    color: Color(0xFF0d1627)),
                                onPressed: _clearName,
                              ),
                              prefixIcon: Icon(Icons.person_outline,
                                  color: Color(0xFF0d1627)),
                              labelStyle: TextStyle(color: Colors.grey),
                              filled: true, // Background ko fill karne ke liye
                              fillColor: Colors.white, // White background
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF0d1627), width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF0d1627), width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),



                          SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isObscured,
                            style: TextStyle(
                              fontWeight: FontWeight.bold, // User ke input text ko bold karne ke liye
                              color: Colors.black, // Input text ka color
                            ),
                            cursorColor: Colors.black, // Cursor ka color black set karne ke liye

                            focusNode: _passwordFocusNode,
                            decoration: InputDecoration(
                              hintText: "Enter Password",
                              hintStyle: TextStyle(color: Colors.grey),
                              errorText:
                              passwordError.isEmpty ? null : passwordError,
                              // Display error if any
                              labelStyle: TextStyle(color: Colors.grey),
                              filled: true, // Background ko fill karne ke liye
                              fillColor: Colors.white, // White background

                              prefixIcon: Icon(Icons.lock_outline,
                                  color: Color(0xFF0d1627)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Color(0xFF0d1627),
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF0d1627), width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF0d1627), width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),

                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: Container(
                              width: double.infinity,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        border:
                                        Border.all(color: Colors.white)),
                                    height: 17,
                                    width: 17,
                                    child: Checkbox(
                                      value: _isChecked,
                                      onChanged: _toggleCheckbox,
                                      activeColor:Color(0xFF0B90A1),
                                      // Checkmark color
                                      checkColor: Colors.black,
                                      // Color of the checkmark
                                      side: BorderSide(color: Colors.black),
                                      // Border color of the checkbox
                                      materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                            'By logging in, you agree to our ',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14),
                                          ),
                                          TextSpan(
                                            text: 'Terms and Conditions',
                                            style: TextStyle(
                                                color: Colors.blue[400],
                                                fontSize: 14,
                                                decoration:
                                                TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                // Handle the link tap here
                                                launchUrl(Uri.parse(
                                                    "https://deodap.in/pages/terms-conditions?srsltid=AfmBOorlAFTcquWvmnM1Sq0E-P9PNHaRzkroAj-rYWhRHhkFoQ8KxU3h"));
                                              },
                                          ),
                                          TextSpan(
                                            text: ' and ',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14),
                                          ),
                                          // Replace the TextSpan with the Link widget
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                                color: Colors.blue[400],
                                                fontSize: 14,
                                                decoration:
                                                TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                // Handle the link tap here
                                                launchUrl(Uri.parse(
                                                    "https://deodap.in/pages/privacy-policy#:~:text=We%20aim%20to%20take%20reasonable,at%20care%40deodap.com."));
                                              },
                                          ),
                                          TextSpan(
                                            text:
                                            '. Please ensure you read and understand these documents before proceeding.',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          OutlinedButton(
                            onPressed: () {
                              _login();

                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0B90A1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                                side: BorderSide(color: Colors.white), // White border

                                minimumSize: Size(double.infinity, 45)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Sign-in",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // Optional: You can add color or other styles
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    )
                ),
              ),
            )
        ),

    );
  }
}
