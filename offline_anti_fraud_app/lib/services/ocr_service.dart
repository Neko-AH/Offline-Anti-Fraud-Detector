import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:offline_anti_fraud_app/config/api_config.dart';

class OCRService {
  // API密钥列表，按优先级排序
  static const List<String> _apiKeys = ApiConfig.apiKeys;
  static const String baseUrl = ApiConfig.baseUrl;
  static const String model = ApiConfig.ocrModel;
  
  // 当前使用的密钥索引
  static int _currentApiKeyIndex = 0;
 
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

  // 支持的图片格式
  static const List<String> validExtensions = ['.png', '.jpeg', '.jpg', '.webp'];

  // 将图像文件转换为Base64编码，并返回编码后的字符串和图像类型
  static Future<Map<String, String>> _imageToBase64(File imageFile) async {
    // 1. 检查输入文件是否为支持的图片格式
    final fileExtension = imageFile.path.split('.').last.toLowerCase();
    final fullExtension = '.$fileExtension';
    
    if (!validExtensions.contains(fullExtension)) {
      throw Exception('不支持的文件格式: $fullExtension。仅支持 ${validExtensions.join(', ')}');
    }
    
    // 2. 读取图像文件
    Uint8List imageBytes = await imageFile.readAsBytes();
    
    // 3. 检查文件大小，如果大于10MB则进行压缩
    const int maxSizeBytes = 10 * 1024 * 1024;
    String imageType = fileExtension;
    
    if (imageBytes.length > maxSizeBytes) {
      // 压缩图像
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage != null) {
        img.Image currentImage = decodedImage;
        
        // 如果是PNG格式，压缩后转换为JPEG格式
        if (fileExtension == 'png') {
          imageType = 'jpeg';
        }
        
        // 逐步调整图像质量直到文件大小符合要求
        int quality = 90;
        while (imageBytes.length > maxSizeBytes && quality > 10) {
          // 无论原格式如何，压缩后都使用JPEG格式
          imageBytes = img.encodeJpg(currentImage, quality: quality);
          
          // 降低质量继续尝试
          quality -= 5;
          
          // 如果质量已经很低但文件仍然太大，缩小图像尺寸
          if (quality <= 10 && imageBytes.length > maxSizeBytes) {
            final int newWidth = (currentImage.width * 0.9).toInt();
            currentImage = img.copyResize(currentImage, width: newWidth);
            quality = 90; // 重置质量，重新开始压缩
          }
        }
      }
    }
    
    // 统一jpeg和jpg格式
    if (imageType == 'jpg') {
      imageType = 'jpeg';
    }
    
    return {
      'base64': base64Encode(imageBytes),
      'type': imageType
    };
  }

  // 将图像文件转换为Base64编码，并返回编码后的字符串和图像类型
  static Future<Map<String, String>> _imageToBase64FromBytes(Uint8List imageBytes, String fileExtension) async {
    // 1. 确保图像类型是支持的格式
    final fullExtension = '.$fileExtension';
    if (!validExtensions.contains(fullExtension)) {
      throw Exception('不支持的文件格式: $fullExtension。仅支持 ${validExtensions.join(', ')}');
    }
    
    String imageType = fileExtension;
    
    // 2. 检查文件大小，如果大于10MB则进行压缩
    const int maxSizeBytes = 10 * 1024 * 1024;
    
    if (imageBytes.length > maxSizeBytes) {
      // 压缩图像
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage != null) {
        img.Image currentImage = decodedImage;
        
        // 如果是PNG格式，压缩后转换为JPEG格式
        if (fileExtension == 'png') {
          imageType = 'jpeg';
        }
        
        // 逐步调整图像质量直到文件大小符合要求
        int quality = 90;
        while (imageBytes.length > maxSizeBytes && quality > 10) {
          // 无论原格式如何，压缩后都使用JPEG格式
          imageBytes = img.encodeJpg(currentImage, quality: quality);
          
          // 降低质量继续尝试
          quality -= 5;
          
          // 如果质量已经很低但文件仍然太大，缩小图像尺寸
          if (quality <= 10 && imageBytes.length > maxSizeBytes) {
            final int newWidth = (currentImage.width * 0.9).toInt();
            currentImage = img.copyResize(currentImage, width: newWidth);
            quality = 90; // 重置质量，重新开始压缩
          }
        }
      }
    }
    
    // 统一jpeg和jpg格式
    if (imageType == 'jpg') {
      imageType = 'jpeg';
    }
    
    return {
      'base64': base64Encode(imageBytes),
      'type': imageType
    };
  }

  // 从文件获取图像类型
  static String _getImageTypeFromPath(String filePath) {
    final fileExtension = filePath.split('.').last.toLowerCase();
    return fileExtension;
  }

  // 调用OCR API进行欺诈检测（支持File和Uint8List）
  static Future<Map<String, dynamic>> detectFraud(dynamic imageData) async {
    try {
      Map<String, String> base64Data;
      
      if (imageData is File) {
        // 从File对象转换
        base64Data = await _imageToBase64(imageData);
      } else if (imageData is Map<String, dynamic> && imageData.containsKey('bytes') && imageData.containsKey('extension')) {
        // 从Map对象转换（包含bytes和extension）
        Uint8List bytes = imageData['bytes'];
        String extension = imageData['extension'];
        base64Data = await _imageToBase64FromBytes(bytes, extension);
      } else {
        throw Exception('不支持的图像数据类型');
      }
      
      String base64Image = base64Data['base64']!;
      String imageType = base64Data['type']!;

      // 构建请求体
      final requestBody = {
        "model": model,
        "messages": [
          {
            "role": "system",
            "content": "任务描述：你是一个专注于识别视觉材料中欺诈风险的AI助手。请仔细分析用户提供的海报、宣传图、招聘宣传图等图像内容（包括其上的文字、视觉元素、设计风格等），判断其是否存在欺诈风险，并给出一针见血的判断理由，理由需简明扼要，最好30个字左右。\n\n输出要求：\n请严格以JSON格式输出，且仅包含以下两个字段：\n1. fraud_confidence：欺诈置信度，一个介于0到1之间的浮点数，代表你认为该图像具有欺诈风险的概率。0代表极不可能，1代表极有可能。\n2. reason：理由说明，一个字符串，清晰、有条理地解释你得出该置信度的依据。请基于图像内容中的具体可疑点进行分析，例如：承诺不切实际的高回报、联系方式模糊、冒充知名品牌、使用紧迫性或威胁性话术、资质证明缺失或伪造、图片质量低劣或存在拼接痕迹等。\n\n分析原则：\n· 请专注于图像本身呈现的信息进行客观分析。\n· 如果图像信息不足或模糊，请在理由中说明，并据此适当降低置信度。\n· 对于招聘海报，请额外关注薪资与要求是否严重不符、公司信息是否可查、招聘流程是否异常简化等。\n· 请保持谨慎，避免对合法但夸张的营销内容误判。\n\n最终，你只需输出一个纯粹的JSON对象，无需任何其他前缀、解释或后续文字。\n\n用户将提供图像描述或上传图像，请开始分析。"
          },
          {
            "role": "user",
            "content": [
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/$imageType;base64,$base64Image"
                }
              }
            ]
          }
        ],
        "response_format": {
          "type": "json_object"
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
            
            // 如果已经是最后一个密钥，不再重试
            if (retryCount >= maxRetries) {
              throw Exception('所有API密钥都已达到${response.statusCode == 429 ? '速率限制' : '认证错误'}: ${response.statusCode} - ${response.body}');
            }
            
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
            
            // 如果已经是最后一个密钥，不再重试
            if (retryCount >= maxRetries) {
              throw Exception('所有API密钥都已达到错误上限: $e');
            }
            
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
      print('OCR检测失败: $e');
      // 返回默认结果
      return {
        "fraud_confidence": 0.0,
        "reason": "检测失败，请重试"
      };
    }
  }
}