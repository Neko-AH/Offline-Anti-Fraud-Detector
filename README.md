# 线下反诈通 (Offline-Anti-Fraud-Detector)
码上AI·CoStrict校园挑战赛 创新应用赛-代码写的对不队-线下防诈通

## 项目概述
线下反诈通是一款基于Flutter+原生Android混合架构开发的反诈骗检测应用，支持线下诈骗检测功能。应用集成了深度学习模型、语音识别、OCR等技术，为用户提供全方位的反诈骗保护。

## 快速体验
**提示**：构建和运行应用需要配置完整的开发环境，过程较为繁琐。如果您只是想快速体验应用，可以直接安装我们已经构建好的 APK 文件。

## 重要配置说明

### API配置
在构建和运行应用之前，您需要配置以下API：

1. **Dart端API配置**：
   - 文件位置：`lib/config/api_config.dart`
   - 配置内容：API密钥、模型名称、基础URL等

2. **Android原生API配置**：
   - **ASR语音识别配置**：`android/app/src/main/java/com/example/offline_anti_fraud_app/AsrService.java`
   - **腾讯地图配置**：`android/app/src/main/kotlin/com/example/offline_anti_fraud_app/AppApplication.kt`

**注意**：缺少API配置会导致应用部分功能无法正常工作，请务必先完成配置再运行应用。

## 运行环境

### 必要环境
- **Flutter SDK**: >=3.4.3 <4.0.0
- **Dart SDK**: 与Flutter SDK兼容的版本
- **Android Studio**: 最新稳定版
- **Android SDK**: API级别 >= 21
- **Gradle**: >= 7.0
- **Java Development Kit (JDK)**: 11 或 17

### 推荐环境
- **操作系统**: Windows 10/11, macOS 10.15+, Ubuntu 20.04+
- **IDE**: Android Studio (推荐) 或 VS Code
- **设备**: Android 5.0+ 真机或模拟器

## 依赖库及安装命令

### Flutter依赖
应用使用以下Flutter依赖库，通过pubspec.yaml管理：

| 依赖名称 | 版本 | 用途 |
|---------|------|------|
| cupertino_icons | ^1.0.6 | iOS风格图标 |
| flutter_svg | ^2.0.10 | SVG图标支持 |
| provider | ^6.1.2 | 状态管理 |
| shared_preferences | ^2.2.13 | 本地存储 |
| image_picker | ^0.8.9 | 图片选择 |
| geolocator | ^10.1.0 | 位置获取 |
| geocoding | ^2.2.0 | 地理编码 |
| permission_handler | ^10.4.3 | 权限处理 |
| http | ^1.2.1 | HTTP请求 |
| device_info_plus | ^10.1.0 | 设备信息 |
| vibration | ^1.8.4 | 震动功能 |
| image | ^4.2.0 | 图像处理 |
| connectivity_plus | ^5.0.2 | 网络连接检查 |

### 原生Android依赖
- **ONNX Runtime**: 用于离线深度学习模型推理
- **腾讯定位SDK**: 用于地理位置服务
- **语音识别组件**: 用于实时语音诈骗检测

### 安装命令

1. **安装Flutter SDK**
   - 参考官方文档: [Flutter安装指南](https://flutter.dev/docs/get-started/install)
   - 验证安装: `flutter doctor`

2. **安装项目依赖**
   ```bash
   # 进入项目根目录（根据实际情况调整路径）
   cd offline_anti_fraud_app
   
   # 获取Flutter依赖
   flutter pub get
   
   # 确保Android依赖同步
   flutter pub run flutter_launcher_icons:main
   ```

## 详细运行步骤

### 步骤1: 配置开发环境

1. **安装Android Studio**
   - 下载并安装: [Android Studio官网](https://developer.android.com/studio)
   - 安装过程中选择"Android Virtual Device"选项

2. **配置Android SDK**
   - 打开Android Studio，进入"Settings" > "Appearance & Behavior" > "System Settings" > "Android SDK"
   - 确保安装了以下组件:
     - Android SDK Platform (最新稳定版)
     - Android SDK Build-Tools (最新稳定版)
     - Android SDK Command-line Tools (latest)
     - Android Emulator

3. **配置环境变量**
   - 确保ANDROID_HOME环境变量指向Android SDK目录
   - 将%ANDROID_HOME%\platform-tools和%ANDROID_HOME%\tools添加到PATH

### 步骤2: 准备运行设备

#### 选项A: 使用Android模拟器
1. 打开Android Studio，点击"AVD Manager"图标
2. 点击"Create Virtual Device..."
3. 选择一个设备型号(推荐Pixel 5或更高)
4. 选择一个系统镜像(推荐API级别28或更高，x86_64架构)
5. 完成虚拟设备创建
6. 点击"Play"按钮启动模拟器

#### 选项B: 使用真机
1. 在Android设备上启用"开发者选项"
   - 进入"设置" > "关于手机"
   - 连续点击"版本号"7次
2. 启用"USB调试"
   - 进入"设置" > "开发者选项"
   - 开启"USB调试"
3. 使用USB数据线连接设备到电脑
4. 授权电脑进行调试

### 步骤3: 运行应用

#### 方法1: 使用命令行
```bash
# 确保设备已连接
flutter devices

# 运行应用
flutter run
```

#### 方法2: 使用Android Studio
1. 打开Android Studio
2. 选择"Open an existing project"
3. 导航到项目根目录并打开
4. 等待项目加载完成
5. 在工具栏中选择目标设备
6. 点击"Run"按钮(绿色三角形图标)

#### 方法3: 使用VS Code
1. 打开VS Code
2. 安装Flutter和Dart扩展
3. 打开项目文件夹
4. 按F5键或点击"Run" > "Start Debugging"

## 项目主要结构

```
offline_anti_fraud_app/
├── android/                    # Android原生代码
│   ├── app/
│   │   ├── libs/               # 第三方库AAR文件
│   │   └── src/main/
│   │       ├── assets/         # 离线模型和资源
│   │       ├── java/           # Java原生代码
│   │       ├── jniLibs/        # 原生库SO文件
│   │       └── kotlin/         # Kotlin原生代码
│   └── build.gradle            # Android构建配置
├── assets/                     # Flutter资源文件
│   ├── images/                 # 图片资源
│   ├── models/                 # 深度学习模型
│   └── vocab/                  # 词汇表
├── lib/                        # Flutter代码
│   ├── components/             # 通用组件
│   ├── pages/                  # 页面组件
│   ├── providers/              # 状态管理
│   ├── services/               # 服务层
│   ├── theme/                  # 主题配置
│   └── utils/                  # 工具类
├── README.md/                  # 项目说明文档
└── pubspec.yaml                # Flutter依赖配置
```

## 核心功能
应用启动后，您可以体验以下核心功能：
1. **线下反诈检测（实时语音检测）**: 实时语音采集与分析
2. **智拍识诈（OCR检测）**: 智能分析海报广告中虚假诈骗内容
3. **辨诈实战**: AI模拟各种诈骗套路
4. **防诈知识闯关**: 反诈知识普及
5. **其他小功能**: 一键举报，家人速通，定址呼救等

## 技术架构

### Flutter层
- **状态管理**: Provider
- **UI框架**: Material Design
- **本地存储**: SharedPreferences
- **权限管理**: permission_handler

### 原生Android层
- **深度学习**: ONNX Runtime
- **语音识别**: 集成语音识别服务
- **定位服务**: 腾讯定位SDK
- **Flutter通信**: MethodChannel

### 本地反诈模型
- **模型类型**: BiLSTM
- **模型格式**: ONNX
- **模型位置**: assets/models/bilstm_fraud_detector_cpu_int8.onnx

## 注意事项

1. **首次运行**: 首次运行时需要授予应用相关权限(麦克风、相机、位置等)
2. **模型加载**: 首次启动时会加载本地反诈模型，可能需要几秒钟时间
3. **性能优化**: 建议在性能较好的设备上运行，以获得最佳体验
4. **Android版本**: 最低支持Android 5.0(API级别21)
5. **网络需求**: 部分功能需要网络连接

## 构建发布版本

### 构建Android APK
```bash
# 构建发布版APK
flutter build apk --release

# 构建特定架构的APK
flutter build apk --release --split-per-abi
```


## 故障排除

### 常见问题

1. **Flutter版本不兼容**
   - 解决方案: 运行`flutter upgrade`更新到兼容版本

2. **Android依赖同步失败**
   - 解决方案: 清除Gradle缓存，运行`flutter clean && flutter pub get`

3. **设备连接问题**
   - 解决方案: 重新连接设备，确保USB调试已启用

4. **权限问题**
   - 解决方案: 在应用设置中手动授予所需权限

5. **模型加载失败**
   - 解决方案: 确保assets/models目录下存在完整的模型文件

6. **中文路径问题**
   - 解决方案: 将整个项目移动至不含中文路径的位置即可

