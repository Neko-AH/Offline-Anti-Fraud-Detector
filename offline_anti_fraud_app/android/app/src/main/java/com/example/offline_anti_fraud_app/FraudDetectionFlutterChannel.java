package com.example.offline_anti_fraud_app;

import android.content.Context;
import android.util.Log;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class FraudDetectionFlutterChannel implements MethodCallHandler {
    private static final String TAG = "FraudDetectionChannel";
    private static final String CHANNEL_NAME = "com.example.offline_anti_fraud_app/fraud_detection";
    
    private final FraudDetectionService fraudDetectionService;
    private final MethodChannel channel;
    
    // 方法名常量
    private static final String METHOD_INIT = "init";
    private static final String METHOD_CLEANUP = "cleanup";
    private static final String METHOD_PREDICT = "predict";
    private static final String METHOD_IS_INITIALIZED = "isInitialized";
    
    // 错误码常量
    private static final String ERROR_INIT_FAILED = "INIT_FAILED";
    private static final String ERROR_NOT_INITIALIZED = "NOT_INITIALIZED";
    private static final String ERROR_PREDICT_FAILED = "PREDICT_FAILED";
    
    public FraudDetectionFlutterChannel(FlutterEngine flutterEngine, Context context) {
        this.fraudDetectionService = new FraudDetectionService(context);
        this.channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME);
        this.channel.setMethodCallHandler(this);
        
        Log.d(TAG, "FraudDetectionFlutterChannel initialized");
    }
    
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        try {
            if (METHOD_INIT.equals(call.method)) {
                // 初始化模型服务
                boolean success = fraudDetectionService.initialize();
                result.success(success);
                Log.d(TAG, "Received init command, result: " + success);
            } else if (METHOD_CLEANUP.equals(call.method)) {
                // 释放模型服务资源
                fraudDetectionService.cleanup();
                result.success(true);
                Log.d(TAG, "Received cleanup command");
            } else if (METHOD_PREDICT.equals(call.method)) {
                // 模型推理
                String text = call.argument("text");
                if (text == null) {
                    result.error(ERROR_PREDICT_FAILED, "Text argument is null", null);
                    return;
                }
                
                FraudDetectionService.FraudResult predResult = fraudDetectionService.predict(text);
                
                // 构建结果映射
                java.util.Map<String, Object> resultMap = new java.util.HashMap<>();
                resultMap.put("predLabel", predResult.predLabel);
                resultMap.put("predProb", predResult.predProb);
                resultMap.put("normalProb", predResult.normalProb);
                resultMap.put("fraudProb", predResult.fraudProb);
                
                result.success(resultMap);
                Log.d(TAG, "Received predict command, result: " + predResult.toString());
            } else if (METHOD_IS_INITIALIZED.equals(call.method)) {
                // 检查模型服务是否已初始化
                boolean isInitialized = fraudDetectionService.isInitialized();
                result.success(isInitialized);
                Log.d(TAG, "Received isInitialized command, result: " + isInitialized);
            } else {
                result.notImplemented();
                Log.w(TAG, "Received unknown method: " + call.method);
            }
        } catch (IllegalStateException e) {
            Log.e(TAG, "Error handling method call: " + e.getMessage());
            result.error(ERROR_NOT_INITIALIZED, e.getMessage(), null);
        } catch (Exception e) {
            Log.e(TAG, "Error handling method call: " + e.getMessage(), e);
            result.error(ERROR_PREDICT_FAILED, e.getMessage(), null);
        }
    }
    
    public void dispose() {
        // 释放模型服务资源
        fraudDetectionService.cleanup();
        // 移除方法调用处理器
        channel.setMethodCallHandler(null);
        Log.d(TAG, "Disposed FraudDetectionFlutterChannel");
    }
}