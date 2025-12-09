import 'package:Deodap_Customprint/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator/loading_indicator.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
class InvitefrdScreen extends StatefulWidget {
  const InvitefrdScreen({super.key});

  @override
  State<InvitefrdScreen> createState() => _InvitefrdScreenState();
}

class _InvitefrdScreenState extends State<InvitefrdScreen> {
  String? imageUrl;

  String? shareLink;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('https://customprint.deodap.com/api_customprint/invite_friend.php'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          imageUrl = data['screen']['image_url'];
          shareLink = data['screen']['link'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Invite a Friend",
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),
        ),
        backgroundColor: Color(0xFF0B90A1),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          // This creates the back button
          onPressed: () {
            Navigator.pop(
                context); // This will navigate back to the previous screen
          },
        ),

      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Scan QR Code',
                style: GoogleFonts.oswald(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              Divider(
                indent: 70.0,
                endIndent: 70.0,
                color: Colors.red.shade900,
                thickness: 2.0,
              ),
              SizedBox(height: 20),
              Container(
                height: 370,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: imageUrl != null
                          ? Image.network(imageUrl!)
                          : Container(),
                      height: 250,
                      width: 250,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Copy and Share App Link',
                style: GoogleFonts.oswald(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              Divider(
                indent: 70.0,
                endIndent: 70.0,
                color: Colors.red.shade900,
                thickness: 2.0,
              ),


              SizedBox(height: 20),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  hintText: shareLink ?? 'Share link',
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.copy, color: Colors.blue.shade900),
                    onPressed: () {
                      if (shareLink != null) {
                        _copyToClipboard(shareLink!);
                      }
                    },
                  ),
                ),
                cursorColor: Colors.blue.shade900,
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 20),
              Text("This QR code is private. If you share it with", style: TextStyle(color: Colors.grey,fontSize:12)),
              Text("someone, they can scan it with their CustomPrint", style: TextStyle(color: Colors.grey,fontSize: 12)),
              Text("Camera to add your application..", style: TextStyle(color: Colors.grey,fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
