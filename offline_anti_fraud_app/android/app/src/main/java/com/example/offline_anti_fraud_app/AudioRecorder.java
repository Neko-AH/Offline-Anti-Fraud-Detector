package com.example.offline_anti_fraud_app;

import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.util.Log;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

public class AudioRecorder {
    private static final String TAG = "AudioRecorder";
    
    // 录音参数配置
    private static final int SAMPLE_RATE = 16000; // 16kHz采样率
    private static final int CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO; // 单声道
    private static final int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT; // 16位PCM
    private static final int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT) * 8; 
    private static final int CHUNK_SIZE = 3200; // 每块3200字节 = 100ms音频，实时识别最佳实践
    private static final int MIN_CHUNK_SIZE = 800; // 降低最小发送块大小 = 25ms音频，加快数据发送
    private static final long MAX_BUFFER_TIME = 300; // 降低最大等待时间，加快数据发送
    private static final double BUFFER_THRESHOLD = 0.7; // 降低缓冲区阈值，更早发送数据
    
    private final AudioListener listener;
    private final AtomicBoolean isRecording = new AtomicBoolean(false);
    private final ExecutorService executorService = Executors.newSingleThreadExecutor();
    
    private AudioRecord audioRecord;
    
    public interface AudioListener {
        void onAudioData(byte[] data);
    }
    
    public AudioRecorder(AudioListener listener) {
        this.listener = listener;
    }
    
    public void startRecording() {
        if (isRecording.get()) {
            Log.d(TAG, "Already recording");
            return;
        }
        
        try {
            // 创建AudioRecord实例
            audioRecord = new AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    SAMPLE_RATE,
                    CHANNEL_CONFIG,
                    AUDIO_FORMAT,
                    BUFFER_SIZE
            );
            
            if (audioRecord.getState() != AudioRecord.STATE_INITIALIZED) {
                throw new IllegalStateException("Failed to initialize AudioRecord");
            }
            
            audioRecord.startRecording();
            isRecording.set(true);
            Log.d(TAG, "Started recording");
            
            // 启动录音线程
            executorService.execute(this::recordAudio);
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to start recording: " + e.getMessage());
            stopRecording();
            throw e;
        }
    }
    
    public void stopRecording() {
        if (!isRecording.get()) {
            Log.d(TAG, "Not recording");
            return;
        }
        
        try {
            isRecording.set(false);
            
            if (audioRecord != null) {
                if (audioRecord.getState() == AudioRecord.STATE_INITIALIZED) {
                    audioRecord.stop();
                }
                audioRecord.release();
                audioRecord = null;
            }
            
            Log.d(TAG, "Stopped recording");
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to stop recording: " + e.getMessage());
        }
    }
    
    private void recordAudio() {
        byte[] buffer = new byte[BUFFER_SIZE];
        int bufferOffset = 0;
        long lastSendTime = System.currentTimeMillis();
        
        // 提高录音线程优先级
        Thread.currentThread().setPriority(Thread.MAX_PRIORITY);
        Log.d(TAG, "Recording thread priority set to MAX_PRIORITY");
        
        while (isRecording.get()) {
            int readBytes = audioRecord.read(buffer, bufferOffset, buffer.length - bufferOffset);
            
            if (readBytes < 0) {
                Log.e(TAG, "Error reading audio data: " + readBytes);
                break;
            } else if (readBytes == 0) {
                try {
                    // 检查是否超过最大等待时间，超过则发送数据
                    if (bufferOffset > 0 && System.currentTimeMillis() - lastSendTime > MAX_BUFFER_TIME) {
                        Log.d(TAG, "Buffer timeout, sending available data: " + bufferOffset + " bytes");
                        byte[] availableData = new byte[bufferOffset];
                        System.arraycopy(buffer, 0, availableData, 0, bufferOffset);
                        if (listener != null) {
                            listener.onAudioData(availableData);
                        }
                        bufferOffset = 0;
                        lastSendTime = System.currentTimeMillis();
                    }
                    
                    // 短暂休眠，避免CPU占用过高
                    Thread.sleep(10);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
                continue;
            }
            
            // 检查缓冲区是否即将溢出
            if (bufferOffset + readBytes > buffer.length * BUFFER_THRESHOLD) {
                // 立即发送当前可用数据，避免溢出
                if (bufferOffset > 0 && listener != null) {
                    byte[] availableData = new byte[bufferOffset];
                    System.arraycopy(buffer, 0, availableData, 0, bufferOffset);
                    listener.onAudioData(availableData);
                    bufferOffset = 0;
                    lastSendTime = System.currentTimeMillis();
                }
            }
            
            bufferOffset += readBytes;
            
            // 当缓冲区有完整的CHUNK_SIZE数据时，发送所有完整块
            while (bufferOffset >= CHUNK_SIZE) {
                byte[] chunk = new byte[CHUNK_SIZE];
                System.arraycopy(buffer, 0, chunk, 0, CHUNK_SIZE);
                
                // 发送音频数据
                if (listener != null) {
                    listener.onAudioData(chunk);
                }
                
                // 将剩余数据移到缓冲区开头
                int remaining = bufferOffset - CHUNK_SIZE;
                if (remaining > 0) {
                    System.arraycopy(buffer, CHUNK_SIZE, buffer, 0, remaining);
                }
                bufferOffset = remaining;
                lastSendTime = System.currentTimeMillis();
            }
            
            // 如果剩余数据达到MIN_CHUNK_SIZE，也立即发送，避免数据堆积
            if (bufferOffset >= MIN_CHUNK_SIZE) {
                byte[] chunk = new byte[bufferOffset];
                System.arraycopy(buffer, 0, chunk, 0, bufferOffset);
                
                // 发送音频数据
                if (listener != null) {
                    listener.onAudioData(chunk);
                }
                bufferOffset = 0;
                lastSendTime = System.currentTimeMillis();
            }
        }
        
        // 处理剩余数据
        if (bufferOffset > 0 && listener != null) {
            byte[] remaining = new byte[bufferOffset];
            System.arraycopy(buffer, 0, remaining, 0, bufferOffset);
            listener.onAudioData(remaining);
        }
        
        Log.d(TAG, "Recording thread exiting");
    }
    
    public boolean isRecording() {
        return isRecording.get();
    }
}