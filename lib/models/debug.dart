import 'dart:developer' as developer;

import '../utilities/date.dart';
import '../utilities/environment.dart';
import '../utilities/http_helper.dart';

enum DebugType { basic, info, summary, error }

// singleton
class MyLog {
  static final MyLog _singleton = MyLog._internal();

  MyLog._internal();

  factory MyLog() => _singleton;

  final List<String> _logMsgList = [];

  static DebugType minDebugType = DebugType.basic; // minimum log to register

  static String loggedUserName = '';
  static String loggedUserEmail = '';

  void _addLog(String heading, String value,
      {String myCustomObject = '', String exception = '', DebugType debugType = DebugType.basic}) {
    List<String> list = [];

    if (debugType.index >= MyLog.minDebugType.index) {
      if (debugType == DebugType.error) {
        list.add('[$heading] *************** ERROR *************************************');
      }

      list.add('[$heading] $value');

      if (myCustomObject.isNotEmpty) {
        list.add('>>'.padRight(heading.length) + myCustomObject);
      }
      if (exception.isNotEmpty) {
        list.add('>>'.padRight(heading.length) + 'Exception: $exception');
      }

      _logMsgList.addAll(list);
    }
  }

  List<String> get logMsgList => _logMsgList;

  void get delete => _logMsgList.clear();

  void _log(String message, {required String name, Object? error}) {
    developer.log(message,
        name: dateTimeToString(DateTime.now(), format: 'mm:ss ') + name, error: error);
    // print( "[$name] $message $error");
  }

  void log(String heading, dynamic message,
      {dynamic myCustomObject, dynamic exception, DebugType debugType = DebugType.basic}) {
    if (debugType.index >= MyLog.minDebugType.index) {
      if (debugType == DebugType.error) {
        _log(
          '\n******************'
          '\n****         *****'
          '\n****  ERROR  *****'
          '\n****         *****'
          '\n******************',
          name: heading,
        );
        if (Environment().isProduction) sendErrorEmail(heading, message);
      }

      _log(message, name: heading);

      if (exception != null) _log(exception.toString(), name: heading, error: exception);

      if (myCustomObject != null) {
        if (myCustomObject is List) {
          for (var item in myCustomObject) {
            _log(''.padLeft(heading.length + 2) + item.toString(), name: '>');
          }
        } else if (myCustomObject is Map) {
          myCustomObject.forEach((k, v) => _log(
              ''.padLeft(heading.length + 2) + '[${k.toString()}]: ${v.toString()}',
              name: '>'));
        } else {
          _log(''.padLeft(heading.length + 2) + myCustomObject.toString(), name: '>');
        }
      }

      _addLog(heading, message,
          myCustomObject: myCustomObject?.toString() ?? '',
          exception: exception?.toString() ?? '',
          debugType: debugType);
    }
  }

  void sendErrorEmail(String heading, dynamic message,
      {dynamic myCustomObject, dynamic exception}) {
    String errorMsg = message.toString();
    if (exception != null) errorMsg += '\n${exception.toString()}';
    if (myCustomObject != null) errorMsg += '\n${myCustomObject.toString()}';
    String emailMessage = errorMsg.replaceAll('\n', '<br>');
    String stack = StackTrace.current.toString().split('\n').take(10).join('<br>');
    emailMessage += '<br>STACK<br>$stack';
    sendEmail(name: loggedUserName, email: loggedUserEmail, message: emailMessage);
  }
}
