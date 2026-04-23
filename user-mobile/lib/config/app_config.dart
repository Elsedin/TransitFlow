import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static String get resolvedApiBaseUrl {
    if (apiBaseUrl.trim().isNotEmpty) return apiBaseUrl.trim();

    if (kIsWeb) return 'http://localhost:5178/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:5178/api'; // AVD default
    return 'http://localhost:5178/api';
  }
}
