package com.baby.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * 睡眠设置实体类
 */
@Data
@TableName("sleep_setting")
public class SleepSetting {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 宝宝ID
     */
    private Long babyId;
    
    /**
     * 默认小睡间隔（分钟）
     */
    private Integer defaultNapInterval;
    
    /**
     * 默认小睡时长（分钟）
     */
    private Integer defaultNapDuration;
    
    /**
     * 默认哄睡提前提醒时间（分钟）
     */
    private Integer defaultSoothingReminderMinutes;
    
    /**
     * 提醒时段开始时间
     */
    private LocalTime reminderStartTime;
    
    /**
     * 提醒时段结束时间
     */
    private LocalTime reminderEndTime;
    
    /**
     * 是否启用提醒: 0-否 1-是
     */
    private Integer reminderEnabled;
    
    /**
     * 晚间入睡目标时间
     */
    private LocalTime bedtimeTarget;
    
    /**
     * 早晨起床目标时间
     */
    private LocalTime wakeTimeTarget;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
    
    @TableLogic
    private Integer deleted;
}
