import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';

import '../models/debug.dart';

final String _classString = 'Theme'.toUpperCase();

// Main colors
const MaterialColor kPrimaryMaterial = Colors.deepPurple;
final Color kPrimaryDark = Colors.deepPurple.shade900;
final Color kPrimaryMedium = Colors.deepPurple.shade200;
final Color kPrimaryLight = Colors.deepPurple.shade100;

// Alternative colors
const MaterialColor kAltMaterial = Colors.deepOrange;
final Color kAltDark = Colors.deepOrange.shade300;
final Color kAltMedium = Colors.deepOrange.shade200;
final Color kAltLight = Colors.deepOrange.shade100;

// misc colors
const Color kBlack = Colors.black;
const Color kDark = Colors.black87;
const Color kMedium = Colors.black54;
const Color kLight = Colors.black26;
const Color kLightest = Colors.white70;
const Color kWhite = Colors.white;

ThemeData generateThemeData(BuildContext context) {
  MyLog.log(_classString, 'generateThemeData', level: Level.FINE);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryDark,
      brightness: Brightness.light,
      surface: kPrimaryLight,
      inversePrimary: kPrimaryMedium,
    ),

    // scaffold
    scaffoldBackgroundColor: Colors.transparent,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: kPrimaryDark, // App bar background
      foregroundColor: kLightest, // App bar text color
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: kPrimaryMedium, // Bottom bar background
      selectedItemColor: kBlack, // Selected item color
      unselectedItemColor: kMedium, // Unselected item color
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarTheme(
      dividerColor: kPrimaryLight,
      indicatorSize: TabBarIndicatorSize.tab,
      // Ensure it fills the tab
      indicator: BoxDecoration(
        color: kPrimaryMedium, // background color
      ),
      labelColor: kDark,
      // Selected label color
      unselectedLabelColor: kPrimaryLight, // Unselected label color
    ),

    // Button theme
    buttonTheme: ButtonThemeData(
      buttonColor: kPrimaryLight,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryLight,
        foregroundColor: kDark,
      ),
    ),

  );
}
