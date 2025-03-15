import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/getwidget.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_logger/simple_logger.dart';
import 'dart:math';

import '../models/debug.dart';

final String _classString = 'Miscellaneous'.toUpperCase();

void myAlertDialog(BuildContext context, String text, {Function? onDialogClosed}) {
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

Future<String> myReturnValueDialog(BuildContext context, String text, String option1, String option2,
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

void showMessage(BuildContext context, String text) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
      text,
      style: const TextStyle(fontSize: 16),
    )));
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

/// 'date random' list from 0 to num-1
List<int> getRandomList(int num, DateTime date) {
  MyLog.log(_classString, 'getRandomList', level: Level.ALL);
  int baseNum = date.millisecondsSinceEpoch;
  List<int> base = List<int>.generate(num, (index) => (baseNum * sin(baseNum + index)).floor() % num).toSet().toList();
  MyLog.log(_classString, 'getRandomList Base Sinus generated list $base', indent: true, level: Level.ALL);

  List<int> all = List<int>.generate(num, (int index) => num - index - 1);
  List<int> diff = all.where((element) => !base.contains(element)).toList();
  MyLog.log(_classString, 'getRandomList Missing numbers list $diff', indent: true, level: Level.ALL);

  // add missing numbers
  for (int i = 0; i < diff.length; i++) {
    if (base[i] <= base.length) {
      base.insert(base[i], diff[i]);
    } else {
      base.insert(0, diff[i]);
    }
  }
  MyLog.log(_classString, 'getRandomList Final order $base', indent: true, level: Level.ALL);

  return base;
}

Widget myCheckBox({required BuildContext context, required void Function(bool?) onChanged, required bool value}) {
  return GFCheckbox(
    onChanged: onChanged,
    value: value,
    size: GFSize.SMALL,
    type: GFCheckboxType.circle,
    activeBgColor: Theme.of(context).primaryColor,
    inactiveBgColor: Theme.of(context).colorScheme.surface,
  );
}

/// return a String formed with the number and the according adverb
/// number = 1, singular = match, plural = matches => 1 match
/// number = 2, singular = car, plural = null => 2 cars
String singularOrPlural(int number, String singular, [String? plural]) {
  if (number == 1) return '1 $singular';
  return '$number ${plural ?? singular + (singular.toUpperCase() == singular ? 'S' : 's')}';
}
