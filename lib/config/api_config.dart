import 'package:flutter/foundation.dart';

/// Central place for backend settings.
class ApiConfig {
  ApiConfig._();

  static const bool useApi = bool.fromEnvironment('USE_API', defaultValue: true);

  static const String _rawUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://campusflow-nq50.onrender.com',
  );

  /// Base URL of the backend API.
  static String get baseUrl {
    var url = _rawUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      url = url
          .replaceFirst('localhost', '10.0.2.2')
          .replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static const String apiPrefix = '';

  // Endpoint paths matching backend routes
  static const String loginPath = '/auth/login';
  static const String signupPath = '/auth/signup';
  static const String programsPath = '/programs';
  static const String registrationsPath = '/registrations';
  static const String feedbackPath = '/feedback';

  /// Render's free plan can take time to wake up.
  static const Duration timeout = Duration(seconds: 45);
}
