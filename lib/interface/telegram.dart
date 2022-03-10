import '../secret.dart';
import 'package:http/http.dart' as http;

class TelegramHelper {

  static void send(String message) async {
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
}
