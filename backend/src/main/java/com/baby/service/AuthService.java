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
}
