import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const int apiPort = 5178;
  static const String androidHost = '10.0.2.2';
  
  static const String stripePublishableKey = 
      "pk_test_51N6bltB4h4hzC4aEpCBeZdHAYwKcoadQ6Q2apjd0QksHwhZvObVNJjQXwVPkUH0YroT2pwN9CFoqmUUztHyymI8b00FQ5SCJBj";
  
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$apiPort/api';
    }
    
    if (Platform.isAndroid) {
      return 'http://$androidHost:$apiPort/api';
    }
    
    if (Platform.isIOS) {
      return 'http://localhost:$apiPort/api';
    }
    
    return 'http://localhost:$apiPort/api';
  }
}
