package com.baby.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 宝宝信息实体类
 */
@Data
@TableName("baby")
public class Baby {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 关联用户ID
     */
    private Long userId;
    
    /**
     * 宝宝昵称
     */
    private String nickname;
    
    /**
     * 出生日期
     */
    private LocalDate birthDate;
    
    /**
     * 性别: 0-女 1-男
     */
    private Integer gender;
    
    /**
     * 出生胎龄（周）
     */
    private Integer gestationalAge;
    
    /**
     * 身高（cm）
     */
    private Double height;
    
    /**
     * 体重（kg）
     */
    private Double weight;
    
    /**
     * 头围（cm）
     */
    private Double headCircumference;
    
    /**
     * 头像URL
     */
    private String avatarUrl;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
    
    @TableLogic
    private Integer deleted;
}
