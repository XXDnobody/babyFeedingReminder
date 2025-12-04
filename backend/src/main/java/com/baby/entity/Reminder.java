package com.baby.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 提醒任务实体类
 */
@Data
@TableName("reminder")
public class Reminder {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 宝宝ID
     */
    private Long babyId;
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 提醒类型: 1-喂奶提醒 2-解冻提醒 3-小睡提醒 4-哄睡提醒
     */
    private Integer reminderType;
    
    /**
     * 提醒标题
     */
    private String title;
    
    /**
     * 提醒内容
     */
    private String content;
    
    /**
     * 预定提醒时间
     */
    private LocalDateTime scheduledTime;
    
    /**
     * 是否已发送: 0-否 1-是
     */
    private Integer sent;
    
    /**
     * 发送时间
     */
    private LocalDateTime sentTime;
    
    /**
     * 关联记录ID（喂养记录或睡眠记录ID）
     */
    private Long relatedRecordId;
    
    /**
     * 状态: 0-待发送 1-已发送 2-已取消
     */
    private Integer status;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
    
    @TableLogic
    private Integer deleted;
}
