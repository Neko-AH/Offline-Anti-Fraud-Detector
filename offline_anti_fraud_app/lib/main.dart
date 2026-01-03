import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:offline_anti_fraud_app/pages/emergency_contacts_page.dart';
import 'package:offline_anti_fraud_app/pages/home_page.dart';
import 'package:offline_anti_fraud_app/pages/login_page.dart';
import 'package:offline_anti_fraud_app/pages/settings_page.dart';
import 'package:offline_anti_fraud_app/providers/auth_provider.dart';
import 'package:offline_anti_fraud_app/providers/emergency_contacts_provider.dart';
import 'package:offline_anti_fraud_app/providers/points_provider.dart';
import 'package:offline_anti_fraud_app/providers/protection_provider.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';
import 'package:offline_anti_fraud_app/utils/screen_adapter.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 使用edgeToEdge模式，让应用延伸到状态栏下方
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 设置状态栏透明，文字为黑色，确保可见性
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
    .then((_) {
      runApp(
        const MyApp(),
      );
    });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthProvider _authProvider = AuthProvider();
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // 初始化应用 - 简化版本，确保稳定性
  Future<void> _initializeApp() async { 
    try {
      // 只初始化最基本的认证状态
      await _authProvider.initialize();
      
      setState(() {
        _isInitialized = true;
      });
      
    } catch (e) {
      setState(() {
        _isInitialized = true;
        // 即使初始化失败，也允许应用继续运行
        _initError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => PointsProvider()),
        ChangeNotifierProvider(create: (_) => ProtectionProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyContactsProvider()),
      ],
      child: MaterialApp(
        title: '线下反诈通',
        theme: AppTheme.themeData,
        // 始终使用home属性，而不是initialRoute，避免配置冲突
        home: _isInitialized
            ? _buildMainContent()
            : _buildLoadingScreen(),
        // 移除initialRoute和routes配置，避免冲突
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  // 构建主内容
  Widget _buildMainContent() {
    // 即使初始化失败，也允许应用继续运行
    if (_initError != null) {
      // 初始化失败时，我们仍然允许应用运行，使用默认的登录状态
      // 这样用户可以使用应用的基本功能，而不会被卡在加载界面
    }

    return Builder(
      builder: (context) {
        // 初始化屏幕适配
        final screenAdapter = ScreenAdapter();
        try {
          screenAdapter.init(context);
        } catch (e) {
          if (kDebugMode) {
            print('屏幕适配初始化失败，但不影响应用运行: $e');
          }
        }

        // 根据登录状态显示不同页面
        return _authProvider.isLoggedIn ? const HomePage() : LoginPage();
      },
    );
  }

  // 构建加载界面
  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '正在初始化应用...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // 构建错误界面
  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                '应用初始化失败',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initError = null;
                    _isInitialized = false;
                  });
                  _initializeApp();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

