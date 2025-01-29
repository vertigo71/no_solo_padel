import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';

// ignore: unused_element
final String _classString = 'Theme'.toUpperCase();

ThemeData myTheme(BuildContext context) {
  // alternative colors
  final Color _backgroundAlt = Colors.deepOrange[300]!;
  const Color _foregroundAlt = Colors.black;
  const Color _unselectedAlt = Colors.black54;

  // main colors
  const MaterialColor _primaryMaterial = Colors.deepPurple;
  final Color _background = Colors.deepPurple[200]!;
  final Color _backgroundLight = Colors.deepPurple[100]!;

  return ThemeData(
    scaffoldBackgroundColor: _backgroundLight,
    // canvasColor
    colorScheme: ColorScheme.light(
      surface: _background, // Use surface instead of background
    ),

    primarySwatch: _primaryMaterial,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: _primaryMaterial),
    ),
    textTheme: GoogleFonts.robotoTextTheme(
      Theme.of(context).textTheme,
    ),
    listTileTheme: Theme.of(context).listTileTheme.copyWith(
          tileColor: _background,
        ),
    cardTheme: Theme.of(context).cardTheme.copyWith(
          color: _background,
        ),
    // alt colors
    appBarTheme: Theme.of(context).appBarTheme.copyWith(
          backgroundColor: _backgroundAlt,
          foregroundColor: _foregroundAlt,
        ),
    bottomNavigationBarTheme: Theme.of(context).bottomNavigationBarTheme.copyWith(
          unselectedItemColor: _unselectedAlt,
          selectedItemColor: _foregroundAlt,
          backgroundColor: _backgroundAlt,
        ),
    tabBarTheme: Theme.of(context).tabBarTheme.copyWith(
          labelColor: _foregroundAlt,
          unselectedLabelColor: _unselectedAlt,
          indicator: const UnderlineTabIndicator(
              // color for indicator (underline)
              borderSide: BorderSide(width: 3, color: _foregroundAlt),
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
