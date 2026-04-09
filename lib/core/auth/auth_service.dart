import 'package:dio/dio.dart';
import '../../config/api_config.dart';

/// Represents the authenticated user returned by the backend.
class AuthUser {
  final String userId;
  final String role;
  final String? entityId; // startup_id (or provider_id in future)
  final String? source;
  final String accessToken;

  const AuthUser({
    required this.userId,
    required this.role,
    this.entityId,
    this.source,
    required this.accessToken,
  });

  factory AuthUser.fromTokenResponse(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthUser(
      userId: user['user_id'] as String,
      role: user['role'] as String,
      entityId: user['entity_id'] as String?,
      source: user['source'] as String?,
      accessToken: json['access_token'] as String,
    );
  }
}

/// HTTP layer for auth endpoints — only talks to the backend, no state held here.
/// State lives in [AuthNotifier] (auth_provider.dart).
class AuthApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  /// Register a new startup account.
  ///
  /// Throws [DioException] on network errors; throws [AuthException] on
  /// 4xx responses (email conflict, validation errors, etc.).
  Future<AuthUser> signUp({
    required String email,
    required String password,
    String role = 'startup',
    String? source,
    String? invitationCode,
    String? stageBucket,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'role': role,
          if (source != null) 'source': source,
          if (invitationCode != null && invitationCode.isNotEmpty)
            'invitation_code': invitationCode,
          if (stageBucket != null && stageBucket.isNotEmpty)
            'stage_bucket': stageBucket,
        },
      );
      return AuthUser.fromTokenResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Sign in with email and password.
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthUser.fromTokenResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  AuthException _toAuthException(DioException e) {
    final statusCode = e.response?.statusCode;
    final detail = (e.response?.data is Map)
        ? (e.response!.data as Map)['detail'] as String?
        : null;

    return switch (statusCode) {
      401 => AuthException('Invalid email or password.', statusCode: 401),
      403 => AuthException('Account is deactivated.', statusCode: 403),
      409 => AuthException(
          detail ?? 'An account with this email already exists.',
          statusCode: 409,
        ),
      422 => AuthException(
          'Please check your details and try again.',
          statusCode: 422,
        ),
      null => AuthException('Could not reach the server. Check your connection.'),
      _ => AuthException(detail ?? 'Something went wrong. Please try again.', statusCode: statusCode),
    };
  }
}

/// Typed error thrown by [AuthApiService] for all auth failures.
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthException($statusCode): $message';
}
