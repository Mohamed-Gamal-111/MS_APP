import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/test_result.dart';

class ParkinsonApiService {
  final http.Client _client;

  ParkinsonApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<bool> healthCheck() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/health');
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 20));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<TestResult> analyzeVideo({
    required String endpoint,
    required PlatformFile videoFile,
  }) async {
    if (videoFile.bytes == null || videoFile.bytes!.isEmpty) {
      throw Exception('لم نتمكن من قراءة الفيديو. من فضلك اختر الفيديو مرة أخرى.');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);
    request.headers['accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes(
        AppConfig.videoFieldName,
        videoFile.bytes!,
        filename: videoFile.name,
      ),
    );

    final streamed = await request.send().timeout(const Duration(minutes: 5));
    final body = await streamed.stream.bytesToString();

    if (body.isEmpty) {
      throw Exception('لم تصل نتيجة من الخادم. حاول مرة أخرى بعد قليل.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw Exception('حدث خطأ في قراءة نتيجة التحليل. حاول مرة أخرى.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('صيغة النتيجة غير واضحة. حاول مرة أخرى.');
    }

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final msg = decoded['detail']?.toString() ??
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'تعذر إرسال الفيديو للتحليل. حاول مرة أخرى.';
      throw Exception(msg);
    }

    return TestResult.fromJson(decoded);
  }
}
