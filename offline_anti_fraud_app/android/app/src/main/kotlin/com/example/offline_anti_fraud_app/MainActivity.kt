package com.example.offline_anti_fraud_app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import androidx.multidex.MultiDex
import androidx.multidex.MultiDexApplication

class MainActivity: FlutterActivity() {
    
    private var asrFlutterChannel: AsrFlutterChannel? = null
    private var fraudDetectionFlutterChannel: FraudDetectionFlutterChannel? = null
    private var tencentLocationFlutterChannel: TencentLocationFlutterChannel? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 设置状态栏颜色适配不同版本
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.statusBarColor = android.graphics.Color.parseColor("#2196F3")
        }
        
        // 设置导航栏颜色适配不同版本
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.navigationBarColor = android.graphics.Color.parseColor("#FFFFFF")
        }
    }
    
    override fun onResume() {
        super.onResume()
        
        // Android 10+ 全面屏手势适配
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.attributes.layoutInDisplayCutoutMode =
                android.view.WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 初始化ASR Flutter通道
        asrFlutterChannel = AsrFlutterChannel(flutterEngine)
        
        // 初始化反诈模型Flutter通道
        fraudDetectionFlutterChannel = FraudDetectionFlutterChannel(flutterEngine, this)
        
        // 初始化腾讯定位Flutter通道
        tencentLocationFlutterChannel = TencentLocationFlutterChannel(flutterEngine, this)
    }
    
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        
        // 释放ASR Flutter通道资源
        asrFlutterChannel?.dispose()
        asrFlutterChannel = null
        
        // 释放反诈模型Flutter通道资源
        fraudDetectionFlutterChannel?.dispose()
        fraudDetectionFlutterChannel = null
        
        // 释放腾讯定位Flutter通道资源
        tencentLocationFlutterChannel = null
    }
}
