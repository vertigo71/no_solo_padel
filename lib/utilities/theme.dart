import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';

import '../models/debug.dart';

final String _classString = 'Theme'.toUpperCase();

// Main colors
const MaterialColor primaryMaterial = Colors.deepPurple;
final Color primaryDark = Colors.deepPurple.shade900;
final Color primaryMedium = Colors.deepPurple.shade200;
final Color primaryLight = Colors.deepPurple.shade100;

// Alternative colors
const MaterialColor altMaterial = Colors.deepOrange;
final Color altDark = Colors.deepOrange.shade300;
final Color altMedium = Colors.deepOrange.shade200;
final Color altLight = Colors.deepOrange.shade100;

// misc colors
const Color black = Colors.black;
const Color dark = Colors.black87;
const Color medium = Colors.black54;
const Color light = Colors.black26;
const Color lightest = Colors.white70;
const Color white = Colors.white;

ThemeData generateThemeData(BuildContext context) {
  MyLog.log(_classString, 'generateThemeData', level: Level.FINE);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.light,
      surface: primaryLight,
      inversePrimary: primaryMedium,
    ),

    // scaffold
    scaffoldBackgroundColor: Colors.transparent,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryDark, // App bar background
      foregroundColor: lightest, // App bar text color
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryMedium, // Bottom bar background
      selectedItemColor: black, // Selected item color
      unselectedItemColor: medium, // Unselected item color
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarTheme(
      dividerColor: primaryLight,
      indicatorSize: TabBarIndicatorSize.tab,
      // Ensure it fills the tab
      indicator: BoxDecoration(
        color: primaryMedium, // background color
      ),
      labelColor: dark,
      // Selected label color
      unselectedLabelColor: primaryLight, // Unselected label color
    ),

    // Button theme
    buttonTheme: ButtonThemeData(
      buttonColor: primaryLight,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: dark,
      ),
    ),
  );
}
