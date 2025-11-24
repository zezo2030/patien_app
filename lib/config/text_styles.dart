import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // الخط العربي الجميل - Cairo (قاهرة)
  // خط حديث وأنيق مناسب للتطبيقات الطبية
  static TextStyle _cairo({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.5, // تحسين المسافة بين الأسطر
      letterSpacing: 0.2, // تباعد بسيط بين الأحرف
    );
  }
  
  // خط بديل أنيق - Almarai (المرعي)
  static TextStyle _almarai({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    return GoogleFonts.almarai(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.5,
    );
  }
  
  // خط جديد عصري - Tajawal (تجوال)
  // خط حديث وأنيق مناسب للعناوين والعناصر المميزة
  static TextStyle _tajawal({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    return GoogleFonts.tajawal(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.6,
      letterSpacing: 0.3,
    );
  }
  
  // أحجام الخطوط
  static const double fontSizeXS = 12.0;
  static const double fontSizeSM = 14.0;
  static const double fontSizeMD = 16.0;
  static const double fontSizeLG = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeXXXL = 32.0;
  
  // خطوط النصوص باستخدام خط Cairo الجميل
  static TextStyle headline1 = _cairo(
    fontSize: fontSizeXXXL,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle headline2 = _cairo(
    fontSize: fontSizeXXL,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle headline3 = _cairo(
    fontSize: fontSizeXL,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodyLarge = _cairo(
    fontSize: fontSizeMD,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodyMedium = _cairo(
    fontSize: fontSizeSM,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  static TextStyle bodySmall = _cairo(
    fontSize: fontSizeXS,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  static TextStyle button = _cairo(
    fontSize: fontSizeSM,
    fontWeight: FontWeight.w600,
    color: AppColors.textInverse,
  );
  
  static TextStyle caption = _cairo(
    fontSize: fontSizeXS,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  // خطوط إضافية باستخدام Almarai للتنويع
  static TextStyle displayLarge = _almarai(
    fontSize: fontSizeXXXL + 8,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle displayMedium = _almarai(
    fontSize: fontSizeXXL + 4,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  // خطوط جديدة باستخدام Tajawal للعناوين والعناصر المميزة
  static TextStyle titleLarge = _tajawal(
    fontSize: fontSizeXL,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle titleMedium = _tajawal(
    fontSize: fontSizeLG,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  static TextStyle titleSmall = _tajawal(
    fontSize: fontSizeMD,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // خط Tajawal للعناوين الرئيسية في البطاقات
  static TextStyle cardTitle = _tajawal(
    fontSize: fontSizeLG,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  // خط Tajawal للأزرار المميزة
  static TextStyle buttonLarge = _tajawal(
    fontSize: fontSizeLG,
    fontWeight: FontWeight.bold,
    color: AppColors.textInverse,
  );
}

