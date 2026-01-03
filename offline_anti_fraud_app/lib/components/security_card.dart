import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_anti_fraud_app/providers/protection_provider.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';

class SecurityCard extends StatefulWidget {
  const SecurityCard({super.key});

  @override
  State<SecurityCard> createState() => _SecurityCardState();
}

class _SecurityCardState extends State<SecurityCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final protectionProvider = Provider.of<ProtectionProvider>(context);
    final bool isProtected = protectionProvider.isProtected;
    final String voiceStatus = protectionProvider.voiceStatus;
    final String lastDetectedSentence = protectionProvider.lastDetectedSentence;
    final bool lastFraudResult = protectionProvider.lastFraudResult;
    final String riskLevel = protectionProvider.getRiskLevel();

    return Container(
      constraints: const BoxConstraints(minHeight: 180.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(22.0),
        boxShadow: const [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 卡片标题和状态徽章
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '实时防护中心',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: isProtected ? AppTheme.success.withOpacity(0.15) : const Color(0xFFFFF8DC),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: Row(
                  children: [
                    isProtected
                      ? Image.asset(
                          'assets/images/lfh.png',
                          width: 18.0,
                          height: 18.0,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          'assets/images/hfh.png',
                          width: 18.0,
                          height: 18.0,
                          fit: BoxFit.contain,
                        ),
                    const SizedBox(width: 6.0),
                    Text(
                      isProtected ? '保护中' : '已关闭',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: isProtected ? AppTheme.success : const Color(0xFFFFCC00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // 防护信息
          if (!isProtected)
            Row(
              children: [
                // 添加警告图片
                Image.asset(
                  'assets/images/jg.png',
                  width: 16.0,
                  height: 16.0,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8.0),
                // 修改后的文本
                const Text(
                  '防护未开启！',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                // 添加防护开启图片
                Image.asset(
                  'assets/images/fhb.png',
                  width: 20.0,
                  height: 20.0,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8.0),
                // 修改后的文本
                const Text(
                  '实时防护已开启！',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8.0),
          Text(
            isProtected
                ? '正在全天候检测诈骗风险，放心使用'
                : '点击开关立即实时监听防护',
            style: TextStyle(
              fontSize: 14.0,
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 20.0),
          
          // 防护模式开关和详情按钮
          _buildControls(protectionProvider, isProtected, context),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isProtected, String riskLevel) {
    Color bgColor, textColor;
    IconData icon;
    String text;

    if (riskLevel == '高风险') {
      bgColor = const Color(0xFFFFEBEE);
      textColor = AppTheme.error;
      icon = Icons.warning;
      text = '高风险';
    } else if (riskLevel == '监听中') {
      bgColor = const Color(0xFFFFF8E6);
      textColor = AppTheme.warning;
      icon = Icons.hearing;
      text = '监听中';
    } else if (riskLevel == '低风险') {
      bgColor = const Color(0xFFE8F5E9);
      textColor = AppTheme.success;
      icon = Icons.shield;
      text = '保护中';
    } else {
      bgColor = const Color(0xFFF5F5F5);
      textColor = Colors.grey;
      icon = Icons.shield_outlined;
      text = '已关闭';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50.0),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14.0,
            color: textColor,
          ),
          const SizedBox(width: 6.0),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionInfo(bool isProtected, String voiceStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isProtected ? '防护模式已开启' : '防护已关闭',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: isProtected ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          isProtected
              ? '语音状态: $voiceStatus'
              : '开启防护模式，享受实时反诈保护',
          style: TextStyle(
            fontSize: 12.0,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLastDetection(String sentence, bool isFraud) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isFraud
            ? AppTheme.error.withOpacity(0.1)
            : AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isFraud
              ? AppTheme.error.withOpacity(0.3)
              : AppTheme.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFraud ? Icons.warning : Icons.check_circle,
            size: 16.0,
            color: isFraud ? AppTheme.error : AppTheme.success,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              sentence,
              style: TextStyle(
                fontSize: 13.0,
                color: isFraud ? AppTheme.error : AppTheme.success,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator(String riskLevel) {
    Color indicatorColor;
    String description;

    switch (riskLevel) {
      case '高风险':
        indicatorColor = AppTheme.error;
        description = '检测到可疑内容';
        break;
      case '监听中':
        indicatorColor = AppTheme.warning;
        description = '实时监听中';
        break;
      case '低风险':
        indicatorColor = AppTheme.success;
        description = '安全状态';
        break;
      default:
        indicatorColor = Colors.grey;
        description = '防护未开启';
    }

    return Row(
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          description,
          style: TextStyle(
            fontSize: 12.0,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(ProtectionProvider protectionProvider, bool isProtected, BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16.0),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        children: [
          // 防护模式开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '防护模式',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Switch(
                value: isProtected,
                onChanged: (value) => protectionProvider.toggleProtection(value, context),
                activeColor: AppTheme.success,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: const Color(0xFFE0E0E0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
