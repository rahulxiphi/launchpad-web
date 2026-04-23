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
