import 'package:flutter/material.dart';

class AppTheme {
  // 主色调
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  // 辅助色
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color secondaryLight = Color(0xFF81C784);
  
  // 功能色
  static const Color orange = Color(0xFFFF9800);
  static const Color blue = Color(0xFF2196F3);
  static const Color red = Color(0xFFFF5252);
  
  // 状态色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFFF5252);
  
  // 背景色
  static const Color background = Color(0xFFF5F7FB);
  static const Color cardBackground = Colors.white;
  
  // 文字色
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textLight = Color(0xFF777777);
  
  // 边框色
  static const Color border = Color(0xFFEEEEEE);
  
  // 圆角
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 18.0;
  static const double borderRadiusLarge = 36.0;
  
  // 阴影
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 10.0,
    offset: Offset(0, 4),
  );
  
  static const BoxShadow buttonShadow = BoxShadow(
    color: Color(0x3364B5F6),
    blurRadius: 8.0,
    offset: Offset(0, 4),
  );
  
  // 主题数据
  static final ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: background,
    cardColor: cardBackground,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12.0,
        color: textLight,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50.0),
      ),
    ),
  );
}
