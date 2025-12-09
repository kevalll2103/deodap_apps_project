import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart'as http;
import 'package:url_launcher/url_launcher.dart';
class Updatescreen extends StatefulWidget {
  const Updatescreen({super.key});

  @override
  State<Updatescreen> createState() => _UpdatescreenState();
}

class _UpdatescreenState extends State<Updatescreen> {

  String shareLink = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('https://customprint.deodap.com/api_sampleTrack/applink.php'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          shareLink = data['screen']['link'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Link to open: $shareLink');

      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 50, right: 20, left: 20),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/rocket_image.png',
                    height: 270,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '🚀 New Version Now Available! 🚀',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      // Yahan aap lines ki limit set kar sakte hain
                      overflow: TextOverflow.ellipsis,
                      // Agar text exceed hota hai toh ellipsis dikhayega
                      textAlign:
                      TextAlign.center, // Text ko center align karega
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dear user, ",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text(
                          "We are thrilled to inform you that a brand-new version of our application has been released! This update not only brings exciting new features but also includes significant enhancements to improve your overall experience.",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text(
                          "What's New?",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Enjoy a smoother and faster experience..",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "Explore fresh functionalities designed to make your tasks easier..",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "We’ve addressed several issues to ensure better stability and reliability.",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(
                          height: 15,
                        ),



                      ],
                    ),
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        final url = Uri.parse(shareLink);
                        await launchUrl(url);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        backgroundColor: Colors.white,
                        minimumSize: Size(200, 50),
                      ),
                      child: Text(
                        "Update Now",
                        style: TextStyle(color: Color(0xFF0d1627),fontSize: 18,fontWeight: FontWeight.bold),
                      )),
                  SizedBox(height: 30),


                ],
              ),
            ),
          ),
        )
    );
  }
}
