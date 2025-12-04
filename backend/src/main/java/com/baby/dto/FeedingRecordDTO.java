package com.baby.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 喂养记录DTO
 */
@Data
public class FeedingRecordDTO {
    
    @NotNull(message = "宝宝ID不能为空")
    private Long babyId;
    
    @NotNull(message = "喂养类型不能为空")
    private Integer feedingType;
    
    /**
     * 母乳来源: 1-亲喂 2-瓶装母乳（冷藏）3-瓶装母乳（冷冻）
     */
    private Integer milkSource;
    
    @NotNull(message = "开始时间不能为空")
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
     * 下一顿是否使用冷藏/冷冻母乳
     */
    private Integer nextMilkSource;
    
    /**
     * 备注
     */
    private String remark;
}
