import 'package:http/http.dart' as http;

import '../models/md_exception.dart';
import '../secret.dart';
import '../models/md_date.dart';
import '../models/md_debug.dart';

final String _classString = 'HttpHelper'.toUpperCase();

enum BotType { register, error }

void sendDatedMessageToTelegram({required String message, required Date matchDate}) {
  MyLog.log(_classString, 'sendDatedMessageToTelegram');
  // add date to the message
  message = '$matchDate\n$message';
  sendMessageToTelegram(message, botType: BotType.register);
}

Future<void> sendMessageToTelegram(String message, {BotType botType = BotType.register}) async {
  late String tmpBotToken;
  late String tmpChatId;

  switch (botType) {
    case BotType.register:
      tmpBotToken = getTelegramBotToken();
      tmpChatId = getTelegramChatId();
      break;
    case BotType.error:
      tmpBotToken = getTelegramErrorBotToken();
      tmpChatId = getTelegramErrorChatId();
      break;
  }

  var url = Uri.parse('https://api.telegram.org/bot$tmpBotToken/'
      'sendMessage?chat_id=$tmpChatId&text=$message');
  http.Response response = await http.post(url);

  if (response.statusCode != 200) {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    MyLog.log(_classString, 'Error al enviar el mensaje a Telegram (código=${response.statusCode})');
    throw MyException('Error al enviar el mensaje a Telegram (código=${response.statusCode})');
  }
}
