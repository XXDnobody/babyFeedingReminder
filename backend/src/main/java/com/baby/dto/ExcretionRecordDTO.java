package com.baby.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 排便排尿记录DTO
 */
@Data
public class ExcretionRecordDTO {
    
    @NotNull(message = "宝宝ID不能为空")
    private Long babyId;
    
    @NotNull(message = "排泄类型不能为空")
    private Integer excretionType;  // 1-大便 2-小便
    
    @NotNull(message = "记录时间不能为空")
    private LocalDateTime recordTime;
    
    private String color;       // 颜色（大便）
    
    private String texture;     // 性状（大便）
    
    private String amount;      // 量
    
    private Integer hasAbnormal; // 是否异常: 0-否 1-是
    
    private String remark;
}
