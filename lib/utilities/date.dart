

import 'package:intl/intl.dart';

// ignore: unused_element
final String _classString = 'Date'.toUpperCase();


class Date extends DateTime {
  Date(DateTime dateTime) : super(dateTime.year, dateTime.month, dateTime.day);

  Date.ymd(super.year, [super.month, super.day]);

  static Date dateTimeToDate(DateTime dateTime) => Date(dateTime);

  static Date now() => dateTimeToDate(DateTime.now());

  static Date? parse(String? formattedString ) {
    try {
      return Date(DateTime.parse(formattedString!));
    } catch (_) {
      return null;
    }
  }

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
