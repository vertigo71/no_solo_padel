import 'dart:developer' as developer;

enum DebugType { basic, info, summary, error }

// singleton
class MyLog {
  static final MyLog _singleton = MyLog._internal();

  MyLog._internal();

  factory MyLog() => _singleton;

  final List<String> _logMsgList = [];

  static DebugType minDebugType = DebugType.basic; // minimum log to register

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

  void _log(String message, { required String name, Object? error}) {
    developer.log( message, name: name, error: error );
    // print( "[$name] $message $error");
  }

  void log(String heading, dynamic value,
      {dynamic myCustomObject, dynamic exception, DebugType debugType = DebugType.basic}) {
    if (debugType.index >= MyLog.minDebugType.index) {
      _log(value, name: heading, error: exception);

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

      _addLog(heading, value,
          myCustomObject: myCustomObject?.toString() ?? '',
          exception: exception?.toString() ?? '',
          debugType: debugType);
    }
  }
}
