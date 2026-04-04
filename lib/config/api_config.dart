class ApiConfig {
  // Update to https://... when deploying
  static const String baseUrl = 'http://localhost:8000/api/v1';

  static const String voiceTokenEndpoint = '$baseUrl/conversations/voice-token';
}
