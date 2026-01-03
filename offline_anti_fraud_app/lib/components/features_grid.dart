import 'package:flutter/material.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';
import 'package:offline_anti_fraud_app/utils/screen_adapter.dart';

class FeaturesGrid extends StatelessWidget {
  final VoidCallback onReportTap;
  final VoidCallback onFamilyTap;
  final VoidCallback onLocationTap;

  const FeaturesGrid({
    super.key,
    required this.onReportTap,
    required this.onFamilyTap,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenAdapter = ScreenAdapter();
    // 根据屏幕宽度和是否为平板调整列数，确保3个卡片能合理显示
    final crossAxisCount = screenAdapter.isTablet ? 3 : 3;
    // 根据屏幕宽度调整间距
    final spacing = screenAdapter.width(12.0);
    // 设置卡片宽高比，确保布局稳定
    final childAspectRatio = 1.0;

    return Container(
      // 添加外部边距，确保与标题的间距
      margin: EdgeInsets.only(top: screenAdapter.width(24.0)),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
        // 移除默认的内边距影响
        padding: EdgeInsets.zero,
        children: [
        // 一键举报卡片
        FeatureCard(
          title: '一键举报',
          imagePath: 'assets/images/cjg.png',
          color: AppTheme.orange,
          onTap: onReportTap,
        ),
        
        // 家人速通卡片
        FeatureCard(
          title: '家人速通',
          imagePath: 'assets/images/ljj.png',
          color: AppTheme.blue,
          onTap: onFamilyTap,
        ),
        
        // 定址呼救卡片
        FeatureCard(
          title: '定址呼救',
          imagePath: 'assets/images/hdw.png',
          color: AppTheme.red,
          onTap: onLocationTap,
        ),
      ],
    ),
  );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? imagePath;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    this.icon,
    this.imagePath,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenAdapter = ScreenAdapter();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: screenAdapter.getBorderRadiusCircular(20.0),
          boxShadow: const [AppTheme.cardShadow],
          border: Border(
            bottom: BorderSide(color: color, width: screenAdapter.width(3.0)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标容器
            Container(
              width: screenAdapter.width(45.0),
              height: screenAdapter.width(45.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: screenAdapter.getBorderRadiusCircular(12.0),
              ),
              child: Center(
                child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      width: screenAdapter.width(30.0), // 增加图片宽度，确保清晰显示
                      height: screenAdapter.width(30.0),
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      icon,
                      size: screenAdapter.width(30.0),
                      color: color,
                    ),
              ),
            ),
            
            SizedBox(height: screenAdapter.height(8.0)),
            
            // 标题
            Text(
              title,
              style: TextStyle(
                fontSize: screenAdapter.fontSize(14.0), // 增加字体大小，提高可读性
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
