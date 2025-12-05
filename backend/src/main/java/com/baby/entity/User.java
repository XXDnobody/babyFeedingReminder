package com.baby.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 用户实体类
 */
@Data
@TableName("user")
public class User {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 用户名
     */
    private String username;
    
    /**
     * 密码（加密存储）
     */
    private String password;
    
    /**
     * 手机号
     */
    private String phone;
    
    /**
     * 邮箱
     */
    private String email;
    
    /**
     * 昵称
     */
    private String nickname;
    
    /**
     * 头像URL
     */
    private String avatarUrl;
    
    /**
     * Apple登录标识
     */
    private String appleId;
    
    /**
     * 微信OpenID
     */
    private String wechatOpenId;
    
    /**
     * 微信UnionID
     */
    private String wechatUnionId;
    
    /**
     * 设备Token（用于推送）
     */
    private String deviceToken;
    
    /**
     * 是否同意用户协议: 0-否 1-是
     */
    private Integer agreedTerms;
    
    /**
     * 账号状态: 0-禁用 1-正常
     */
    private Integer status;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
    
    @TableLogic
    private Integer deleted;
}
