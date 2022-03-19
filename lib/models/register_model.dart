import '../utilities/date.dart';

// add messages with timeStamp
class RegisterModel {
  // date = match date
  final Date _date;
  String _registerMessage = '';
  List<String> _registerMsgList = [];

  static const String _timeStampFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String _divider = '>> ';

  static String _getTimedMessage(String message) =>
      dateTimeToString(DateTime.now(), format: _timeStampFormat) + _divider + message;

  RegisterModel({
    required Date date,
    required String message,
  })  : _date = date,
        _registerMessage = _getTimedMessage(message);

  RegisterModel.date({
    required Date date,
  }) : _date = date;

  RegisterModel.list({required Date date, required List<String> registerMsgList})
      : _date = date,
        _registerMsgList = registerMsgList;

  Date get date => _date;

  String get registerMessage => _registerMessage;

  String get foldedString => _registerMsgList.fold('', (a, b) => '$a\n$b');

  List<String> get registerMsgList => _registerMsgList;

  void addMsgToList(String message) {
    _registerMsgList.add(_getTimedMessage(message));
  }

  static DateTime getRegisterTimeStamp(String text) {
    return extractDateTime(text, start: 0, format: _timeStampFormat);
  }

  static String getRegisterText(String text) {
    return text.substring(_timeStampFormat.length + _divider.length);
  }

  @override
  String toString() {
    return ('${date.toYyyyMMdd()}: $_registerMessage>');
  }
}
