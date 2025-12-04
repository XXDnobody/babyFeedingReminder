package com.baby.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 睡眠记录DTO
 */
@Data
public class SleepRecordDTO {
    
    @NotNull(message = "宝宝ID不能为空")
    private Long babyId;
    
    @NotNull(message = "睡眠类型不能为空")
    private Integer sleepType;
    
    @NotNull(message = "开始时间不能为空")
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
     * 睡眠质量: 1-好 2-一般 3-差
     */
    private Integer quality;
    
    /**
     * 备注
     */
    private String remark;
}
