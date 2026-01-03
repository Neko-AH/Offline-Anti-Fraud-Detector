// 集中API配置管理
class ApiConfig {
  // 通用API配置
  static const String baseUrl = "https://ark.cn-beijing.volces.com/api/v3";
  
  // 模型配置
  static const String fraudDetectionModel = "doubao-seed-1-6-251015";
  static const String fraudPreventionModel = "doubao-seed-1-6-flash-250828";
  static const String ocrModel = "doubao-seed-1-6-vision-250815";
  
  // API密钥列表
  static const List<String> apiKeys = [
    // 补充密钥
  ];
  
  // 地图API配置
  static const String mapApiKey = ''; // 补充密钥
  static const String mapApiUrl = 'https://apis.map.qq.com/ws/location/v1/ip';

  // 注意：上述配置仅涵盖Dart端，还需要在以下文件中配置相应的API：
  // 1. Android端ASR配置：android/app/src/main/java/com/example/offline_anti_fraud_app/AsrService.java
  // 2. Android端腾讯定位配置：android/app/src/main/kotlin/com/example/offline_anti_fraud_app/AppApplication.kt

}