import '../models/debug.dart';
import '../secret.dart';
import 'package:http/http.dart' as http;

import '../utilities/date.dart';

final String _classString = 'TelegramHelper'.toUpperCase();

Future<void> sendMessageToTelegram(
    {required String message, required Date matchDate, int? fromDaysAgoToTelegram}) async {
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

  String _botToken = await getTelegramBotToken();
  String _chatId = await getTelegramChatId();

  var url = Uri.parse('https://api.telegram.org/bot$_botToken/'
      'sendMessage?chat_id=$_chatId&text=$message');
  http.Response response = await http.post(url);

  if (response.statusCode != 200) {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Error al enviar el mensaje a Telegram (código=${response.statusCode})');
  }
}
