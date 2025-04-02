import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:getwidget/getwidget.dart';

import '../models/debug.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import 'app_colors.dart';

final String _classString = 'UiHelper'.toUpperCase();

class UiHelper {
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

  static Widget userInfoTile(MyUser user, [Function? onPressed]) {
    final String sosInfo = user.emergencyInfo.isNotEmpty ? 'SOS: ${user.emergencyInfo}\n' : '';

    ImageProvider<Object>? imageProvider;
    try {
      if (user.avatarUrl != null) {
        imageProvider = NetworkImage(user.avatarUrl!);
      }
    } catch (e) {
      MyLog.log(_classString, 'Error building image for user $user', level: Level.WARNING, indent: true);
      imageProvider = null;
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.blueAccent,
        backgroundImage: imageProvider,
        child: imageProvider == null ? Text('?', style: TextStyle(fontSize: 24, color: Colors.white)) : null,
      ),
      isThreeLine: true,
      title: Text(user.name),
      subtitle: Text('${sosInfo}Usuario: ${user.email.split('@')[0]}\n'
          'Ranking: ${user.rankingPos}'),
      trailing: Text('${user.userType.displayName}\n'
          'Login: ${user.loginCount} veces\n'
          '${user.lastLogin?.toMask(mask: 'dd/MM/yy') ?? ''}'),
      onTap: () {
        if (onPressed != null) onPressed();
      },
    );
  }

  static void myAlertDialog(BuildContext context, String text, {Function? onDialogClosed}) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('¡Atención!'),
          content: Text(text),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cerrar'),
              onPressed: () {
                context.pop();
                if (onDialogClosed != null) {
                  onDialogClosed(); // Call the optional callback function
                }
              },
            ),
          ],
        ),
      );
    }
  }

  static Future<String> myReturnValueDialog(BuildContext context, String text, String option1, String option2,
      {String option3 = '', String option4 = ''}) async {
    if (context.mounted) {
      dynamic response = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: const Text('¡Atención!'),
                content: Text(text),
                actionsPadding: const EdgeInsets.all(10.0),
                actions: <Widget>[
                  ElevatedButton(
                      child: Text(option1),
                      onPressed: () {
                        Navigator.pop(context, option1);
                      }),
                  ElevatedButton(
                      child: Text(option2),
                      onPressed: () {
                        Navigator.pop(context, option2);
                      }),
                  if (option3.isNotEmpty)
                    ElevatedButton(
                        child: Text(option3),
                        onPressed: () {
                          Navigator.pop(context, option3);
                        }),
                  if (option4.isNotEmpty)
                    ElevatedButton(
                        child: Text(option4),
                        onPressed: () {
                          Navigator.pop(context, option4);
                        }),
                ],
              ));
      if (response is String) {
        return response;
      } else {
        return '';
      }
    }
    return '';
  }

  static void showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, style: const TextStyle(fontSize: 16))));
  }

  static Widget myCheckBox(
      {required BuildContext context, required void Function(bool?) onChanged, required bool value}) {
    return GFCheckbox(
      onChanged: onChanged,
      value: value,
      size: GFSize.SMALL,
      type: GFCheckboxType.circle,
      activeBgColor: Theme.of(context).primaryColor,
      inactiveBgColor: Theme.of(context).colorScheme.surface,
    );
  }

  static Color getMatchColor(MyMatch match) {
    switch (match.isOpen) {
      case true:
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  static Color getPlayingStateColor(BuildContext context, PlayingState playingState) {
    switch (playingState) {
      case PlayingState.unsigned:
        return Theme.of(context).listTileTheme.tileColor ?? Theme.of(context).colorScheme.surface;
      case PlayingState.playing:
      case PlayingState.signedNotPlaying:
      case PlayingState.reserve:
        return darken(Theme.of(context).canvasColor, .2);
    }
  }

  static Color getUserColor(MyUser user) {
    switch (user.userType) {
      case UserType.admin:
        return Colors.green;
      case UserType.superuser:
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  static Color darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}

/// TextFormField uppercase formatter: allow = false => deny list
class UpperCaseTextFormatter extends CaseTextFormatter {
  UpperCaseTextFormatter(super.filterPattern, {required super.allow, super.replacementString})
      : super(toUppercase: true);
}

/// TextFormField lowercase formatter: allow = false => deny list
class LowerCaseTextFormatter extends CaseTextFormatter {
  LowerCaseTextFormatter(super.filterPattern, {required super.allow, super.replacementString})
      : super(toUppercase: false);
}

/// TextFormField uppercase/lowercase formatter: allow = false => deny list
class CaseTextFormatter extends FilteringTextInputFormatter {
  CaseTextFormatter(super.filterPattern, {required this.toUppercase, required super.allow, super.replacementString});

  final bool toUppercase;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    TextEditingValue value = super.formatEditUpdate(oldValue, newValue);
    return TextEditingValue(
      text: toUppercase ? value.text.toUpperCase() : value.text.toLowerCase(),
      selection: value.selection,
    );
  }
}
