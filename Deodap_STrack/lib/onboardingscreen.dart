import 'package:Deodap_STrack/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class Onboardingscreen extends StatefulWidget {
  const Onboardingscreen({super.key});

  @override
  State<Onboardingscreen> createState() => _OnboardingscreenState();
}

class _OnboardingscreenState extends State<Onboardingscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [

      Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/onboarding_i9mage.png",scale: 4),
                  SizedBox(height: 20),
                  Text(
                    'Get Started With',
                    style: GoogleFonts.oswald(
                      textStyle: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B90A1),
                      ),
                    ),
                  ),
                  Text(
                    'Deodap Sample-Tracking App',
                    style: GoogleFonts.oswald(
                      textStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(

                          "1.Inventory at a Glance :",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        Text(
                          "Instantly access a list of all incoming and outgoing samples.Keep records structured and up to date effortlessly.",
                          style: TextStyle(color: Colors.grey,fontSize: 12),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "2.Seamless Entry Logging :",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        Text(
                          "Capture essential details as soon as a sample arrives.Upload images for a visual record with every entry.",
                          style: TextStyle(color: Colors.grey,fontSize: 12),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "3.Exit with Clarity :",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        Text(
                          "Log sample dispatch with complete documentation.Attach relevant images to maintain a clear audit trail.",
                          style: TextStyle(color: Colors.grey,fontSize: 12),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "4.History that Speaks :",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        Text(
                          "Find past samples with ease using advanced filters.Maintain an organized and transparent tracking system.",
                          style: TextStyle(color: Colors.grey,fontSize: 12),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "5.Get Started with DeoDap :",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        Text(
                          "A simple and efficient way to manage warehouse samples.Reduce manual errors with digital entry and exit tracking.Start now and bring clarity to your sample management.",
                          style: TextStyle(color: Colors.grey,fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Positioned(
            top: 40,
            right: 10,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => Loginscreen()),  // Go to Login Screen after version mismatch
                );
              },
              child: Text(
                "Skip",
                style: TextStyle(
                  color: Color(0xFF0B90A1),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            right: 30,
            left: 30,
            bottom: 20,
            child: OutlinedButton(onPressed: (){
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => Loginscreen()),  // Go to Login Screen after version mismatch
              );
            },
                style: ElevatedButton.styleFrom(
                  backgroundColor:  Color(0xFF0B90A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ), // Button background color
                ),
                child: Text("Continue",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 17),)),
          ),
        ],
      ),
    );
  }
}
