import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const int apiPort = 5178;
  
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$apiPort/api';
    }
    
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$apiPort/api';
    }
    
    if (Platform.isIOS) {
      return 'http://localhost:$apiPort/api';
    }
    
    return 'http://localhost:$apiPort/api';
  }
}
