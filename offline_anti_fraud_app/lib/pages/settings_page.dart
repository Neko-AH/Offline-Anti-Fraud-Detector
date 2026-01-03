import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_anti_fraud_app/pages/login_page.dart';
import 'package:offline_anti_fraud_app/providers/auth_provider.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: const Color(0xFFDBEAFE),
      end: const Color(0xFFBFDBFE),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 420 ? 375.0 : screenWidth;

    // 颜色常量
    const primaryColor = Color(0xFF1E88E5);
    const dangerColor = Color(0xFFEF4444);
    const darkColor = Color(0xFF1E293B);

    // 尺寸常量 - 使用Flutter标准尺寸单位
    const radius = 16.0;
    const htmlLineHeight = 1.6;

    // 间距/内边距常量
    const padding24 = 24.0;
    const padding20 = 20.0;
    const padding16 = 16.0;
    const padding32 = 32.0;
    const padding40 = 40.0;

    // 头像相关尺寸
    const avatarContainerSize = 90.0;
    const avatarIconSize = 50.0;
    const avatarBottomMargin = 24.0;

    // 文字大小
    const text14 = 14.0;
    const text15 = 15.0;
    const text16 = 16.0;
    const text17_6 = 17.6;
    const text20 = 20.0;
    const text22_4 = 22.4;
    const text26_4 = 26.4;

    // 弹窗相关尺寸
    const dialogIconSize = 60.0;
    const dialogRadius = 30.0;
    const dialogBtnRadius = 8.0;
    const dialogBtnBorderWidth = 1.0;

    // 底部文字/图标尺寸
    const lockIconSize = 14.4;
    const privacyTextSize = 14.4;

    // 其他间距
    const margin48 = 48.0;
    const padding28_8 = 28.8;
    const spacing12_8 = 12.8;
    const spacing8 = 8.0;
    const spacing10 = 10.0;
    const spacing16 = 16.0;
    const spacing20 = 20.0;
    const spacing24 = 24.0;
    const spacing45 = 45.0;
    const logoutBtnRadius = 50.0;
    const logoutBtnBorderWidth = 2.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F2FE), Color(0xFFDBEAFE)],
          ),
        ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                // 头部区域
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 16.0), // 调整顶部内边距
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [primaryColor, primaryColor],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Image.asset(
                          'assets/images/return.png',
                          width: 20.0,
                          height: 20.0,
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      SizedBox(width: 12.0),
                      Text(
                        '设置中心',
                        style: TextStyle(
                          fontSize: text17_6,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Noto Sans SC',
                        ),
                      ),
                    ],
                  ),
                ),

              // 核心：用户信息面板
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(padding24, margin48, padding24, margin48),
                    padding: EdgeInsets.symmetric(
                      vertical: padding28_8,
                      horizontal: padding24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 20.0,
                          offset: const Offset(0, 4.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 头像容器
                        Container(
                          width: avatarContainerSize,
                          height: avatarContainerSize,
                          margin: EdgeInsets.only(bottom: avatarBottomMargin),
                          child: Stack(
                            children: [
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: _colorAnimation.value?.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(avatarContainerSize / 2),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Center(
                                child: Image.asset(
                                  'assets/images/profile.png',
                                  width: avatarIconSize,
                                  height: avatarIconSize,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 用户ID
                        Text(
                          '123***',
                          style: TextStyle(
                            fontSize: text22_4,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                            fontFamily: 'Noto Sans SC',
                            height: htmlLineHeight,
                          ),
                        ),

                        SizedBox(height: spacing12_8),

                        // 应用名称
                        Text(
                          '线下反诈通',
                          style: TextStyle(
                            fontSize: text26_4,
                            fontWeight: FontWeight.w700,
                            color: darkColor,
                            fontFamily: 'Noto Sans SC',
                            height: htmlLineHeight,
                          ),
                        ),

                        SizedBox(height: spacing8),

                        // 标语
                        Text(
                          '实时保护您的生命财产安全',
                          style: TextStyle(
                            fontSize: text16,
                            color: AppTheme.textSecondary.withOpacity(0.8),
                            fontFamily: 'Noto Sans SC',
                            height: htmlLineHeight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 底部按钮区域 - 始终固定在底部，无分块样式
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: padding40,
                  bottom: padding40 + MediaQuery.of(context).padding.bottom,
                  left: padding32,
                  right: padding32,
                ),
                margin: const EdgeInsets.only(bottom: 0.0),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 280.0),
                      child: TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(radius),
                              ),
                              contentPadding: const EdgeInsets.all(24),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: dialogIconSize,
                                    height: dialogIconSize,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: dangerColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(dialogRadius),
                                    ),
                                    child: Transform.scale(
                                      scale: 0.6,
                                      child: Image.asset(
                                        'assets/images/删除项目.png',
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.warning_amber_outlined,
                                          size: dialogIconSize,
                                          color: dangerColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '确认退出？',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '确定要退出登录吗？退出后将暂停实时保护功能',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF5F5F5),
                                          foregroundColor: const Color(0xFF666666),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(dialogBtnRadius),
                                            side: const BorderSide(
                                              color: Color(0xFFE0E0E0),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          '取消',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await authProvider.logout();
                                          if (mounted) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const LoginPage(),
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: dangerColor,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(dialogBtnRadius),
                                          ),
                                        ),
                                        child: const Text(
                                          '确认',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: dangerColor,
                          padding: EdgeInsets.symmetric(vertical: padding16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(logoutBtnRadius),
                            side: BorderSide(color: dangerColor, width: logoutBtnBorderWidth),
                          ),
                        ),
                        icon: Image.asset(
                          'assets/images/log_out.png',
                          width: 20.0,
                          height: 20.0,
                          color: dangerColor,
                        ),
                        label: Text(
                          '退出登录',
                          style: TextStyle(
                            fontSize: text17_6,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Noto Sans SC',
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: spacing24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/lock.png',
                          width: lockIconSize,
                          height: lockIconSize,
                          color: const Color(0xFF64748B),
                        ),
                        SizedBox(width: spacing8),
                        Text(
                          '本系统不会存储您的任何隐私数据',
                          style: TextStyle(
                            fontSize: privacyTextSize,
                            color: const Color(0xFF64748B),
                            fontFamily: 'Noto Sans SC',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}