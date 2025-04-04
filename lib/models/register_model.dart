import 'package:cloud_firestore/cloud_firestore.dart';

import '../utilities/date.dart';

// register fields in firestore
enum RegisterFs { register, date, registerMessage }

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
    return ('${date.toYyyyMMdd()}:${_msgList.last}>');
  }

  factory RegisterModel.fromJson(Map<String, dynamic> json) => RegisterModel.list(
        date: Date.parse(json[RegisterFs.date.name]) ?? Date.ymd(1971),
        timedMsgList: (json[RegisterFs.registerMessage.name] ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        RegisterFs.date.name: date.toYyyyMMdd(),
        RegisterFs.registerMessage.name: FieldValue.arrayUnion(_msgList),
      };
}
