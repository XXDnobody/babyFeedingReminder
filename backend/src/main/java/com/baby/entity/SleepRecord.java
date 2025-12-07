package com.baby.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 睡眠记录实体类
 */
@Data
@TableName("sleep_record")
public class SleepRecord {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 宝宝ID
     */
    private Long babyId;
    
    /**
     * 睡眠类型: 1-睡眠 2-夜间睡眠
     */
    private Integer sleepType;
    
    /**
     * 开始时间（入睡时间）
     */
    private LocalDateTime startTime;
    
    /**
     * 结束时间（醒来时间）
     */
    private LocalDateTime endTime;
    
    /**
     * 实际睡眠时长（分钟）
     */
    private Integer duration;
    
    /**
     * 计划睡眠时长（分钟）
     */
    private Integer plannedDuration;
    
    /**
     * 下次睡眠预计时间
     */
    private LocalDateTime nextNapTime;
    
    /**
     * 哄睡提醒时间（提前多少分钟）
     */
    private Integer soothingReminderMinutes;
    
    /**
     * 睡眠质量: 1-好 2-一般 3-差
     */
    private Integer quality;
    
    /**
     * 备注
     */
    private String remark;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
    
    @TableLogic
    private Integer deleted;
}
