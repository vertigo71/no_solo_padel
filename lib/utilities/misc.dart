import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:math';

import '../models/debug.dart';
import '../models/user_model.dart';

final String _classString = 'Miscellaneous'.toUpperCase();

ThemeData myTheme(BuildContext context) {
  // alternative colors
  final Color _backgroundAlt = Colors.deepOrange[400]!;
  const Color _foregroundAlt = Colors.black;
  const Color _unselectedAlt = Colors.black54;

  // main colors
  const MaterialColor _primaryMaterial = Colors.deepPurple;
  final Color _background = Colors.deepPurple[200]!;
  final Color _backgroundLight = Colors.deepPurple[100]!;

  return ThemeData(
    scaffoldBackgroundColor: _backgroundLight,
    // canvasColor
    backgroundColor: _background,

    primarySwatch: _primaryMaterial,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(primary: _primaryMaterial),
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

class Environment {
  static final Environment _singleton = Environment._internal();

  Environment._internal();

  factory Environment() => _singleton;

  bool _isProduction = false;
  bool _initialized = false;
  PackageInfo? _packageInfo;
  String _appName = '';

  Future<void> initialize() async {
    if (!_initialized) {
      _packageInfo = await PackageInfo.fromPlatform();
      assert(_packageInfo != null);
      _appName = _packageInfo!.appName;
      if (_appName.contains('_dev')) {
        _isProduction = false;
        MyLog().log(_classString, 'Development environment initialized');
      } else {
        _isProduction = true;
        MyLog().log(_classString, 'Production environment initialized');
      }
      _initialized = true;
    }
  }

  PackageInfo get packageInfo {
    assert(_initialized);
    return _packageInfo!;
  }

  bool get isProduction {
    assert(_initialized);
    return _isProduction;
  }

  bool get isDevelopment {
    assert(_initialized);
    return !_isProduction;
  }

  bool get isInitialized => _initialized;
}

class Date extends DateTime {
  Date(DateTime dateTime) : super(dateTime.year, dateTime.month, dateTime.day);

  Date.ymd(int year, [int month = 1, int day = 1]) : super(year, month, day);

  static Date dateTimeToDate(DateTime dateTime) => Date(dateTime);

  static Date now() => dateTimeToDate(DateTime.now());

  @override
  Date add(Duration duration) => Date(super.add(duration));

  @override
  Date subtract(Duration duration) => Date(super.subtract(duration));

  @override
  String toString() {
    return DateFormat('EEEE, d-MMMM', 'es_ES').format(this);
  }

  String toYyyyMMdd() {
    return DateFormat('yyyyMMdd', 'es_ES').format(this);
  }

  String toMask({String mask = 'yyyyMMdd'}) {
    return DateFormat(mask, 'es_ES').format(this);
  }
}

String dateTimeToString(DateTime date, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
  return DateFormat(format, 'es_ES').format(date);
}

DateTime extractDateTime(String string, {int start = 0, String format = 'yyyy-MM-dd HH:mm:ss'}) {
  return DateTime.parse(string.substring(start, format.length));
}

void myAlertDialog(BuildContext context, String text) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.background,
            title: const Text('¡Atención!'),
            content: Text(text),
            actions: <Widget>[
              ElevatedButton(
                  child: const Text('Cerrar'),
                  onPressed: () {
                    Navigator.pop(context);
                  })
            ],
          ));
}

Future<String> myReturnValueDialog(
    BuildContext context, String text, String option1, String option2,
    {String option3 = '', String option4 = ''}) async {
  dynamic response = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.background,
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

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
    text,
    style: const TextStyle(fontSize: 16),
  )));
}

// TextFormField uppercase formatter
// allow = false => deny list
class UpperCaseTextFormatter extends FilteringTextInputFormatter {
  UpperCaseTextFormatter(Pattern filterPattern,
      {required bool allow, String replacementString = ''})
      : super(filterPattern, allow: allow, replacementString: replacementString);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    TextEditingValue value = super.formatEditUpdate(oldValue, newValue);
    return TextEditingValue(
      text: value.text.toUpperCase(),
      selection: value.selection,
    );
  }
}

// 'date random' list from 0 to num-1
List<int> getRandomList(int num, DateTime date) {
  int baseNum = date.millisecondsSinceEpoch;
  List<int> base =
      List<int>.generate(num, (index) => (baseNum * sin(baseNum + index)).floor() % num)
          .toSet()
          .toList();
  MyLog().log(_classString, 'getRandomList Base Sinus generated list $base');
  List<int> all = List<int>.generate(num, (int index) => num - index - 1);
  List<int> diff = all.where((element) => !base.contains(element)).toList();
  MyLog().log(_classString, 'getRandomList Missing numbers list $diff');
  // add missing numbers
  for (int i = 0; i < diff.length; i++) {
    if (base[i] <= base.length) {
      base.insert(base[i], diff[i]);
    } else {
      base.insert(0, diff[i]);
    }
  }
  MyLog().log(_classString, 'getRandomList Final order $base');

  return base;
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

GFToggle myGFToggle(
    {required BuildContext context, required void Function(bool?) onChanged, required bool value}) {
  return GFToggle(
    onChanged: onChanged,
    value: value,
    type: GFToggleType.ios,
    enabledTrackColor: darken(Theme.of(context).backgroundColor, 0.3),
  );
}
