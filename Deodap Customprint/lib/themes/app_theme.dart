import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final appTheme = ThemeData(
  primaryColor: Color(0xFF0B90A1),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF0B90A1),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.oswald(
      textStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),
  textTheme: TextTheme(
    headlineMedium: GoogleFonts.oswald(
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
    bodyLarge: GoogleFonts.oswald(
      textStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF0B90A1),
    secondary: Colors.orange,
  ),
);
