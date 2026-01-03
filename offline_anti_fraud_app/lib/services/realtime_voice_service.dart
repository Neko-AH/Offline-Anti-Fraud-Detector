import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 实时语音监听服务
/// 负责累积语音内容并提供实时语音识别功能
class RealtimeVoiceService {
  static final RealtimeVoiceService _instance = RealtimeVoiceService._internal();
  factory RealtimeVoiceService() => _instance;
  RealtimeVoiceService._internal();

  // 旧历史对话（从上一次识别的对话末尾截取，固定长度）
  String _oldHistoryText = '';
  
  // 新累计对话（当前会话累积的文本）
  String _newAccumulatedText = '';
  
  // 当前识别到的一句话
  String _currentSentence = '';
  
  // 句子计数，用于实现每三句话检测一次
  int _sentenceCount = 0;
  static const int _SENTENCE_TRIGGER_COUNT = 3; // 每3句话触发一次检测
  
  // 语音识别状态
  bool _isListening = false;
  
  // MethodChannel用于与原生Android通信
  static const MethodChannel _channel = MethodChannel('com.example.offline_anti_fraud_app/asr');
  static const MethodChannel _fraudDetectionChannel = MethodChannel(
      'com.example.offline_anti_fraud_app/fraud_detection');
  
  // 监听器回调
  Function(String)? onSentenceDetected;
  Function(String)? onStatusChanged;
  Function(bool, String)? onFraudDetected; // 添加诈骗检测结果回调
  Function()? onApiKeyError; // 添加API密钥错误回调
  
  // 定时器相关
  Timer? _detectionTimer;
  DateTime? _lastActivityTime;
  static const int _DETECTION_INTERVAL = 10; // 10秒检测间隔（优化用户体验）
  static const int _MAX_HISTORY_LENGTH = 300; // 最大历史对话长度（字）
  static const int _TRIGGER_LENGTH = 380; // 触发检测的文本长度（字），超过时立马发送至模型检测，不做截断

  // Getters
  bool get isListening => _isListening;
  String get accumulatedText => _oldHistoryText + (_oldHistoryText.isNotEmpty ? ' ' : '') + _newAccumulatedText; // 最终识别内容
  String get oldHistoryText => _oldHistoryText;
  String get newAccumulatedText => _newAccumulatedText;
  String get currentSentence => _currentSentence;

  /// 开始实时语音监听
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      _isListening = true;
      _oldHistoryText = '';
      _newAccumulatedText = '';
      _currentSentence = '';
      _sentenceCount = 0; // 重置句子计数
      _lastActivityTime = DateTime.now();
      
      _notifyStatusChanged('开始语音监听...');
      
      // 设置MethodChannel监听器
      _setupChannelListeners();
      
      // 调用原生Android的ASR服务
      await _channel.invokeMethod('start');
      
      // 不自动创建定时器，只在有活动语音时创建
      
    } catch (e) {
      _isListening = false;
      _notifyStatusChanged('语音监听启动失败: $e');
      debugPrint('开始语音监听失败: $e');
    }
  }

  /// 停止语音监听
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      // 调用原生Android的ASR服务停止方法
      await _channel.invokeMethod('stop');
      
      _isListening = false;
      _notifyStatusChanged('语音监听已停止');
      
      // 取消定时器
      _cancelTimer();
      
      // 保存累积的文本到本地（可选）
      await _saveAccumulatedText();
      
    } catch (e) {
      _notifyStatusChanged('停止语音监听失败: $e');
      debugPrint('停止语音监听失败: $e');
    }
  }
  
  /// 设置MethodChannel监听器，接收来自原生Android的事件
  void _setupChannelListeners() {
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'asrResult':
          // 处理ASR识别结果
          String result = call.arguments as String;
          await _onNewSentenceDetected(result);
          break;
        case 'statusChanged':
          // 处理状态变化
          String status = call.arguments as String;
          _notifyStatusChanged(status);
          break;
        case 'error':
          // 处理错误信息
          String error = call.arguments as String;
          _notifyStatusChanged('ASR错误: $error');
          debugPrint('ASR错误: $error');
          break;
        case 'apiKeyError':
          // 处理API密钥错误
          debugPrint('收到API密钥错误通知，所有密钥都已失效');
          _notifyStatusChanged('API密钥已全部失效，正在关闭防护模式...');
          // 调用API密钥错误回调
          onApiKeyError?.call();
          break;
      }
    });
  }

  /// 处理新识别到的句子
  Future<void> _onNewSentenceDetected(String sentence) async {
    _currentSentence = sentence;
    
    // 更新活动时间
    _lastActivityTime = DateTime.now();
    
    // 累积新对话：之前的新对话内容 + 新句子
    if (_newAccumulatedText.isEmpty) {
      _newAccumulatedText = sentence;
    } else {
      _newAccumulatedText += ' ' + sentence;
    }
    
    // 增加句子计数
    _sentenceCount++;
    debugPrint('当前句子计数: $_sentenceCount');
    
    // 通知监听器检测到新句子
    onSentenceDetected?.call(sentence);
    _notifyStatusChanged('识别到: $sentence');
    
    // 计算最终识别内容
    String finalDetectionText = accumulatedText;
    
    // 三个并行检测条件：
    // 1. 文本长度达到触发阈值
    // 2. 每3句话触发一次检测
    // 3. 定时检测（已在else分支中处理）
    if (finalDetectionText.length >= _TRIGGER_LENGTH) {
      await _detectFraud();
    } else if (_sentenceCount >= _SENTENCE_TRIGGER_COUNT) {
      // 每3句话触发一次检测
      debugPrint('达到句子触发计数 ($_SENTENCE_TRIGGER_COUNT句)，开始检测诈骗风险...');
      await _detectFraud();
    } else {
      // 只有当定时器不存在时才创建，确保只保留一个定时器
      if (_detectionTimer == null || !_detectionTimer!.isActive) {
        _startDetectionTimer();
      }
    }
  }



  /// 启动检测定时器，只在定时器不存在时创建
  void _startDetectionTimer() {
    // 取消之前的定时器（如果存在）
    _cancelTimer();
    
    // 创建新的一次性定时器
    _detectionTimer = Timer(Duration(seconds: _DETECTION_INTERVAL), () async {
      // 只有在有活动语音时才检测
      if (_lastActivityTime != null && _isListening) {
        await _detectFraud();
      }
      
      // 定时器执行后自动销毁，下次有活动语音时重新创建
      _detectionTimer = null;
    });
    
    debugPrint('启动检测定时器，$_DETECTION_INTERVAL秒后检测');
  }

  /// 取消定时器
  void _cancelTimer() {
    if (_detectionTimer != null) {
      _detectionTimer!.cancel();
      _detectionTimer = null;
    }
  }

  /// 调用本地反诈模型进行检测
  Future<void> _detectFraud() async {
    // 计算最终识别内容
    String finalDetectionText = accumulatedText;
    if (!_isListening || finalDetectionText.isEmpty) return;
    
    try {
      _notifyStatusChanged('正在检测诈骗风险...');
      
      // 调用原生反诈模型检测 - 方法名从detect改为predict
      dynamic result = await _fraudDetectionChannel.invokeMethod('predict', {
        'text': finalDetectionText
      });
      
      // 安全解析原生返回的结果，处理类型不匹配问题
      Map<dynamic, dynamic> resultMap = result as Map<dynamic, dynamic>;
      
      // 处理predLabel，可能是字符串或数字
      String predLabel;
      if (resultMap['predLabel'] is String) {
        predLabel = resultMap['predLabel'] as String;
      } else {
        // 如果是数字，转换为字符串
        predLabel = resultMap['predLabel'].toString();
      }
      
      // 获取诈骗概率
      double fraudProb = (resultMap['fraudProb'] as num).toDouble();
      
      // 转换为Flutter期望的格式
      bool isFraud = predLabel == 'fraud' || predLabel == '1' || fraudProb > 0.5;
      String message = isFraud ? '检测到诈骗风险！' : '未检测到诈骗风险';
      
      _notifyStatusChanged('检测完成: $message');
      debugPrint('诈骗检测结果: $isFraud, 概率: $fraudProb, 消息: $message');
      
      // 通知监听器检测结果
      onFraudDetected?.call(isFraud, message);
      
      // 检测后将最终识别内容的末尾250字作为旧历史对话，清空新累计对话
      // 无论检测结果如何，都更新历史对话（诈骗情况由provider处理）
      if (finalDetectionText.length > _MAX_HISTORY_LENGTH) {
        _oldHistoryText = finalDetectionText.substring(finalDetectionText.length - _MAX_HISTORY_LENGTH);
      } else {
        _oldHistoryText = finalDetectionText;
      }
      
      // 清空新累计对话和句子计数
      _newAccumulatedText = '';
      _sentenceCount = 0; // 重置句子计数
      
    } catch (e) {
      _notifyStatusChanged('诈骗检测失败: $e');
      debugPrint('诈骗检测失败: $e');
    }
  }

  /// 清空累积的文本
  void clearAccumulatedText() {
    _oldHistoryText = '';
    _newAccumulatedText = '';
    _currentSentence = '';
    _sentenceCount = 0; // 重置句子计数
    _lastActivityTime = null;
    _cancelTimer();
    _notifyStatusChanged('已清空累积文本');
  }

  /// 手动添加文本（用于测试）
  Future<void> addManualText(String text) async {
    if (!_isListening) {
      _notifyStatusChanged('请先开启语音监听');
      return;
    }
    
    await _onNewSentenceDetected(text);
  }

  /// 保存累积的文本到本地
  Future<void> _saveAccumulatedText() async {
    try {
      // 这里可以实现本地存储逻辑
      // 比如保存到SharedPreferences或文件中
      String finalText = accumulatedText;
      debugPrint('保存累积文本: $finalText');
    } catch (e) {
      debugPrint('保存文本失败: $e');
    }
  }

  /// 通知状态变化
  void _notifyStatusChanged(String status) {
    onStatusChanged?.call(status);
    debugPrint('语音服务状态: $status');
  }

  /// 获取服务统计信息
  Map<String, dynamic> getStatistics() {
    String finalText = accumulatedText;
    return {
      'isListening': _isListening,
      'finalDetectionTextLength': finalText.length,
      'oldHistoryTextLength': _oldHistoryText.length,
      'newAccumulatedTextLength': _newAccumulatedText.length,
      'currentSentenceLength': _currentSentence.length,
      'sentenceCount': finalText.split(' ').where((word) => word.isNotEmpty).length,
      'lastActivityTime': _lastActivityTime?.toIso8601String() ?? '',
    };
  }
}