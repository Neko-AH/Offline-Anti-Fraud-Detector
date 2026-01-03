package com.example.offline_anti_fraud_app;

import android.util.Log;

import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.plugin.common.MethodChannel;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.handshake.ServerHandshake;
import org.json.JSONObject;

import java.net.URI;
import java.nio.ByteBuffer;
import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.Base64;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class AsrService {
    private static final String TAG = "AsrService";
    // API密钥池
    private static final String[] API_KEYS = {
        // 补充密钥
    };
    private static final String MODEL = "qwen3-asr-flash-realtime";
    private static final String BASE_URL = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime";
    
    private int currentApiKeyIndex = 0; // 当前使用的密钥索引
    private Set<Integer> triedApiKeyIndices = new HashSet<>(); // 用于跟踪已经尝试过的密钥索引

    // 重连相关配置
    private static final int MAX_RECONNECT_ATTEMPTS = 5; // 最大重连次数
    private static final long INITIAL_RECONNECT_DELAY = 1000; // 初始重连延迟（毫秒）
    private static final long MAX_RECONNECT_DELAY = 30000; // 最大重连延迟（毫秒）
    
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final AtomicBoolean isReconnecting = new AtomicBoolean(false);
    private WebSocketClient webSocketClient;
    private AudioRecorder audioRecorder;
    private AsrListener listener;
    private int reconnectAttempts = 0;
    private long reconnectDelay = INITIAL_RECONNECT_DELAY;
    private final ExecutorService sendExecutor = Executors.newSingleThreadExecutor(); // 单独的线程用于发送音频数据，避免阻塞录音线程
    
    public interface AsrListener {
        void onAsrResult(String result);
        void onStatusChanged(String status);
        void onError(String error);
    }
    
    public AsrService() {
        audioRecorder = new AudioRecorder(new AudioRecorder.AudioListener() {
            @Override
            public void onAudioData(byte[] data) {
                sendAudioData(data);
            }
        });
    }
    
    public void setListener(AsrListener listener) {
        this.listener = listener;
    }
    
    public void start() {
        if (isRunning.get()) {
            Log.d(TAG, "ASR service is already running");
            return;
        }
        
        try {
            isRunning.set(true);
            // 每次启动服务时，从头检查API密钥
            resetReconnectState();
            connectWebSocket();
            audioRecorder.startRecording();
            notifyStatusChanged("ASR服务已启动");
        } catch (Exception e) {
            Log.e(TAG, "Failed to start ASR service: " + e.getMessage());
            notifyError("启动ASR服务失败: " + e.getMessage());
            stop();
        }
    }
    
    public void stop() {
        if (!isRunning.get()) {
            Log.d(TAG, "ASR service is not running");
            return;
        }
        
        try {
            isRunning.set(false);
            
            if (audioRecorder != null) {
                audioRecorder.stopRecording();
            }
            
            if (webSocketClient != null && webSocketClient.isOpen()) {
                webSocketClient.close(1000, "ASR service stopped");
            }
            
            notifyStatusChanged("ASR服务已停止");
        } catch (Exception e) {
            Log.e(TAG, "Failed to stop ASR service: " + e.getMessage());
            notifyError("停止ASR服务失败: " + e.getMessage());
        }
    }
    
    // 获取当前API密钥
    private String getCurrentApiKey() {
        return API_KEYS[currentApiKeyIndex];
    }
    
    // 切换到下一个API密钥
    private void switchToNextApiKey() {
        if (currentApiKeyIndex < API_KEYS.length - 1) {
            currentApiKeyIndex++;
            Log.d(TAG, "切换到下一个API密钥: " + getCurrentApiKey());
        } else {
            Log.d(TAG, "已达到最后一个API密钥，重置为第一个");
            currentApiKeyIndex = 0;
        }
    }
    
    private void connectWebSocket() throws Exception {
        String url = BASE_URL + "?model=" + MODEL;
        Log.d(TAG, "Connecting to ASR server: " + url);
        Log.d(TAG, "使用API密钥索引 " + currentApiKeyIndex + ": " + getCurrentApiKey());
        
        // 创建信任所有证书的SSL上下文（用于解决Android SSL验证严格的问题）
        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(null, new TrustManager[]{
            new X509TrustManager() {
                @Override
                public void checkClientTrusted(X509Certificate[] chain, String authType) {
                    // 信任所有客户端证书
                }
                
                @Override
                public void checkServerTrusted(X509Certificate[] chain, String authType) {
                    // 信任所有服务器证书
                }
                
                @Override
                public X509Certificate[] getAcceptedIssuers() {
                    return new X509Certificate[0];
                }
            }
        }, new SecureRandom());
        
        // 创建WebSocket客户端，使用自定义的SSL上下文
        // 注意：Java-WebSocket 1.5.6版本的WebSocketClient构造函数不直接支持SSLContext
        // 我们通过设置全局的HostnameVerifier来绕过证书验证
        javax.net.ssl.HttpsURLConnection.setDefaultHostnameVerifier(
            new javax.net.ssl.HostnameVerifier() {
                @Override
                public boolean verify(String hostname, javax.net.ssl.SSLSession session) {
                    // 信任所有主机名，仅用于测试环境
                    return true;
                }
            }
        );
        
        // 设置全局SSL上下文
        javax.net.ssl.HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.getSocketFactory());
        
        webSocketClient = new WebSocketClient(new URI(url)) {
            @Override
            public void onOpen(ServerHandshake handshake) {
                Log.d(TAG, "WebSocket connected");
                // 重置重连状态
                resetReconnectState();
                sendSessionUpdate();
                notifyStatusChanged("已连接到ASR服务器");
            }
            
            @Override
            public void onMessage(String message) {
                handleAsrResponse(message);
            }
            
            @Override
            public void onClose(int code, String reason, boolean remote) {
                Log.d(TAG, "WebSocket closed: " + code + " - " + reason);
                notifyStatusChanged("已断开ASR服务器连接");
                
                // 重置重连状态，确保能执行重连
                isReconnecting.set(false);
                
                // 处理重连逻辑（由handleReconnect决定是否切换密钥）
                handleReconnect();
            }
            
            @Override
            public void onError(Exception ex) {
                Log.e(TAG, "WebSocket error: " + ex.getMessage());
                
                // 重置重连状态，确保能执行重连
                isReconnecting.set(false);
                
                // 只记录错误，不抛出异常，避免崩溃
                notifyError("ASR服务器连接错误: " + ex.getMessage());
                
                // 处理重连逻辑（由handleReconnect决定是否切换密钥）
                handleReconnect();
            }
        };
        
        // 添加请求头，使用当前API密钥
        webSocketClient.addHeader("Authorization", "Bearer " + getCurrentApiKey());
        webSocketClient.addHeader("OpenAI-Beta", "realtime=v1");
        
        webSocketClient.connectBlocking();
    }
    
    private void sendSessionUpdate() {
        try {
            // 创建modalities数组，使用JSONArray而不是普通Java数组
            org.json.JSONArray modalitiesArray = new org.json.JSONArray();
            modalitiesArray.put("text");
            
            JSONObject sessionUpdate = new JSONObject()
                    .put("event_id", "event_" + System.currentTimeMillis())
                    .put("type", "session.update")
                    .put("session", new JSONObject()
                            .put("modalities", modalitiesArray)
                            .put("input_audio_format", "pcm")
                            .put("sample_rate", 16000)
                            .put("input_audio_transcription", new JSONObject()
                                    .put("language", "zh"))
                            .put("turn_detection", new JSONObject()
                                    .put("type", "server_vad")
                                    .put("threshold", 0.15)
                                    .put("silence_duration_ms", 500)));
            
            if (webSocketClient != null && webSocketClient.isOpen()) {
                webSocketClient.send(sessionUpdate.toString());
                Log.d(TAG, "Sent session update: " + sessionUpdate.toString());
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to send session update: " + e.getMessage());
        }
    }
    
    private void sendAudioData(byte[] data) {
        if (!isRunning.get() || webSocketClient == null || !webSocketClient.isOpen()) {
            return;
        }
        
        // 将音频数据发送操作提交到单独的线程执行，避免阻塞录音线程
        sendExecutor.submit(() -> {
            try {
                String encoded = Base64.getEncoder().encodeToString(data);
                JSONObject audioEvent = new JSONObject()
                        .put("event_id", "event_" + System.currentTimeMillis())
                        .put("type", "input_audio_buffer.append")
                        .put("audio", encoded);
                
                webSocketClient.send(audioEvent.toString());
            } catch (Exception e) {
                Log.e(TAG, "发送音频数据失败: " + e.getMessage());
                notifyError("发送音频数据失败: " + e.getMessage());
            }
        });
    }
    
    private void handleAsrResponse(String message) {
        try {
            JSONObject data = new JSONObject(message);
            String eventType = data.optString("type");
            
            if ("conversation.item.input_audio_transcription.completed".equals(eventType)) {
                String transcript = data.optString("transcript");
                notifyAsrResult(transcript);
            } else if ("conversation.item.input_audio_transcription.partial".equals(eventType)) {
                String transcript = data.optString("transcript");
                notifyAsrResult(transcript);
            }
        } catch (Exception e) {
            Log.e(TAG, "解析ASR结果失败: " + e.getMessage());
            notifyError("解析ASR结果失败: " + e.getMessage());
        }
    }
    
    private void notifyAsrResult(String result) {
        if (listener != null) {
            listener.onAsrResult(result);
        }
    }
    
    private void notifyStatusChanged(String status) {
        if (listener != null) {
            listener.onStatusChanged(status);
        }
    }
    
    private void notifyError(String error) {
        if (listener != null) {
            listener.onError(error);
        }
    }
    
    /**
     * 处理重连逻辑
     */
    private void handleReconnect() {
        if (!isRunning.get() || isReconnecting.get()) {
            Log.d(TAG, "Skipping reconnect: isRunning=" + isRunning.get() + ", isReconnecting=" + isReconnecting.get());
            return;
        }
        
        // 标记当前API密钥已被尝试
        triedApiKeyIndices.add(currentApiKeyIndex);
        Log.d(TAG, "Marked API key index " + currentApiKeyIndex + " as tried");
        Log.d(TAG, "Tried API key indices: " + triedApiKeyIndices);
        
        // 检查是否所有API密钥都已尝试过
        if (triedApiKeyIndices.size() >= API_KEYS.length) {
            Log.e(TAG, "All API keys have been used and failed, notifying with api密钥失效");
            notifyError("api密钥失效");
            notifyStatusChanged("api密钥失效");
            stop();
            return;
        }
        
        // 切换到下一个API密钥
        switchToNextApiKey();
        Log.d(TAG, "Switched to next API key index " + currentApiKeyIndex);
        
        // 如果当前密钥已经尝试过，继续切换直到找到一个未尝试过的密钥
        while (triedApiKeyIndices.contains(currentApiKeyIndex)) {
            switchToNextApiKey();
            Log.d(TAG, "Current API key index " + currentApiKeyIndex + " already tried, switching again");
        }
        
        isReconnecting.set(true);
        
        // 使用初始重连延迟，因为这是一个新的API密钥
        long delay = INITIAL_RECONNECT_DELAY;
        
        Log.d(TAG, "Attempting to reconnect with new API key index " + currentApiKeyIndex + " in " + delay + "ms");
        notifyStatusChanged("尝试切换API密钥重连中...");
        
        // 延迟执行重连
        new Thread(() -> {
            try {
                Thread.sleep(delay);
                reconnect();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                isReconnecting.set(false);
            }
        }).start();
    }
    
    /**
     * 执行重连操作
     */
    private void reconnect() {
        try {
            Log.d(TAG, "Reconnecting...");
            
            // 关闭旧连接
            if (webSocketClient != null) {
                webSocketClient.close();
                webSocketClient = null;
            }
            
            // 重新连接
            connectWebSocket();
        } catch (Exception e) {
            Log.e(TAG, "Reconnect failed: " + e.getMessage());
            isReconnecting.set(false);
            // 继续尝试重连
            handleReconnect();
        } finally {
            isReconnecting.set(false);
        }
    }
    
    /**
     * 重置重连状态和API密钥索引
     */
    private void resetReconnectState() {
        reconnectAttempts = 0;
        reconnectDelay = INITIAL_RECONNECT_DELAY;
        isReconnecting.set(false);
        // 连接成功时重置API密钥索引到第一个并清除已尝试密钥集合
        currentApiKeyIndex = 0;
        triedApiKeyIndices.clear();
        Log.d(TAG, "Reconnect state reset，API密钥索引已重置，已尝试密钥集合已清除");
    }
}