import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:offline_anti_fraud_app/config/api_config.dart';

class FraudDetectionService {
  // API密钥列表，按优先级排序，与ocr_service.dart保持一致
  static const List<String> _apiKeys = ApiConfig.apiKeys;
  
  // 当前使用的密钥索引
  static int _currentApiKeyIndex = 0;
  
  static const String baseUrl = ApiConfig.baseUrl;
  static const String model = ApiConfig.fraudDetectionModel;
  
  // 系统提示，与fraud_judge.py保持一致
  static const String systemPrompt = """
请你作为对话文本诈骗倾向检测专员，完成以下任务：
1. 阅读并分析提供的对话文本（文本可能未经过处理、存在识别不清晰的情况，需先自行筛选出有效信息，忽略无关干扰内容），判断该文本是否含有诈骗倾向；
2. 诈骗倾向判断标准：包含但不限于以下诈骗相关特征即判定为有诈骗倾向（标注1），无任何以下特征则判定为无诈骗倾向（标注0）：
（1）以中奖、返利、退税等名义诱导对方提供个人信息或进行转账；
（2）冒充公检法、银行、运营商、客服等官方身份，谎称对方涉嫌违法、账户异常等，要求配合调查、转账至“安全账户”；
（3）以恋爱、交友为幌子，诱导对方参与投资、赌博等非法活动或进行大额转账；
（4）以低价购物、代办证件、刷单返利等名义，诱导对方预付资金或泄露银行卡、验证码等敏感信息；
（5）以借钱应急、项目投资等名义，通过虚假承诺回报诱导对方转账，且存在隐瞒真实身份或用途的情况；
（6）以销售“特效药”“保健品”、代办养老手续、推荐“养老投资项目”等名义，骗取老年人钱财；或冒充亲属、熟人谎称出事急需用钱，诱导老年人转账；
（7）以赠送游戏皮肤、玩具、零食等为诱饵，诱导儿童提供家长银行卡信息、支付验证码，或直接诱导儿童进行扫码转账、充值消费。
3. 严格按照JSON格式输出结果，不得添加任何额外文本，字段说明如下：
- Fraud_Tendency：数字类型，你认为是否含有诈骗倾向，0表示无诈骗倾向，1表示有诈骗倾向；
- Reason：字符串类型，结合对话文本具体内容，说明判断依据，50字左右即可。
""";
  
  // 获取当前API密钥
  static String get currentApiKey => _apiKeys[_currentApiKeyIndex];
  
  // 切换到下一个API密钥
  static void _switchToNextApiKey() {
    if (_currentApiKeyIndex < _apiKeys.length - 1) {
      _currentApiKeyIndex++;
      print('切换到下一个API密钥: ${currentApiKey}');
    }
  }
  
  // 重置API密钥到第一个
  static void resetApiKeys() {
    _currentApiKeyIndex = 0;
    print('重置API密钥列表');
  }

  // 调用诈骗检测API
  static Future<Map<String, dynamic>> detectFraud(String text) async {
    try {
      // 构建请求体
      final requestBody = {
        "model": model,
        "messages": [
          {
            "role": "system",
            "content": systemPrompt
          },
          {
            "role": "user",
            "content": text
          }
        ],
        "response_format": {
          "type": "json_object"
        },
        "extra_body": {
          "thinking": {
            "type": "enabled" // 使用深度思考能力
          }
        }
      };

      // 重试机制：最多重试API密钥数量次
      int retryCount = 0;
      final maxRetries = _apiKeys.length;
      
      while (retryCount < maxRetries) {
        try {
          // 发送请求，使用当前API密钥
          final response = await http.post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${currentApiKey}'
            },
            body: json.encode(requestBody),
          );

          // 解析响应
          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            final message = responseData['choices'][0]['message'];
            final result = json.decode(message['content']);
            return result;
          } else if (response.statusCode == 429 || response.statusCode == 401) {
            // 遇到速率限制或认证错误，切换到下一个API密钥
            print('API请求失败: ${response.statusCode} - ${response.body}');
            print('遇到${response.statusCode == 429 ? '速率限制' : '认证错误'}，正在切换API密钥...');
            
            _switchToNextApiKey();
            retryCount++;
            
            // 短暂延迟后重试
            await Future.delayed(Duration(milliseconds: 500));
          } else {
            // 其他错误，直接抛出
            throw Exception('API请求失败: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          // 检查是否是速率限制、认证错误或其他可恢复错误
          if (e.toString().contains('429') || 
              e.toString().contains('404') ||
              e.toString().contains('403') ||
              e.toString().contains('401') ||
              e.toString().contains('RateLimitError') ||
              e.toString().contains('ModelNotOpen') ||
              e.toString().contains('NotFoundError') ||
              e.toString().contains('SetLimitExceeded') ||
              e.toString().toLowerCase().contains('authenticationerror')) {
            // 遇到可恢复错误，切换到下一个API密钥
            print('API请求失败: $e');
            print('遇到错误，正在切换API密钥...');
            
            _switchToNextApiKey();
            retryCount++;
            
            // 短暂延迟后重试
            await Future.delayed(Duration(milliseconds: 500));
          } else {
            // 其他错误，直接抛出
            rethrow;
          }
        }
      }
      
      // 所有重试都失败
      throw Exception('所有API密钥都已达到速率限制');
    } catch (e) {
      print('诈骗检测失败: $e');
      // 返回默认结果，当检测失败时，默认相信本地模型结果
      return {
        "Fraud_Tendency": 1,
        "Reason": "外部检测服务调用失败，默认相信本地模型结果"
      };
    }
  }
}