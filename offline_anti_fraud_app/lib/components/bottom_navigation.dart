import 'package:flutter/material.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 获取底部安全区域高度
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(color: AppTheme.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0 + bottomPadding),
      child: Row(
        children: [
          // 首页导航项 - 使用Expanded确保每个导航项占据相等宽度
          Expanded(
            child: NavItem(
              imagePath: 'assets/images/lfz.png',
              title: '首页',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
          ),
          
          // 辨诈实战导航项
          Expanded(
            child: NavItem(
              imagePath: 'assets/images/lsz.png',
              title: '辨诈实战',
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
          ),
          
          // 防诈游戏导航项
          Expanded(
            child: NavItem(
              imagePath: 'assets/images/lyx.png',
              title: '防诈游戏',
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ),
          
          // 我的导航项
          Expanded(
            child: NavItem(
              imagePath: 'assets/images/lwd.png',
              title: '我的',
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    this.icon,
    this.imagePath,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.primaryColor.withOpacity(0.1),
      highlightColor: AppTheme.primaryColor.withOpacity(0.05),
      // 确保点击区域覆盖整个导航项
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: double.infinity,
        height: 56.0,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                imagePath != null
                  ? Image.asset(
                      imagePath!,
                      width: 24.0,
                      height: 24.0,
                      color: isActive ? AppTheme.primaryColor : AppTheme.textLight,
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      icon,
                      size: 24.0,
                      color: isActive ? AppTheme.primaryColor : AppTheme.textLight,
                    ),
                if (isActive)
                  Positioned(
                    top: -2.0,
                    right: -8.0,
                    child: Container(
                      width: 4.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.0,
                color: isActive ? AppTheme.primaryColor : AppTheme.textLight,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
