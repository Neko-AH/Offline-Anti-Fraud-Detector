package com.example.offline_anti_fraud_app

import android.util.Log
import androidx.multidex.MultiDexApplication
import com.tencent.map.geolocation.TencentLocationManagerOptions

class AppApplication : MultiDexApplication() {
    private val TAG = "AppApplication"
    
    override fun onCreate() {
        super.onCreate()
        // 初始化MultiDex支持
        androidx.multidex.MultiDex.install(this)
        
        // 初始化腾讯定位SDK
        try {
            TencentLocationManagerOptions.setKey("")    // 补充密钥
            Log.d(TAG, "Tencent Location SDK initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Tencent Location SDK: ${e.message}")
            e.printStackTrace()
        }
    }
}