import 'package:simple_logger/simple_logger.dart';

import '../utilities/date.dart';
import '../utilities/misc.dart';
import 'debug.dart';

/// constant to log the class name.
final String _classString = '<md> Parameters'.toLowerCase();

// parameter fields in Firestore
enum ParameterFs { parameters }

/// Enum representing available application parameters.
enum ParametersEnum {
  matchDaysToView(defaultValue: '10'), // Number of days to view matches.
  matchDaysKeeping(defaultValue: '15'), // Number of days to keep match history.
  registerDaysAgoToView(defaultValue: '1'), // Number of days ago to view registration data.
  registerDaysKeeping(defaultValue: '15'), // Number of days to keep registration history.
  fromDaysAgoToTelegram(defaultValue: '2'), // Number of days before a match to send a Telegram notification.
  defaultCommentText(defaultValue: 'Introducir comentario por defecto'), // Default comment text.
  minDebugLevel(defaultValue: '1'), // Minimum debug level.
  weekDaysMatch(defaultValue: 'LMXJ'), // Days of the week when matches can be played.
  showLog(defaultValue: '0'), // Flag to show log to all users.
  ;

  /// Default value for the parameter.
  final String defaultValue;

  /// Constructor to initialize the enum value with a default value.
  const ParametersEnum({required this.defaultValue});
}

/// Class to manage application parameters.
///
/// This class encapsulates the logic for storing, retrieving, and
/// manipulating application configuration parameters. It uses an enum
/// [ParametersEnum] to define the available parameters and stores their
/// values in a map.
class MyParameters {
  /// Map to store parameter values, keyed by [ParametersEnum].
  final Map<ParametersEnum, String> _values = {for (var value in ParametersEnum.values) value: value.defaultValue};

  /// Constant string representing days of the week.
  static const String daysOfWeek = 'LMXJVSD';

  /// Constructor for [MyParameters].
  ///
  /// Logs the creation of the instance if debug mode is enabled.
  MyParameters() {
    MyLog.log(_classString, 'Constructor');
  }

  /// Converts a [Date] object to a character representing the day of the week.
  ///
  /// Returns a character from [daysOfWeek] corresponding to the day of the week.
  static String dayCharFromDate(Date date) => daysOfWeek[date.weekday - DateTime.monday];

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

  /// Checks if a day is playable based on the [weekDaysMatch] parameter.
  ///
  /// Returns true if the day of the week is included in the [weekDaysMatch]
  /// parameter, false otherwise.
  bool isDayPlayable(Date date) {
    return getStrValue(ParametersEnum.weekDaysMatch).contains(dayCharFromDate(date));
  }

  /// Gets the minimum debug level from the [minDebugLevel] parameter.
  ///
  /// Returns the [Level] corresponding to the [minDebugLevel] parameter, or
  /// [Level.INFO] if the parameter is not found or the value is invalid.
  Level get minDebugLevel => MyLog.int2level(getIntValue(ParametersEnum.minDebugLevel) ?? 1);

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
}
