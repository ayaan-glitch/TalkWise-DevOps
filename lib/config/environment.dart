// lib/config/environment.dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-api-domain.com/api/v1',
  );
  
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
}