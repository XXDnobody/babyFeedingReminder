package com.baby.service;

import com.baby.dto.LoginRequest;
import com.baby.dto.LoginResponse;

/**
 * 认证服务接口
 */
public interface AuthService {
    
    /**
     * Apple登录
     */
    LoginResponse loginWithApple(LoginRequest request);
    
    /**
     * 微信登录
     */
    LoginResponse loginWithWechat(LoginRequest request);
    
    /**
     * 手机号密码登录
     */
    LoginResponse loginWithPhone(LoginRequest request);
    
    /**
     * 手机号注册
     */
    LoginResponse registerWithPhone(LoginRequest request);
    
    /**
     * 发送短信验证码
     * @param phone 手机号
     * @param scene 场景类型: register-注册, login-登录, reset-重置密码
     */
    void sendSmsCode(String phone, String scene);
    
    /**
     * 验证短信验证码
     */
    boolean verifySmsCode(String phone, String code);
    
    /**
     * 重置密码
     */
    void resetPassword(LoginRequest request);
    
    /**
     * 刷新Token
     */
    LoginResponse refreshToken(String token);
    
    /**
     * 验证Token是否有效
     */
    boolean validateToken(String token);
    
    /**
     * 退出登录
     */
    void logout(Long userId);
    
    /**
     * 手机号验证码快速登录（未注册自动注册）
     */
    LoginResponse quickLoginWithPhone(LoginRequest request);
}
