import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_anti_fraud_app/pages/home_page.dart';
import 'package:offline_anti_fraud_app/providers/auth_provider.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _showAgreement = true;
  bool _showPassword = false;
  bool _loginFailed = false;
  String _errorMessage = ''; // 新增错误信息变量
  final _phoneController = TextEditingController(text: '123456');
  final _passwordController = TextEditingController(text: '123456');

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white, // 背景颜色改为白色
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white, // 确保整个容器为白色
          child: Stack(
            children: [
              // 用户协议弹窗
              if (_showAgreement)
                _buildAgreementModal(),
              
              // 登录页面
              if (!_showAgreement)
                _buildLoginForm(context),
            ],
          ),
        ),
      ),
    );
  }

  // 用户协议弹窗
  Widget _buildAgreementModal() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // 协议标题
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppTheme.primaryColor,
                  child: Transform.scale(
                    scale: 0.6,
                    child: Image.asset(
                      'assets/images/bxy.png',
                      fit: BoxFit.contain,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  '用户协议与隐私政策',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // 协议内容
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFF), // 改为#F8FAFF
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '欢迎使用线下反诈通',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '感谢您选择使用我们的产品。在开始使用前，请仔细阅读以下用户协议和隐私政策条款。',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF424242), // 更深的灰色
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    const Text(
                      '用户协议',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1. 您同意遵守所有适用的法律法规，不得利用本服务进行任何非法活动。',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF424242), // 更深的灰色
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2. 您同意不干扰本服务的正常运行，不尝试获取未授权的访问权限。',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF424242), // 更深的灰色
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3. 我们保留在任何时候修改本协议的权利，修改后的协议将在本页面公布。',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF424242), // 更深的灰色
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    const Text(
                      '隐私政策',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '我们非常重视您的隐私权，并承诺保护您的个人信息安全。',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF424242), // 更深的灰色
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E6), // 保持原浅黄色背景
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: const Color(0xFFFF9800), // 左侧橙色竖线
                            width: 3, // 窄幅竖线
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '语音监控说明',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '为了提供更好的反诈服务，我们需要您的同意开启语音实时监控功能：',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF424242), // 与隐私政策文字样式一致
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• 系统将实时分析您的通话内容以识别潜在的诈骗风险',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF424242), // 与隐私政策文字样式一致
                            ),
                          ),
                          const Text(
                            '• 所有分析过程均在设备端完成，您的语音数据不会被上传或保存',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF424242), // 与隐私政策文字样式一致
                            ),
                          ),
                          const Text(
                            '• 监控结果仅用于诈骗预警，不会用于其他目的',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF424242), // 与隐私政策文字样式一致
                            ),
                          ),
                          const Text(
                            '• 您可以随时在设置中关闭此功能',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF424242), // 与隐私政策文字样式一致
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 隐私保护说明文本 - 移到语音监控说明模块外下方
                    const Text(
                      '您提供的信息将受到严格保护，我们采取多种安全措施来防止未经授权的访问、使用或泄露。',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF424242), // 更深的灰色
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 协议按钮
          Container(
            margin: const EdgeInsets.only(top: 50, left: 20, right: 20), // 进一步增加顶部间距
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 不同意，退出应用
                      // 这里只是关闭弹窗，实际应用中可以添加退出逻辑
                      setState(() {
                        _showAgreement = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100], // 再变浅一点
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 20), // 增加按钮高度
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '不同意',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 同意，进入登录页面
                      setState(() {
                        _showAgreement = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5), // 改为#1e88e5
                      padding: const EdgeInsets.symmetric(vertical: 20), // 增加按钮高度
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '同意并继续',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // 字体颜色改为白色
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 登录表单
  Widget _buildLoginForm(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          // 应用Logo和标题
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF1E88E5), // 改为#1e88e5
                    borderRadius: BorderRadius.circular(20), // 更加圆润的边框
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x331565C0),
                        blurRadius: 8.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: 0.8, // 改为0.8缩放
                    child: Image.asset(
                      'assets/images/d.png',
                      fit: BoxFit.contain,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  '线下反诈通',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '守护您的财产安全',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // 登录表单
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // 账号标签
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '账号',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold, // 改为加粗
                      color: Color(0xFF424242), // 更深的灰色
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 账号输入框
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: '请输入账号',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Color(0xFFF8FAFF), // 改为#F8FAFF
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // 变小一点的圆角半径
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)), // 改为清晰浅灰边框
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)), // 改为清晰浅灰边框
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.error),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    // 清除错误状态
                    setState(() {
                      _loginFailed = false;
                      _errorMessage = '';
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // 密码标签
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '密码',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold, // 改为加粗
                      color: Color(0xFF424242), // 更深的灰色
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 密码输入框
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: '请输入密码',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Color(0xFFF8FAFF), // 改为#F8FAFF
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // 变小一点的圆角半径
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)), // 改为清晰浅灰边框
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)), // 改为清晰浅灰边框
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[400], // 浅灰色图标
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 25),
                
                // 登录按钮
                ElevatedButton(
                  onPressed: () async {
                    final phone = _phoneController.text.trim();
                    final password = _passwordController.text.trim();
                    
                    // 验证手机号
                    if (phone.isEmpty) {
                      setState(() {
                        _errorMessage = '请输入账号';
                        _loginFailed = true;
                      });
                      Future.delayed(const Duration(seconds: 3), () {
                        setState(() {
                          _loginFailed = false;
                          _errorMessage = '';
                        });
                      });
                      return;
                    }
                    
                    if (password.isEmpty) {
                      setState(() {
                        _errorMessage = '请输入密码';
                        _loginFailed = true;
                      });
                      Future.delayed(const Duration(seconds: 3), () {
                        setState(() {
                          _loginFailed = false;
                          _errorMessage = '';
                        });
                      });
                      return;
                    }
                    
                    // 登录验证
                    final success = await authProvider.login(phone, password);
                    
                    if (success) {
                      // 登录成功，跳转到首页
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    } else {
                      // 登录失败
                      setState(() {
                        _loginFailed = true;
                        _errorMessage = '账号或密码错误，请重试';
                      });
                      Future.delayed(const Duration(seconds: 3), () {
                        setState(() {
                          _loginFailed = false;
                          _errorMessage = '';
                        });
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E88E5), // 改为#1e88e5
                    padding: const EdgeInsets.symmetric(vertical: 18), // 增加垂直内边距
                    minimumSize: const Size(double.infinity, 56), // 增加高度从50到56
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '登录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // 文字颜色改为白色
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                
                // 测试账号信息
                Container(
                  width: double.infinity, // 和登录按钮一样的宽度
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F5FF), // 改为#F0F5FF
                    borderRadius: BorderRadius.circular(12), // 和登录按钮一样的圆角
                    border: Border.all(color: Color(0xFFE0E0E0)), // 添加边框与输入框保持一致
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 常量定义
                      const accountText = '测试账号：123456';
                      const passwordText = '测试密码：123456';
                      const separatorText = '|';
                      const textStyle = TextStyle(
                        color: Color(0xFF1E88E5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      );
                      const horizontalSpacing = 16.0;
                      const verticalSpacing = 4.0;
                       
                      // 使用TextPainter计算文本宽度
                      final accountTextPainter = TextPainter(
                        text: TextSpan(text: accountText, style: textStyle),
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                      )..layout();
                       
                      final passwordTextPainter = TextPainter(
                        text: TextSpan(text: passwordText, style: textStyle),
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                      )..layout();
                       
                      // 计算分隔符宽度
                      final separatorTextPainter = TextPainter(
                        text: TextSpan(text: separatorText, style: textStyle),
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                      )..layout();
                       
                      // 计算总宽度（文本宽度 + 间距 + 分隔符宽度）
                      final totalWidth = accountTextPainter.width + horizontalSpacing + passwordTextPainter.width + separatorTextPainter.width;
                       
                      // 如果总宽度小于容器宽度，水平排列；否则垂直排列
                      if (totalWidth <= constraints.maxWidth) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              accountText,
                              style: textStyle,
                            ),
                            SizedBox(width: horizontalSpacing / 2),
                            Text(
                              separatorText,
                              style: textStyle,
                            ),
                            SizedBox(width: horizontalSpacing / 2),
                            Text(
                              passwordText,
                              style: textStyle,
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              accountText,
                              style: textStyle,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: verticalSpacing),
                            Text(
                              passwordText,
                              style: textStyle,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                
                // 错误信息
                if (_loginFailed)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage.isNotEmpty ? _errorMessage : '手机号或密码错误，请重试',
                      style: const TextStyle(color: AppTheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
