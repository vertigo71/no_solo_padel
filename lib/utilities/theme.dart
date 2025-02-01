import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';

// ignore: unused_element
final String _classString = 'Theme'.toUpperCase();

ThemeData myTheme(BuildContext context) {
  // alternative colors
  final Color backgroundAlt = Colors.deepOrange[300]!;
  const Color foregroundAlt = Colors.black;
  const Color unselectedAlt = Colors.black54;

  // main colors
  const MaterialColor primaryMaterial = Colors.deepPurple;
  final Color background = Colors.deepPurple[200]!;
  final Color backgroundLight = Colors.deepPurple[100]!;

  return ThemeData(
    scaffoldBackgroundColor: backgroundLight,
    // canvasColor
    colorScheme: ColorScheme.light(
      surface: background, // Use surface instead of background
    ),

    primarySwatch: primaryMaterial,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: primaryMaterial),
    ),
    textTheme: GoogleFonts.robotoTextTheme(
      Theme.of(context).textTheme,
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

Color getUserColor(MyUser user) {
  switch (user.userType) {
    case UserType.admin:
      return Colors.green;
    case UserType.superuser:
      return Colors.blue;
    default:
      return Colors.red;
  }
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}
