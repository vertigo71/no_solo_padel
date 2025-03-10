import 'package:flutter/material.dart';

import 'app_colors.dart';

// ignore: unused_element
final String _classString = 'Theme'.toUpperCase();

ThemeData generateThemeData(BuildContext context) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryMaterial,
      brightness: Brightness.light,
      surface: primaryLight,
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryDark, // App bar background
      foregroundColor: lightest, // App bar text color
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: black, // Selected item color
      unselectedItemColor: medium, // Unselected item color
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarTheme(
      dividerColor: primaryLight,
      indicatorSize: TabBarIndicatorSize.tab,
      // Ensure it fills the tab
      indicator: BoxDecoration(
        color: primaryLight, // If you don't want a background color
      ),
      labelColor: dark,
      // Selected label color
      unselectedLabelColor: primaryLight, // Unselected label color
    ),
  );
}


