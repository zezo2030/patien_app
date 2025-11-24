import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية - تصميم طبي احترافي
  static const Color primary = Color(0xFF0D7A8C);      // أزرق طبي داكن
  static const Color primaryLight = Color(0xFF1A9BB8);  // أزرق طبي فاتح
  static const Color secondary = Color(0xFF00A896);     // أخضر طبي (تيركواز)
  static const Color accent = Color(0xFF06C5D1);        // سماوي طبي
  static const Color success = Color(0xFF10B981);      // أخضر نجاح طبي
  static const Color error = Color(0xFFEF4444);        // أحمر خطأ طبي
  static const Color warning = Color(0xFFF59E0B);       // برتقالي تحذير
  static const Color info = Color(0xFF3B82F6);         // أزرق معلومات
  
  // ألوان الخلفية - نظيفة وطبية
  static const Color background = Color(0xFFF0F9FF);    // أزرق فاتح جداً
  static const Color backgroundLight = Color(0xFFFAFCFF); // أبيض مزرق
  static const Color surface = Color(0xFFFFFFFF);      // أبيض نقي
  static const Color card = Color(0xFFFFFFFF);         // أبيض للبطاقات
  
  // ألوان النص
  static const Color textPrimary = Color(0xFF1E293B);   // رمادي داكن
  static const Color textSecondary = Color(0xFF64748B); // رمادي متوسط
  static const Color textDisabled = Color(0xFFCBD5E1); // رمادي فاتح
  static const Color textInverse = Color(0xFFFFFFFF);   // أبيض
  
  // ألوان الحدود
  static const Color border = Color(0xFFE2E8F0);       // رمادي فاتح للحدود
  static const Color divider = Color(0xFFE2E8F0);      // رمادي فاتح للفواصل
  
  // التدرجات اللونية - طبية احترافية
  static const List<Color> gradientPrimary = [
    Color(0xFF0D7A8C),
    Color(0xFF1A9BB8),
  ];
  
  static const List<Color> gradientSecondary = [
    Color(0xFF1A9BB8),
    Color(0xFF00A896),
  ];
  
  static const List<Color> gradientMedical = [
    Color(0xFF0D7A8C),
    Color(0xFF06C5D1),
    Color(0xFF00A896),
  ];
  
  static const List<Color> gradientSuccess = [
    Color(0xFF10B981),
    Color(0xFF34D399),
  ];
  
  static const List<Color> gradientError = [
    Color(0xFFEF4444),
    Color(0xFFF87171),
  ];
  
  // ألوان إضافية للتصميم الطبي
  static const Color medicalBlue = Color(0xFF0EA5E9);   // أزرق طبي
  static const Color medicalTeal = Color(0xFF14B8A6);  // تيركواز طبي
  static const Color medicalGreen = Color(0xFF22C55E); // أخضر طبي
}

