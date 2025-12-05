package com.baby.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 登录响应DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 访问Token
     */
    private String accessToken;
    
    /**
     * 刷新Token
     */
    private String refreshToken;
    
    /**
     * Token过期时间（秒）
     */
    private Long expiresIn;
    
    /**
     * 用户昵称
     */
    private String nickname;
    
    /**
     * 用户头像
     */
    private String avatarUrl;
    
    /**
     * 是否新用户
     */
    private Boolean isNewUser;
}
