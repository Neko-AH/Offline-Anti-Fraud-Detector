import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:offline_anti_fraud_app/services/ocr_service.dart';
import 'package:offline_anti_fraud_app/theme/app_theme.dart';
import 'package:offline_anti_fraud_app/utils/snackbar_utils.dart';

class SmartCameraCard extends StatefulWidget {
  const SmartCameraCard({super.key});

  @override
  State<SmartCameraCard> createState() => _SmartCameraCardState();
}

class _SmartCameraCardState extends State<SmartCameraCard> {
  final _imagePicker = ImagePicker();
  File? _savedImage;
  Map<String, dynamic>? _webImageData; // Web平台使用，保存图片字节和扩展名
  String? _imagePath;
  bool _isScanning = false;

  // 显示智能扫描中弹窗
  void _showScanningDialog() {
    // 先调用拍照功能
    _takePicture().then((_) {
      // 检查图片数据是否可用（Web平台检查_webImageData，原生平台检查_savedImage）
      bool hasImageData = false;
      if (kIsWeb) {
        hasImageData = _webImageData != null;
      } else {
        hasImageData = _savedImage != null;
      }
      
      if (hasImageData) {
        // 拍照完成后显示扫描弹窗
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 加载圆圈
                    Container(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    // 扫描文字
                    const Text(
                      '智能扫描中...',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'AI正在深度分析图片内容',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // 调用OCR检测
        _performOCRDetection();
      }
    });
  }

  // 显示图片诈骗风险预警弹窗
  void _showImageFraudRiskWarning(BuildContext context, String reason) {
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
                        '温馨提示：当前图片中出现疑似诈骗特征。',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          height: 1.4, // 调整行高，使文本更紧凑
                        ),
                      ),
                      const SizedBox(height: 10.0), // 调整间距
                      Text(
                        reason,
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
                        Navigator.pop(context); // 关闭图片诈骗风险预警弹窗
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

  // 显示诈骗风险预警弹窗
  void _showFraudRiskWarning(BuildContext context, String reason) {
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
                        '暂未发现诈骗风险',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
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
                        '温馨提示: 当前图片暂未发现诈骗特征。',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          height: 1.4, // 调整行高，使文本更紧凑
                        ),
                      ),
                      const SizedBox(height: 10.0), // 调整间距
                      Text(
                        reason,
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
                        Navigator.pop(context); // 关闭诈骗风险预警弹窗
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

  // 执行OCR检测
  Future<void> _performOCRDetection() async {
    try {
      dynamic imageData;
      
      // 根据平台选择图片数据类型
      if (kIsWeb) {
        // Web平台：使用包含bytes和extension的Map对象
        imageData = _webImageData;
      } else {
        // 原生平台：使用File对象
        imageData = _savedImage;
      }
      
      if (imageData != null) {
        // 调用OCR服务进行欺诈检测
        final result = await OCRService.detectFraud(imageData);
        final fraudConfidence = result['fraud_confidence'] as double;
        final reason = result['reason'] as String;

        // 关闭扫描弹窗
        if (mounted) {
          Navigator.of(context).pop();
        }

        // 根据检测结果显示相应弹窗
        if (mounted) {
          if (fraudConfidence >= 0.5) {
            _showImageFraudRiskWarning(context, reason);
          } else {
            _showFraudRiskWarning(context, reason);
          }
        }
      }
    } catch (e) {
      print('OCR检测失败: $e');
      // 关闭扫描弹窗
      if (mounted) {
        Navigator.of(context).pop();
        // 显示错误提示
        SnackBarUtils.showSnackBar('检测失败，请重试: $e', context);
      }
    }
  }

  // 拍摄照片或选择照片并保存
  Future<void> _takePicture() async {
    try {
      // 清除之前保存的图片数据，防止用户取消拍照后使用旧图片
      setState(() {
        if (kIsWeb) {
          _webImageData = null;
        } else {
          _savedImage = null;
        }
      });
      
      // 根据平台选择图片来源
      final ImageSource source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
      
      // 仅在原生平台检查相机权限
      if (!kIsWeb) {
        // 检查相机权限
        final status = await Permission.camera.status;
        if (status.isDenied) {
          // 权限被拒绝，请求权限
          final result = await Permission.camera.request();
          if (result.isDenied) {
            // 请求后仍被拒绝
            if (mounted) {
              SnackBarUtils.showSnackBar('需要相机权限才能使用此功能', context);
            }
            return;
          } else if (result.isPermanentlyDenied) {
            // 权限被永久拒绝
            if (mounted) {
              SnackBarUtils.showSnackBar('相机权限已被永久拒绝，请在系统设置中开启', context);
            }
            return;
          }
        } else if (status.isPermanentlyDenied) {
          // 权限被永久拒绝
          if (mounted) {
            SnackBarUtils.showSnackBar('相机权限已被永久拒绝，请在系统设置中开启', context);
          }
          return;
        }
      }
      
      // 使用相机拍摄照片或从相册选择照片
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // 在Web平台上，pickedFile.path可能不是有效的文件路径
        // 我们需要直接使用pickedFile来获取文件内容，不使用文件系统
        if (kIsWeb) {
          // Web平台：直接保存图片字节和扩展名
          final bytes = await pickedFile.readAsBytes();
          // 从文件名获取扩展名
          final fileName = pickedFile.name;
          final fileExtension = fileName.split('.').last.toLowerCase();
          
          setState(() {
            _webImageData = {
              'bytes': bytes,
              'extension': fileExtension
            };
          });
        } else {
          // 原生平台：使用原来的逻辑
          // 获取应用文档目录
          final directory = Directory.systemTemp;
          // 创建保存文件
          final savedImage = File('${directory.path}/smart_photo.jpg');
          // 复制拍摄的照片到保存路径，覆盖已有文件
          await File(pickedFile.path).copy(savedImage.path);

          setState(() {
            _savedImage = savedImage;
            _imagePath = savedImage.path;
          });
        }
      }
    } catch (e) {
      // 显示错误提示，检查widget是否仍然挂载
      if (mounted) {
        // 检查是否是权限相关错误
        if (e.toString().contains('permission') || e.toString().contains('Permission')) {
          // 权限被拒绝
          SnackBarUtils.showSnackBar('需要相机权限才能使用此功能', context);
        } else {
          // 其他错误
          SnackBarUtils.showSnackBar(kIsWeb ? '拍摄失败，请重试' : '拍摄失败，请重试', context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(22.0),
        boxShadow: const [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片标题和相机图标
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '智拍识诈',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Transform.scale(
                  scale: 0.6,
                  child: Image.asset(
                    'assets/images/lxj.png',
                    width: 20.0,
                    height: 20.0,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // 描述文本
          const Text(
            '使用相机扫描可疑海报，即刻获得诈骗风险分析',
            style: TextStyle(
              fontSize: 14.0,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          
          const Spacer(),
          
          // 开始智能识别按钮
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _showScanningDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                elevation: 0,
                shadowColor: AppTheme.buttonShadow.color,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/bxj.png',
                    width: 20.0,
                    height: 20.0,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    '开始智能识别',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
