package com.example.offline_anti_fraud_app;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

public class AsrFlutterChannel implements MethodCallHandler {
    private static final String TAG = "AsrFlutterChannel";
    private static final String CHANNEL_NAME = "com.example.offline_anti_fraud_app/asr";
    
    private final AsrService asrService;
    private final MethodChannel channel;
    private final Handler mainHandler; // 主线程Handler，用于确保MethodChannel调用在主线程执行
    
    // 方法名常量
    private static final String METHOD_START = "start";
    private static final String METHOD_STOP = "stop";
    
    // 事件名常量
    private static final String EVENT_ASR_RESULT = "asrResult";
    private static final String EVENT_STATUS_CHANGED = "statusChanged";
    private static final String EVENT_ERROR = "error";
    private static final String EVENT_API_KEY_ERROR = "apiKeyError"; // 添加API密钥错误事件
    
    public AsrFlutterChannel(FlutterEngine flutterEngine) {
        this.asrService = new AsrService();
        this.channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME);
        this.channel.setMethodCallHandler(this);
        this.mainHandler = new Handler(Looper.getMainLooper()); // 初始化主线程Handler
        
        // 设置ASR服务监听器
        this.asrService.setListener(new AsrService.AsrListener() {
            @Override
            public void onAsrResult(String result) {
                final String finalResult = result;
                // 确保在主线程调用MethodChannel
                mainHandler.post(() -> {
                    // 发送ASR结果到Flutter
                    channel.invokeMethod(EVENT_ASR_RESULT, finalResult);
                });
            }
            
            @Override
            public void onStatusChanged(String status) {
                final String finalStatus = status;
                // 确保在主线程调用MethodChannel
                mainHandler.post(() -> {
                    // 发送状态变化到Flutter
                    channel.invokeMethod(EVENT_STATUS_CHANGED, finalStatus);
                });
                Log.d(TAG, "ASR状态变化: " + status);
            }
            
            @Override
            public void onError(String error) {
                final String finalError = error;
                // 确保在主线程调用MethodChannel
                mainHandler.post(() -> {
                    // 检查是否是API密钥失效错误
                    if ("api密钥失效".equals(finalError)) {
                        // 发送API密钥错误事件到Flutter
                        channel.invokeMethod(EVENT_API_KEY_ERROR, null);
                        Log.e(TAG, "API密钥失效，所有密钥都已失败");
                    } else {
                        // 发送普通错误信息到Flutter
                        channel.invokeMethod(EVENT_ERROR, finalError);
                    }
                });
                Log.e(TAG, "ASR错误: " + error);
            }
        });
    }
    
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        try {
            if (METHOD_START.equals(call.method)) {
                // 启动ASR服务
                asrService.start();
                result.success(true);
                Log.d(TAG, "Received start command");
            } else if (METHOD_STOP.equals(call.method)) {
                // 停止ASR服务
                asrService.stop();
                result.success(true);
                Log.d(TAG, "Received stop command");
            } else {
                result.notImplemented();
                Log.w(TAG, "Received unknown method: " + call.method);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error handling method call: " + e.getMessage());
            result.error("ASR_ERROR", e.getMessage(), null);
        }
    }
    
    public void dispose() {
        // 停止ASR服务
        asrService.stop();
        // 移除方法调用处理器
        channel.setMethodCallHandler(null);
        Log.d(TAG, "Disposed AsrFlutterChannel");
    }
}