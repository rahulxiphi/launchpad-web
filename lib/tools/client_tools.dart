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
