import 'package:cloud_firestore/cloud_firestore.dart';

import 'md_date.dart';

// register fields in firestore
enum RegisterFs { register, date, registerMessage }

// add messages with timeStamp
class RegisterModel {
  // date = match date
  Date date;
  final List<String> _msgList = [];

  static const String _kTimeStampFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String _kDivider = '>> ';

  static String _getTimedMessage(String message) =>
      dateTimeToString(DateTime.now(), format: _kTimeStampFormat) + _kDivider + message;

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
    return extractDateTime(text, start: 0, format: _kTimeStampFormat);
  }

  static String getRegisterText(String text) {
    return text.substring(_kTimeStampFormat.length + _kDivider.length);
  }

  @override
  String toString() {
    return ('${date.toYyyyMmDd()}:${_msgList.last}>');
  }

  factory RegisterModel.fromJson(Map<String, dynamic> json) => RegisterModel.list(
        date: Date.parse(json[RegisterFs.date.name]) ?? Date.ymd(1971),
        timedMsgList: (json[RegisterFs.registerMessage.name] ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        RegisterFs.date.name: date.toYyyyMmDd(),
        RegisterFs.registerMessage.name: FieldValue.arrayUnion(_msgList),
      };
}
