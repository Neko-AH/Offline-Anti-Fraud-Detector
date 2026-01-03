import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:offline_anti_fraud_app/components/bottom_navigation.dart';
import 'package:offline_anti_fraud_app/pages/fraud_game_page.dart';
import 'package:offline_anti_fraud_app/pages/fraud_prevention_page.dart';
import 'package:offline_anti_fraud_app/pages/profile_page.dart';
import 'package:offline_anti_fraud_app/components/bottom_navigation.dart';
import 'package:offline_anti_fraud_app/providers/auth_provider.dart';
import 'package:offline_anti_fraud_app/providers/emergency_contacts_provider.dart';
import 'package:offline_anti_fraud_app/providers/protection_provider.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';
import 'package:offline_anti_fraud_app/components/security_card.dart';
import 'package:offline_anti_fraud_app/components/smart_camera_card.dart';
import 'package:offline_anti_fraud_app/config/api_config.dart';
import 'package:offline_anti_fraud_app/components/features_grid.dart';
import 'package:offline_anti_fraud_app/utils/screen_adapter.dart';
import 'package:offline_anti_fraud_app/utils/snackbar_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    // 注册应用生命周期监听
    WidgetsBinding.instance.addObserver(this);
    // 初始化防护服务，如果防护模式是开启的则加载相关服务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final protectionProvider = Provider.of<ProtectionProvider>(context, listen: false);
      protectionProvider.initialize(context);
    });
  }

  @override
  void dispose() {
    // 取消注册应用生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final protectionProvider = Provider.of<ProtectionProvider>(context, listen: false);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // 应用进入后台，自动关闭防护模式
      if (protectionProvider.isProtected) {
        protectionProvider.toggleProtection(false, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final phoneNumber = authProvider.phoneNumber;
    
    // 监听键盘高度变化
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    final List<Widget> _pages = [
      const _HomeContent(),
      const FraudPreventionPage(),
      const FraudGamePage(),
      ProfilePage(phoneNumber: phoneNumber, authProvider: authProvider),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: _pages,
            )
          ),
          // 键盘弹出时平滑隐藏底部导航栏
          // 核心修复：完全自适应内容高度，通过SizedBox控制显示/隐藏
          SizedBox(
            height: isKeyboardVisible ? 0 : null, // 隐藏时设置高度为0，显示时自适应
            child: AnimatedOpacity(
              opacity: isKeyboardVisible ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500), // 1秒透明度动画
              curve: Curves.fastOutSlowIn,
              child: AnimatedSlide(
                offset: isKeyboardVisible ? const Offset(0, 1) : Offset.zero,
                duration: const Duration(milliseconds: 500), // 1秒滑动动画
                curve: Curves.fastOutSlowIn,
                child: BottomNavigation(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                      _pageController.jumpToPage(index);
                    });
                  }
                ),
              ),
            ),
          )
        ]
      )
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  bool _showReportModal = false;
  bool _showFamilyModal = false;
  bool _showLocationModal = false;
  bool _showSetFamilyModal = false;
  bool _showCallFamilyModal = false;

  Position? _currentPosition;
  String _locationText = '未获取位置';

  // MethodChannel for Tencent Location SDK
  static const MethodChannel _locationChannel = MethodChannel('tencent_location_channel');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 移除自动定位，仅在用户点击"定址呼救"时触发
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    final snackBarUtils = SnackBarUtils.createSnackBar(message, context);
    ScaffoldMessenger.of(context).showSnackBar(snackBarUtils);
  }

  void _handleReport() {
    setState(() {
      _showReportModal = true;
    });
  }

  void _handleFamily() {
    final contactsProvider = Provider.of<EmergencyContactsProvider>(context, listen: false);
    if (contactsProvider.hasContact) {
      setState(() {
        _showCallFamilyModal = true;
      });
    } else {
      setState(() {
        _showSetFamilyModal = true;
      });
    }
  }

  // 使用IP定位获取位置信息
  Future<void> _getLocationByIp() async {
    try {
      final String key = ApiConfig.mapApiKey;
      final String url = '${ApiConfig.mapApiUrl}?key=$key';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 0) {
          // IP定位成功
          final adInfo = data['result']['ad_info'];
          
          setState(() {
            // 构建IP定位的地址文本
            _locationText = '${adInfo['nation']} ${adInfo['province']} ${adInfo['city']}';
          });
          return;
        }
      }
      
      // IP定位失败
      setState(() {
        _locationText = '获取位置失败';
      });
    } catch (e) {
      print('IP定位失败: $e');
      setState(() {
        _locationText = '获取位置失败';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    bool allMethodsFailed = false;

    try {
      // 检查位置服务是否启用
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // 位置服务未启用，尝试使用IP定位
        await _getLocationByIp();
        allMethodsFailed = _locationText == '获取位置失败';
      } else {
        // 检查位置权限
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            // 位置权限被拒绝，尝试使用IP定位
            await _getLocationByIp();
            allMethodsFailed = _locationText == '获取位置失败';
          } else if (permission == LocationPermission.deniedForever) {
            // 位置权限被永久拒绝，尝试使用IP定位
            await _getLocationByIp();
            allMethodsFailed = _locationText == '获取位置失败';
          } else {
            // 权限获取成功，依次尝试三种定位方式
            bool tencentSuccess = false;
            bool geolocatorSuccess = false;
            bool ipSuccess = false;

            // 1. 优先使用腾讯定位SDK获取位置
            if (!kIsWeb) {
              try {
                // 调用腾讯定位SDK获取详细位置信息
                final Map<dynamic, dynamic> locationData = await _locationChannel.invokeMethod('getCurrentLocation');
                
                // 解析位置数据
                final double latitude = locationData['latitude'] as double;
                final double longitude = locationData['longitude'] as double;
                final String address = locationData['address'] as String? ?? '';
                final String country = locationData['country'] as String? ?? '';
                final String province = locationData['province'] as String? ?? '';
                final String city = locationData['city'] as String? ?? '';
                final String district = locationData['district'] as String? ?? '';
                final String street = locationData['street'] as String? ?? '';
                final String streetNo = locationData['streetNo'] as String? ?? '';
                final String poiName = locationData['poiName'] as String? ?? '';
                
                setState(() {
                  // 构建详细地址文本
                  if (address.isNotEmpty) {
                    _locationText = address;
                  } else {
                    _locationText = '$country $province $city $district $street $streetNo $poiName';
                  }
                });
                tencentSuccess = true;
              } catch (tencentError) {
                print('腾讯定位SDK调用失败，将使用备用方案: $tencentError');
                // 腾讯定位SDK调用失败，继续使用备用方案
              }
            }

            // 2. 如果腾讯SDK失败，尝试使用Geolocator获取位置
            if (!tencentSuccess) {
              try {
                _currentPosition = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                  timeLimit: const Duration(seconds: 15),
                );

                List<Placemark> placemarks = await placemarkFromCoordinates(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                );

                if (placemarks.isNotEmpty) {
                  Placemark placemark = placemarks[0];
                  setState(() {
                    _locationText = '${placemark.country} ${placemark.administrativeArea} ${placemark.locality} ${placemark.subLocality} ${placemark.thoroughfare}';
                  });
                } else {
                  setState(() {
                    _locationText = '纬度: ${_currentPosition!.latitude.toStringAsFixed(6)}, 经度: ${_currentPosition!.longitude.toStringAsFixed(6)}';
                  });
                }
                geolocatorSuccess = true;
              } catch (geolocatorError) {
                print('Geolocator调用失败，将使用IP定位: $geolocatorError');
                // Geolocator调用失败，继续使用IP定位
              }
            }

            // 3. 如果前两种方式都失败，尝试使用IP定位
            if (!tencentSuccess && !geolocatorSuccess) {
              await _getLocationByIp();
              ipSuccess = _locationText != '获取位置失败';
              allMethodsFailed = !ipSuccess;
            }
          }
        } else if (permission == LocationPermission.deniedForever) {
          // 位置权限被永久拒绝，尝试使用IP定位
          await _getLocationByIp();
          allMethodsFailed = _locationText == '获取位置失败';
        } else {
          // 权限获取成功，依次尝试三种定位方式
          bool tencentSuccess = false;
          bool geolocatorSuccess = false;
          bool ipSuccess = false;

          // 1. 优先使用腾讯定位SDK获取位置
          if (!kIsWeb) {
            try {
              // 调用腾讯定位SDK获取详细位置信息
              final Map<dynamic, dynamic> locationData = await _locationChannel.invokeMethod('getCurrentLocation');
              
              // 解析位置数据
              final double latitude = locationData['latitude'] as double;
              final double longitude = locationData['longitude'] as double;
              final String address = locationData['address'] as String? ?? '';
              final String country = locationData['country'] as String? ?? '';
              final String province = locationData['province'] as String? ?? '';
              final String city = locationData['city'] as String? ?? '';
              final String district = locationData['district'] as String? ?? '';
              final String street = locationData['street'] as String? ?? '';
              final String streetNo = locationData['streetNo'] as String? ?? '';
              final String poiName = locationData['poiName'] as String? ?? '';
              
              setState(() {
                // 构建详细地址文本
                if (address.isNotEmpty) {
                  _locationText = address;
                } else {
                  _locationText = '$country $province $city $district $street $streetNo $poiName';
                }
              });
              tencentSuccess = true;
            } catch (tencentError) {
              print('腾讯定位SDK调用失败，将使用备用方案: $tencentError');
              // 腾讯定位SDK调用失败，继续使用备用方案
            }
          }

          // 2. 如果腾讯SDK失败，尝试使用Geolocator获取位置
          if (!tencentSuccess) {
            try {
              _currentPosition = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 15),
              );

              List<Placemark> placemarks = await placemarkFromCoordinates(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              );

              if (placemarks.isNotEmpty) {
                Placemark placemark = placemarks[0];
                setState(() {
                  _locationText = '${placemark.country} ${placemark.administrativeArea} ${placemark.locality} ${placemark.subLocality} ${placemark.thoroughfare}';
                });
              } else {
                setState(() {
                  _locationText = '纬度: ${_currentPosition!.latitude.toStringAsFixed(6)}, 经度: ${_currentPosition!.longitude.toStringAsFixed(6)}';
                });
              }
              geolocatorSuccess = true;
            } catch (geolocatorError) {
              print('Geolocator调用失败，将使用IP定位: $geolocatorError');
              // Geolocator调用失败，继续使用IP定位
            }
          }

          // 3. 如果前两种方式都失败，尝试使用IP定位
          if (!tencentSuccess && !geolocatorSuccess) {
            await _getLocationByIp();
            ipSuccess = _locationText != '获取位置失败';
            allMethodsFailed = !ipSuccess;
          }
        }
      }
    } catch (e) {
      print('定位过程中发生异常: $e');
      // 发生异常，尝试使用IP定位
      await _getLocationByIp();
      allMethodsFailed = _locationText == '获取位置失败';
    }

    // 只有当所有定位方式都失败时，才显示获取位置超时的底部弹窗
    if (allMethodsFailed) {
      _showToast('获取位置超时，请检查网络或位置服务');
    }
  }

  Widget _getModalIcon(IconData icon) {
    final iconSize = 36.0; // 调整图标大小，确保在60x60圆圈内完全显示
    if (icon == Icons.report_problem) {
      return Image.asset(
        'assets/images/cjg.png',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    } else if (icon == Icons.person_add) {
      return Image.asset(
        'assets/images/ljj.png',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    } else if (icon == Icons.location_on) {
      return Image.asset(
        'assets/images/hdw.png',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    } else if (icon == Icons.phone) {
      return Image.asset(
        'assets/images/ldh.png',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    } else {
      return Icon(
        icon,
        size: iconSize,
        color: Colors.grey,
      );
    }
  }

  void _handleLocation() {
    setState(() {
      _locationText = '查询中...';
      _showLocationModal = true;
    });
    _getCurrentLocation();
  }

  void _saveFamilyPhone() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showToast('请输入联系人姓名');
      return;
    }
    if (phone.isEmpty) {
      _showToast('请输入手机号码');
      return;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showToast('请输入有效的手机号码');
      return;
    }

    final contactsProvider = Provider.of<EmergencyContactsProvider>(context, listen: false);
    contactsProvider.saveContact(name, phone);

    setState(() {
      _showSetFamilyModal = false;
    });
    _showToast('家人号码已保存！');
  }

  @override
  Widget build(BuildContext context) {
    // ========== 使用Flutter标准布局组件 ==========
    // 基础间距/内边距
    const padding16Horizontal = 16.0;    // 16px
    const padding24Bottom = 24.0;        // 24px
    const padding24Top = 40.0;           // 40px
    const padding16Bottom = 16.0;        // 16px
    const margin16Bottom = 16.0;         // 16px
    const margin8Bottom = 8.0;           // 8px
    const margin4Horizontal = 4.0;       // 4px
    const margin12Bottom = 12.0;         // 12px
    const margin32Bottom = 32.0;         // 32px
    const width40 = 40.0;                // 40px
    const height40 = 40.0;               // 40px
    const radius6 = 6.0;                 // 6px
    const shadowBlur8 = 8.0;             // 8px
    const shadowOffset4 = 4.0;           // 4px
    const width30 = 30.0;                // 30px
    const height30 = 30.0;               // 30px
    const margin12Width = 12.0;          // 12px
    const fontSize20 = 20.0;             // 20px

    // ========== 核心修复：恢复Stack布局，让弹窗能覆盖显示 ==========
    return Stack(
      children: [
        // 主内容区域（可滚动）
        SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 蓝色背景容器（向下延伸）
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.98, 0.98],
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: padding16Horizontal).copyWith(bottom: padding24Bottom),
                child: Column(
                  children: [
                    // 应用标题和Logo
                    Container(
                      padding: EdgeInsets.only(top: padding24Top, bottom: padding16Bottom),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: width40,
                              height: height40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(radius6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x331565C0),
                                    blurRadius: shadowBlur8,
                                    offset: const Offset(0, shadowOffset4),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/d.png',
                                width: width30,
                                height: height30,
                                fit: BoxFit.contain,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: margin12Width),
                            Text(
                              '线下反诈通',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSize20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 实时防护中心卡片
                    Container(
                      margin: EdgeInsets.only(bottom: margin16Bottom),
                      child: const SecurityCard(),
                    ),

                    // 智拍识诈卡片
                    const SmartCameraCard(),
                  ],
                ),
              ),

              // 安全工具区域
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding16Horizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: margin8Bottom),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: margin4Horizontal),
                      child: Text(
                        '安全工具',
                        style: TextStyle(
                          fontSize: fontSize20, // 18px → 微调为20px等效
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    FeaturesGrid(
                      onReportTap: _handleReport,
                      onFamilyTap: _handleFamily,
                      onLocationTap: _handleLocation,
                    ),
                    SizedBox(height: margin32Bottom),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ========== 弹窗层：必须放在Stack中才能覆盖显示 ==========
        if (_showReportModal)
          _buildReportModal(),

        if (_showFamilyModal)
          _buildFamilyModal(),

        if (_showLocationModal)
          _buildLocationModal(),

        if (_showSetFamilyModal)
          _buildSetFamilyModal(),

        if (_showCallFamilyModal)
          _buildCallFamilyModal(),
      ],
    );
  }

  // 一键举报弹窗
  Widget _buildReportModal() {
    return _buildModalOverlay(
      child: _buildModal(
        icon: Icons.report_problem,
        iconColor: AppTheme.orange,
        iconBgColor: AppTheme.orange.withOpacity(0.15),
        title: '一键举报',
        content: '已为您上传本地录音。是否确认发送到公安在线平台？',
        confirmText: '确认',
        onConfirm: () {
          _showToast('举报信息已提交 (模拟)');
          setState(() {
            _showReportModal = false;
          });
        },
        onCancel: () {
          setState(() {
            _showReportModal = false;
          });
        },
        note: '本功能为测试阶段，并不会真实发送',
      ),
      onTapOutside: () {
        setState(() {
          _showReportModal = false;
        });
      },
    );
  }

  // 家人速通弹窗
  Widget _buildFamilyModal() {
    return _buildModalOverlay(
      child: _buildModal(
        icon: Icons.people,
        iconColor: AppTheme.blue,
        iconBgColor: AppTheme.blue.withOpacity(0.15),
        title: '家人速通',
        content: '已检测到您尚未配置应急联系人手机号',
        confirmText: '去设置',
        onConfirm: () {
          setState(() {
            _showFamilyModal = false;
            _showSetFamilyModal = true;
          });
        },
        onCancel: () {
          setState(() {
            _showFamilyModal = false;
          });
        },
      ),
      onTapOutside: () {
        setState(() {
          _showFamilyModal = false;
        });
      },
    );
  }

  // 定址呼救弹窗
  Widget _buildLocationModal() {
    return _buildModalOverlay(
      child: _buildModal(
        icon: Icons.location_on,
        iconColor: AppTheme.red,
        iconBgColor: AppTheme.red.withOpacity(0.15),
        title: '定址呼救',
        content: '当前位置：$_locationText\n是否立即拨打110报警？',
        confirmText: '立即报警',
        onConfirm: () {
          _showToast('正在呼叫110... (模拟)');
          setState(() {
            _showLocationModal = false;
          });
        },
        onCancel: () {
          setState(() {
            _showLocationModal = false;
          });
        },
        note: '本功能为测试阶段，并不会真实拨打110',
      ),
      onTapOutside: () {
        setState(() {
          _showLocationModal = false;
        });
      },
    );
  }

  // 设置家人号码弹窗
  Widget _buildSetFamilyModal() {
    return _buildModalOverlay(
      child: _buildModal(
        icon: Icons.person_add,
        iconColor: AppTheme.blue,
        iconBgColor: AppTheme.blue.withOpacity(0.15),
        title: '添加紧急联系人',
        content: Column(
          children: [
            SizedBox(height: 16), // 16px
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '联系人姓名',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // 12px
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // 12px
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                hintText: '输入联系人姓名',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, // 16px
                  vertical: 14,   // 14px
                ),
              ),
            ),
            SizedBox(height: 16), // 16px
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: '电话号码',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // 12px
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // 12px
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                hintText: '输入手机号码',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, // 16px
                  vertical: 14,   // 14px
                ),
              ),
              keyboardType: TextInputType.phone,
              maxLength: 11,
            ),
          ],
        ),
        confirmText: '保存',
        onConfirm: _saveFamilyPhone,
        onCancel: () {
          setState(() {
            _showSetFamilyModal = false;
          });
        },
        note: '此联系人将用于紧急情况时的快速呼叫',
      ),
      onTapOutside: () {
        setState(() {
          _showSetFamilyModal = false;
        });
      },
    );
  }

  // 呼叫家人弹窗
  Widget _buildCallFamilyModal() {
    final contactsProvider = Provider.of<EmergencyContactsProvider>(context, listen: false);
    final contact = contactsProvider.contact!;

    return _buildModalOverlay(
      child: _buildModal(
        icon: Icons.phone,
        iconColor: AppTheme.blue,
        iconBgColor: AppTheme.blue.withOpacity(0.15),
        title: '家人速通',
        content: '即将呼叫 ${contact['name']} - ${contact['phone']}',
        confirmText: '立即呼叫',
        onConfirm: () {
          _showToast('正在呼叫 ${contact['name']}... (模拟)');
          setState(() {
            _showCallFamilyModal = false;
          });
        },
        onCancel: () {
          setState(() {
            _showCallFamilyModal = false;
          });
        },
      ),
      onTapOutside: () {
        setState(() {
          _showCallFamilyModal = false;
        });
      },
    );
  }

  // 模态框覆盖层
  Widget _buildModalOverlay({
    required Widget child,
    required VoidCallback onTapOutside
  }) {
    return GestureDetector(
      onTap: onTapOutside,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 阻止点击弹窗内容关闭弹窗
            child: child,
          ),
        ),
      ),
    );
  }

  // 通用模态框
  Widget _buildModal({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required dynamic content,
    required String confirmText,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    String? note,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),    // 24px
      padding: const EdgeInsets.all(24),         // 24px
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),              // 24px
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,          // 10px
            offset: const Offset(0, 5),         // 5px
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,               // 60px
            height: 60,              // 60px
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(30),              // 30px
            ),
            alignment: Alignment.center,
            child: _getModalIcon(icon),
          ),
          const SizedBox(height: 16),        // 16px

          Text(
            title,
            style: TextStyle(
              fontSize: 20,       // 20px
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),        // 16px

          if (content is String)
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,     // 16px
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            )
          else
            content,
          const SizedBox(height: 24),        // 24px

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.border,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,   // 24px
                    vertical: 12    // 12px
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),         // 16px
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5), // #1e88e5 背景颜色
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,   // 24px
                    vertical: 12    // 12px
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  confirmText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),        // 16px

          if (note != null)
            Text(
              note,
              style: TextStyle(
                fontSize: 12,       // 12px
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}