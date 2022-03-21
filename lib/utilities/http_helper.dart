import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/debug.dart';
import '../secret.dart';
import 'date.dart';

final String _classString = 'HttpHelper'.toUpperCase();

Future<int> sendEmail(
    {required String name, required String email, required String message}) async {
  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  const serviceId = emailJSServiceId;
  const templateId = emailJSTemplateId;
  const userId = emailJSUserId;
  final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      //This line makes sure it works for all platforms.
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {'from_name': name, 'from_email': email, 'message': message}
      }));
  return response.statusCode;
}

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

  String _botToken =  getTelegramBotToken();
  String _chatId =  getTelegramChatId();

  var url = Uri.parse('https://api.telegram.org/bot$_botToken/'
      'sendMessage?chat_id=$_chatId&text=$message');
  http.Response response = await http.post(url);

  if (response.statusCode != 200) {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Error al enviar el mensaje a Telegram (código=${response.statusCode})');
  }
}
