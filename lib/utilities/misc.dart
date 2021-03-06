import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/getwidget.dart';
import 'dart:math';

import '../models/debug.dart';
import 'theme.dart';

final String _classString = 'Miscellaneous'.toUpperCase();

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

/// TextFormField uppercase formatter: allow = false => deny list
class UpperCaseTextFormatter extends CaseTextFormatter {
  UpperCaseTextFormatter(Pattern filterPattern,
      {required bool allow, String replacementString = ''})
      : super(filterPattern, toUppercase: true, allow: allow, replacementString: replacementString);
}

/// TextFormField lowercase formatter: allow = false => deny list
class LowerCaseTextFormatter extends CaseTextFormatter {
  LowerCaseTextFormatter(Pattern filterPattern,
      {required bool allow, String replacementString = ''})
      : super(filterPattern,
            toUppercase: false, allow: allow, replacementString: replacementString);
}

/// TextFormField uppercase/lowercase formatter: allow = false => deny list
class CaseTextFormatter extends FilteringTextInputFormatter {
  CaseTextFormatter(Pattern filterPattern,
      {required this.toUppercase, required bool allow, String replacementString = ''})
      : super(filterPattern, allow: allow, replacementString: replacementString);

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

/// 'date random' list from 0 to num-1
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

Widget myCheckBox(
    {required BuildContext context, required void Function(bool?) onChanged, required bool value}) {
  return GFCheckbox(
    onChanged: onChanged,
    value: value,
    size: GFSize.SMALL,
    type: GFCheckboxType.circle,
    activeBgColor: darken(Theme.of(context).backgroundColor, 0.3),
    inactiveBgColor: Theme.of(context).backgroundColor,
  );
}

/// return a String formed with the number and the according adverb
/// number = 1, singular = match, plural = matches => 1 match
/// number = 2, singular = car, plural = null => 2 cars
String singularOrPlural(int number, String singular, [String? plural]) {
  if (number == 1) return '1 $singular';
  return '$number ' + (plural ?? singular + (singular.toUpperCase() == singular ? 'S' : 's'));
}
