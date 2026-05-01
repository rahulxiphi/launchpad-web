import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ProspectClassification {
  final String? inferredStageBucket;
  final double? inferredStageConfidence;
  final String? inferredStageConfidenceLabel;
  final List<String> inferredStageReasons;
  final String? inferredStageUpdatedAt;
  final String? confirmedStageBucket;
  final String? stageSelectionSource;
  final String? confirmedStageUpdatedAt;

  const ProspectClassification({
    this.inferredStageBucket,
    this.inferredStageConfidence,
    this.inferredStageConfidenceLabel,
    this.inferredStageReasons = const [],
    this.inferredStageUpdatedAt,
    this.confirmedStageBucket,
    this.stageSelectionSource,
    this.confirmedStageUpdatedAt,
  });

  bool get hasClassification =>
      inferredStageBucket != null && inferredStageBucket!.isNotEmpty;
}

class UpdateProspectClassificationResult {
  final String prospectId;
  final ProspectClassification classification;

  const UpdateProspectClassificationResult({
    required this.prospectId,
    required this.classification,
  });
}

/// Response from the prospect/init endpoint.
class ProspectInitResult {
  final String prospectId;
  final String stageBucket;
  final String agentDisplayName;
  final int conversationPhase;
  final bool isReturning;
  final ProspectClassification? classification;

  ProspectInitResult({
    required this.prospectId,
    required this.stageBucket,
    required this.agentDisplayName,
    this.conversationPhase = 1,
    this.isReturning = false,
    this.classification,
  });
}

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

  Future<void> updateProspectProfile(
    String prospectId, {
    required String email,
    String? fullName,
    String? phoneNumber,
    String? companyName,
    bool? incorporated,
    String? companyStage,
    String? industry,
    String? headcount,
    Map<String, bool>? selectedPrioritiesJson,
  }) async {
    await _dio.patch(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/profile',
      data: {
        'email': email,
        if (fullName != null) 'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (companyName != null) 'company_name': companyName,
        if (incorporated != null) 'incorporated': incorporated,
        if (companyStage != null) 'company_stage': companyStage,
        if (industry != null) 'industry': industry,
        if (headcount != null) 'headcount': headcount,
        if (selectedPrioritiesJson != null)
          'selected_priorities_json': selectedPrioritiesJson,
      },
    );
  }

  /// Initialize a prospect session from an invitation code.
  /// Resolves the invitation code to a stage_bucket and agent.
  Future<ProspectInitResult> initProspect(
    String invitationCode, {
    String? email,
  }) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/prospect/init',
      data: {
        'invitation_code': invitationCode,
        if (email != null) 'email': email,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ProspectInitResult(
      prospectId: data['prospect_id'] as String,
      stageBucket: data['stage_bucket'] as String,
      agentDisplayName: data['agent_display_name'] as String,
      conversationPhase: data['conversation_phase'] as int? ?? 1,
      isReturning: data['is_returning'] as bool? ?? false,
    );
  }

  /// Fetches an existing prospect by ID.
  /// Used for return visits via /?p=<UUID>.
  Future<ProspectInitResult> getProspect(String prospectId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId',
    );
    final data = response.data as Map<String, dynamic>;
    final classificationData = data['classification'] as Map<String, dynamic>?;
    return ProspectInitResult(
      prospectId: data['prospect_id'] as String,
      stageBucket: data['stage_bucket'] as String,
      agentDisplayName: data['agent_display_name'] as String? ?? 'your JPMC AI Advisor',
      conversationPhase: data['conversation_phase'] as int? ?? 1,
      isReturning: true,
      classification: classificationData == null
        ? null
        : ProspectClassification(
          inferredStageBucket:
            classificationData['inferred_stage_bucket'] as String?,
          inferredStageConfidence:
              (classificationData['inferred_stage_confidence'] as num?)
                ?.toDouble(),
            inferredStageConfidenceLabel:
              classificationData['inferred_stage_confidence_label'] as String?,
          inferredStageReasons:
            (classificationData['inferred_stage_reasons'] as List?)
                ?.whereType<String>()
                .toList() ??
              const [],
          inferredStageUpdatedAt:
            classificationData['inferred_stage_updated_at'] as String?,
            confirmedStageBucket:
              classificationData['confirmed_stage_bucket'] as String?,
            stageSelectionSource:
              classificationData['stage_selection_source'] as String?,
            confirmedStageUpdatedAt:
              classificationData['confirmed_stage_updated_at'] as String?,
        ),
    );
  }

      Future<UpdateProspectClassificationResult> updateProspectClassification(
      String prospectId, {
      required String selectedStageBucket,
      }) async {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/classification',
        data: {
        'selected_stage_bucket': selectedStageBucket,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final classificationData = data['classification'] as Map<String, dynamic>;
      return UpdateProspectClassificationResult(
        prospectId: data['prospect_id'] as String,
        classification: ProspectClassification(
        inferredStageBucket: classificationData['inferred_stage_bucket'] as String?,
        inferredStageConfidence:
          (classificationData['inferred_stage_confidence'] as num?)?.toDouble(),
        inferredStageConfidenceLabel:
          classificationData['inferred_stage_confidence_label'] as String?,
        inferredStageReasons:
          (classificationData['inferred_stage_reasons'] as List?)
              ?.whereType<String>()
              .toList() ??
            const [],
        inferredStageUpdatedAt:
          classificationData['inferred_stage_updated_at'] as String?,
        confirmedStageBucket:
          classificationData['confirmed_stage_bucket'] as String?,
        stageSelectionSource: classificationData['stage_selection_source'] as String?,
        confirmedStageUpdatedAt:
          classificationData['confirmed_stage_updated_at'] as String?,
        ),
      );
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
