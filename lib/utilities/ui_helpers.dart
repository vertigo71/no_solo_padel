import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/debug.dart';
import '../models/user_model.dart';
import 'app_colors.dart';

final String _classString = 'UiHelper'.toUpperCase();

class UiHelpers {
  /// BottomNavigationBarItem: set a background color over the selected option
  static BottomNavigationBarItem buildNavItem(int index, Widget icon, String label, int selectedIndex) {
    MyLog.log(_classString, 'BottomNavigationBarItem', level: Level.ALL);

    final isSelected = selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected ? primaryMedium : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: icon,
      ),
      label: label,
    );
  }
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
