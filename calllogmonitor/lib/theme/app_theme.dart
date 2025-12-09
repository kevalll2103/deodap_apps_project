import 'package:flutter/material.dart';

class AppTheme {
  // Primary warm color palette
  static const Color primaryWarm = Color(0xFFFCF7EF); // #FCF7EF - Main background
  static const Color warmAccent = Color(0xFFF5E6D3); // Slightly darker warm tone
  static const Color warmDark = Color(0xFFE8D5C4); // Darker warm for borders
  static const Color warmLight = Color(0xFFFEFBF7); // Lighter warm for cards

  // Complementary colors
  static const Color primaryBrown = Color(0xFF8B6F47); // Warm brown for text
  static const Color accentBrown = Color(0xFFA0845C); // Lighter brown
  static const Color darkBrown = Color(0xFF6B5139); // Dark brown for emphasis

  // Status colors with warm tones
  static const Color successWarm = Color(0xFF7D8471); // Warm green
  static const Color warningWarm = Color(0xFFD4A574); // Warm orange
  static const Color errorWarm = Color(0xFFB85450); // Warm red
  static const Color infoWarm = Color(0xFF6B8CAE); // Warm blue

  // Neutral colors
  static const Color textPrimary = Color(0xFF3C2E26); // Dark brown text
  static const Color textSecondary = Color(0xFF6B5139); // Medium brown text
  static const Color textTertiary = Color(0xFF8B6F47); // Light brown text
  static const Color dividerColor = Color(0xFFE8D5C4);

  // Gradient definitions
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFEFBF7),
      Color(0xFFFCF7EF),
      Color(0xFFF5E6D3),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFA0845C),
      Color(0xFF8B6F47),
    ],
  );

  // Shadow definitions
  static List<BoxShadow> get warmShadow => [
    BoxShadow(
      color: darkBrown.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: darkBrown.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Text styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );

  // Button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryBrown,
    foregroundColor: primaryWarm,
    elevation: 4,
    shadowColor: darkBrown.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryBrown,
    side: BorderSide(color: warmDark, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  // Input decoration
  static InputDecoration getInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: bodyMedium,
      prefixIcon: icon != null ? Icon(icon, color: accentBrown) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: warmDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: warmDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBrown, width: 2),
      ),
      filled: true,
      fillColor: warmLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: warmLight,
    borderRadius: BorderRadius.circular(16),
    boxShadow: cardShadow,
    border: Border.all(color: warmDark.withOpacity(0.3)),
  );

  // App bar theme
  static AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: primaryWarm,
    foregroundColor: textPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: headingMedium,
    iconTheme: const IconThemeData(color: primaryBrown),
  );

  // Drawer theme
  static DrawerThemeData get drawerTheme => DrawerThemeData(
    backgroundColor: warmLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
  );

  // Main theme data
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    primaryColor: primaryBrown,
    scaffoldBackgroundColor: primaryWarm,
    colorScheme: ColorScheme.light(
      primary: primaryBrown,
      secondary: accentBrown,
      surface: warmLight,
      background: primaryWarm,
      onPrimary: primaryWarm,
      onSecondary: primaryWarm,
      onSurface: textPrimary,
      onBackground: textPrimary,
    ),
    appBarTheme: appBarTheme,
    drawerTheme: drawerTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: warmDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: warmDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBrown, width: 2),
      ),
      filled: true,
      fillColor: warmLight,
    ),
    cardTheme: CardThemeData(
      color: warmLight,
      elevation: 4,
      shadowColor: darkBrown.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: 1,
    ),
    textTheme: const TextTheme(
      headlineLarge: headingLarge,
      headlineMedium: headingMedium,
      headlineSmall: headingSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelSmall: caption,
    ),
  );
}