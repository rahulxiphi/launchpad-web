import 'package:dio/dio.dart';
import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import '../config/api_config.dart';

/// HTTP client shared by all tools (reuses connection pool).
final _dio = Dio(BaseOptions(
  baseUrl: ApiConfig.baseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));

// ---------------------------------------------------------------------------
// capture-need
// ---------------------------------------------------------------------------

class CaptureNeedTool implements ClientTool {
  final String? prospectId;

  CaptureNeedTool({this.prospectId});

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    try {
      final body = <String, dynamic>{
        'category': parameters['category'] ?? 'general',
        if (parameters['subcategory'] != null)
          'subcategory': parameters['subcategory'],
        if (parameters['description'] != null)
          'description': parameters['description'],
        if (parameters['urgency'] != null) 'urgency': parameters['urgency'],
        if (prospectId != null) 'prospect_id': prospectId,
      };

      final resp = await _dio.post(
        '/conversations/tools/capture-need',
        data: body,
      );

      return ClientToolResult.success({
        'need_id': resp.data['need_id'],
        'status': resp.data['status'],
      });
    } catch (e) {
      return ClientToolResult.failure('Failed to capture need: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// search-products
// ---------------------------------------------------------------------------

class SearchProductsTool implements ClientTool {
  final String? prospectId;

  SearchProductsTool({this.prospectId});

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    try {
      final body = <String, dynamic>{
        'query': parameters['query'] ?? '',
        'top_k': parameters['top_k'] ?? 3,
        if (prospectId != null) 'prospect_id': prospectId,
      };

      final resp = await _dio.post(
        '/conversations/tools/search-products',
        data: body,
      );

      final results = (resp.data['results'] as List<dynamic>)
          .map((r) => {
                'name': r['name'],
                'category': r['category'],
                'short_description': r['short_description'],
                'provider_name': r['provider_name'],
                'score': r['score'],
              })
          .toList();

      return ClientToolResult.success({'products': results});
    } catch (e) {
      return ClientToolResult.failure('Failed to search products: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// record-off-ramp
// ---------------------------------------------------------------------------

class RecordOffRampTool implements ClientTool {
  final String? prospectId;

  RecordOffRampTool({this.prospectId});

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    try {
      final body = <String, dynamic>{
        'action_type': parameters['action_type'] ?? 'signup',
        if (parameters['product_id'] != null)
          'product_id': parameters['product_id'],
        if (parameters['notes'] != null) 'notes': parameters['notes'],
        if (prospectId != null) 'prospect_id': prospectId,
      };

      final resp = await _dio.post(
        '/conversations/tools/record-off-ramp',
        data: body,
      );

      return ClientToolResult.success({
        'queued': resp.data['queued'],
        'action_type': resp.data['action_type'],
      });
    } catch (e) {
      return ClientToolResult.failure('Failed to record off-ramp: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// search-product-catalog (JSON catalog search)
// ---------------------------------------------------------------------------

class SearchProductCatalogTool implements ClientTool {
  final String? prospectId;
  final String stageBucket;

  SearchProductCatalogTool({this.prospectId, required this.stageBucket});

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    try {
      final body = <String, dynamic>{
        'stage_bucket': parameters['stage_bucket'] ?? stageBucket,
        'need_signals': parameters['need_signals'] is List
            ? parameters['need_signals']
            : <String>[],
        'top_k': parameters['top_k'] ?? 5,
      };

      final resp = await _dio.post(
        '/conversations/tools/search-catalog',
        data: body,
      );

      final results = (resp.data['results'] as List<dynamic>)
          .map((r) => {
                'name': r['name'],
                'category': r['category'],
                'short_description': r['short_description'],
                'key_features': r['key_features'],
                'estimated_value': r['estimated_value'],
                'eligibility': r['eligibility'],
              })
          .toList();

      return ClientToolResult.success({'products': results});
    } catch (e) {
      return ClientToolResult.failure('Failed to search product catalog: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// advance-phase (mid-call phase transition)
// ---------------------------------------------------------------------------

class AdvancePhaseTool implements ClientTool {
  final String? prospectId;
  final void Function(int)? onPhaseAdvanced;

  AdvancePhaseTool({this.prospectId, this.onPhaseAdvanced});

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    try {
      final body = <String, dynamic>{
        'prospect_id': prospectId ?? parameters['prospect_id'],
        'collected_attributes': parameters['collected_attributes'] is Map
            ? parameters['collected_attributes']
            : <String, dynamic>{},
      };

      final resp = await _dio.post(
        '/conversations/advance-phase',
        data: body,
      );

      if (onPhaseAdvanced != null) {
        onPhaseAdvanced!(resp.data['new_phase']);
      }

      return ClientToolResult.success({
        'new_phase': resp.data['new_phase'],
        'top_product_signals': resp.data['top_product_signals'],
      });
    } catch (e) {
      return ClientToolResult.failure('Failed to advance phase: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// record-handoff (mid-call handoff to human banker)
// ---------------------------------------------------------------------------

class RecordHandoffTool implements ClientTool {
  final String? prospectId;

  RecordHandoffTool({this.prospectId});

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    try {
      final body = <String, dynamic>{
        'prospect_id': prospectId ?? parameters['prospect_id'],
        'product_interests': parameters['product_interests'] is List
            ? parameters['product_interests']
            : <String>[],
        if (parameters['notes'] != null) 'notes': parameters['notes'],
      };

      final resp = await _dio.post(
        '/conversations/record-handoff',
        data: body,
      );

      return ClientToolResult.success({
        'handoff_id': resp.data['handoff_id'],
        'assigned_manager_type': resp.data['assigned_manager_type'],
        'status': resp.data['status'],
      });
    } catch (e) {
      return ClientToolResult.failure('Failed to record handoff: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// set-response-chips (ElevenLabs turn-level UI hints)
// ---------------------------------------------------------------------------

class SetResponseChipsPayload {
  final bool showChips;
  final List<String> chips;
  final String? category;
  final int? ttlMs;

  const SetResponseChipsPayload({
    required this.showChips,
    required this.chips,
    this.category,
    this.ttlMs,
  });
}

class SetResponseChipsTool implements ClientTool {
  final void Function(SetResponseChipsPayload payload) onUpdate;

  SetResponseChipsTool({required this.onUpdate});

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    try {
      print('[chips][tool] set_response_chips called with raw params: $parameters');

      final show = parameters['show_chips'];
      final bool showChips = show is bool
          ? show
          : show?.toString().toLowerCase() == 'true';

      final rawChips = parameters['chips'];
      final List<String> chips = rawChips is List
          ? rawChips
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toSet()
              .take(5)
              .toList()
          : const <String>[];

      final rawCategory = parameters['category'];
      final String? category = rawCategory == null
          ? null
          : rawCategory.toString().trim().isEmpty
              ? null
              : rawCategory.toString().trim().toLowerCase();

      final rawTtl = parameters['ttl_ms'];
      final int? ttlMs = rawTtl is int
          ? rawTtl
          : int.tryParse(rawTtl?.toString() ?? '');

      final payload = SetResponseChipsPayload(
        showChips: showChips,
        chips: chips,
        category: category,
        ttlMs: ttlMs,
      );

      print(
        '[chips][tool] parsed payload showChips=${payload.showChips} chips=${payload.chips} category=${payload.category} ttlMs=${payload.ttlMs}',
      );

      onUpdate(payload);

      print('[chips][tool] onUpdate dispatched successfully');
      // This tool is registered with expects_response=false, so it should not
      // emit a tool response back to the ElevenLabs runtime.
      return null;
    } catch (e) {
      print('[chips][tool] execute failed: $e');
      return ClientToolResult.failure('Failed to set response chips: $e');
    }
  }
}
