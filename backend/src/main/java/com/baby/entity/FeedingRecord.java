package com.baby.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 喂养记录实体类
 */
@Data
@TableName("feeding_record")
public class FeedingRecord {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 宝宝ID
     */
    private Long babyId;
    
    /**
     * 喂养类型: 1-母乳 2-奶粉 3-混合喂养
     */
    private Integer feedingType;
    
    /**
     * 母乳来源: 1-亲喂 2-瓶装母乳（冷藏）3-瓶装母乳（冷冻）
     */
    private Integer milkSource;
    
    /**
     * 开始时间
     */
    private LocalDateTime startTime;
    
    /**
     * 结束时间
     */
    private LocalDateTime endTime;
    
    /**
     * 奶量（毫升）
     */
    private Integer amount;
    
    /**
     * 喂养时长（分钟）
     */
    private Integer duration;
    
    /**
     * 下次喂奶预计时间
     */
    private LocalDateTime nextFeedingTime;
    
    /**
     * 是否需要提前解冻: 0-否 1-是
     */
    private Integer needThaw;
    
    /**
     * 解冻提醒时间（提前多少分钟）
     */
    private Integer thawReminderMinutes;
    
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
