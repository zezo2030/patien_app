import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // أحجام الخطوط
  static const double fontSizeXS = 12.0;
  static const double fontSizeSM = 14.0;
  static const double fontSizeMD = 16.0;
  static const double fontSizeLG = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeXXXL = 32.0;
  
  // خطوط النصوص
  static TextStyle headline1 = const TextStyle(
    fontSize: fontSizeXXXL,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle headline2 = const TextStyle(
    fontSize: fontSizeXXL,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle headline3 = const TextStyle(
    fontSize: fontSizeXL,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodyLarge = const TextStyle(
    fontSize: fontSizeMD,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodyMedium = const TextStyle(
    fontSize: fontSizeSM,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static TextStyle bodySmall = const TextStyle(
    fontSize: fontSizeXS,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static TextStyle button = const TextStyle(
    fontSize: fontSizeSM,
    fontWeight: FontWeight.w500,
    color: AppColors.textInverse,
  );
  
  static TextStyle caption = const TextStyle(
    fontSize: fontSizeXS,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

