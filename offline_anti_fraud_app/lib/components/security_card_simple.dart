import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_anti_fraud_app/providers/protection_provider.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';

class SecurityCardSimple extends StatelessWidget {
  const SecurityCardSimple({super.key});

  @override
  Widget build(BuildContext context) {
    final protectionProvider = Provider.of<ProtectionProvider>(context);
    final bool isProtected = protectionProvider.isProtected;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(22.0),
        boxShadow: const [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: isProtected ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      isProtected ? Icons.shield : Icons.shield_outlined,
                      size: 14.0,
                      color: isProtected ? AppTheme.success : Colors.grey,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      isProtected ? '保护中' : '已关闭',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: isProtected ? AppTheme.success : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // 防护信息
          Text(
            isProtected ? '您目前处于安全状态' : '防护已关闭',
            style: TextStyle(
              fontSize: 14.0,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            isProtected 
                ? '反诈模型实时防护中，守护您的财产安全' 
                : '开启防护模式，享受实时反诈保护',
            style: TextStyle(
              fontSize: 14.0,
              color: AppTheme.textSecondary,
            ),
          ),
          
          const Spacer(),
          
          // 防护模式开关
          Container(
            padding: const EdgeInsets.only(top: 16.0),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
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
          ),
        ],
      ),
    );
  }
}