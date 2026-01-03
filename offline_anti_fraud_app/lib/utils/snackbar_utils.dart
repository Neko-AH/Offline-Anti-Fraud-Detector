import 'package:flutter/material.dart';

/// 弹窗工具类，统一管理所有底部弹窗的样式和高度
class SnackBarUtils {
  /// 计算弹窗高度，与底部导航栏保持一致或略高
  static double calculateSnackBarHeight(BuildContext context) {
    // 底部导航栏高度：88.0px + 底部安全区域高度
    // 弹窗高度略高于底部导航栏，设置为96.0px + 底部安全区域高度
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return 88.0;
  }

  /// 创建统一样式的SnackBar
  static SnackBar createSnackBar(String message, BuildContext context) {
    final snackBarHeight = calculateSnackBarHeight(context);
    
    return SnackBar(
      content: SizedBox(
        height: snackBarHeight, // 使用完整高度，确保与导航栏等高
        child: Container(
          width: double.infinity,
          alignment: Alignment.centerLeft, // 垂直居中，水平左对齐
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.centerLeft, // 确保文本位于中横线
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left, // 文本左对齐
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1E88E5),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.fixed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: EdgeInsets.zero, // 移除默认内边距
      margin: null, // 固定行为下margin必须为null
    );
  }

  /// 显示统一样式的SnackBar
  static void showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      createSnackBar(message, context),
    );
  }
}