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
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final String? companyName;
  final bool incorporated;
  final String? companyStage;
  final String? industry;
  final String? headcount;
  final Map<String, bool> selectedPrioritiesJson;
  final ProspectClassification? classification;

  ProspectInitResult({
    required this.prospectId,
    required this.stageBucket,
    required this.agentDisplayName,
    this.conversationPhase = 1,
    this.isReturning = false,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.companyName,
    this.incorporated = false,
    this.companyStage,
    this.industry,
    this.headcount,
    this.selectedPrioritiesJson = const {},
    this.classification,
  });

  Map<String, dynamic> toDynamicVariables({bool lockProfileFields = false}) {
    final selectedPriorities = selectedPrioritiesJson.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return {
      'is_return_visit': isReturning,
      'lock_profile_fields': lockProfileFields,
      if (fullName != null) 'userName': fullName,
      if (email != null) 'userEmail': email,
      if (phoneNumber != null) 'userPhone': phoneNumber,
      if (companyName != null) 'companyName': companyName,
      'isPostIncorporated': incorporated,
      if (companyStage != null) 'stage': companyStage,
      if (industry != null) 'industry': industry,
      if (headcount != null) 'headcount': headcount,
      if (selectedPrioritiesJson.isNotEmpty)
        'selectedPriorities': selectedPrioritiesJson,
      if (selectedPriorities.isNotEmpty) 'priorities': selectedPriorities,
    };
  }
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

class RelationshipHubChatResult {
  final String replyMarkdown;
  final Map<String, dynamic> rawResponse;

  const RelationshipHubChatResult({
    required this.replyMarkdown,
    this.rawResponse = const {},
  });
}

class ChatHistoryMessage {
  final int id;
  final String type;
  final String content;

  const ChatHistoryMessage({
    required this.id,
    required this.type,
    required this.content,
  });

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    return ChatHistoryMessage(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class ChatHistoryResult {
  final List<ChatHistoryMessage> messages;
  final int total;
  final bool hasMore;

  const ChatHistoryResult({
    required this.messages,
    required this.total,
    required this.hasMore,
  });
}

/// Combined profile: form data + AI-collected attributes from ElevenLabs conversations.
class ProviderPublic {
  final String providerId;
  final String companyName;
  final String? description;
  final String? websiteUrl;
  final String? hqLocation;
  final int? foundedYear;
  final String? logoUrl;

  ProviderPublic({
    required this.providerId,
    required this.companyName,
    this.description,
    this.websiteUrl,
    this.hqLocation,
    this.foundedYear,
    this.logoUrl,
  });

  factory ProviderPublic.fromJson(Map<String, dynamic> json) {
    return ProviderPublic(
      providerId: json['provider_id'] as String,
      companyName: json['company_name'] as String,
      description: json['description'] as String?,
      websiteUrl: json['website_url'] as String?,
      hqLocation: json['hq_location'] as String?,
      foundedYear: json['founded_year'] as int?,
      logoUrl: json['logo_url'] as String?,
    );
  }
}

class ProductPublic {
  final String productId;
  final String name;
  final String category;
  final String? subcategory;
  final String description;
  final String? shortDescription;
  final Map<String, dynamic> eligibilityCriteria;
  final List<String> stageFit;
  final List<String> targetIndustries;
  final String? pricingModel;
  final String? pricingDetails;
  final List<dynamic> features;
  final List<String> benefits;
  final String? integrationInfo;
  final String? signupUrl;
  final double? matchScore;
  final String? matchReasoning;
  final ProviderPublic? provider;

  ProductPublic({
    required this.productId,
    required this.name,
    required this.category,
    this.subcategory,
    required this.description,
    this.shortDescription,
    this.eligibilityCriteria = const {},
    this.stageFit = const [],
    this.targetIndustries = const [],
    this.pricingModel,
    this.pricingDetails,
    this.features = const [],
    this.benefits = const [],
    this.integrationInfo,
    this.signupUrl,
    this.matchScore,
    this.matchReasoning,
    this.provider,
  });

  factory ProductPublic.fromJson(Map<String, dynamic> json) {
    return ProductPublic(
      productId: json['product_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      description: json['description'] as String,
      shortDescription: json['short_description'] as String?,
      eligibilityCriteria:
          Map<String, dynamic>.from(json['eligibility_criteria'] ?? {}),
      stageFit: List<String>.from(json['stage_fit'] ?? []),
      targetIndustries: List<String>.from(json['target_industries'] ?? []),
      pricingModel: json['pricing_model'] as String?,
      pricingDetails: json['pricing_details'] as String?,
      features: List<dynamic>.from(json['features'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      integrationInfo: json['integration_info'] as String?,
      signupUrl: json['signup_url'] as String?,
      matchScore: (json['match_score'] as num?)?.toDouble(),
      matchReasoning: json['match_reasoning'] as String?,
      provider: json['provider'] != null
          ? ProviderPublic.fromJson(json['provider'])
          : null,
    );
  }
}

class ProspectFullProfile {
  final String prospectId;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final String? companyName;
  final bool incorporated;
  final String? companyStage;
  final String? industry;
  final String? headcount;
  final Map<String, bool> selectedPrioritiesJson;
  final String? stageBucket;
  final int conversationCount;
  final int conversationPhase;
  final String? invitationCode;
  final Map<String, dynamic> aiAttributes;

  const ProspectFullProfile({
    required this.prospectId,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.companyName,
    this.incorporated = false,
    this.companyStage,
    this.industry,
    this.headcount,
    this.selectedPrioritiesJson = const {},
    this.stageBucket,
    this.conversationCount = 0,
    this.conversationPhase = 1,
    this.invitationCode,
    this.aiAttributes = const {},
  });
}


class ConversationService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
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
      email: data['email'] as String?,
      fullName: data['full_name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      companyName: data['company_name'] as String?,
      incorporated: data['incorporated'] as bool? ?? false,
      companyStage: data['company_stage'] as String?,
      industry: data['industry'] as String?,
      headcount: data['headcount'] as String?,
      selectedPrioritiesJson: (data['selected_priorities_json'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value == true,
            ),
          ) ??
          const {},
    );
  }

  /// Fetches an existing prospect by email for pre-filling.
  Future<ProspectInitResult> lookupProspectByEmail(String email) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/lookup-email/$email',
    );
    final data = response.data as Map<String, dynamic>;
    return ProspectInitResult(
      prospectId: data['prospect_id'] as String,
      stageBucket: data['stage_bucket'] as String,
      agentDisplayName:
          data['agent_display_name'] as String? ?? 'your JPMC AI Advisor',
      conversationPhase: data['conversation_phase'] as int? ?? 1,
      isReturning: true,
      email: data['email'] as String?,
      fullName: data['full_name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      companyName: data['company_name'] as String?,
      incorporated: data['incorporated'] as bool? ?? false,
      companyStage: data['company_stage'] as String?,
      industry: data['industry'] as String?,
      headcount: data['headcount'] as String?,
      selectedPrioritiesJson: (data['selected_priorities_json'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value == true,
            ),
          ) ??
          const {},
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
      agentDisplayName:
          data['agent_display_name'] as String? ?? 'your JPMC AI Advisor',
      conversationPhase: data['conversation_phase'] as int? ?? 1,
      isReturning: true,
      email: data['email'] as String?,
      fullName: data['full_name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      companyName: data['company_name'] as String?,
      incorporated: data['incorporated'] as bool? ?? false,
      companyStage: data['company_stage'] as String?,
      industry: data['industry'] as String?,
      headcount: data['headcount'] as String?,
      selectedPrioritiesJson: (data['selected_priorities_json'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value == true,
            ),
          ) ??
          const {},
      classification: classificationData == null
          ? null
          : ProspectClassification(
              inferredStageBucket:
                  classificationData['inferred_stage_bucket'] as String?,
              inferredStageConfidence:
                  (classificationData['inferred_stage_confidence'] as num?)
                      ?.toDouble(),
              inferredStageConfidenceLabel:
                  classificationData['inferred_stage_confidence_label']
                      as String?,
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

  Future<RelationshipHubChatResult> sendRelationshipHubChat(
    String userMessage, {
    String? prospectId,
    Map<String, dynamic> context = const {},
  }) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/relationship-hub/chat',
      data: {
        'user_message': userMessage,
        if (prospectId != null) 'prospect_id': prospectId,
        'context': context,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return RelationshipHubChatResult(
      replyMarkdown: data['reply_markdown'] as String? ?? '',
      rawResponse: (data['raw_response'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const {},
    );
  }

  /// Fetches profile form data plus the latest AI-collected attribute list.
  Future<ProspectFullProfile> getProspectFullProfile(String prospectId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/full-profile',
    );
    final data = response.data as Map<String, dynamic>;
    return ProspectFullProfile(
      prospectId: data['prospect_id'] as String,
      email: data['email'] as String?,
      fullName: data['full_name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      companyName: data['company_name'] as String?,
      incorporated: data['incorporated'] as bool? ?? false,
      companyStage: data['company_stage'] as String?,
      industry: data['industry'] as String?,
      headcount: data['headcount'] as String?,
      selectedPrioritiesJson:
          (data['selected_priorities_json'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value == true),
              ) ??
              const {},
      stageBucket: data['stage_bucket'] as String?,
      conversationCount: data['conversation_count'] as int? ?? 0,
      conversationPhase: data['conversation_phase'] as int? ?? 1,
      invitationCode: data['invitation_code'] as String?,
      aiAttributes:
          (data['ai_attributes'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              const {},
    );
  }

  /// Fetch paginated chat history from the n8n_chat_histories table.
  ///
  /// Uses cursor-based pagination: pass [beforeId] to load messages older than
  /// that id.  Omit or pass 0 to load the most recent messages.
  Future<ChatHistoryResult> getChatHistory(
    String prospectId, {
    int limit = 30,
    int beforeId = 0,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (beforeId > 0) {
      queryParams['before_id'] = beforeId;
    }
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/relationship-hub/chat-history/$prospectId',
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    final messages = (data['messages'] as List<dynamic>?)
            ?.map((m) =>
                ChatHistoryMessage.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];
    return ChatHistoryResult(
      messages: messages,
      total: data['total'] as int? ?? 0,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  Future<List<ProductPublic>> listProducts({String? prospectId}) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/products',
      queryParameters: {
        if (prospectId != null) 'prospect_id': prospectId,
      },
    );
    final data = response.data['products'] as List;
    return data.map((json) => ProductPublic.fromJson(json)).toList();
  }
}
