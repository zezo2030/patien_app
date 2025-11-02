import 'dart:io';

/// API Configuration
/// 
/// يحدد هذا الملف إعدادات الاتصال بالـ API
/// يمكنك تعديل القيم حسب بيئة التطوير أو الإنتاج
class ApiConfig {
  // Base URL للـ API
  // للتطوير المحلي: http://localhost:3000/v1
  // للإنتاج: https://your-domain.com/v1
  static const String _devBaseUrl = 'http://localhost:3000/v1';
  static const String _prodBaseUrl = 'https://your-domain.com/v1';
  
  // تحديد البيئة (dev أو prod)
  static const bool _isProduction = false;
  
  /// الحصول على Base URL المناسب حسب المنصة والبيئة
  static String get baseUrl {
    final String base = _isProduction ? _prodBaseUrl : _devBaseUrl;
    
    // للـ Android Emulator، استبدل localhost بـ 10.0.2.2
    if (Platform.isAndroid && base.contains('localhost')) {
      return base.replaceAll('http://localhost', 'http://10.0.2.2');
    }
    
    // للـ iOS Simulator أو المنصات الأخرى، استخدم localhost
    return base;
  }
  
  /// Timeout للطلبات (بالثواني)
  static const int requestTimeout = 30;
  
  /// Headers الافتراضية للطلبات
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// طباعة معلومات الاتصال (للتطوير فقط)
  static void printConfig() {
    print('═══════════════════════════════════════');
    print('🔧 API Configuration');
    print('═══════════════════════════════════════');
    print('Base URL: $baseUrl');
    print('Environment: ${_isProduction ? "Production" : "Development"}');
    print('Platform: ${Platform.operatingSystem}');
    print('Timeout: ${requestTimeout}s');
    print('═══════════════════════════════════════');
  }
}

