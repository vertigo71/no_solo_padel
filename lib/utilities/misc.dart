import 'package:diacritic/diacritic.dart';
import 'package:simple_logger/simple_logger.dart';
import 'dart:math';

import '../models/debug.dart';

final String _classString = 'Miscellaneous'.toUpperCase();

/// Generates a pseudo-random list of integers based on a given date and length.
///
/// This function produces a list of integers of length [numOfElements], where the order of
/// elements is determined by a pseudo-random sequence derived from the
/// milliseconds since epoch of the provided [dateSeed]. The generated sequence aims
/// to distribute the numbers 0 to [numOfElements] - 1 in a seemingly random order.
///
/// The process involves:
/// 1. Generating a base list using a sinusoidal function and the date's timestamp.
/// 2. Identifying numbers within the range 0 to [numOfElements] - 1 that are missing from the base list.
/// 3. Inserting the missing numbers into the base list at positions determined by
///    the existing elements in the base list, or at the beginning if the position
///    is out of bounds.
///
/// The use of the date's timestamp as a seed allows for reproducible sequences
/// given the same date, while providing different sequences for different dates.
///
/// [num]: The desired length of the generated list.
/// [date]: The date used to generate the pseudo-random sequence.
///
/// Returns: A list of integers of length [numOfElements] in a pseudo-random order.
///
List<int> getRandomList(int numOfElements, DateTime dateSeed) {
  MyLog.log(_classString, 'getRandomList', level: Level.ALL);
  int baseNum = dateSeed.millisecondsSinceEpoch;
  List<int> base =
      List<int>.generate(numOfElements, (index) => (baseNum * sin(baseNum + index)).floor() % numOfElements)
          .toSet()
          .toList();
  MyLog.log(_classString, 'getRandomList Base Sinus generated list $base', indent: true, level: Level.ALL);

  List<int> all = List<int>.generate(numOfElements, (int index) => numOfElements - index - 1);
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

/// return a String formed with the number and the according adverb
/// number = 1, singular = match, plural = matches => 1 match
/// number = 2, singular = car, plural = null => 2 cars
String singularOrPlural(int number, String singular, [String? plural]) {
  if (number == 1) return '1 $singular';
  return '$number ${plural ?? singular + (singular.toUpperCase() == singular ? 'S' : 's')}';
}

int boolToInt(bool value) => value ? 1 : 0;

bool intToBool(int value) => value == 0 ? false : true;

String boolToStr(bool value) => value.toString();

/// true if value != 0 or is 'true'
bool strToBool(String value) {
  int? intValue = int.tryParse(value);
  if (intValue != null) return intValue != 0;
  if (value == 'true') return true;
  return false;
}

String lowCaseNoDiacritics(String str) => removeDiacritics(str.toLowerCase());

