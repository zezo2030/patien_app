import 'dart:io';
import 'test_config.dart';

/// API Configuration
///
/// يحدد هذا الملف إعدادات الاتصال بالـ API
/// يمكنك تعديل القيم حسب بيئة التطوير أو الإنتاج
class ApiConfig {
  // Base URL للـ API
  // للتطوير المحلي: http://localhost:3000/v1
  // للأجهزة الفعلية: استخدم IP جهازك مثل http://192.168.1.3:3000/v1
  // للإنتاج: https://your-domain.com/v1

  // ⚠️ مهم: غيّر هذا الـ IP إلى IP جهازك على الشبكة المحلية
  // للحصول على IP جهازك: Windows: ipconfig | Mac/Linux: ifconfig
  // استخدم IP من نفس الشبكة المحلية (WiFi) التي يتصل بها جهاز الموبايل
  // static const String _localIP = '192.168.1.3'; // غيّر هذا إلى IP جهازك

  static const String _devBaseUrl = 'http://medcodesa.cloud/api';
  static const String _devBaseUrlPhysicalDevice = 'http://medcodesa.cloud/api';
  static const String _prodBaseUrl = 'https://medcodesa.cloud/api';

  // تحديد البيئة (dev أو prod)
  static const bool _isProduction = false;

  // تحديد ما إذا كان التطبيق يعمل على جهاز فعلي (غير Emulator/Simulator)
  // يمكن تعيين هذا بناءً على المنصة أو متغير بيئة
  static const bool _usePhysicalDeviceIP =
      true; // غيّر إلى true للأجهزة الفعلية

  /// الحصول على Base URL المناسب حسب المنصة والبيئة
  static String get baseUrl {
    if (_isProduction) {
      return _prodBaseUrl;
    }

    // إذا كان يجب استخدام IP للأجهزة الفعلية
    if (_usePhysicalDeviceIP) {
      // للـ Android Emulator، استخدم 10.0.2.2
      if (Platform.isAndroid) {
        // يمكن التحقق من Emulator vs Physical Device
        // للآن، نستخدم IP المحلي للأجهزة الفعلية
        return _devBaseUrlPhysicalDevice;
      }

      // للـ iOS Simulator، يمكن استخدام localhost
      // لكن للأجهزة الفعلية، استخدم IP المحلي
      if (Platform.isIOS) {
        return _devBaseUrlPhysicalDevice;
      }
    }

    // للمنصات الأخرى أو Emulator
    if (Platform.isAndroid) {
      // Android Emulator
      return _devBaseUrl.replaceAll('http://localhost', 'http://10.0.2.2');
    }

    // Desktop أو iOS Simulator
    return _devBaseUrl;
  }

  /// Timeout للطلبات (بالثواني)
  static const int requestTimeout = 30;

  /// Headers الافتراضية للطلبات
  static Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (TestConfig.isTestModeEnabled) {
      headers['x-test-mode'] = 'true';
    }

    return headers;
  }

  /// الحصول على Base URL بدون /v1 (للملفات الثابتة)
  static String get baseUrlWithoutV1 {
    final String currentBaseUrl = baseUrl; // استخدم baseUrl getter
    return currentBaseUrl.replaceAll('/v1', '');
  }

  /// بناء URL كامل من مسار نسبي (للملفات الثابتة)
  /// يقبل المسارات النسبية مثل /static/... أو /uploads/...
  static String buildFullUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }

    // إذا كان URL كامل بالفعل، ارجعه كما هو
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
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
