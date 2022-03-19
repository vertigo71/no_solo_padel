import '../utilities/misc.dart';
import 'debug.dart';

final String _classString = 'Parameters'.toUpperCase();

enum ParametersEnum {
  matchDaysToView,
  matchDaysKeeping,
  registerDaysAgoToView,
  registerDaysKeeping,
  fromDaysAgoToTelegram,
  defaultCommentText,
  minDebugLevel, // according to DebugType
  weekDaysMatch, // days where matches can be played
  showLog, // show log for all users (bool)
}

const List<String> parametersDefault = [
  '10', // matchDaysToView
  '15', // matchDaysKeeping
  '1', // registerDaysAgoToView
  '15', // registerDaysKeeping
  '2', // fromDaysAgoToTelegram
  'Introducir comentario por defecto', //defaultCommentText
  '0', // according to DebugType, minDebugLevel
  'LMXJ', // weekDaysMatch
  '0', //showLog
];

class MyParameters {
  final List<String> _values =
      List.generate(ParametersEnum.values.length, (index) => parametersDefault[index]);

  static const String daysOfWeek = 'LMXJVSD';

  static String dayOfTheWeekToStr(Date date) => daysOfWeek[date.weekday - DateTime.monday];

  static int boolToInt(bool value) => value ? 1 : 0;

  static bool intToBool(int value) => value == 0 ? false : true;

  static String boolToStr(bool value) => value ? 'true' : 'false';

  /// true if value > 0 or is 'true'
  static bool strToBool(String value) {
    int? intValue = int.tryParse(value);
    if (intValue != null) return intValue > 0;
    if (value == 'true') return true;
    return false;
  }

  static String intToStr(int value) => value.toString();

  String getStrValue(ParametersEnum parameter) => _values[parameter.index];

  int getIntValue(ParametersEnum parameter) {
    int? intValue = int.tryParse(_values[parameter.index]);
    if (intValue != null) return intValue;
    MyLog()
        .log(_classString, 'ERROR: value $parameter is not an integer', debugType: DebugType.error);
    return -1;
  }

  bool getBoolValue(ParametersEnum parameter) => strToBool(_values[parameter.index]);

  void setValue(ParametersEnum parameter, String? value) {
    if (value == null) {
      _values[parameter.index] = parametersDefault[parameter.index];
    } else {
      _values[parameter.index] = value;
    }
  }

  bool isDayPlayable(Date date) {
    return getStrValue(ParametersEnum.weekDaysMatch).contains(dayOfTheWeekToStr(date));
  }

  DebugType get minDebugLevel => DebugType.values[getIntValue(ParametersEnum.minDebugLevel)];

  @override
  String toString() {
    return _values.toString();
  }

  static MyParameters fromJson(Map<String, dynamic> json) {
    MyParameters myParameters = MyParameters();
    for (ParametersEnum value in ParametersEnum.values) {
      myParameters.setValue(value, json[value.name]);
    }
    return myParameters;
  }

  Map<String, dynamic> toJson() => {
        for (ParametersEnum value in ParametersEnum.values) value.name: getStrValue(value),
      };
}
