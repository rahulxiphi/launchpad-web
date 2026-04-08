import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Response from the voice-token endpoint.
class VoiceTokenResult {
  final String conversationToken;
  final String agentId;
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;

  VoiceTokenResult({
    required this.conversationToken,
    required this.agentId,
    required this.stageBucket,
    this.prospectId,
    this.dynamicVariables = const {},
  });
}

class ConversationService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Creates a pre-auth prospect and returns the prospect_id.
  Future<String> createProspect(String stageBucket, {String? email}) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/prospect',
      data: {
        'stage_bucket': stageBucket,
        if (email != null) 'email': email,
      },
    );
    return response.data['prospect_id'] as String;
  }

  /// Calls POST /conversations/voice-token and returns the full result
  /// including dynamic_variables for the SDK.
  Future<VoiceTokenResult> getVoiceToken(
    String stageBucket, {
    String? prospectId,
  }) async {
    final response = await _dio.post(
      ApiConfig.voiceTokenEndpoint,
      data: {
        'stage_bucket': stageBucket,
        if (prospectId != null) 'prospect_id': prospectId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return VoiceTokenResult(
      conversationToken: data['conversation_token'] as String,
      agentId: data['agent_id'] as String,
      stageBucket: data['stage_bucket'] as String,
      prospectId: data['prospect_id'] as String?,
      dynamicVariables:
          (data['dynamic_variables'] as Map<String, dynamic>?) ?? {},
    );
  }
}
