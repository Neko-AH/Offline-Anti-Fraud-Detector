import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:offline_anti_fraud_app/services/realtime_voice_service.dart';
import 'package:offline_anti_fraud_app/services/fraud_detection_service.dart';
import 'package:vibration/vibration.dart';
import 'package:offline_anti_fraud_app/utils/snackbar_utils.dart';

class ProtectionProvider extends ChangeNotifier {
  bool _isProtected = false;
  bool _isRecording = false;
  bool _hasPermission = false;
  BuildContext? _context; // 添加上下文存储
  
  // 反诈模型服务相关
  static const MethodChannel _fraudDetectionChannel = MethodChannel(
      'com.example.offline_anti_fraud_app/fraud_detection');
  bool _isModelInitialized = false;
  
  // 语音服务相关
  final RealtimeVoiceService _voiceService = RealtimeVoiceService();
  String _voiceStatus = '未开始监听';
  String _lastDetectedSentence = '';
  String _accumulatedText = '';
  bool _lastFraudResult = false;
  String _lastDetectionMessage = '';
  DateTime? _lastDetectionTime;

  // Getters
  bool get isProtected => _isProtected;
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  bool get isModelInitialized => _isModelInitialized;
  String get voiceStatus => _voiceStatus;
  String get lastDetectedSentence => _lastDetectedSentence;
  String get accumulatedText => _accumulatedText;
  bool get lastFraudResult => _lastFraudResult;
  String get lastDetectionMessage => _lastDetectionMessage;
  DateTime? get lastDetectionTime => _lastDetectionTime;

  ProtectionProvider() {
    _loadProtectionState();
    _checkRecordPermission();
    _initializeVoiceService();
  }
  
  /// 初始化防护服务，如果防护模式是开启的则加载相关服务
  Future<void> initialize(BuildContext context) async {
    _context = context;
    
    // 重新从本地存储加载防护状态，确保获取最新值
    await _loadProtectionState();
    
    // 开始监听网络变化
    _startNetworkListening();
    
    // 如果防护模式是开启的
    if (_isProtected) {
      // 检查服务是否已经在运行
      bool isServiceRunning = _isRecording && _isModelInitialized;
      
      // 如果服务没有运行，执行完整的开启流程
      if (!isServiceRunning) {
        // 先确保服务处于关闭状态，避免重复初始化
        await _handleProtectionOff();
        // 然后执行与手动开启相同的逻辑
        await _handleProtectionOn(context);
      }
    }
  }

  // 从本地存储加载防护状态
  Future<void> _loadProtectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isProtected = prefs.getBool('isProtected') ?? false;
      notifyListeners();
    } catch (e) {
      print('Failed to load protection state: $e');
    }
  }

  // 保存防护状态到本地存储
  Future<void> _saveProtectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isProtected', _isProtected);
    } catch (e) {
      print('Failed to save protection state: $e');
    }
  }

  // 检查录音权限
  Future<void> _checkRecordPermission() async {
    try {
      PermissionStatus status = await Permission.microphone.status;
      _hasPermission = status.isGranted;
      notifyListeners();
    } catch (e) {
      print('Failed to check record permission: $e');
      _hasPermission = false;
      notifyListeners();
    }
  }

  // 请求录音权限
  Future<bool> _requestRecordPermission() async {
    try {
      PermissionStatus status = await Permission.microphone.status;
      
      // 如果权限已经被永久拒绝，直接返回false
      if (status.isPermanentlyDenied) {
        _hasPermission = false;
        notifyListeners();
        return false;
      }
      
      // 请求权限
      status = await Permission.microphone.request();
      
      _hasPermission = status.isGranted;
      notifyListeners();
      
      return _hasPermission;
    } catch (e) {
      print('Failed to request record permission: $e');
      _hasPermission = false;
      notifyListeners();
      return false;
    }
  }

  // 开始录音（由ASR服务处理，此处仅更新状态）
  Future<void> _startRecording() async {
    try {
      _isRecording = true;
      notifyListeners();
      print('开始录音...');
    } catch (e) {
      print('录音失败: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  // 停止录音（由ASR服务处理，此处仅更新状态）
  Future<void> _stopRecording() async {
    try {
      _isRecording = false;
      notifyListeners();
      print('停止录音...');
    } catch (e) {
      print('停止录音失败: $e');
    }
  }

  // 切换防护模式
  Future<void> toggleProtection(bool value, BuildContext context) async {
    _isProtected = value;
    _context = context; // 保存上下文
    await _saveProtectionState();
    notifyListeners();

    if (_isProtected) {
      await _handleProtectionOn(context);
    } else {
      await _handleProtectionOff();
    }
  }


  // 初始化语音服务
  void _initializeVoiceService() {
    // 设置语音服务的回调
    _voiceService.onSentenceDetected = (String sentence) {
      _lastDetectedSentence = sentence;
      _accumulatedText = _voiceService.accumulatedText;
      notifyListeners();
    };

    _voiceService.onStatusChanged = (String status) {
      _voiceStatus = status;
      notifyListeners();
      
      // 监听ASR连接错误
      if (status.contains('ASR服务器连接错误') || 
          status.contains('ASR错误') ||
          status.contains('连接错误')) {
        debugPrint('检测到ASR连接错误，正在关闭防护模式...');
        _handleAsrConnectionError();
      }
    };
    
    // 添加诈骗检测结果回调
    _voiceService.onFraudDetected = (bool isFraud, String message) {
      _lastFraudResult = isFraud;
      _lastDetectionMessage = message;
      _lastDetectionTime = DateTime.now();
      _lastDetectedSentence = _voiceService.currentSentence;
      _accumulatedText = _voiceService.accumulatedText;
      
      debugPrint('本地诈骗检测结果: $isFraud, 消息: $message');
      notifyListeners();
      
      // 如果本地模型检测到诈骗，调用新的检测服务进行双重验证
      if (isFraud && _context != null) {
        _performDualVerification();
      }
    };
    
    // 添加API密钥错误回调
    _voiceService.onApiKeyError = () {
      debugPrint('收到语音服务的API密钥错误通知，正在关闭防护模式...');
      handleApiKeyError();
    };
  }

  // 初始化反诈模型服务
  Future<void> _initializeFraudDetectionModel(BuildContext context) async {
    try {
      _voiceStatus = '正在加载反诈模型...';
      notifyListeners();
      
      // 调用原生方法初始化模型
      bool success = await _fraudDetectionChannel.invokeMethod('init');
      _isModelInitialized = success;
      
      if (success) {
        _voiceStatus = '反诈模型加载成功';
        print('反诈模型服务初始化成功');
      } else {
        _voiceStatus = '反诈模型加载失败';
        print('反诈模型服务初始化失败');
        
        // 用户需求：模型加载失败时，在app底部显示提示信息
        _showModelLoadFailedWarning(context);
        
        // 用户需求：模型加载失败时，停止加载本地模型服务
        // 关闭防护模式
        _isProtected = false;
        await _saveProtectionState();
        await _stopRecording();
        await _voiceService.stopListening();
      }
      
      notifyListeners();
    } on PlatformException catch (e) {
      _isModelInitialized = false;
      _voiceStatus = '反诈模型加载失败';
      print('反诈模型服务初始化失败: ${e.message}');
      
      // 用户需求：模型加载失败时，在app底部显示提示信息
      _showModelLoadFailedWarning(context);
      
      // 用户需求：模型加载失败时，停止加载本地模型服务
      // 关闭防护模式
      _isProtected = false;
      await _saveProtectionState();
      await _stopRecording();
      await _voiceService.stopListening();
      
      notifyListeners();
    }
  }

  // 清理反诈模型服务
  Future<void> _cleanupFraudDetectionModel() async {
    try {
      await _fraudDetectionChannel.invokeMethod('cleanup');
      _isModelInitialized = false;
      print('反诈模型服务已清理');
    } on PlatformException catch (e) {
      print('反诈模型服务清理失败: ${e.message}');
    }
  }
  
  /// 执行双重验证逻辑
  Future<void> _performDualVerification() async {
    debugPrint('本地模型检测到诈骗，正在调用外部检测服务进行双重验证...');
    
    // 获取完整的检测文本（历史对话+当前累计的对话）
    String detectionText = _voiceService.accumulatedText;
    debugPrint('外部检测服务使用的完整检测文本: $detectionText');
    
    // 调用新的检测服务
    try {
      final externalResult = await FraudDetectionService.detectFraud(detectionText);
      debugPrint('外部检测服务结果: $externalResult');
      
      // 检查外部检测结果是否也为诈骗
      if (externalResult.containsKey('Fraud_Tendency') && 
          externalResult['Fraud_Tendency'] == 1) {
        // 双重检测都为诈骗，显示警告弹窗
        _showFraudRiskWarning(_context!);
        debugPrint('双重检测都为诈骗！已显示警告弹窗');
        
        // 外部模型检测到诈骗，清空历史上下文
        _clearDetectionState();
      } else {
        // 外部检测未检测到诈骗，不显示弹窗
        debugPrint('外部检测未检测到诈骗，不显示警告弹窗');
        
        // 清空诈骗检测结果
        _resetDetectionResult();
      }
    } catch (error) {
      debugPrint('外部检测服务调用失败: $error');
      
      // 外部检测服务调用失败，默认返回1（有诈骗），显示警告弹窗并清空历史
      _showFraudRiskWarning(_context!);
      debugPrint('外部检测服务调用失败，默认相信本地模型结果，已显示警告弹窗');
      
      // 外部模型调用失败，清空历史上下文
      _clearDetectionState();
    }
  }
  
  /// 清空检测状态和历史上下文
  void _clearDetectionState() {
    _voiceService.clearAccumulatedText();
    _lastDetectedSentence = '';
    _accumulatedText = '';
    _lastFraudResult = false;
    _lastDetectionMessage = '';
    _lastDetectionTime = null;
    notifyListeners();
  }
  
  /// 重置检测结果（不清空历史）
  void _resetDetectionResult() {
    _lastFraudResult = false;
    _lastDetectionMessage = '';
    _lastDetectionTime = null;
    notifyListeners();
  }

  // 处理防护模式开启
  Future<void> _handleProtectionOn(BuildContext context) async {
    // 1. 检查网络连接
    bool isConnected = await _checkNetworkConnection();
    if (!isConnected) {
      // 网络异常，显示提示
      _showNetworkErrorWarning(context);
      // 关闭防护模式
      _isProtected = false;
      await _saveProtectionState();
      notifyListeners();
      return;
    }
    
    // 2. 检查录音权限
    PermissionStatus status = await Permission.microphone.status;
    
    if (status.isPermanentlyDenied) {
      // 权限被永久拒绝，显示特殊提示
      _showPermissionPermanentlyDeniedWarning(context);
      // 关闭防护模式
      _isProtected = false;
      await _saveProtectionState();
      notifyListeners();
    } else {
      bool granted = await _requestRecordPermission();
        if (granted) {
          await _startRecording();
          // 初始化反诈模型服务 - 传入BuildContext参数
          await _initializeFraudDetectionModel(context);
          // 只有模型初始化成功才启动语音监听服务
          if (_isModelInitialized) {
            // 启动语音监听服务
            await _voiceService.startListening();
          }
        } else {
        _showPermissionDeniedWarning(context);
        // 如果没有权限，关闭防护模式
        _isProtected = false;
        await _saveProtectionState();
        notifyListeners();
      }
    }
  }
  
  // 检查网络连接
  Future<bool> _checkNetworkConnection() async {
    try {
      // 使用connectivity_plus检查网络连接
      var connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('网络检查失败: $e');
      // 发生异常时默认认为网络不可用
      return false;
    }
  }

  // 开始监听网络变化
  void _startNetworkListening() {
    // 监听网络连接变化
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      print('网络连接变化: $result');
      if (result == ConnectivityResult.none) {
        // 网络关闭，关闭防护模式
        if (_isProtected) {
          _handleNetworkError();
        }
      }
    });
  }

  // 处理网络错误
  Future<void> _handleNetworkError() async {
    // 关闭防护模式
    _isProtected = false;
    await _saveProtectionState();
    await _handleProtectionOff();
    notifyListeners();
    
    // 显示网络错误弹窗
    if (_context != null) {
      _showNetworkErrorWarning(_context!);
    }
  }

  // 处理ASR连接错误
  Future<void> _handleAsrConnectionError() async {
    // 关闭防护模式
    _isProtected = false;
    await _saveProtectionState();
    await _handleProtectionOff();
    notifyListeners();
    
    // 显示网络错误弹窗
    if (_context != null) {
      _showNetworkErrorWarning(_context!);
    }
  }
  
  // 显示网络异常提示
  void _showNetworkErrorWarning(BuildContext context) {
    SnackBarUtils.showSnackBar('网络连接异常，防护模式无法开启', context);
  }

  // 处理防护模式关闭
  Future<void> _handleProtectionOff() async {
    if (_isRecording) {
      await _stopRecording();
    }
    // 停止语音监听服务
    await _voiceService.stopListening();
    // 清理反诈模型服务
    await _cleanupFraudDetectionModel();
  }

  // 手动添加文本（用于测试）
  Future<void> addManualText(String text) async {
    if (_isProtected) {
      await _voiceService.addManualText(text);
    } else {
      _voiceStatus = '请先开启防护模式';
      notifyListeners();
    }
  }

  // 清空累积文本
  void clearAccumulatedText() {
    _voiceService.clearAccumulatedText();
    _lastDetectedSentence = '';
    _accumulatedText = '';
    _lastFraudResult = false;
    _lastDetectionMessage = '';
    _lastDetectionTime = null;
    notifyListeners();
  }
  
  // 处理密钥错误，关闭防护模式
  Future<void> handleApiKeyError() async {
    _isProtected = false;
    await _saveProtectionState();
    await _handleProtectionOff();
    notifyListeners();
    
    // 显示密钥错误弹窗
    if (_context != null) {
      _showApiKeyErrorWarning(_context!);
    }
  }
  
  // 显示API密钥错误提示（使用底部弹窗样式）
  void _showApiKeyErrorWarning(BuildContext context) {
    SnackBarUtils.showSnackBar('API密钥已全部失效，请联系管理员更新密钥', context);
  }

  // 获取语音服务统计信息
  Map<String, dynamic> getVoiceStatistics() {
    return _voiceService.getStatistics();
  }

  // 检查诈骗风险等级
  String getRiskLevel() {
    if (!_isProtected) return '未开启';
    
    if (_lastFraudResult) {
      return '高风险';
    } else if (_accumulatedText.length > 50) {
      return '监听中';
    } else if (_voiceService.isListening) {
      return '低风险';
    } else {
      return '未开启';
    }
  }

  // 显示权限被拒绝提示
  void _showPermissionDeniedWarning(BuildContext context) {
    SnackBarUtils.showSnackBar('录音权限被拒绝，防护模式无法正常工作', context);
  }
  
  // 显示模型加载失败提示
  void _showModelLoadFailedWarning(BuildContext context) {
    SnackBarUtils.showSnackBar('反诈模型加载失败，防护模式已关闭', context);
  }

  // 显示权限永久拒绝提示
  void _showPermissionPermanentlyDeniedWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('权限提示'),
        content: const Text('录音权限已被永久拒绝，需要您手动在系统设置中开启，否则防护模式无法正常工作。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  // 显示疑似诈骗风险预警弹窗
  void _showFraudRiskWarning(BuildContext context) {
    // 在防护模式下，弹出风险弹窗时触发震动提醒
    _triggerVibrationAlert();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Container(
          decoration: BoxDecoration(
            // 创建从中心到边缘的渐变，实现按钮区域与弹窗背景的自然过渡
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF8DC), // 弹窗背景色
                Color(0xFFFFFAE5), // 轻微过渡色
                Color(0xFFF5F7FB), // 按钮区域背景色
                Color(0xFFF5F7FB), // 按钮区域背景色
              ],
              stops: [0.0, 0.6, 0.85, 1.0],
            ),
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题区域
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 20.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/jg.png',
                        width: 24.0,
                        height: 24.0,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8.0),
                      const Text(
                        '诈骗风险预警',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 内容区域
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '温馨提示：当前对话中出现疑似诈骗特征。',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '建议先核实对方身份，',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                          TextSpan(
                            text: '切勿随意透露',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                          TextSpan(
                            text: '银行卡、验证码、家庭住址等隐私信息。',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20.0),
              
              // 按钮区域 - 与背景自然融合
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Center(
                  child: Container(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        '我知道了',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 触发震动提醒
  Future<void> _triggerVibrationAlert() async {
    try {
      debugPrint('开始触发震动提醒...');
      
      // 检查设备是否支持震动
      bool? hasVibrator = await Vibration.hasVibrator();
      debugPrint('设备震动支持状态: $hasVibrator');
      
      if (hasVibrator == true) {
        // 使用震动模式：短震动3次，间隔150毫秒
        debugPrint('正在执行震动模式: [0, 100, 150, 100, 150, 100]');
        await Vibration.vibrate(pattern: [0, 100, 150, 100, 150, 100]);
        debugPrint('震动提醒执行完成');
      } else {
        debugPrint('当前设备不支持震动功能（这在电脑上运行是正常的）');
      }
    } catch (e) {
      debugPrint('震动功能异常: $e');
      debugPrint('注意：在电脑上运行时震动功能不可用是正常现象');
      // 震动功能失败不影响正常功能，只记录日志
    }
  }
}