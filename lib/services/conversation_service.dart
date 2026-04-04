import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ConversationService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Calls POST /conversations/voice-token and returns the LiveKit conversation token.
  Future<String> getVoiceToken(String stageBucket) async {
    final response = await _dio.post(
      ApiConfig.voiceTokenEndpoint,
      data: {'stage_bucket': stageBucket},
    );
    return response.data['conversation_token'] as String;
  }
}
