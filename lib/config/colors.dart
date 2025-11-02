import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية
  static const Color primary = Color(0xFF2E86AB);      // أزرق أساسي
  static const Color secondary = Color(0xFFA23B72);     // وردي ثانوي
  static const Color accent = Color(0xFFF18F01);       // برتقالي مميز
  static const Color success = Color(0xFF4CAF50);      // أخضر نجاح
  static const Color error = Color(0xFFF44336);        // أحمر خطأ
  static const Color warning = Color(0xFFFF9800);      // برتقالي تحذير
  static const Color info = Color(0xFF2196F3);         // أزرق معلومات
  
  // ألوان الخلفية
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  
  // ألوان النص
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled = Color(0xFFADB5BD);
  static const Color textInverse = Color(0xFFFFFFFF);
  
  // ألوان الحدود
  static const Color border = Color(0xFFE9ECEF);
  static const Color divider = Color(0xFFDEE2E6);
  
  // التدرجات اللونية
  static const List<Color> gradientPrimary = [
    Color(0xFF2E86AB),
    Color(0xFFA23B72),
  ];
  
  static const List<Color> gradientSecondary = [
    Color(0xFFA23B72),
    Color(0xFFF18F01),
  ];
  
  static const List<Color> gradientSuccess = [
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
  ];
  
  static const List<Color> gradientError = [
    Color(0xFFF44336),
    Color(0xFFE91E63),
  ];
}

