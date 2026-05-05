class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String voiceTokenEndpoint = '$baseUrl/conversations/voice-token';
}
