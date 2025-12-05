package com.baby.dto;

import lombok.Data;

/**
 * 登录请求DTO
 */
@Data
public class LoginRequest {
    
    /**
     * Apple登录的identityToken
     */
    private String identityToken;
    
    /**
     * Apple登录的authorizationCode
     */
    private String authorizationCode;
    
    /**
     * Apple用户标识
     */
    private String appleUserId;
    
    /**
     * 微信授权code
     */
    private String code;
    
    /**
     * 用户昵称（首次登录时可能需要）
     */
    private String nickname;
    
    /**
     * 用户头像URL
     */
    private String avatarUrl;
    
    /**
     * 设备Token（用于推送）
     */
    private String deviceToken;
    
    /**
     * 是否同意用户协议和隐私政策
     */
    private Boolean agreedTerms;
}
