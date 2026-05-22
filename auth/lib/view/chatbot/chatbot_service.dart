import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatBotService {
  // غيّر اللينك ده بلينك الباك إند الحقيقي
  static const String baseUrl = 'http://127.0.0.1:8000/chat';

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'لا يوجد رد';
      }

      return 'حدث خطأ أثناء الاتصال بالسيرفر';
    } catch (e) {
      return 'تعذر الاتصال بالمساعد الطبي';
    }
  }
}