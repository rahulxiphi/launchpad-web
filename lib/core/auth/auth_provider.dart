import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'token_storage.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthUser? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _service;
  final TokenStorage _storage;

  AuthNotifier(this._service, this._storage) : super(const AuthState());

  /// Called at app startup — restores session from secure storage if a token exists.
  /// In mock mode we only have a token, not the full user payload, so we mark
  /// the user as authenticated with a minimal object parsed from the stored token.
  Future<void> tryAutoLogin() async {
    final token = await _storage.getToken();
    if (token == null) return;

    // Decode the JWT claims client-side (no signature verification needed here —
    // the backend verifies on every API call).
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw const FormatException('bad jwt');

      // Base64url decode the payload section
      final bytes = _base64Decode(parts[1]);
      final jsonStr = String.fromCharCodes(bytes);
      final claims = _parseJson(jsonStr);

      final exp = claims['exp'] as int?;
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (DateTime.now().isAfter(expiry)) {
          // Token expired — clear and stay logged out
          await _storage.clearToken();
          return;
        }
      }

      state = state.copyWith(
        user: AuthUser(
          userId: claims['sub'] as String,
          role: claims['role'] as String,
          entityId: claims['entity_id'] as String?,
          source: claims['source'] as String?,
          accessToken: token,
        ),
      );
    } catch (_) {
      // Malformed token — discard silently
      await _storage.clearToken();
    }
  }

  /// Sign up and persist the token.
  Future<void> signUp({
    required String email,
    required String password,
    String? invitationCode,
    String? stageBucket,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.signUp(
        email: email,
        password: password,
        invitationCode: invitationCode,
        stageBucket: stageBucket,
      );
      await _storage.saveToken(user.accessToken);
      state = AuthState(user: user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error. Please try again.',
      );
    }
  }

  /// Login and persist the token.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.login(email: email, password: password);
      await _storage.saveToken(user.accessToken);
      state = AuthState(user: user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error. Please try again.',
      );
    }
  }

  /// Clear session — token deleted from secure storage, state reset.
  Future<void> logout() async {
    await _storage.clearToken();
    state = const AuthState();
  }

  /// Clear any displayed error (e.g. when user starts typing again).
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Base64 helpers (dart:convert not imported to keep deps minimal) ───────────

List<int> _base64Decode(String s) {
  // dart:convert IS available in Flutter — use it directly
  // This helper wraps it for clarity.
  final normalised = s.replaceAll('-', '+').replaceAll('_', '/');
  final padded = normalised.padRight(
    normalised.length + (4 - normalised.length % 4) % 4,
    '=',
  );
  return _decodeBase64(padded);
}

// We use dart:convert which is always available in Flutter.
List<int> _decodeBase64(String s) {
  final table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final output = <int>[];
  var buffer = 0;
  var bitsLeft = 0;
  for (final char in s.runes) {
    final c = String.fromCharCode(char);
    if (c == '=') break;
    final val = table.indexOf(c);
    if (val < 0) continue;
    buffer = (buffer << 6) | val;
    bitsLeft += 6;
    if (bitsLeft >= 8) {
      bitsLeft -= 8;
      output.add((buffer >> bitsLeft) & 0xff);
    }
  }
  return output;
}

Map<String, dynamic> _parseJson(String s) {
  // Minimal JSON object parser for JWT payloads (flat key/value pairs only).
  // We only need sub, role, entity_id, source, exp — all are strings or ints.
  final result = <String, dynamic>{};
  final inner = s.trim().replaceFirst('{', '').replaceAll(RegExp(r'\}$'), '');
  // Split by top-level commas — simple enough for flat JWT payloads
  final pairs = inner.split(RegExp(r',(?=(?:[^"]*"[^"]*")*[^"]*$)'));
  for (final pair in pairs) {
    final colonIdx = pair.indexOf(':');
    if (colonIdx < 0) continue;
    final rawKey = pair.substring(0, colonIdx).trim().replaceAll('"', '');
    final rawVal = pair.substring(colonIdx + 1).trim();
    if (rawVal == 'null') {
      result[rawKey] = null;
    } else if (rawVal.startsWith('"')) {
      result[rawKey] = rawVal.replaceAll('"', '');
    } else {
      result[rawKey] = int.tryParse(rawVal) ?? double.tryParse(rawVal) ?? rawVal;
    }
  }
  return result;
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());
final _authApiServiceProvider = Provider<AuthApiService>((_) => AuthApiService());

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(_authApiServiceProvider),
    ref.read(_tokenStorageProvider),
  );
});

/// Convenience provider — true when a valid user is in state.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
