import 'package:flutter/material.dart';

class ScreenAdapter {
  static final ScreenAdapter _instance = ScreenAdapter._internal();
  factory ScreenAdapter() => _instance;
  ScreenAdapter._internal();

  late BuildContext _context;
  late double _screenWidth;
  late double _screenHeight;
  late double _pixelRatio;

  // 初始化屏幕信息
  void init(BuildContext context) {
    _context = context;
    final mediaQueryData = MediaQuery.of(context);
    _screenWidth = mediaQueryData.size.width;
    _screenHeight = mediaQueryData.size.height;
    _pixelRatio = mediaQueryData.devicePixelRatio;
  }

  // 获取屏幕宽度
  double get screenWidth => _screenWidth;

  // 获取屏幕高度
  double get screenHeight => _screenHeight;

  // 获取像素密度
  double get pixelRatio => _pixelRatio;

  // 获取状态栏高度
  double get statusBarHeight {
    return MediaQuery.of(_context).padding.top;
  }

  // 获取底部安全区域高度
  double get bottomSafeAreaHeight {
    return MediaQuery.of(_context).padding.bottom;
  }

  // 获取屏幕总高度（包括状态栏）
  double get totalScreenHeight {
    return _screenHeight + statusBarHeight + bottomSafeAreaHeight;
  }

  // 基准宽度（375px，以iPhone 6/7/8为基准）
  static const double _baseWidth = 375.0;
  
  // 基准高度（667px，以iPhone 6/7/8为基准）
  static const double _baseHeight = 667.0;

  // 根据宽度适配
  double width(double value) {
    return value * _screenWidth / _baseWidth;
  }

  // 根据高度适配
  double height(double value) {
    return value * _screenHeight / _baseHeight;
  }

  // 根据最小边适配（用于正方形布局）
  double min(double value) {
    double minSize = _screenWidth < _screenHeight ? _screenWidth : _screenHeight;
    return value * minSize / _baseWidth;
  }

  // 字体大小适配
  double fontSize(double fontSize) {
    // 使用宽度作为基准进行字体适配
    double adaptedFontSize = width(fontSize);
    
    // 限制字体大小的最大值和最小值
    if (adaptedFontSize > fontSize * 1.5) {
      adaptedFontSize = fontSize * 1.5;
    } else if (adaptedFontSize < fontSize * 0.8) {
      adaptedFontSize = fontSize * 0.8;
    }
    
    return adaptedFontSize;
  }

  // 获取适配的EdgeInsets
  EdgeInsets getEdgeInsets({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? all,
  }) {
    return EdgeInsets.only(
      left: left != null ? width(left) : all != null ? width(all) : 0,
      top: top != null ? height(top) : all != null ? height(all) : 0,
      right: right != null ? width(right) : all != null ? width(all) : 0,
      bottom: bottom != null ? height(bottom) : all != null ? height(all) : 0,
    );
  }

  // 获取适配的EdgeInsets.symmetric
  EdgeInsets getEdgeInsetsSymmetric({
    double? horizontal,
    double? vertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: horizontal != null ? width(horizontal) : 0,
      vertical: vertical != null ? height(vertical) : 0,
    );
  }

  // 获取适配的BorderRadius
  BorderRadius getBorderRadius({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
    double? all,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft != null ? width(topLeft) : all != null ? width(all) : 0),
      topRight: Radius.circular(topRight != null ? width(topRight) : all != null ? width(all) : 0),
      bottomLeft: Radius.circular(bottomLeft != null ? width(bottomLeft) : all != null ? width(all) : 0),
      bottomRight: Radius.circular(bottomRight != null ? width(bottomRight) : all != null ? width(all) : 0),
    );
  }

  // 获取适配的BorderRadius.circular
  BorderRadius getBorderRadiusCircular(double radius) {
    return BorderRadius.circular(width(radius));
  }

  // 获取适配的Size
  Size getSize(double baseWidth, double baseHeight) {
    return Size(width(baseWidth), height(baseHeight));
  }

  // 获取适配的Offset
  Offset getOffset(double dx, double dy) {
    return Offset(width(dx), height(dy));
  }

  // 判断是否为平板
  bool get isTablet {
    return _screenWidth >= 600;
  }

  // 判断是否为横屏
  bool get isLandscape {
    return _screenWidth > _screenHeight;
  }

  // 判断是否为竖屏
  bool get isPortrait {
    return _screenHeight >= _screenWidth;
  }

  // 获取屏幕密度类型
  ScreenDensity get screenDensity {
    if (_pixelRatio < 1.5) {
      return ScreenDensity.ldpi;
    } else if (_pixelRatio < 2.0) {
      return ScreenDensity.mdpi;
    } else if (_pixelRatio < 3.0) {
      return ScreenDensity.hdpi;
    } else if (_pixelRatio < 4.0) {
      return ScreenDensity.xhdpi;
    } else {
      return ScreenDensity.xxhdpi;
    }
  }

  // 根据屏幕密度调整边距
  double getScaledPadding(double basePadding) {
    switch (screenDensity) {
      case ScreenDensity.ldpi:
        return basePadding * 0.75;
      case ScreenDensity.mdpi:
        return basePadding * 0.875;
      case ScreenDensity.hdpi:
        return basePadding;
      case ScreenDensity.xhdpi:
        return basePadding * 1.125;
      case ScreenDensity.xxhdpi:
        return basePadding * 1.25;
    }
  }

  // 获取适配的图标大小
  double getIconSize(double baseSize) {
    double adaptedSize = width(baseSize);
    
    // 图标大小范围调整
    if (adaptedSize > baseSize * 1.3) {
      adaptedSize = baseSize * 1.3;
    } else if (adaptedSize < baseSize * 0.7) {
      adaptedSize = baseSize * 0.7;
    }
    
    return adaptedSize;
  }

  // 获取适配的卡片高度
  double getCardHeight(double baseHeight) {
    if (isTablet) {
      // 平板上卡片可以更高
      return height(baseHeight * 1.2);
    } else {
      return height(baseHeight);
    }
  }

  // 获取列表项高度
  double getListItemHeight(double baseHeight) {
    if (isTablet) {
      // 平板上列表项可以更高
      return height(baseHeight * 1.3);
    } else if (isLandscape) {
      // 横屏时列表项高度适当减少
      return height(baseHeight * 0.9);
    } else {
      return height(baseHeight);
    }
  }

  // 获取按钮尺寸
  Size getButtonSize(double baseWidth, double baseHeight) {
    double adaptedWidth = width(baseWidth);
    double adaptedHeight = height(baseHeight);
    
    // 确保按钮最小触摸区域
    if (adaptedHeight < 48) {
      adaptedHeight = 48;
    }
    if (adaptedWidth < 48) {
      adaptedWidth = 48;
    }
    
    return Size(adaptedWidth, adaptedHeight);
  }

  // 获取网格列数（响应式布局）
  int getGridColumns(double baseItemWidth, {double spacing = 16}) {
    double availableWidth = _screenWidth - width(spacing * 2);
    double itemWidth = width(baseItemWidth);
    double spacingWidth = width(spacing);
    
    int columns = (availableWidth + spacingWidth) ~/ (itemWidth + spacingWidth);
    return columns > 0 ? columns : 1;
  }

  // 获取图片宽高比适配的尺寸
  Size getImageSize(double baseWidth, double aspectRatio) {
    double adaptedWidth = width(baseWidth);
    double adaptedHeight = adaptedWidth / aspectRatio;
    
    // 如果高度超过屏幕，按高度限制
    if (adaptedHeight > _screenHeight - statusBarHeight - bottomSafeAreaHeight - 100) {
      adaptedHeight = _screenHeight - statusBarHeight - bottomSafeAreaHeight - 100;
      adaptedWidth = adaptedHeight * aspectRatio;
    }
    
    return Size(adaptedWidth, adaptedHeight);
  }

  // 打印屏幕信息（调试用）
  void printScreenInfo() {
    print('=== 屏幕信息 ===');
    print('屏幕宽度: $_screenWidth');
    print('屏幕高度: $_screenHeight');
    print('像素密度: $_pixelRatio');
    print('屏幕密度类型: ${screenDensity}');
    print('状态栏高度: $statusBarHeight');
    print('底部安全区域高度: $bottomSafeAreaHeight');
    print('是否为平板: $isTablet');
    print('是否为横屏: $isLandscape');
    print('===============');
  }
}

// 屏幕密度枚举
enum ScreenDensity {
  ldpi,  // ~120dpi
  mdpi,  // ~160dpi
  hdpi,  // ~240dpi
  xhdpi, // ~320dpi
  xxhdpi,// ~480dpi
}

// 扩展方法，方便使用
extension ScreenAdapterExtension on double {
  double w(BuildContext context) {
    ScreenAdapter adapter = ScreenAdapter();
    adapter.init(context);
    return adapter.width(this);
  }

  double h(BuildContext context) {
    ScreenAdapter adapter = ScreenAdapter();
    adapter.init(context);
    return adapter.height(this);
  }

  double sp(BuildContext context) {
    ScreenAdapter adapter = ScreenAdapter();
    adapter.init(context);
    return adapter.fontSize(this);
  }
}

// 扩展方法，用于整数
extension ScreenAdapterIntExtension on int {
  double w(BuildContext context) {
    return toDouble().w(context);
  }

  double h(BuildContext context) {
    return toDouble().h(context);
  }

  double sp(BuildContext context) {
    return toDouble().sp(context);
  }
}