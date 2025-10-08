import 'package:intl/intl.dart';

// ignore: unused_element
final String _classString = 'Date'.toUpperCase();

class Date extends DateTime {
  Date(DateTime dateTime) : super(dateTime.year, dateTime.month, dateTime.day);

  Date.ymd(super.year, [super.month, super.day]);

  static Date dateTimeToDate(DateTime dateTime) => Date(dateTime);

  static Date now() => dateTimeToDate(DateTime.now());

  static Date? parse(String? formattedString) {
    try {
      return Date(DateTime.parse(formattedString!));
    } catch (_) {
      return null;
    }
  }

  /// Adds a number of whole calendar days, ignoring time zone or DST changes.
  ///
  /// This performs pure date arithmetic: adding 1 day to March 30 yields
  /// March 31, even if a daylight-saving transition occurs in between.
  Date addDays(int days) => Date(DateTime(year, month, day + days));

  /// Subtracts a number of whole calendar days, ignoring time zone or DST changes.
  ///
  /// This performs pure date arithmetic unaffected by daylight-saving shifts.
  Date subtractDays(int days) => Date(DateTime(year, month, day - days));

  /// Adds a [Duration] to this date using [DateTime.add].
  ///
  /// ⚠️ Be aware: when using local time, adding 24 hours across a
  /// daylight-saving boundary may *not* advance the calendar date by one day.
  /// For example, adding `Duration(hours: 24)` to a date within a DST change
  /// can yield the same day or skip two days depending on the transition.
  @override
  Date add(Duration duration) => Date(super.add(duration));

  /// Subtracts a [Duration] from this date using [DateTime.subtract].
  ///
  /// ⚠️ Note: similar to [add], subtracting 24 hours across a DST transition
  /// can shift the resulting local time by one hour, leading to an unexpected
  /// calendar date difference.
  @override
  Date subtract(Duration duration) => Date(super.subtract(duration));

  @override
  String toString() {
    return DateFormat('EEEE, d-MMMM', 'es_ES').format(this);
  }

  String toYyyyMmDd() {
    return DateFormat('yyyyMMdd', 'es_ES').format(this);
  }

  String toMask({String mask = 'yyyyMMdd'}) {
    return DateFormat(mask, 'es_ES').format(this);
  }

  String longFormat() => toMask(mask: 'EEEE, d \'de\' MMMM \'de\' yyyy');
}

String dateTimeToString(DateTime date, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
  return DateFormat(format, 'es_ES').format(date);
}

DateTime extractDateTime(String string, {int start = 0, String format = 'yyyy-MM-dd HH:mm:ss'}) {
  return DateTime.parse(string.substring(start, format.length));
}
