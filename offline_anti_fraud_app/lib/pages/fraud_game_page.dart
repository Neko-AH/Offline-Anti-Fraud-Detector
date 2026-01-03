import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:offline_anti_fraud_app/providers/points_provider.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';
import 'package:offline_anti_fraud_app/utils/snackbar_utils.dart';

class FraudGamePage extends StatefulWidget {
  const FraudGamePage({super.key});

  @override
  State<FraudGamePage> createState() => _FraudGamePageState();
}

class _FraudGamePageState extends State<FraudGamePage> {
  int _currentQuestionIndex = 0;
  int _selectedOption = -1;
  bool _isCompleted = false;
  bool _showAnswer = false;
  bool _isCorrect = false;
  bool _hasSubmitted = false;

  List<Map<String, dynamic>> _questionStates = [];

  List<Map<String, dynamic>> _questionPool = [];
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/Question_bank.json');
      final data = json.decode(response);
      
      // 从JSON中提取所有题目
      List<Map<String, dynamic>> allQuestions = [];
      for (var level in data['all']) {
        for (var question in level['questions']) {
          allQuestions.add({
            'question': question['question'],
            'options': question['options'],
            'correctAnswer': question['correct'],
            'explanation': question['explanation'],
          });
        }
      }
      
      // 尝试加载保存的游戏进度
      final savedProgress = await _loadGameProgress();
      
      setState(() {
        _questionPool = allQuestions;
        
        if (savedProgress != null) {
          // 恢复保存的游戏进度
          _questions = List<Map<String, dynamic>>.from(savedProgress['questions']);
          _currentQuestionIndex = savedProgress['currentQuestionIndex'];
          _questionStates = List<Map<String, dynamic>>.from(savedProgress['questionStates']);
          _isCompleted = savedProgress['isCompleted'];
          
          // 恢复当前题目的状态
          if (_currentQuestionIndex < _questionStates.length) {
            final currentState = _questionStates[_currentQuestionIndex];
            _selectedOption = currentState['selectedOption'];
            _showAnswer = currentState['hasSubmitted'];
            _isCorrect = currentState['isCorrect'];
            _hasSubmitted = currentState['hasSubmitted'];
          }
        } else {
          // 初始化新的游戏
          _initializeQuestions();
          _questionStates = List.generate(_questions.length, (index) => {
            'selectedOption': -1,
            'isCorrect': false,
            'hasSubmitted': false,
          });
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeQuestions() {
    final List<Map<String, dynamic>> shuffledPool = List.from(_questionPool)..shuffle();
    _questions = shuffledPool.take(10).toList();
  }

  Future<Map<String, dynamic>?> _loadGameProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('fraudGameProgress');
      
      if (progressJson != null) {
        return json.decode(progressJson);
      }
    } catch (e) {
      print('Error loading game progress: $e');
    }
    return null;
  }

  Future<void> _saveGameProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = {
        'questions': _questions,
        'currentQuestionIndex': _currentQuestionIndex,
        'questionStates': _questionStates,
        'isCompleted': _isCompleted,
      };
      
      final progressJson = json.encode(progress);
      await prefs.setString('fraudGameProgress', progressJson);
    } catch (e) {
      print('Error saving game progress: $e');
    }
  }

  Future<void> _clearGameProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fraudGameProgress');
    } catch (e) {
      print('Error clearing game progress: $e');
    }
  }

  void _restartGame() {
    // 清除之前的游戏进度
    _clearGameProgress();
    
    // 从完整题库中重新随机选择 10 个题目
    _initializeQuestions();
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOption = -1;
      _isCompleted = false;
      _showAnswer = false;
      _isCorrect = false;
      _hasSubmitted = false;
      _questionStates = List.generate(_questions.length, (index) => {
        'selectedOption': -1,
        'isCorrect': false,
        'hasSubmitted': false,
      });
    });
  }

  void _selectOption(int index) {
    if (!_showAnswer) {
      setState(() {
        _selectedOption = index;
      });
    }
  }

  void _submitAnswer() {
    if (_selectedOption == -1) {
      SnackBarUtils.showSnackBar('请选择一个选项', context);
      return;
    }

    final isCorrect = _selectedOption == _questions[_currentQuestionIndex]['correctAnswer'];
    _isCorrect = isCorrect;
    _hasSubmitted = true;

    _questionStates[_currentQuestionIndex] = {
      'selectedOption': _selectedOption,
      'isCorrect': isCorrect,
      'hasSubmitted': true,
    };

    if (isCorrect) {
      Provider.of<PointsProvider>(context, listen: false).addPoints(10);
    }

    setState(() {
      _showAnswer = true;
    });

    // 保存游戏进度
    _saveGameProgress();
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        final currentState = _questionStates[_currentQuestionIndex];
        _selectedOption = currentState['selectedOption'];
        _showAnswer = currentState['hasSubmitted'];
        _isCorrect = currentState['isCorrect'];
        _hasSubmitted = currentState['hasSubmitted'];
      });
      
      // 保存游戏进度
      _saveGameProgress();
    } else {
      setState(() {
        _isCompleted = true;
      });
      
      // 保存游戏进度
      _saveGameProgress();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        final currentState = _questionStates[_currentQuestionIndex];
        _selectedOption = currentState['selectedOption'];
        _showAnswer = currentState['hasSubmitted'];
        _isCorrect = currentState['isCorrect'];
        _hasSubmitted = currentState['hasSubmitted'];
      });
      
      // 保存游戏进度
      _saveGameProgress();
    }
  }

  Color _getOptionColor(int index) {
    if (!_showAnswer) {
      return _selectedOption == index
          ? AppTheme.primaryColor.withOpacity(0.1)
          : Colors.white;
    }

    final correctIndex = _questions[_currentQuestionIndex]['correctAnswer'];

    if (_isCorrect) {
      if (index == correctIndex) {
        return AppTheme.success.withOpacity(0.1);
      }
    } else {
      if (index == _selectedOption) {
        return AppTheme.error.withOpacity(0.1);
      } else if (index == correctIndex) {
        return AppTheme.success.withOpacity(0.1);
      }
    }
    return Colors.white;
  }

  Color _getOptionBorderColor(int index) {
    if (!_showAnswer) {
      return _selectedOption == index ? AppTheme.primaryColor : AppTheme.border;
    }

    final correctIndex = _questions[_currentQuestionIndex]['correctAnswer'];

    if (_isCorrect) {
      if (index == correctIndex) {
        return AppTheme.success;
      }
    } else {
      if (index == _selectedOption) {
        return AppTheme.error;
      } else if (index == correctIndex) {
        return AppTheme.success;
      }
    }
    return AppTheme.border;
  }

  Color _getOptionCircleColor(int index) {
    if (!_showAnswer) {
      return _selectedOption == index ? AppTheme.primaryDark : AppTheme.primaryLight;
    }

    final correctIndex = _questions[_currentQuestionIndex]['correctAnswer'];

    if (_isCorrect) {
      if (index == correctIndex) {
        return AppTheme.success;
      }
    } else {
      if (index == _selectedOption) {
        return AppTheme.error;
      } else if (index == correctIndex) {
        return AppTheme.success;
      }
    }
    return AppTheme.primaryLight;
  }

  Color _getOptionTextColor(int index) {
    if (!_showAnswer) {
      return AppTheme.textPrimary;
    }

    final correctIndex = _questions[_currentQuestionIndex]['correctAnswer'];

    if (_isCorrect) {
      if (index == correctIndex) {
        return AppTheme.success;
      }
    } else {
      if (index == _selectedOption) {
        return AppTheme.error;
      } else if (index == correctIndex) {
        return AppTheme.success;
      }
    }
    return AppTheme.textPrimary;
  }

  String _getExplanation(int questionIndex) {
    return _questions[questionIndex]['explanation'];
  }

  @override
  Widget build(BuildContext context) {
    // 使用固定像素值，保持界面一致性
    // 基础间距/内边距
    const padding12Vertical = 12.0;
    const padding8Horizontal = 8.0;
    const padding2Vertical = 2.0;
    const padding4Horizontal = 4.0;
    const padding20All = 20.0;
    const padding16All = 16.0;
    const padding12All = 12.0;
    const padding15Vertical = 15.0;
    const padding14Vertical = 14.0;
    const padding6Horizontal = 6.0;

    // 间距
    const margin4Height = 4.0;
    const margin10Height = 10.0;
    const margin5Height = 5.0;
    const margin16Height = 16.0;
    const margin8Bottom = 8.0;
    const margin10Right = 10.0;
    const margin12Right = 12.0;
    const margin12Height = 12.0;
    const margin8Height = 8.0;
    const margin16Bottom = 16.0;
    const margin12Width = 12.0;
    const margin8Width = 8.0;

    // 圆角
    const radius12 = 12.0;
    const radius10 = 10.0;
    const radius18 = 18.0;
    const radius14 = 14.0;
    const radius13 = 13.0;

    // 尺寸
    const size12 = 12.0;
    const size13 = 13.0;
    const size14 = 14.0;
    const size16 = 16.0;
    const size22 = 22.0;
    const size28 = 28.0;
    const size26 = 26.0;
    const height8 = 8.0;

    // 阴影
    const shadowBlur6 = 6.0;
    const shadowOffset3 = 3.0;
    const shadowBlur12 = 12.0;
    const shadowOffset4 = 4.0;
    const shadowBlur10 = 10.0;

    // 显示加载状态
    if (_isLoading || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      // 让整个页面内容可滚动，彻底解决溢出
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // 页面标题区域
              Container(
                padding: EdgeInsets.fromLTRB(0, 40.0, 0, padding12Vertical),
                decoration: const BoxDecoration(
                  color: AppTheme.cardBackground,
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Row(
                          children: [
                            const Expanded(child: SizedBox()),
                            Text(
                              '防诈知识闯关',
                              style: TextStyle(
                                fontSize: size22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: padding16All),
                            child: Consumer<PointsProvider>(
                              builder: (context, pointsProvider, child) {
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: padding8Horizontal, vertical: padding2Vertical),
                                  decoration: BoxDecoration(
                                    color: AppTheme.border,
                                    borderRadius: BorderRadius.circular(radius12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/credit.png',
                                        width: size12,
                                        height: size12,
                                      ),
                                      SizedBox(width: padding4Horizontal),
                                      Text(
                                        '${pointsProvider.points}',
                                        style: TextStyle(
                                          fontSize: size12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: margin4Height),
                  Center(
                    child: Text(
                      '一共${_questions.length}题，每答对1题获得10积分',
                      style: TextStyle(
                        fontSize: size14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                  SizedBox(height: margin10Height),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: padding16All * 1.5),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '第${_currentQuestionIndex + 1}题',
                              style: TextStyle(
                                fontSize: size13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              '共${_questions.length}题',
                              style: TextStyle(
                                fontSize: size13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: margin5Height),
                        Container(
                          height: height8,
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(radius10),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                height: height8,
                                decoration: BoxDecoration(
                                  color: AppTheme.border,
                                  borderRadius: BorderRadius.circular(radius10),
                                ),
                              ),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(
                                  height: height8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(radius10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 主要内容区域
            Container(
              padding: EdgeInsets.all(padding20All),
              child: Column(
                children: [
                  // 题目容器
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(radius18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x08000000),
                          blurRadius: shadowBlur12,
                          offset: Offset(0, shadowOffset4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 题目头部
                        Container(
                          padding: EdgeInsets.all(padding16All),
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            border: Border(
                              bottom: BorderSide(color: AppTheme.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: size28,
                                height: size28,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(radius14),
                                ),
                                child: Center(
                                  child: Text(
                                    '${_currentQuestionIndex + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: size14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: margin10Right),
                              Text(
                                '防诈选择题',
                                style: TextStyle(
                                  fontSize: size16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 题目内容
                        Container(
                          padding: EdgeInsets.all(padding16All),
                          child: Column(
                            children: [
                              // 题目文本
                              Text(
                                currentQuestion['question'],
                                style: TextStyle(
                                  fontSize: size16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: margin12Height),

                              // 选项列表
                              Column(
                                children: [
                                  ...List.generate(currentQuestion['options'].length, (index) {
                                    return GestureDetector(
                                      onTap: _showAnswer ? null : () => _selectOption(index),
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: margin8Bottom),
                                        padding: EdgeInsets.all(padding12All),
                                        decoration: BoxDecoration(
                                          color: _getOptionColor(index),
                                          borderRadius: BorderRadius.circular(radius12),
                                          boxShadow: _selectedOption == index
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                                    blurRadius: shadowBlur6,
                                                    offset: Offset(0, shadowOffset3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: size26,
                                              height: size26,
                                              margin: EdgeInsets.only(right: margin12Right),
                                              decoration: BoxDecoration(
                                                color: _getOptionCircleColor(index),
                                                borderRadius: BorderRadius.circular(radius13),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  String.fromCharCode(65 + index),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: size14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                currentQuestion['options'][index],
                                                style: TextStyle(
                                                  fontSize: size14,
                                                  color: _getOptionTextColor(index),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                  // 错误提示和防诈知识
                                  if (_showAnswer && !_isCorrect) ...[
                                    SizedBox(height: margin12Height),
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/warn.png',
                                          width: size14,
                                          height: size14,
                                          color: AppTheme.error,
                                        ),
                                        SizedBox(width: margin8Width),
                                        Text(
                                          '回答错误',
                                          style: TextStyle(
                                            color: AppTheme.error,
                                            fontSize: size14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: margin8Height),
                                    Container(
                                      padding: EdgeInsets.all(padding12All),
                                      decoration: BoxDecoration(
                                        color: AppTheme.border.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(radius12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '防诈知识：',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: size14,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: margin4Height),
                                          Text(
                                            _getExplanation(_currentQuestionIndex),
                                            style: TextStyle(
                                              fontSize: size14,
                                              color: AppTheme.textPrimary,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // 正确时的防诈知识
                                  if (_showAnswer && _isCorrect) ...[
                                    SizedBox(height: margin12Height),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '防骗知识：',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: size14,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: margin8Height),
                                        Text(
                                          _getExplanation(_currentQuestionIndex),
                                          style: TextStyle(
                                            fontSize: size14,
                                            color: AppTheme.textPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_currentQuestionIndex == _questions.length - 1) ...[
                                      SizedBox(height: margin16Bottom),
                                      Container(
                                        padding: EdgeInsets.all(padding12All),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(radius12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '恭喜完成所有测试！',
                                            style: TextStyle(
                                              fontSize: size16,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1E88E5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 行动按钮区域
                  SizedBox(height: margin16Height),

                  if (!_showAnswer)
                    GestureDetector(
                      onTap: _submitAnswer,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: padding15Vertical),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(radius14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x3364B5F6),
                              blurRadius: shadowBlur10,
                              offset: Offset(0, shadowOffset4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '提交',
                          style: TextStyle(
                            fontSize: size16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: padding15Vertical),
                              decoration: BoxDecoration(
                                color: _currentQuestionIndex > 0 ? AppTheme.primaryColor : Colors.grey,
                                borderRadius: BorderRadius.circular(radius14),
                                boxShadow: _currentQuestionIndex > 0 ? [
                                  BoxShadow(
                                    color: const Color(0x3364B5F6),
                                    blurRadius: shadowBlur10,
                                    offset: Offset(0, shadowOffset4),
                                  ),
                                ] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '上一题',
                                style: TextStyle(
                                  fontSize: size16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: margin12Width),
                        Expanded(
                          child: GestureDetector(
                            onTap: _currentQuestionIndex == _questions.length - 1 ? _restartGame : _goToNextQuestion,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: padding15Vertical),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(radius14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x3364B5F6),
                                    blurRadius: shadowBlur10,
                                    offset: Offset(0, shadowOffset4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _currentQuestionIndex == _questions.length - 1
                                    ? '下一轮'
                                    : '下一题',
                                style: TextStyle(
                                  fontSize: size16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
      ),
    );
  }
}