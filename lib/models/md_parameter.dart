import 'package:simple_logger/simple_logger.dart';

import 'md_date.dart';
import '../utilities/ut_misc.dart';
import 'md_debug.dart';

/// constant to log the class name.
final String _classString = '<md> Parameters'.toLowerCase();

// parameter fields in Firestore
enum ParameterFs { parameters }

/// Type of parameter
enum ParamType { basic, scoreRanking, leagueRanking }

/// Enum representing application parameters.
enum ParametersEnum {
  // basic
  bVersion(defaultValue: '0.0', paramType: ParamType.basic),
  bDefaultRanking(defaultValue: '5000', paramType: ParamType.basic),
  bMatchDaysToView(defaultValue: '20', paramType: ParamType.basic),
  bMatchDaysKeeping(defaultValue: '15', paramType: ParamType.basic),
  bRegisterDaysAgoToView(defaultValue: '1', paramType: ParamType.basic),
  bRegisterDaysKeeping(defaultValue: '15', paramType: ParamType.basic),
  bDefaultCommentText(defaultValue: 'Comentario por defecto', paramType: ParamType.basic),
  bMinDebugLevel(defaultValue: '5', paramType: ParamType.basic),
  bWeekDaysMatch(defaultValue: 'LMJ', paramType: ParamType.basic),
  bShowLog(defaultValue: '0', paramType: ParamType.basic),
  // scoreRanking
  sStep(defaultValue: '20', paramType: ParamType.scoreRanking),
  sRange(defaultValue: '40', paramType: ParamType.scoreRanking),
  sRankingDiffToHalf(defaultValue: '1000', paramType: ParamType.scoreRanking),
  sFreePoints(defaultValue: '100', paramType: ParamType.scoreRanking),
  // leagueRanking
  // points = 1, if score difference is less than lThreshold1
  // points = 2, if score difference is between lThreshold1 and lThreshold2
  // points = 3, if score difference is greater than lThreshold2
  lThreshold1(defaultValue: '3', paramType: ParamType.leagueRanking),
  lThreshold2(defaultValue: '9', paramType: ParamType.leagueRanking),
  ;

  final String defaultValue;
  final ParamType _paramType;

  const ParametersEnum({required this.defaultValue, required ParamType paramType}) : _paramType = paramType;

  bool isRankingParameter() => _paramType == ParamType.scoreRanking;

  bool isBasicParameter() => _paramType == ParamType.basic;

  static Iterable<ParametersEnum> valuesByType(ParamType paramType) {
    return ParametersEnum.values.where((p) => p._paramType == paramType);
  }
}

/// Class to manage application parameters.
///
/// This class encapsulates the logic for storing, retrieving, and
/// manipulating application configuration parameters. It uses an enum
/// [ParametersEnum] to define the available parameters and stores their
/// values in a map.
class MyParameters {
  /// Map to store parameter values, keyed by [ParametersEnum].
  final Map<ParametersEnum, String> _values;

  /// Constant string representing days of the week.
  static const String kDaysOfWeek = 'LMXJVSD';

  /// Constructor for [MyParameters].
  ///
  /// Logs the creation of the instance if debug mode is enabled.
  MyParameters() : _values = {for (var value in ParametersEnum.values) value: value.defaultValue} {
    MyLog.log(_classString, 'Constructor', level: Level.FINE);
  }

  /// Constructor with a single parameter.
  ///
  /// Initializes a new [MyParameters] instance with values from another.
  MyParameters.fromMyParameters(MyParameters original)
      : _values = Map.from(original._values) {
    MyLog.log(_classString, 'Cloning constructor', level: Level.FINE);
  }


  /// Converts a [Date] object to a character representing the day of the week.
  ///
  /// Returns a character from [kDaysOfWeek] corresponding to the day of the week.
  static String dayCharFromDate(Date date) => kDaysOfWeek[date.weekday - DateTime.monday];

  /// Gets the string value of a parameter.
  ///
  /// Returns the string value associated with the given [parameter], or an
  /// empty string if the parameter is not found.
  String getStrValue(ParametersEnum parameter) => _values[parameter] ?? '';

  /// Gets the integer value of a parameter.
  ///
  /// Returns the integer value associated with the given [parameter], or null
  /// if the parameter is not found or the value is not a valid integer.
  int? getIntValue(ParametersEnum parameter) {
    final String value = _values[parameter]!;
    final int? intValue = int.tryParse(value);
    if (intValue == null) {
      MyLog.log(_classString, 'ERROR: ${parameter.name} = $value is not an integer', level: Level.WARNING);
      return null;
    }
    return intValue;
  }

  /// Gets the boolean value of a parameter.
  ///
  /// Returns the boolean value associated with the given [parameter], or false
  /// if the parameter is not found or the value is not a valid boolean.
  bool getBoolValue(ParametersEnum parameter) => strToBool(_values[parameter] ?? '');

  /// Sets the value of a parameter.
  ///
  /// Updates the value of the given [parameter] with the provided [value].
  void setValue(ParametersEnum parameter, String value) {
    _values[parameter] = value;
  }

  /// Checks if a day is playable based on the [bWeekDaysMatch] parameter.
  ///
  /// Returns true if the day of the week is included in the [bWeekDaysMatch]
  /// parameter, false otherwise.
  bool isDayPlayable(Date date) {
    return getStrValue(ParametersEnum.bWeekDaysMatch).contains(dayCharFromDate(date));
  }

  /// Gets the minimum debug level from the [minDebugLevel] parameter.
  ///
  /// Returns the [Level] corresponding to the [minDebugLevel] parameter, or
  Level get minDebugLevel => MyLog.int2level(
      getIntValue(ParametersEnum.bMinDebugLevel) ?? int.tryParse(ParametersEnum.bMinDebugLevel.defaultValue) ?? 1);

  /// Returns a string representation of the parameters map.
  ///
  /// Returns the string representation of the [_values] map.
  @override
  String toString() => _values.toString();

  /// Creates a [MyParameters] instance from a JSON map.
  ///
  /// Deserializes the given [json] map into a [MyParameters] instance.
  factory MyParameters.fromJson(Map<String, dynamic> json) {
    MyParameters myParameters = MyParameters();
    for (ParametersEnum value in ParametersEnum.values) {
      final String? jsonValue = json[value.name];
      if (jsonValue != null) {
        myParameters.setValue(value, jsonValue);
      }
    }
    return myParameters;
  }

  /// Converts the [MyParameters] instance to a JSON map.
  ///
  /// Serializes the [_values] map into a JSON map.
  Map<String, dynamic> toJson() => {
        for (var entry in _values.entries) entry.key.name: entry.value,
      };

  /// Creates a deep copy (clone) of this [MyParameters] instance.
  ///
  /// Returns a new instance with the exact same parameter values.
  MyParameters clone() {
    return MyParameters.fromMyParameters(this);
  }
}
