package com.baby.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 喂养设置实体类
 */
@Data
@TableName("feeding_setting")
public class FeedingSetting {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 宝宝ID
     */
    private Long babyId;
    
    /**
     * 默认喂养类型: 1-母乳 2-奶粉
     */
    private Integer defaultFeedingType;
    
    /**
     * 默认奶量（毫升）
     */
    private Integer defaultAmount;
    
    /**
     * 默认喂养时长（分钟）
     */
    private Integer defaultDuration;
    
    /**
     * 默认喂养间隔（分钟）
     */
    private Integer defaultInterval;
    
    /**
     * 提醒时段开始时间
     */
    private String reminderStartTime;

    /**
     * 提醒时段结束时间
     */
    private String reminderEndTime;
    
    /**
     * 是否启用提醒: 0-否 1-是
     */
    private Integer reminderEnabled;
    
    /**
     * 冷藏母乳解冻提前时间（分钟）
     */
    private Integer refrigeratedThawMinutes;
    
    /**
     * 冷冻母乳解冻提前时间（分钟）
     */
    private Integer frozenThawMinutes;
    
    /**
     * 默认下一顿奶源: 0-不提醒 1-亲喂/现冲 2-冷藏母乳 3-冷冻母乳
     */
    private Integer defaultNextMilkSource;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
    
    @TableLogic
    private Integer deleted;
}
