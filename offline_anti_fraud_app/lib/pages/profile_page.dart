import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_anti_fraud_app/pages/settings_page.dart';
import 'package:offline_anti_fraud_app/providers/auth_provider.dart';
import 'package:offline_anti_fraud_app/providers/points_provider.dart';
import 'package:offline_anti_fraud_app/providers/protection_provider.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';
import 'package:offline_anti_fraud_app/pages/emergency_contacts_page.dart';

class ProfilePage extends StatelessWidget {
  final String phoneNumber;
  final AuthProvider authProvider;

  const ProfilePage({super.key, this.phoneNumber = '131****8495', required this.authProvider});

  // 格式化用户ID，显示前三位，后面用*号替换
  String _formatUserId(String userId) {
    if (userId.isEmpty) {
      return '';
    }
    if (userId.length <= 3) {
      return userId;
    }
    // 显示前三位，后面用*号替换
    return '${userId.substring(0, 3)}${'*' * (userId.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 420 ? 375.0 : screenWidth;

    // 使用固定像素值，保持界面一致性
    // 基础尺寸
    const blueBgHeight = 350.0;
    const avatarSize = 90.0;
    const avatarBorderWidth = 3.0;
    const avatarIconSize = 50.0;
    const avatarBottomMargin = 20.0;

    // 文字大小
    const text16 = 16.0;
    const text22 = 22.0;
    const text22Bold = 22.0;

    // 间距/内边距
    const padding16 = 16.0;
    const padding30 = 30.0;
    const padding20 = 20.0;
    const margin5 = 5.0;
    const margin20Top = 20.0;
    const margin15Bottom = 15.0;
    const margin14Right = 14.0;
    const padding14Vertical = 14.0;
    const margin32Bottom = 32.0;

    // 功能卡片相关尺寸
    const cardIconContainerSize = 42.0;
    const cardIconSize = 20.0;
    const cardRadius = 16.0;
    const cardIconRadius = 12.0;
    const arrowIconSize = 16.0;

    // 阴影相关尺寸
    const shadowBlur6 = 6.0;
    const shadowOffset3 = 3.0;
    const shadowBlur12 = 12.0;
    const shadowOffset4 = 4.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // 主要内容区域，使用Stack实现顶部蓝色区域填充
          Expanded(
            child: Stack(
              children: [
                // 蓝色背景
                Container(
                  height: blueBgHeight,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E88E5),
                  ),
                ),

                // 内容区域
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // 用户信息区域
                      Container(
                        padding: EdgeInsets.fromLTRB(padding16, 60.0, padding16, padding20),
                        child: Column(
                          children: [
                            // 头像和用户信息
                            Column(
                              children: [
                                Container(
                                  width: avatarSize,
                                  height: avatarSize,
                                  margin: EdgeInsets.only(bottom: avatarBottomMargin),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E88E5),
                                    borderRadius: BorderRadius.circular(avatarSize / 2),
                                    border: Border.all(color: Colors.white, width: avatarBorderWidth),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0x33000000),
                                        blurRadius: shadowBlur6,
                                        offset: Offset(0, shadowOffset3),
                                      ),
                                    ],
                                  ),
                                  child: Transform.scale(
                                    scale: 0.6,
                                    child: Image.asset(
                                      'assets/images/btx.png',
                                      width: avatarIconSize,
                                      height: avatarIconSize,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Text(
                                  '欢迎回来',
                                  style: TextStyle(
                                    fontSize: text22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: margin5),
                                Text(
                                  '您好，${_formatUserId(authProvider.userId)}',
                                  style: TextStyle(
                                    fontSize: text16,
                                    fontWeight: FontWeight.w400,
                                    color: const Color.fromRGBO(255, 255, 255, 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 功能卡片区域
                      Container(
                        margin: EdgeInsets.only(top: margin20Top),
                        padding: EdgeInsets.all(padding16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Column(
                          children: [
                            // 账户功能标题
                            Container(
                              margin: EdgeInsets.only(bottom: margin15Bottom),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '账户功能',
                                style: TextStyle(
                                  fontSize: text16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),

                            // 积分账户卡片
                            GestureDetector(
                              onTap: () {
                                // 可以添加积分详情功能
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: margin15Bottom),
                                padding: EdgeInsets.all(padding16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(cardRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0x08000000),
                                      blurRadius: shadowBlur12,
                                      offset: Offset(0, shadowOffset4),
                                    ),
                                  ],
                                ),
                                child: Consumer<PointsProvider>(
                                  builder: (context, pointsProvider, child) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(vertical: padding14Vertical),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: cardIconContainerSize,
                                                height: cardIconContainerSize,
                                                margin: EdgeInsets.only(right: margin14Right),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.border,
                                                  borderRadius: BorderRadius.circular(cardIconRadius),
                                                ),
                                                child: Transform.scale(
                                                  scale: 0.6,
                                                  child: Image.asset(
                                                    'assets/images/credit.png',
                                                    width: cardIconSize,
                                                    height: cardIconSize,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '积分账户',
                                                    style: TextStyle(
                                                      fontSize: text16,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${pointsProvider.points}',
                                            style: TextStyle(
                                              fontSize: text22Bold,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // 紧急联系人卡片
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmergencyContactsPage(),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: margin15Bottom),
                                padding: EdgeInsets.all(padding16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(cardRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0x08000000),
                                      blurRadius: shadowBlur12,
                                      offset: Offset(0, shadowOffset4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: padding14Vertical),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: cardIconContainerSize,
                                            height: cardIconContainerSize,
                                            margin: EdgeInsets.only(right: margin14Right),
                                            decoration: BoxDecoration(
                                              color: AppTheme.border,
                                              borderRadius: BorderRadius.circular(cardIconRadius),
                                            ),
                                            child: Transform.scale(
                                              scale: 0.6,
                                              child: Image.asset(
                                                'assets/images/ljj.png',
                                                width: cardIconSize,
                                                height: cardIconSize,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '配置紧急联系人',
                                                style: TextStyle(
                                                  fontSize: text16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: arrowIconSize,
                                        color: AppTheme.textLight,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 设置卡片
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsPage(),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: margin15Bottom),
                                padding: EdgeInsets.all(padding16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(cardRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0x08000000),
                                      blurRadius: shadowBlur12,
                                      offset: Offset(0, shadowOffset4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: padding14Vertical),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: cardIconContainerSize,
                                            height: cardIconContainerSize,
                                            margin: EdgeInsets.only(right: margin14Right),
                                            decoration: BoxDecoration(
                                              color: AppTheme.border,
                                              borderRadius: BorderRadius.circular(cardIconRadius),
                                            ),
                                            child: Transform.scale(
                                              scale: 0.6,
                                              child: Image.asset(
                                                'assets/images/sz.png',
                                                width: cardIconSize,
                                                height: cardIconSize,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '设置',
                                                style: TextStyle(
                                                  fontSize: text16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: arrowIconSize,
                                        color: AppTheme.textLight,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: margin32Bottom),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}