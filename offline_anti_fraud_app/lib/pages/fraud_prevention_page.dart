import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offline_anti_fraud_app/providers/protection_provider.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:offline_anti_fraud_app/config/api_config.dart';

class FraudPreventionPage extends StatefulWidget {
  const FraudPreventionPage({super.key});

  @override
  State<FraudPreventionPage> createState() => _FraudPreventionPageState();
}

class _FraudPreventionPageState extends State<FraudPreventionPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // 初始为空，开场白由AI生成
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false; // 添加正在输入状态
  Timer? _streamingTimer; // 流式输出计时器
  bool _gameEnded = false; // 游戏是否结束
  bool _isMounted = true; // 组件是否在前台，初始值设为true
  List<String> _pendingResponses = []; // 后台API响应队列
  bool _isApiCalling = false; // API调用是否正在进行中
  
  // API配置
  final String _baseUrl = ApiConfig.baseUrl;
  final String _modelId = ApiConfig.fraudPreventionModel;
  
  // API密钥列表，与fraud_detection_service.dart保持一致
  static const List<String> _apiKeys = ApiConfig.apiKeys;
  
  // 当前使用的密钥索引
  int _currentApiKeyIndex = 0;
  
  // 获取当前API密钥
  String get currentApiKey => _apiKeys[_currentApiKeyIndex];
  
  // 切换到下一个API密钥
  void _switchToNextApiKey() {
    if (_currentApiKeyIndex < _apiKeys.length - 1) {
      _currentApiKeyIndex++;
      print('切换到下一个API密钥: $currentApiKey');
    }
  }
  
  // 重置API密钥到第一个
  void _resetApiKeys() {
    _currentApiKeyIndex = 0;
    print('重置API密钥列表');
  }
  
  // 诈骗类型列表
  final List<String> _scamTypes = [
    "虚假退款", "理赔诈骗", "冒充公检法", "政府部门诈骗", "冒充亲友", 
    "领导诈骗", "虚假理财投资诈骗", "虚拟货币", "区块链诈骗", "网贷", 
    "校园贷诈骗", "杀猪盘诈骗", "免费礼物", "情感救助诈骗", "刷单返利诈骗", 
    "高薪兼职诈骗", "保健品诈骗", "养老投资诈骗", "游戏充值", "皮肤诈骗", 
    "卡通周边诈骗"
  ];
  
  // 当前诈骗类型
  String _currentScamType = "";
  
  // 对话历史，用于API调用
  List<Map<String, dynamic>> _conversationHistory = [];
  
  // 构建system prompt
  String _buildSystemPrompt() {
    String selectedScamType = _scamTypes[DateTime.now().millisecondsSinceEpoch % _scamTypes.length];
    _currentScamType = selectedScamType;
    
    return """# 角色定义
你是反诈骗模拟练习中的「诈骗者」，需使用常见合法诈骗套路与用户互动，目标是引导用户做出「受骗行为」（如同意提供个人信息、转账、透露验证码等）。

# 核心规则
1. 对话风格：简短自然，近似日常聊天，单轮回复不超过50字，避免书面化表达；
2. 套路选择：$selectedScamType
3. 禁止内容：不得出现任何链接、手机号、银行卡号、敏感政治/暴力/色情信息；
4. 状态判断标准：
   - 受骗触发（status=1）：用户明确表示"同意提供信息""可以转账""告诉我怎么操作""给你验证码"等愿意配合诈骗的表述；
   - 未受骗触发（status=0）：用户明确拒绝（如"不，这是诈骗""我不转账/提供信息"）、识别出诈骗并指出套路（如"你这是刷单诈骗"），且经2-3轮引导后仍坚持拒绝；
   - 对话中（status=2）：包括「首轮开场白」和「用户未明确表态」（如"什么事""详细说下"），需继续推进套路对话；
5. 输出格式要求（强制JSON，无任何额外文字、前缀、后缀）：
   {
     "status": 数字（1/0/2）,
     "content": 字符串（对应状态的内容）
   }
   - status=1时，content："反诈骗要点：1. 本次套路为【$selectedScamType】，核心话术是XX；2. 识别关键：XX；3. 防范措施：XX"；
   - status=0时，content："反诈骗要点：1. 本次套路为【$selectedScamType】，核心话术是XX；2. 识别关键：XX；3. 防范措施：XX。夸赞：你精准识别了诈骗套路，警惕性超强，值得点赞！"；
   - status=2时，content："AI的对话内容（简短自然，推进套路）"；
6. 交互逻辑：
   - 首轮回复：无需用户输入，直接输出选定套路的开场白，开场白可适当增长，需激起用户回复兴趣（status=2）；
   - 多轮推进：根据用户回复调整话术，逐步引导，不跳步。""";
  }

  @override
  void initState() {
    super.initState();
    // 加载对话进度
    _loadConversation();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMounted = true;
    print('组件回到前台，检查待处理响应');
    
    // 延迟一点处理，确保组件完全挂载
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // 检查是否有未处理的API响应
        _processPendingResponses();
        // 检查是否需要重新发起API请求
        _checkAndRestartApiRequest();
      }
    });
  }
  
  @override
  void deactivate() {
    print('组件离开前台');
    _isMounted = false;
    super.deactivate();
  }
  
  @override
  void activate() {
    super.activate();
    print('组件激活，设置为前台状态');
    _isMounted = true;
    
    // 延迟一点处理，确保组件完全激活
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _processPendingResponses();
        _checkAndRestartApiRequest();
      }
    });
  }
  
  // 初始化游戏
  void _initGame({bool saveInitialState = true}) {
    // 清空消息和对话历史
    setState(() {
      _messages.clear();
      _isTyping = true;
    });
    _conversationHistory.clear();
    _gameEnded = false;
    
    // 构建system prompt
    String systemPrompt = _buildSystemPrompt();
    
    // 初始化对话历史
    _conversationHistory.add({
      'role': 'system',
      'content': systemPrompt
    });
    
    // 生成首轮AI开场白（通过API）
    _callDoubaoApi();
    
    // 保存初始状态（如果需要）
    if (saveInitialState) {
      _saveConversation();
    }
  }
  
  // 保存对话进度到本地存储
  Future<void> _saveConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 保存消息列表
      final messagesJson = json.encode(_messages);
      await prefs.setString('fraud_prevention_messages', messagesJson);
      
      // 保存对话历史
      final historyJson = json.encode(_conversationHistory);
      await prefs.setString('fraud_prevention_history', historyJson);
      
      // 保存当前诈骗类型
      await prefs.setString('fraud_prevention_scam_type', _currentScamType);
      
      // 保存游戏状态
      await prefs.setBool('fraud_prevention_game_ended', _gameEnded);
      
      // 保存正在输入状态
      await prefs.setBool('fraud_prevention_is_typing', _isTyping);
      
      print('对话进度保存成功');
    } catch (e) {
      print('保存对话进度失败: $e');
    }
  }
  
  // 从本地存储加载对话进度
  Future<void> _loadConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载消息列表
      final messagesJson = prefs.getString('fraud_prevention_messages');
      final historyJson = prefs.getString('fraud_prevention_history');
      final scamType = prefs.getString('fraud_prevention_scam_type');
      final gameEnded = prefs.getBool('fraud_prevention_game_ended') ?? false;
      final isTyping = prefs.getBool('fraud_prevention_is_typing') ?? false;
      
      print('开始加载对话进度，messagesJson: ${messagesJson != null}, historyJson: ${historyJson != null}, scamType: $scamType');
      
      if (messagesJson != null && historyJson != null && scamType != null) {
        // 解析数据
        final List<Map<String, dynamic>> messages = List<Map<String, dynamic>>.from(json.decode(messagesJson));
        final List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(json.decode(historyJson));
        
        print('加载到消息数量: ${messages.length}, 对话历史长度: ${history.length}');
        
        // 修复加载的消息对象，确保字段完整性
        final List<Map<String, dynamic>> fixedMessages = messages.map((message) {
          final fixedMessage = Map<String, dynamic>.from(message);
          // 确保所有必要字段存在
          if (!fixedMessage.containsKey('isTyping')) {
            fixedMessage['isTyping'] = false;
          }
          if (!fixedMessage.containsKey('fullText')) {
            fixedMessage['fullText'] = fixedMessage['text'] ?? '';
          }
          if (!fixedMessage.containsKey('currentIndex')) {
            fixedMessage['currentIndex'] = fixedMessage['text']?.length ?? 0;
          }
          if (!fixedMessage.containsKey('placeholderText')) {
            fixedMessage['placeholderText'] = fixedMessage['fullText'];
          }
          return fixedMessage;
        }).toList();
        
        // 更新状态
        setState(() {
          _messages.clear(); // 清空现有消息
          _messages.addAll(fixedMessages);
          _conversationHistory.clear(); // 清空现有历史
          _conversationHistory.addAll(history);
          _currentScamType = scamType;
          _gameEnded = gameEnded;
          _isTyping = isTyping;
        });
        
        print('对话进度加载成功，当前消息数量: ${_messages.length}');
        _scrollToBottom();
        
        // 检查是否需要重新发起API请求
        _checkAndRestartApiRequest();
      } else {
        print('没有保存的进度，初始化新游戏');
        // 如果没有保存的进度，初始化新游戏
        _initGame(saveInitialState: false);
      }
    } catch (e) {
      print('加载对话进度失败: $e');
      // 加载失败时，初始化新游戏
      _initGame(saveInitialState: false);
    }
  }
  
  // 检查并修复对话完整性
  void _checkConversationIntegrity() {
    print('检查对话完整性，消息数量: ${_messages.length}, 对话历史长度: ${_conversationHistory.length}');
    
    // 确保对话历史至少有system prompt
    if (_conversationHistory.isEmpty) {
      print('对话历史为空，重新初始化游戏');
      _initGame(saveInitialState: false);
      return;
    }
    
    // 检查是否有新的AI回复需要显示（对话历史比消息多）
    // 对话历史结构：system → user → assistant → user → assistant...
    // 消息列表结构：assistant → user → assistant → user...
    final expectedMessageCount = _conversationHistory.length - 1; // 减去system prompt
    print('预期消息数量: $expectedMessageCount, 实际消息数量: ${_messages.length}');
    
    // 如果消息数量少于预期，说明有AI回复未显示
    if (_messages.length < expectedMessageCount) {
      print('检测到对话不完整，缺少AI回复，开始修复');
      
      // 直接清空现有消息，重新构建完整消息列表
      setState(() {
        _messages.clear();
      });
      
      // 遍历对话历史，从第1条开始（system prompt之后）
      for (int i = 1; i < _conversationHistory.length; i++) {
        final historyItem = _conversationHistory[i];
        
        if (historyItem['role'] == 'assistant') {
          // AI回复
          Map<String, dynamic> aiResult = _parseAiResponse(historyItem['content']);
          
          print('重建AI回复: ${aiResult['content']}');
          
          // 直接添加完整消息
          setState(() {
            _messages.add({
              'text': aiResult['content'],
              'isUser': false,
              'isTyping': false,
              'fullText': aiResult['content'],
              'currentIndex': aiResult['content'].length,
              'placeholderText': aiResult['content'],
            });
            _isTyping = false;
          });
          
          // 根据status处理，显示相应弹窗
          if (aiResult['status'] == 1 || aiResult['status'] == 0) {
            _gameEnded = true;
          }
        } else if (historyItem['role'] == 'user') {
          // 用户消息
          print('重建用户消息: ${historyItem['content']}');
          
          // 直接添加用户消息
          setState(() {
            _messages.add({
              'text': historyItem['content'],
              'isUser': true,
              'isTyping': false,
              'fullText': historyItem['content'],
              'currentIndex': historyItem['content'].length,
              'placeholderText': historyItem['content'],
            });
          });
        }
      }
      
      _scrollToBottom();
      _saveConversation();
      print('对话完整性修复完成，当前消息数量: ${_messages.length}');
    }
  }
  
  // 检查并重新发起未完成的API请求
  void _checkAndRestartApiRequest() {
    print('开始检查API请求状态');
    
    // 检查条件1：检查对话完整性
    _checkConversationIntegrity();
    
    // 检查条件2：游戏未结束，但处于正在输入状态且没有活跃的流式输出计时器
    // 这种情况通常发生在用户快速切换界面导致API请求被中断
    if (!_gameEnded && _isTyping && _streamingTimer == null) {
      // 检查对话历史长度
      if (_conversationHistory.length > 1) {
        // 检查是否已经有AI回复但未显示
        final lastHistory = _conversationHistory.last;
        final hasAiReply = lastHistory['role'] == 'assistant';
        
        if (!hasAiReply) {
          // 没有AI回复，重新发起API请求
          print('检测到未完成的API请求，重新发起请求');
          _callDoubaoApi();
        } else {
          // 已经有AI回复，重置状态
          print('检测到已完成的API请求但状态异常，重置状态');
          setState(() {
            _isTyping = false;
          });
          _saveConversation();
        }
      } else if (_conversationHistory.length == 1 && _messages.isEmpty) {
        // 只有system prompt，且没有消息，这是正常的初始化状态
        // 不要重新初始化，只需要重新发起API请求获取AI开场白
        print('检测到初始化状态，重新发起API请求获取AI开场白');
        _callDoubaoApi();
      } else {
        // 其他情况，重置正在输入状态
        print('检测到异常的正在输入状态，重置状态');
        setState(() {
          _isTyping = false;
        });
        _saveConversation();
      }
    }
    
    // 检查条件3：检查是否有未完全显示的消息
    // 这种情况发生在API请求完成，但流式显示未完成时用户切换界面
    if (_messages.isNotEmpty) {
      for (int i = 0; i < _messages.length; i++) {
        final Map<String, dynamic> message = _messages[i];
        // 确保所有必要字段存在
        if (!message.containsKey('isUser') || !message.containsKey('isTyping') || 
            !message.containsKey('text') || !message.containsKey('fullText')) {
          continue;
        }
        
        if (!message['isUser'] && message['isTyping'] == true && 
            message['text'].length < message['fullText'].length) {
          // 找到未完全显示的消息，继续流式显示
          print('检测到未完全显示的消息，继续流式显示');
          _startStreaming(i);
          break;
        }
      }
    }
    
    // 检查条件4：处理待处理的API响应
    _processPendingResponses();
    
    print('API请求状态检查完成');
  }
  
  // 显示受骗提示弹窗
  void _showDeceivedWarning(BuildContext context, String content) {
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
                        '您已受骗',
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
              
              // 内容区域 - 完全自适应高度，根据内容动态调整
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(16.0),
                constraints: BoxConstraints(
                  maxHeight: 300, // 最大高度限制，适当放宽以容纳更多内容
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          height: 1.4, // 调整行高，使文本更紧凑
                        ),
                      ),
                    ],
                  ),
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
                        Navigator.pop(context); // 关闭弹窗
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
  
  // 显示成功识别诈骗提示弹窗
  void _showSuccessWarning(BuildContext context, String content) {
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
                Color(0xFFF0FFF0), // 指定的颜色：#F0FFF0
                Color(0xFFF0FFF0), // 指定的颜色：#F0FFF0
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
                        'assets/images/lfx.png',
                        width: 24.0,
                        height: 24.0,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8.0),
                      const Text(
                        '成功识别诈骗',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 内容区域 - 完全自适应高度，根据内容动态调整
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(16.0),
                constraints: BoxConstraints(
                  maxHeight: 300, // 最大高度限制，适当放宽以容纳更多内容
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          height: 1.4, // 调整行高，使文本更紧凑
                        ),
                      ),
                    ],
                  ),
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
                        Navigator.pop(context); // 关闭弹窗
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
  
  // 处理待处理的API响应
  void _processPendingResponses() {
    if (_pendingResponses.isNotEmpty && mounted) {
      print('开始处理待处理响应，队列大小: ${_pendingResponses.length}');
      
      // 创建临时列表，避免并发修改问题
      final List<String> responsesToProcess = List.from(_pendingResponses);
      
      // 清空待处理队列
      _pendingResponses.clear();
      
      // 处理所有待处理的响应
      for (String aiRaw in responsesToProcess) {
        Map<String, dynamic> aiResult = _parseAiResponse(aiRaw);
        
        print('处理待处理响应，结果: $aiResult');
        
        // 确保在处理响应时组件仍然挂载
        if (mounted) {
          // 使用流式输出显示AI回复
          _addStreamingMessage(aiResult['content']);
          
          // 根据status处理，显示相应弹窗
          if (aiResult['status'] == 1 || aiResult['status'] == 0) {
            _gameEnded = true;
            
            // 延迟显示弹窗，确保消息已经显示
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                if (aiResult['status'] == 1) {
                  _showDeceivedWarning(context, aiResult['content']);
                } else {
                  _showSuccessWarning(context, aiResult['content']);
                }
              }
            });
          }
        }
      }
      
      // 保存对话进度
      _saveConversation();
      print('待处理响应处理完成');
    } else {
      print('没有待处理响应或组件未挂载');
    }
  }
  
  // 检查错误类型并返回对应的处理策略
  Map<String, dynamic> _getErrorStrategy(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    
    // 可恢复错误 - 切换密钥重试
    Set<String> recoverablePatterns = {
      '429', '404', '403', '401', '502', '503', '504', // HTTP状态码
      'ratelimiterror', 'modelnotopen', 'notfounderror', 'setlimitexceeded', 'authenticationerror', // 特定错误类型
      'timeout', 'connection', 'gateway', // 网络相关错误
    };
    
    bool isRecoverable = recoverablePatterns.any((pattern) => errorStr.contains(pattern));
    
    // 网络错误或其他错误 - 所有错误都返回相同的友好提示
    return {
      'isRecoverable': isRecoverable,
      'shouldRetry': isRecoverable,
      'errorMessage': '刚才有点卡，你说啥？',
      'isNetworkError': false
    };
  }
  
  // 调用Doubao API
  Future<void> _callDoubaoApi() async {
    // 检查是否已经在调用API，避免重复调用导致多个开场白
    if (_isApiCalling) {
      print('API调用已在进行中，跳过重复调用');
      return;
    }
    
    try {
      // 设置API调用中标志
      setState(() {
        _isApiCalling = true;
      });
      
      // 构建请求体
      final requestBody = {
        "model": _modelId,
        "messages": _conversationHistory,
        "temperature": 0.8,
        "response_format": {"type": "json_object"}
      };
      
      print('开始发送API请求，对话历史长度: ${_conversationHistory.length}');
      
      // 重试机制：
      // - 针对可恢复错误：最多重试API密钥数量次
      // - 针对网络未连接：不重试，直接提示用户
      int retryCount = 0;
      final maxRetries = _apiKeys.length;
      bool requestSuccess = false;
      
      while (retryCount < maxRetries && !requestSuccess) {
        try {
          print('使用API密钥索引 $_currentApiKeyIndex 发送请求');
          
          // 发送请求，使用当前API密钥
          final response = await http.post(
            Uri.parse("$_baseUrl/chat/completions"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $currentApiKey"
            },
            body: json.encode(requestBody)
          );
          
          // 解析响应
          if (response.statusCode == 200) {
            // 请求成功
            final responseData = json.decode(response.body);
            final aiRaw = responseData['choices'][0]['message']['content'];
            
            print('API响应成功获取，raw: $aiRaw');
            
            // 检查组件是否在前台可见
            if (mounted && _isMounted) {
              // 组件在前台，直接处理响应
              Map<String, dynamic> aiResult = _parseAiResponse(aiRaw);
              
              // 更新对话历史，保存AI原始JSON
              _conversationHistory.add({
                'role': 'assistant',
                'content': aiRaw
              });
              
              // 使用流式输出
              print('直接处理响应，调用_addStreamingMessage');
              _addStreamingMessage(aiResult['content']);
              
              // 根据status处理，显示相应弹窗
              if (aiResult['status'] == 1 || aiResult['status'] == 0) {
                _gameEnded = true;
                
                // 延迟显示弹窗，确保消息已经显示
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    if (aiResult['status'] == 1) {
                      _showDeceivedWarning(context, aiResult['content']);
                    } else {
                      _showSuccessWarning(context, aiResult['content']);
                    }
                  }
                });
              }
              
              // 保存对话进度
              _saveConversation();
            } else {
              // 组件不在前台，将响应添加到待处理队列
              print('组件不可见，添加响应到待处理队列: $aiRaw');
              _pendingResponses.add(aiRaw);
              
              // 更新对话历史
              _conversationHistory.add({
                'role': 'assistant',
                'content': aiRaw
              });
              
              // 更新状态
              _isTyping = false;
              
              // 保存对话进度
              _saveConversation();
              
              print('待处理队列大小: ${_pendingResponses.length}');
            }
            
            // 请求成功，退出循环
            requestSuccess = true;
          } else {
            // 检查HTTP状态码错误策略
            String errorMsg = 'API请求失败: ${response.statusCode} - ${response.body}';
            print(errorMsg);
            
            // 处理HTTP错误
            var errorStrategy = _getErrorStrategy(response.statusCode);
            if (errorStrategy['shouldRetry']) {
              // 可恢复错误，切换到下一个API密钥
              print('遇到可恢复的HTTP错误，正在切换API密钥...');
              _switchToNextApiKey();
              retryCount++;
              await Future.delayed(Duration(milliseconds: 500));
            } else {
              // 不可恢复错误，直接抛出
              throw Exception(errorMsg);
            }
          }
        } catch (e) {
          // 检查异常的错误策略
          var errorStrategy = _getErrorStrategy(e);
          print('API请求失败: $e');
          
          if (errorStrategy['shouldRetry']) {
            // 可恢复错误，切换到下一个API密钥
            print('遇到可恢复异常，正在切换API密钥...');
            _switchToNextApiKey();
            retryCount++;
            await Future.delayed(Duration(milliseconds: 500));
          } else {
            // 不可恢复错误，直接抛出
            print('遇到不可恢复错误，不再重试: $e');
            throw Exception(e);
          }
        }
      }
      
      // 如果所有重试都失败
      if (!requestSuccess) {
        print('所有API密钥都已尝试，请求失败');
        throw Exception('所有API密钥都已达到速率限制或遇到错误');
      }
    } catch (e) {
      // 处理异常
      print("API调用异常：$e");
      
      // 获取错误处理策略
      var errorStrategy = _getErrorStrategy(e);
      
      // 检查组件是否在前台
      if (_isMounted && mounted) {
        // 组件在前台，根据错误策略显示相应消息
        Map<String, dynamic> aiResult = {
          'status': 2, 
          'content': errorStrategy['errorMessage']
        };
        _addStreamingMessage(aiResult['content']);
      } else {
        // 组件不在前台，更新状态并保存
        _isTyping = false;
        _saveConversation();
      }
    } finally {
      // 无论成功失败，都重置API调用标志
      setState(() {
        _isApiCalling = false;
        _isTyping = false;
      });
      
      print('API调用结束，重置调用状态');
    }
  }

  @override
  void dispose() {
    // 保存对话进度（注意：这里不要设置_gameEnded = true，否则会导致游戏结束状态被错误保存）
    _saveConversation();
    
    // 取消所有计时器
    _streamingTimer?.cancel();
    
    // 释放资源
    _messageController.dispose();
    _scrollController.dispose();
    
    super.dispose();
  }
  
  // 解析AI响应
  Map<String, dynamic> _parseAiResponse(String responseText) {
    try {
      final result = json.decode(responseText.trim());
      if (result.containsKey('status') && result.containsKey('content')) {
        return {
          'status': result['status'],
          'content': result['content']
        };
      }
      throw Exception("缺少必要字段");
    } catch (e) {
      // 异常时默认继续对话
      return {'status': 2, 'content': '刚才有点卡，你说啥？'};
    }
  }

  void _sendMessage() {
    if (_gameEnded) {
      // 游戏结束后重置
      _initGame();
      return;
    }
    
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      // 确保对话历史格式正确
      if (_conversationHistory.isEmpty) {
        // 初始化对话历史
        String systemPrompt = _buildSystemPrompt();
        _conversationHistory.add({
          'role': 'system',
          'content': systemPrompt
        });
      }
      
      // 添加用户消息到消息列表
      final Map<String, dynamic> userMessage = {
        'text': message,
        'isUser': true,
        'isTyping': false,
        'fullText': message,
        'currentIndex': message.length,
        'placeholderText': message,
      };
      
      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
        _isTyping = true; // 设置为正在输入状态
      });
      
      // 自动滚动到底部
      _scrollToBottom();
      
      // 延迟一点再滚动，确保正在输入状态显示时也能滚动到底部
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });

      // 将用户输入添加到对话历史
      _conversationHistory.add({
        'role': 'user',
        'content': message
      });
      
      // 保存对话进度
      _saveConversation();

      // 调用API获取AI回复
      _callDoubaoApi();
    }
  }
  
  // 流式输出消息
  void _addStreamingMessage(String fullText) {
    // 检查组件是否仍然挂载
    if (!mounted) return;
    
    setState(() {
      _isTyping = false; // 取消"正在输入中"状态
      _messages.add({
        'text': '', // 开始时为空
        'isUser': false,
        'isTyping': true, // 设置为正在逐字显示
        'fullText': fullText, // 保存完整文本
        'currentIndex': 0, // 当前显示的字符索引
      });
    });
    
    _scrollToBottom();
    
    // 开始流式输出
    _startStreaming(_messages.length - 1);
    
    // 保存对话进度
    _saveConversation();
  }
  
  // 开始流式输出
  void _startStreaming(int messageIndex) {
    _streamingTimer?.cancel(); // 取消之前的计时器
    
    const typingSpeed = Duration(milliseconds: 50); // 打字速度
    int currentIndex = 0;
    String fullText = _messages[messageIndex]['fullText'];
    
    // 预先设置完整文本和占位符，避免容器高度频繁变化
    setState(() {
      // 预先设置完整文本，确保容器有固定高度
      _messages[messageIndex]['text'] = '';
      _messages[messageIndex]['placeholderText'] = fullText;
      _messages[messageIndex]['isTyping'] = true;
    });
    
    _streamingTimer = Timer.periodic(typingSpeed, (timer) {
      if (currentIndex < fullText.length) {
        // 检查组件是否仍然挂载
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        // 直接更新消息文本
        _messages[messageIndex]['text'] = fullText.substring(0, currentIndex + 1);
        _messages[messageIndex]['currentIndex'] = currentIndex + 1;
        
        // 优化：大幅减少UI更新频率，每5个字符更新一次
        if (currentIndex % 1 == 0) { 
          setState(() {});
          
          // 每10个字符滚动一次，减少滚动对UI的影响
          if (currentIndex % 18 == 0) {
            _scrollToBottom();
          }
        }
        
        currentIndex++;
      } else {
        // 检查组件是否仍然挂载
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        // 流式输出完成
        setState(() {
          _messages[messageIndex]['text'] = fullText;
          _messages[messageIndex]['isTyping'] = false;
          _messages[messageIndex].remove('placeholderText'); // 移除占位符
        });
        
        timer.cancel();
        _scrollToBottom(); // 最终滚动到底部
        
        // 保存对话进度
        _saveConversation();
      }
    });
  }
  
  // 直接显示消息（保留用于初始消息）
  void _addMessageDirectly(String fullText) {
    // 检查组件是否仍然挂载
    if (!mounted) return;
    
    setState(() {
      _isTyping = false; // 取消"正在输入中"状态
      _messages.add({
        'text': fullText, // 直接显示完整文本
        'isUser': false,
        'isTyping': false, // 不使用逐字显示
        'fullText': fullText, // 保存完整文本
      });
    });
    
    _scrollToBottom();
    
    // 保存对话进度
    _saveConversation();
  }
  
  // 自动滚动到底部，确保最后一条消息有足够空间显示
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // 滚动到最大滚动范围，并添加额外的偏移量
        // 确保最后一条消息与输入框之间有足够的空间
        double scrollOffset = _scrollController.position.maxScrollExtent;
        
        // 添加额外的偏移量，根据实际情况调整
        // 这个值可以根据输入框的高度和间距进行调整
        scrollOffset += 50.0; // 添加50px的额外空间
        
        _scrollController.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6F0FF),
              Color(0xFFF5F9FF),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
              // 页面标题和标签 - 移除图标，覆盖顶部所有区域
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x08000000),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4.0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 居中标题，移除返回按钮，采用iOS风格设计
                    Column(
                      children: [
                      Text(
                        '辨诈实战演练',
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        '提高防诈骗意识，保护个人信息安全',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: AppTheme.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 内容区域 - 只显示文本聊天视图
            Expanded(
              child: _buildChatView(),
            ),
          ],
        ),
      ),
    );
  }

  // 文本聊天视图
  Widget _buildChatView() {
    return GestureDetector(
      // 点击页面空白区域自动收回输入法
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Column(
        children: [
        // 聊天头部 - iOS风格设计
        Container(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF1E88E5),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8.0,
                      offset: const Offset(0, 3.0),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/robot.png',
                  width: 24.0,
                  height: 24.0,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI反诈实战',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 8.0,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '模拟各类诈骗套路',
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 消息列表 - 使用渐变背景，增大聊天框
        Expanded(
          child: Stack(
            children: [
              // 渐变背景
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE6F0FF),
                      Color(0xFFF5F9FF),
                    ],
                  ),
                ),
              ),

              // 消息列表 - 可以遮挡背景提示，添加滚动控制器
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length + (_isTyping ? 1 : 0), // 如果正在输入，增加一个item
                itemBuilder: (context, index) {
                  // 如果是最后一个项目且正在输入中，显示正在输入提示
                  if (index == _messages.length && _isTyping) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6.0),
                            topRight: Radius.circular(20.0),
                            bottomLeft: Radius.circular(20.0),
                            bottomRight: Radius.circular(20.0),
                          ),
                          boxShadow: [
                            const BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 6.0,
                              offset: Offset(0, 2.0),
                            ),
                          ],
                          border: Border.all(color: AppTheme.border, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.textLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              '对方正在输入中',
                              style: TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 14.5,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 显示普通消息
                  final message = _messages[index];
                  return Align(
                    alignment: message['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
                    child: Stack(
                      children: [
                        // 占位符文本 - 用于固定容器高度，避免拉伸
                        Opacity(
                          opacity: 0.0,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            margin: const EdgeInsets.only(bottom: 12.0),
                            decoration: BoxDecoration(
                                color: message['isUser'] ? AppTheme.primaryColor : Colors.white,
                                borderRadius: message['isUser']
                                    ? const BorderRadius.only(
                                        topLeft: Radius.circular(20.0),
                                        topRight: Radius.circular(6.0),
                                        bottomLeft: Radius.circular(20.0),
                                        bottomRight: Radius.circular(20.0),
                                      )
                                    : const BorderRadius.only(
                                        topLeft: Radius.circular(6.0),
                                        topRight: Radius.circular(20.0),
                                        bottomLeft: Radius.circular(20.0),
                                        bottomRight: Radius.circular(20.0),
                                      ),
                                border: !message['isUser'] ? Border.all(color: AppTheme.border, width: 0.5) : null,
                              ),
                            child: Text(
                              message['placeholderText'] ?? message['fullText'] ?? message['text'],
                              style: TextStyle(
                                  color: message['isUser'] ? Colors.white : AppTheme.textPrimary,
                                  fontSize: 14.5,
                                  height: 1.55,
                                ),
                            ),
                          ),
                        ),
                        // 实际显示的文本
                        Container(
                          constraints: const BoxConstraints(maxWidth: 280.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          margin: const EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(
                              color: message['isUser'] ? AppTheme.primaryColor : Colors.white,
                              borderRadius: message['isUser']
                                  ? const BorderRadius.only(
                                      topLeft: Radius.circular(20.0),
                                      topRight: Radius.circular(6.0),
                                      bottomLeft: Radius.circular(20.0),
                                      bottomRight: Radius.circular(20.0),
                                    )
                                  : const BorderRadius.only(
                                      topLeft: Radius.circular(6.0),
                                      topRight: Radius.circular(20.0),
                                      bottomLeft: Radius.circular(20.0),
                                      bottomRight: Radius.circular(20.0),
                                    ),
                              boxShadow: [
                                const BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.1),
                                  blurRadius: 6.0,
                                  offset: Offset(0, 2.0),
                                ),
                              ],
                              border: !message['isUser'] ? Border.all(color: AppTheme.border, width: 0.5) : null,
                            ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  message['text'],
                                  style: TextStyle(
                                      color: message['isUser'] ? Colors.white : AppTheme.textPrimary,
                                      fontSize: 14.5,
                                      height: 1.55,
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // 输入区域 - 美化设计，增大输入框
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: AppTheme.border, width: 0.5),
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12.0,
                offset: Offset(0, -4.0),
              ),
            ],
          ),
          child: Column(
            children: [
              // 游戏结束提示
              if (_gameEnded) 
                Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: Color(0xFF4CAF50), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF4CAF50),
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          '游戏已结束，点击发送按钮重新开始',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // 输入框和发送按钮
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(32.0),
                        border: Border.all(color: AppTheme.border, width: 0.5),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: _gameEnded ? '点击发送按钮重新开始游戏' : '输入您的回复...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 15.0,
                          color: AppTheme.textPrimary,
                        ),
                        // 当获取焦点时滚动到底部，延迟执行确保输入法完全弹出
                        onTap: () {
                          // 添加500毫秒延迟，确保输入法完全弹出后再滚动
                          // 这样可以确保滚动位置更加准确
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _scrollToBottom();
                          });
                        },
                        // 监听焦点变化，获取焦点时滚动到底部
                        onTapOutside: (_) {
                          // 点击输入框外部，键盘隐藏时不需要滚动
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 52.0,
                      height: 52.0,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF1E88E5),
                            Color(0xFF1E88E5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26.0),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0x3364B5F6),
                            blurRadius: 6.0,
                            offset: Offset(0, 3.0),
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        scale: 0.6,
                        child: Image.asset(
                          'assets/images/submit.png',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
}
