import 'package:http/http.dart' as http;

import '../models/debug.dart';
import '../secret.dart';
import 'date.dart';

final String _classString = 'HttpHelper'.toUpperCase();
enum BotType { register, log, error}

void sendDatedMessageToTelegram(
    {required String message, required Date matchDate, int? fromDaysAgoToTelegram}) {
  if (fromDaysAgoToTelegram != null) {
    if (fromDaysAgoToTelegram < 0) {
      throw Exception('Periodo para mandar un telegram tiene que ser positivo');
    }
    Date minDate = matchDate.subtract(Duration(days: fromDaysAgoToTelegram));
    MyLog().log(_classString, 'days ago = $fromDaysAgoToTelegram, minDate = $minDate');

    if (Date.now().isBefore(minDate)) return;
  }

  // add date to the message
  message = '$matchDate\n$message';
  sendMessageToTelegram(message, botType: BotType.register );
}

Future<void> sendMessageToTelegram(String message , { BotType botType = BotType.register }) async {
  late String _botToken;
  late String _chatId;

  if ( botType == BotType.error) {
    _botToken = getTelegramErrorBotToken();
    _chatId = getTelegramErrorChatId();
  }
  else if ( botType == BotType.register ){
    _botToken = getTelegramBotToken();
    _chatId = getTelegramChatId();
  }

  var url = Uri.parse('https://api.telegram.org/bot$_botToken/'
      'sendMessage?chat_id=$_chatId&text=$message');
  http.Response response =  await http.post(url);

  if (response.statusCode != 200) {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Error al enviar el mensaje a Telegram (código=${response.statusCode})');
  }
}
