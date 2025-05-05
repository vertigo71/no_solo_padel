import 'package:simple_logger/simple_logger.dart';

class MyException implements Exception {
  final List<String> messages = [];
  Exception? exception;
  Level level;

  MyException(String message, {Object? e, this.level = Level.INFO}) {
    messages.add(message);
    if (e != null) {
      if (e is MyException) {
        messages.addAll(e.messages);
        exception = e.exception;
        if (e.level.value > level.value) level = e.level;
      } else if (e is Exception) {
        exception = e;
      } else {
        messages.add(e.toString());
      }
    }
  }

  @override
  String toString() {
    String returnString = '';
    for (String message in messages) {
      returnString += '$message\n';
    }
    if (exception != null) {
      if (level.value >= Level.SEVERE.value) {
        returnString += 'ERROR GRAVE:${exception.toString()}';
      } else {
        returnString += 'ERROR=${exception.toString()}';
      }
    }
    return returnString;
  }
}
