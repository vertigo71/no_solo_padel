import 'package:no_solo_padel_dev/database/fields.dart';

import '../utilities/date.dart';

// add messages with timeStamp
class RegisterModel {
  // date = match date
  Date date;
  final List<String> _msgList = [];

  static const String _timeStampFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String _divider = '>> ';

  static String _getTimedMessage(String message) =>
      dateTimeToString(DateTime.now(), format: _timeStampFormat) + _divider + message;

  RegisterModel({required this.date, String? message}) {
    if (message != null) _msgList.add(_getTimedMessage(message));
  }

  RegisterModel.list({required this.date, required List<String> timedMsgList}) {
    _msgList.addAll(timedMsgList);
  }

  String get foldedString => _msgList.fold('', (a, b) => '$a\n$b');

  List<String> get msgList => _msgList;

  void addMsg(String message) {
    _msgList.add(_getTimedMessage(message));
  }

  static DateTime getRegisterTimeStamp(String text) {
    return extractDateTime(text, start: 0, format: _timeStampFormat);
  }

  static String getRegisterText(String text) {
    return text.substring(_timeStampFormat.length + _divider.length);
  }

  @override
  String toString() {
    return ('${date.toYyyyMMdd()}: ${_msgList.last}>');
  }

  static RegisterModel fromJson(Map<String, dynamic> json) => RegisterModel.list(
        date: Date.parse(json[DBFields.date.name]) ?? Date.ymd(1971),
        timedMsgList: json[DBFields.registerMessage.name] ?? [],
      );

  Map<String, dynamic> toJson() => {
        DBFields.date.name: date,
        DBFields.registerMessage.name: _msgList,
      };
}
