package com.baby.dto;

import lombok.Data;

/**
 * 发送短信验证码请求DTO
 */
@Data
public class SmsCodeRequest {
    
    /**
     * 手机号
     */
    private String phone;
    
    /**
     * 场景类型: register-注册, login-登录, reset-重置密码
     */
    private String scene;
}
