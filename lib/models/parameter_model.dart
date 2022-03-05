import '../utilities/misc.dart';
import 'debug.dart';

final String _classString = 'Parameters'.toUpperCase();

enum ParametersEnum {
  matchDaysToView,
  matchDaysKeeping,
  registerDaysAgoToView,
  registerDaysKeeping,
  minDebugLevel, // according to DebugType
  weekDaysMatch, // days where matches can be played
}

const List<String> parametersDefault = [
  '10',
  '15',
  '1',
  '15',
  '0', // according to DebugType
  'LMXJ', // days where matches can be played
];

class MyParameters {
  MyParameters() {
    MyLog().log(_classString, 'Building');
    setValue(ParametersEnum.matchDaysToView, null );
    setValue(ParametersEnum.matchDaysKeeping, null);
    setValue(ParametersEnum.registerDaysAgoToView, null);
    setValue(ParametersEnum.registerDaysKeeping, null);
    setValue(ParametersEnum.minDebugLevel, null);
    setValue(ParametersEnum.weekDaysMatch, null);
  }

  final List<String> _values =
      List.generate(ParametersEnum.values.length, (index) => '');

  static const String daysOfWeek = 'LMXJVSD';
  static final Map<int, String> _mapOfDaysWeek = {
    for (int day = DateTime.monday; day <= DateTime.sunday; day++)
      day: daysOfWeek[day - DateTime.monday],
  };

  static String dayOfTheWeekToStr(Date date) {
    return _mapOfDaysWeek[date.weekday] ?? '';
  }

  static int dayOfTheWeekToInt(String dayLabel) {
    return _mapOfDaysWeek.keys
        .firstWhere((k) => _mapOfDaysWeek[k] == dayLabel, orElse: () => 0);
  }

  static int boolToInt(bool value) => value ? 1 : 0;

  static bool intToBool(int value) => value == 0 ? false : true;

  static String boolToStr(bool value) => value ? 'true' : 'false';

  static bool strToBool(String value) => value == 'true' ? true : false;

  static String intToStr(int value) => value.toString();

  static int strToInt(String value) => int.parse(value);

  String getStrValue(ParametersEnum parameter) => _values[parameter.index];

  int getIntValue(ParametersEnum parameter) =>
      strToInt(_values[parameter.index]);

  bool getBoolValue(ParametersEnum parameter) =>
      strToBool(_values[parameter.index]);

  void setValue(ParametersEnum parameter, String? value) {
    if ( value == null) {
      _values[parameter.index] = parametersDefault[parameter.index];
    } else {
      _values[parameter.index] = value;
    }
  }

  bool isDayPlayable(Date date) {
    return getStrValue(ParametersEnum.weekDaysMatch)
        .contains(dayOfTheWeekToStr(date));
  }

  DebugType get minDebugLevel =>
      DebugType.values[getIntValue(ParametersEnum.minDebugLevel)];

  @override
  String toString() {
    return _values.toString();
  }
}
