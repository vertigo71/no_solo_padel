import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../models/debug.dart';
import '../models/user_model.dart';

final String _classString = 'Miscellaneous'.toUpperCase();

ThemeData myTheme(BuildContext context) {
  return ThemeData(
    scaffoldBackgroundColor: const Color(0xC8CDBDE5),
    primarySwatch: Colors.deepPurple,
    buttonTheme: Theme.of(context).buttonTheme.copyWith(
          highlightColor: Colors.deepPurple,
        ),
    textTheme: GoogleFonts.robotoTextTheme(
      Theme.of(context).textTheme,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
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
