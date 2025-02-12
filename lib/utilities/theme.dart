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


/* second version // TODO: remove this code
ThemeData generateThemeData(BuildContext context) {
  // Main colors
  const MaterialColor primaryMaterial = Colors.deepPurple;
  final Color background = Colors.deepPurple[200]!;
  final Color backgroundLight = Colors.deepPurple[100]!;

  // Alternative colors
  final Color backgroundAlt = Colors.deepOrange[300]!;
  const Color foregroundAlt = Colors.black;
  const Color unselectedAlt = Colors.black54;

  return ThemeData(
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: primaryMaterial,
      backgroundColor: background, // Use background for scaffold background
    ).copyWith(
      secondary: backgroundAlt,
      // Use backgroundAlt as secondary color
      surface: backgroundLight,
      // Use backgroundLight for surfaces (cards, dialogs, etc.)
      onPrimary: Colors.white,
      // Text color on primary color
      onSecondary: foregroundAlt,
      // Text color on secondary color
      onSurface: backgroundAlt,
      // Text color on surface color
      onError: Colors.red,
      // Error color
      brightness: Brightness.light, // Or Brightness.dark if you prefer
    ),


// App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryMaterial, // App bar background
      foregroundColor: Colors.white, // App bar text color
      titleTextStyle: const TextStyle(
        // Customize app bar text style
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white, // App bar icons color
      ),
    ),

    // Button Theme
    buttonTheme: ButtonThemeData(
      buttonColor: primaryMaterial, // Button background color
      textTheme: ButtonTextTheme.primary, // Use primary text theme for buttons
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryMaterial, // Elevated button background color
        foregroundColor: Colors.white, // Elevated button text color
        textStyle: const TextStyle(fontWeight: FontWeight.bold), // Example
        shape: RoundedRectangleBorder(
          // Example
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),

    // Text Theme
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: foregroundAlt),
      // Body text
      bodyMedium: TextStyle(color: foregroundAlt),
      // Body text
      bodySmall: TextStyle(color: foregroundAlt),
      // Body text
      headlineLarge: TextStyle(color: foregroundAlt),
      // Headlines
      headlineMedium: TextStyle(color: foregroundAlt),
      // Headlines
      headlineSmall: TextStyle(color: foregroundAlt),
      // Headlines
      titleLarge: TextStyle(color: foregroundAlt),
      // Titles
      titleMedium: TextStyle(color: foregroundAlt),
      // Titles
      titleSmall: TextStyle(color: foregroundAlt),
      // Titles
      labelLarge: TextStyle(color: foregroundAlt),
      // Button labels, etc.
      labelMedium: TextStyle(color: foregroundAlt),
      // Button labels, etc.
      labelSmall: TextStyle(color: foregroundAlt), // Button labels, etc.
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // Fill input fields
      fillColor: background,
      // Use backgroundLight as fill color
      border: OutlineInputBorder(
        // Use outlined border
        borderSide: BorderSide.none, // Remove border line
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
      ),
      focusedBorder: OutlineInputBorder(
        // Border when focused
        borderSide: BorderSide(color: primaryMaterial), // Primary color border
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
      ),
      labelStyle: TextStyle(
        color: foregroundAlt,
        backgroundColor: background,
      ),
      // Label text color
      hintStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            // Use caption style
            color: unselectedAlt, // Override color if needed
          ),
    ),

    // ListTile Theme
    listTileTheme: ListTileThemeData(
      textColor: foregroundAlt, // Text color in list tiles
      iconColor: foregroundAlt, // Icon color in list tiles
      tileColor: backgroundLight, // Background color of list tiles
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: backgroundLight, // Card background color
      elevation: 2.0, // Card elevation
      shape: RoundedRectangleBorder(
        // Rounded corners for cards
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: background, // Background color
      selectedItemColor: primaryMaterial, // Selected item color
      unselectedItemColor: unselectedAlt, // Unselected item color
      // You can also customize the selected/unselected icon theme here
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarTheme(
      indicator: BoxDecoration(
        // Customize the indicator
        border: Border(
          bottom: BorderSide(
            color: primaryMaterial, // Indicator color
            width: 2.0,
          ),
        ),
      ),
      labelColor: foregroundAlt, // Selected label color
      unselectedLabelColor: unselectedAlt, // Unselected label color
    ),

	*/

/*
First version: ThemeData myTheme(BuildContext context) {
  // alternative colors
  final Color backgroundAlt = Colors.deepOrange[300]!;
  const Color foregroundAlt = Colors.black;
  const Color unselectedAlt = Colors.black54;

  // main colors
  const MaterialColor primaryMaterial = Colors.deepPurple;
  final Color background = Colors.deepPurple[200]!;
  final Color backgroundLight = Colors.deepPurple[100]!;

  // fonts
  final TextStyle bodyLargeStyle = GoogleFonts.roboto(
    // Use bodyLarge, bodyMedium, bodySmall
    textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              // Inherit and copy
              fontSize: 16.0,
              color: Colors.black87,
            ) ??
        const TextStyle(), // Provide default if parent is null
  );
  final TextStyle headlineLargeStyle = GoogleFonts.roboto(
    // Use headlineLarge, headlineMedium, headlineSmall
    textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
            ) ??
        const TextStyle(), // Provide default if parent is null
  );

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryMaterial,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: backgroundLight,
    // for Material 3

    // canvasColor: backgroundLight, for Material 2

    primarySwatch: primaryMaterial,

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryMaterial,
        foregroundColor: Colors.white, // Example
        textStyle: const TextStyle(fontWeight: FontWeight.bold), // Example
        shape: RoundedRectangleBorder(
          // Example
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(), // Add const for better performance
      labelStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 12.0, // Smaller font size
      ),
      hintStyle: const TextStyle(
        color: Colors.black,
        fontSize: 12.0, // Smaller font size
      ),
    ),

    textTheme: TextTheme(
      bodyLarge: bodyLargeStyle,
      headlineLarge: headlineLargeStyle,
    ),

    listTileTheme: Theme.of(context).listTileTheme.copyWith(
          tileColor: background,
        ),

    cardTheme: Theme.of(context).cardTheme.copyWith(
          color: background,
        ),

    // alt colors
    appBarTheme: Theme.of(context).appBarTheme.copyWith(
          backgroundColor: backgroundAlt,
          foregroundColor: foregroundAlt,
        ),

    bottomNavigationBarTheme: Theme.of(context).bottomNavigationBarTheme.copyWith(
          unselectedItemColor: unselectedAlt,
          selectedItemColor: foregroundAlt,
          backgroundColor: backgroundAlt,
        ),

    tabBarTheme: Theme.of(context).tabBarTheme.copyWith(
          labelColor: foregroundAlt,
          unselectedLabelColor: unselectedAlt,
          indicator: const UnderlineTabIndicator(
              // color for indicator (underline)
              borderSide: BorderSide(width: 3, color: foregroundAlt),
              insets: EdgeInsets.all(1)),
        ),

    // others
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
*/
