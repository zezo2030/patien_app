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
  
  /// الحصول على Base URL بدون /v1 (للملفات الثابتة)
  static String get baseUrlWithoutV1 {
    final String base = _isProduction ? _prodBaseUrl : _devBaseUrl;
    String url = base.replaceAll('/v1', '');
    
    // للـ Android Emulator، استبدل localhost بـ 10.0.2.2
    if (Platform.isAndroid && url.contains('localhost')) {
      url = url.replaceAll('http://localhost', 'http://10.0.2.2');
    }
    
    return url;
  }

  /// بناء URL كامل من مسار نسبي (للملفات الثابتة)
  /// يقبل المسارات النسبية مثل /static/... أو /uploads/...
  static String buildFullUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    
    // إذا كان URL كامل بالفعل، ارجعه كما هو
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    // إذا كان يبدأ بـ /static أو /، أضف Base URL
    if (relativePath.startsWith('/static') || relativePath.startsWith('/')) {
      return '$baseUrlWithoutV1$relativePath';
    }
    
    // إذا لم يكن كذلك، ارجعه كما هو
    return relativePath;
  }

  /// طباعة معلومات الاتصال (للتطوير فقط)
  static void printConfig() {
    print('═══════════════════════════════════════');
    print('🔧 API Configuration');
    print('═══════════════════════════════════════');
    print('Base URL: $baseUrl');
    print('Base URL (without /v1): $baseUrlWithoutV1');
    print('Environment: ${_isProduction ? "Production" : "Development"}');
    print('Platform: ${Platform.operatingSystem}');
    print('Timeout: ${requestTimeout}s');
    print('═══════════════════════════════════════');
  }
}

