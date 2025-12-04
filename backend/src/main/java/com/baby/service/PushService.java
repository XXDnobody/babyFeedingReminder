package com.baby.service;

/**
 * 推送服务接口
 */
public interface PushService {
    
    /**
     * 发送推送通知
     * @param deviceToken 设备Token
     * @param title 标题
     * @param content 内容
     */
    void sendPush(String deviceToken, String title, String content);
    
    /**
     * 发送静默推送
     * @param deviceToken 设备Token
     * @param payload 负载数据
     */
    void sendSilentPush(String deviceToken, String payload);
}
