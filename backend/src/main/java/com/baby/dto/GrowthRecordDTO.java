package com.baby.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 身高体重测量记录DTO
 */
@Data
public class GrowthRecordDTO {
    
    @NotNull(message = "宝宝ID不能为空")
    private Long babyId;
    
    @NotNull(message = "测量日期不能为空")
    private LocalDate measureDate;
    
    private BigDecimal height;      // 身高（cm）
    
    private BigDecimal weight;      // 体重（kg）
    
    private BigDecimal headCircumference;  // 头围（cm）
    
    private String remark;
}
