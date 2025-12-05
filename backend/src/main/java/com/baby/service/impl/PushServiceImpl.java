package com.baby.service.impl;

import com.baby.service.PushService;
import com.eatthepath.pushy.apns.ApnsClient;
import com.eatthepath.pushy.apns.ApnsClientBuilder;
import com.eatthepath.pushy.apns.PushNotificationResponse;
import com.eatthepath.pushy.apns.util.ApnsPayloadBuilder;
import com.eatthepath.pushy.apns.util.SimpleApnsPayloadBuilder;
import com.eatthepath.pushy.apns.util.SimpleApnsPushNotification;
import com.eatthepath.pushy.apns.util.TokenUtil;
import com.eatthepath.pushy.apns.util.concurrent.PushNotificationFuture;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.time.Instant;
import java.util.concurrent.ExecutionException;

/**
 * APNs推送服务实现类
 * 使用Pushy库实现苹果推送
 */
@Slf4j
@Service
public class PushServiceImpl implements PushService {
    
    @Value("${apns.enabled:false}")
    private boolean apnsEnabled;
    
    @Value("${apns.production:false}")
    private boolean apnsProduction;
    
    @Value("${apns.topic:com.baby.feedingreminder}")
    private String apnsTopic;
    
    @Value("${apns.certificate-path:}")
    private Resource certificatePath;
    
    @Value("${apns.certificate-password:}")
    private String certificatePassword;
    
    private ApnsClient apnsClient;
    
    @PostConstruct
    public void init() {
        if (!apnsEnabled) {
            log.info("APNs推送未启用，将使用模拟模式");
            return;
        }
        
        try {
            String server = apnsProduction 
                    ? ApnsClientBuilder.PRODUCTION_APNS_HOST 
                    : ApnsClientBuilder.DEVELOPMENT_APNS_HOST;
            
            apnsClient = new ApnsClientBuilder()
                    .setApnsServer(server)
                    .setClientCredentials(
                            certificatePath.getInputStream(), 
                            certificatePassword)
                    .build();
            
            log.info("✅ APNs客户端初始化成功，服务器: {}", server);
        } catch (IOException e) {
            log.error("❌ APNs客户端初始化失败: {}", e.getMessage());
            apnsEnabled = false;
        }
    }
    
    @PreDestroy
    public void destroy() {
        if (apnsClient != null) {
            try {
                apnsClient.close().get();
                log.info("APNs客户端已关闭");
            } catch (Exception e) {
                log.error("APNs客户端关闭失败", e);
            }
        }
    }
    
    @Override
    public void sendPush(String deviceToken, String title, String content) {
        if (deviceToken == null || deviceToken.isEmpty()) {
            log.warn("设备Token为空，跳过推送");
            return;
        }
        
        if (!apnsEnabled || apnsClient == null) {
            log.info("📤 [模拟推送] 标题: {}, 内容: {}, deviceToken: {}...", 
                    title, content, deviceToken.substring(0, Math.min(16, deviceToken.length())));
            return;
        }
        
        try {
            // 标准化deviceToken（移除空格和尖括号）
            String sanitizedToken = TokenUtil.sanitizeTokenString(deviceToken);
            
            // 构建推送负载
            ApnsPayloadBuilder payloadBuilder = new SimpleApnsPayloadBuilder()
                    .setAlertTitle(title)
                    .setAlertBody(content)
                    .setSound("default")
                    .setBadgeNumber(1);
            
            String payload = payloadBuilder.build();
            
            // 创建推送通知
            SimpleApnsPushNotification notification = new SimpleApnsPushNotification(
                    sanitizedToken,
                    apnsTopic,
                    payload,
                    Instant.now().plusSeconds(86400),  // 24小时过期
                    com.eatthepath.pushy.apns.DeliveryPriority.IMMEDIATE,
                    com.eatthepath.pushy.apns.PushType.ALERT
            );
            
            // 发送推送
            PushNotificationFuture<SimpleApnsPushNotification, PushNotificationResponse<SimpleApnsPushNotification>> 
                    sendFuture = apnsClient.sendNotification(notification);
            
            PushNotificationResponse<SimpleApnsPushNotification> response = sendFuture.get();
            
            if (response.isAccepted()) {
                log.info("✅ APNs推送成功: title={}, deviceToken={}...", 
                        title, sanitizedToken.substring(0, 16));
            } else {
                log.warn("❌ APNs推送被拒绝: reason={}, deviceToken={}...", 
                        response.getRejectionReason().orElse("unknown"),
                        sanitizedToken.substring(0, 16));
                
                // 如果Token无效，记录日志
                if (response.getTokenInvalidationTimestamp().isPresent()) {
                    log.warn("Token已失效，失效时间: {}", 
                            response.getTokenInvalidationTimestamp().get());
                }
            }
            
        } catch (ExecutionException e) {
            log.error("❌ APNs推送执行失败: deviceToken={}..., error={}", 
                    deviceToken.substring(0, Math.min(16, deviceToken.length())), 
                    e.getMessage());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.error("❌ APNs推送被中断");
        } catch (Exception e) {
            log.error("❌ APNs推送异常: {}", e.getMessage(), e);
        }
    }
    
    @Override
    public void sendSilentPush(String deviceToken, String payload) {
        if (deviceToken == null || deviceToken.isEmpty()) {
            log.warn("设备Token为空，跳过静默推送");
            return;
        }
        
        if (!apnsEnabled || apnsClient == null) {
            log.info("📤 [模拟静默推送] payload: {}, deviceToken: {}...", 
                    payload, deviceToken.substring(0, Math.min(16, deviceToken.length())));
            return;
        }
        
        try {
            String sanitizedToken = TokenUtil.sanitizeTokenString(deviceToken);
            
            // 静默推送负载
            ApnsPayloadBuilder payloadBuilder = new SimpleApnsPayloadBuilder()
                    .setContentAvailable(true);
            
            String silentPayload = payloadBuilder.build();
            
            SimpleApnsPushNotification notification = new SimpleApnsPushNotification(
                    sanitizedToken,
                    apnsTopic,
                    silentPayload,
                    Instant.now().plusSeconds(86400),
                    com.eatthepath.pushy.apns.DeliveryPriority.CONSERVE_POWER,
                    com.eatthepath.pushy.apns.PushType.BACKGROUND
            );
            
            PushNotificationFuture<SimpleApnsPushNotification, PushNotificationResponse<SimpleApnsPushNotification>> 
                    sendFuture = apnsClient.sendNotification(notification);
            
            PushNotificationResponse<SimpleApnsPushNotification> response = sendFuture.get();
            
            if (response.isAccepted()) {
                log.info("✅ APNs静默推送成功");
            } else {
                log.warn("❌ APNs静默推送被拒绝: reason={}", 
                        response.getRejectionReason().orElse("unknown"));
            }
            
        } catch (Exception e) {
            log.error("❌ APNs静默推送失败: {}", e.getMessage());
        }
    }
}
