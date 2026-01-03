package com.example.offline_anti_fraud_app;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

import com.huaban.analysis.jieba.JiebaSegmenter;
import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtEnvironment;
import ai.onnxruntime.OrtException;
import ai.onnxruntime.OrtSession;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.LongBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class FraudDetectionService {
    private static final String TAG = "FraudDetectionService";
    
    // 模型配置参数
    private static final String MODEL_PATH = "bilstm_fraud_detector_cpu_int8.onnx";
    private static final String WORD2IDX_PATH = "word2idx.json";
    private static final int MAX_SEQ_LEN = 400;
    private static final int PAD_IDX = 0;
    private static final int UNK_IDX = 1;
    private static final int POS_LABEL = 1; // 1=诈骗，0=正常
    
    // ONNX Runtime相关
    private OrtEnvironment ortEnvironment;
    private OrtSession ortSession;
    
    // 词表和分词器
    private Map<String, Integer> word2idx;
    private JiebaSegmenter jiebaSegmenter;
    
    // 初始化标志
    private boolean isInitialized = false;
    
    // 上下文
    private final Context context;
    
    public FraudDetectionService(Context context) {
        this.context = context;
    }
    
    /**
     * 初始化模型服务
     */
    public synchronized boolean initialize() {
        if (isInitialized) {
            Log.d(TAG, "模型服务已经初始化");
            return true;
        }
        
        Log.d(TAG, "开始初始化模型服务...");
        
        // 重置状态
        isInitialized = false;
        
        // 检查上下文
        if (context == null) {
            Log.e(TAG, "初始化失败：上下文为空");
            return false;
        }
        
        try {
            // 检查模型文件是否存在
            AssetManager assetManager = context.getAssets();
            checkFileExists(assetManager, MODEL_PATH);
            checkFileExists(assetManager, WORD2IDX_PATH);
            
            // 1. 加载词表
            Log.d(TAG, "步骤1: 开始加载词表...");
            loadWord2idx();
            Log.d(TAG, "步骤1: 词表加载成功，大小: " + word2idx.size());
            
            // 2. 初始化Jieba分词器
            Log.d(TAG, "步骤2: 开始初始化Jieba分词器...");
            
            // 用户需求：严格使用Jieba分词器，不使用降级处理
            // 初始化失败直接抛出异常，停止模型服务加载
            jiebaSegmenter = new JiebaSegmenter();
            
            Log.d(TAG, "步骤2: Jieba分词器初始化成功");
            
            // 3. 初始化ONNX Runtime环境
            Log.d(TAG, "步骤3: 开始初始化ONNX Runtime环境...");
            ortEnvironment = OrtEnvironment.getEnvironment();
            Log.d(TAG, "步骤3: ONNX Runtime环境初始化成功");
            
            // 4. 加载ONNX模型
            Log.d(TAG, "步骤4: 开始加载ONNX模型...");
            InputStream modelInputStream = assetManager.open(MODEL_PATH);
            // 将InputStream转换为byte数组，因为ONNX Runtime v1.23.2不支持直接从InputStream创建Session
            byte[] modelBytes = new byte[modelInputStream.available()];
            int bytesRead = modelInputStream.read(modelBytes);
            modelInputStream.close();
            Log.d(TAG, "步骤4: 模型文件读取完成，大小: " + bytesRead + " 字节");
            
            Log.d(TAG, "步骤4: 开始创建ONNX Session...");
            ortSession = ortEnvironment.createSession(modelBytes);
            Log.d(TAG, "步骤4: ONNX Session创建成功");
            
            // 5. 先将isInitialized设为true，因为performInitializationCheck()会调用predict()方法
            isInitialized = true;
            
            // 6. 执行初始化检查
            Log.d(TAG, "步骤5: 开始执行初始化检查...");
            boolean checkResult = performInitializationCheck();
            
            if (!checkResult) {
                Log.e(TAG, "步骤5: 模型服务初始化检查失败");
                isInitialized = false;
                cleanup();
            } else {
                Log.d(TAG, "步骤5: 模型服务初始化检查成功");
                Log.d(TAG, "模型服务初始化成功完成");
            }
            
            return isInitialized;
            
        } catch (IOException e) {
            Log.e(TAG, "模型服务初始化失败 - IO异常: " + e.getMessage(), e);
            cleanup();
            return false;
        } catch (JSONException e) {
            Log.e(TAG, "模型服务初始化失败 - JSON异常: " + e.getMessage(), e);
            cleanup();
            return false;
        } catch (Exception e) {
            Log.e(TAG, "模型服务初始化失败: " + e.getMessage(), e);
            cleanup();
            return false;
        }
    }
    
    /**
     * 检查文件是否存在
     */
    private void checkFileExists(AssetManager assetManager, String fileName) throws IOException {
        try {
            InputStream is = assetManager.open(fileName);
            is.close();
            Log.d(TAG, "文件存在: " + fileName);
        } catch (IOException e) {
            Log.e(TAG, "文件不存在或无法读取: " + fileName, e);
            throw e;
        }
    }
    
    /**
     * 加载词表
     */
    private void loadWord2idx() throws IOException, JSONException {
        Log.d(TAG, "开始加载词表...");
        
        AssetManager assetManager = context.getAssets();
        InputStream inputStream = assetManager.open(WORD2IDX_PATH);
        BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, "UTF-8"));
        
        StringBuilder jsonContent = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            jsonContent.append(line);
        }
        reader.close();
        
        JSONObject jsonObject = new JSONObject(jsonContent.toString());
        word2idx = new HashMap<>();
        
        // 使用Iterator遍历JSONObject，兼容所有Android版本
        Iterator<String> keys = jsonObject.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            int value = jsonObject.getInt(key);
            word2idx.put(key, value);
        }
        
        Log.d(TAG, "词表加载成功，词表大小: " + word2idx.size());
    }
    
    /**
     * 执行初始化检查
     */
    private boolean performInitializationCheck() {
        try {
            Log.d(TAG, "开始执行初始化检查...");
            
            // 使用测试文本进行推理
            String testText = "A: 孙先生，根据您上次在社区健康讲座上的登记，我们发现您对改善睡眠和心脑健康特别关注，正好今天有一批日本进口的深海鱼油软胶囊到货，功效提升30%…B: 我什么时候登记过？我没去过什么讲座。A: 诶，您别急着否认！可能是家人代您登记的。而且系统显示您近期的体检报告中，微量元素硒含量偏低，这可关乎免疫力！我们这款德国富硒酵母片就是专门针对这种状况的B: 什么系统？我没做过那种检查。免疫力挺好的。A: 方女士，健康数据是不会骗人的！现在忽视骨骼健康，将来受罪的可是自己。我们特别为像您这样有远见的客户准备了限量版的纳米高钙片，比普通钙片吸收快五倍…B: 限量版？听起来像是在清库存。A: 刘主任，您看您说笑了！我们这可是高科技产品，市场需求量大得很！不过今天，只要您订购一个疗程的高钙片，就能免费获赠一瓶市价千元的澳洲进口辅酶Q10，这可是心脏的保护神！B: 免费送？那岂不是把高钙片的钱算进去了。A: 杜先生，这账可不能这么算！健康是无价的！您想想，有多少人因为肠胃不适吃不下睡不好？我们这款复合益生菌固体饮料，能有效调节肠道菌群，改善消化吸收，让您浑身舒畅…B: 我平时吃得挺好的，没什么不舒服。";
            FraudResult result = predict(testText);
            
            Log.d(TAG, "初始化检查完成，测试结果: " + result.toString());
            return true;
            
        } catch (Exception e) {
            Log.e(TAG, "初始化检查失败: " + e.getMessage(), e);
            return false;
        }
    }
    
    /**
     * 文本预处理
     */
    private PreprocessedText preprocessText(String text) {
        // 处理空值
        if (text == null || text.isEmpty()) {
            text = "";
        }
        
        // 分词
        List<String> wordList;
        
        // 用户需求：严格使用Jieba分词器，不使用降级处理
        // 直接调用Jieba分词器，异常会直接抛出
        wordList = jiebaSegmenter.sentenceProcess(text.trim());
        
        // 词转索引
        List<Integer> wordIndices = new ArrayList<>();
        for (String word : wordList) {
            Integer idx = word2idx.get(word);
            wordIndices.add(idx != null ? idx : UNK_IDX);
        }
        
        // 截断/填充
        int seqLen = wordIndices.size();
        if (seqLen > MAX_SEQ_LEN) {
            wordIndices = wordIndices.subList(0, MAX_SEQ_LEN);
            seqLen = MAX_SEQ_LEN;
        } else {
            int paddingLen = MAX_SEQ_LEN - seqLen;
            for (int i = 0; i < paddingLen; i++) {
                wordIndices.add(PAD_IDX);
            }
        }
        
        // 转换为long数组
        long[] wordIndicesArray = new long[wordIndices.size()];
        for (int i = 0; i < wordIndices.size(); i++) {
            wordIndicesArray[i] = wordIndices.get(i);
        }
        
        return new PreprocessedText(wordIndicesArray, seqLen);
    }
    
    /**
     * 模型推理
     */
    public synchronized FraudResult predict(String text) {
        if (!isInitialized) {
            throw new IllegalStateException("模型服务尚未初始化");
        }
        
        // 添加输入检查
        if (text == null || text.isEmpty()) {
            return new FraudResult(0, 1.0f, 1.0f, 0.0f); // 返回正常结果
        }
        
        Log.d(TAG, "开始模型推理，输入文本长度: " + text.length());
        
        try {
            // 文本预处理
            PreprocessedText preprocessedText = preprocessText(text);
            Log.d(TAG, "文本预处理完成，序列长度: " + preprocessedText.seqLen);
            
            // 准备输入张量
            long[] wordIndices = preprocessedText.wordIndices;
            long[] seqLens = {preprocessedText.seqLen};
            
            // 检查张量数据
            Log.d(TAG, "创建输入张量，wordIndices长度: " + wordIndices.length + ", seqLens: " + seqLens[0]);
            
            // 创建输入张量
            OnnxTensor wordIndicesTensor = null;
            OnnxTensor seqLensTensor = null;
            OrtSession.Result results = null;
            
            try {
                // 使用安全方式创建张量
                wordIndicesTensor = OnnxTensor.createTensor(ortEnvironment, LongBuffer.wrap(wordIndices), new long[]{1, MAX_SEQ_LEN});
                seqLensTensor = OnnxTensor.createTensor(ortEnvironment, LongBuffer.wrap(seqLens), new long[]{1});
                
                Log.d(TAG, "输入张量创建成功");
                
                // 构建输入映射
                Map<String, OnnxTensor> inputMap = new HashMap<>();
                inputMap.put("word_indices", wordIndicesTensor);
                inputMap.put("seq_lens", seqLensTensor);
                
                Log.d(TAG, "输入映射构建完成，准备执行推理");
                
                // 执行推理
                results = ortSession.run(inputMap);
                
                Log.d(TAG, "推理执行完成，输出数量: " + results.size());
                
                // 处理输出
                if (results.size() > 0) {
                    Log.d(TAG, "获取输出张量");
                    float[][] logits = (float[][]) results.get(0).getValue();
                    
                    // 计算softmax概率
                    float[] probs = softmax(logits[0]);
                    
                    // 确定预测标签
                    int predLabel = probs[1] > probs[0] ? 1 : 0;
                    float predProb = probs[predLabel];
                    
                    Log.d(TAG, "推理结果处理完成，预测标签: " + predLabel + ", 概率: " + predProb);
                    
                    // 返回结果
                    return new FraudResult(predLabel, predProb, probs[0], probs[1]);
                } else {
                    Log.e(TAG, "推理结果为空");
                    return new FraudResult(0, 0.5f, 0.5f, 0.5f); // 返回中立结果
                }
            } finally {
                // 安全释放资源
                if (wordIndicesTensor != null) {
                    try {
                        wordIndicesTensor.close();
                    } catch (Exception e) {
                        Log.e(TAG, "释放wordIndicesTensor失败: " + e.getMessage());
                    }
                }
                if (seqLensTensor != null) {
                    try {
                        seqLensTensor.close();
                    } catch (Exception e) {
                        Log.e(TAG, "释放seqLensTensor失败: " + e.getMessage());
                    }
                }
                if (results != null) {
                    try {
                        results.close();
                    } catch (Exception e) {
                        Log.e(TAG, "释放results失败: " + e.getMessage());
                    }
                }
            }
        } catch (OrtException e) {
            Log.e(TAG, "ONNX Runtime异常: " + e.getMessage(), e);
            throw new RuntimeException("ONNX Runtime推理失败: " + e.getMessage(), e);
        } catch (Exception e) {
            Log.e(TAG, "模型推理失败，非ONNX异常: " + e.getMessage(), e);
            throw new RuntimeException("模型推理失败: " + e.getMessage(), e);
        }
    }
    
    /**
     * Softmax计算
     */
    private float[] softmax(float[] logits) {
        float[] expLogits = new float[logits.length];
        float maxLogit = logits[0];
        
        // 找到最大值（数值稳定）
        for (float logit : logits) {
            if (logit > maxLogit) {
                maxLogit = logit;
            }
        }
        
        // 计算指数
        float sumExp = 0.0f;
        for (int i = 0; i < logits.length; i++) {
            expLogits[i] = (float) Math.exp(logits[i] - maxLogit);
            sumExp += expLogits[i];
        }
        
        // 计算概率
        float[] probs = new float[logits.length];
        for (int i = 0; i < logits.length; i++) {
            probs[i] = expLogits[i] / sumExp;
        }
        
        return probs;
    }
    
    /**
     * 释放资源
     */
    public synchronized void cleanup() {
        try {
            if (ortSession != null) {
                ortSession.close();
                ortSession = null;
            }
            
            if (ortEnvironment != null) {
                ortEnvironment.close();
                ortEnvironment = null;
            }
            
            isInitialized = false;
            Log.d(TAG, "模型服务资源已释放");
        } catch (OrtException e) {
            Log.e(TAG, "释放资源失败: " + e.getMessage(), e);
        } catch (Exception e) {
            Log.e(TAG, "释放资源失败 - 其他异常: " + e.getMessage(), e);
        }
    }
    
    /**
     * 获取初始化状态
     */
    public boolean isInitialized() {
        return isInitialized;
    }
    
    /**
     * 预处理文本结果类
     */
    private static class PreprocessedText {
        long[] wordIndices;
        int seqLen;
        
        PreprocessedText(long[] wordIndices, int seqLen) {
            this.wordIndices = wordIndices;
            this.seqLen = seqLen;
        }
    }
    
    /**
     * 诈骗检测结果类
     */
    public static class FraudResult {
        public int predLabel;
        public float predProb;
        public float normalProb;
        public float fraudProb;
        
        public FraudResult(int predLabel, float predProb, float normalProb, float fraudProb) {
            this.predLabel = predLabel;
            this.predProb = predProb;
            this.normalProb = normalProb;
            this.fraudProb = fraudProb;
        }
        
        @Override
        public String toString() {
            return "FraudResult{" +
                    "predLabel=" + predLabel +
                    ", predProb=" + predProb +
                    ", normalProb=" + normalProb +
                    ", fraudProb=" + fraudProb +
                    '}';
        }
    }
}