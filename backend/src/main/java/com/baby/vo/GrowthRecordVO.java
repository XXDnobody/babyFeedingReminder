package com.baby.vo;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 生长记录VO（包含百分位数据）
 */
@Data
public class GrowthRecordVO {
    
    private Long id;
    private Long babyId;
    private LocalDate measureDate;
    
    // 测量值
    private BigDecimal height;          // 身高（cm）
    private BigDecimal weight;          // 体重（kg）
    private BigDecimal headCircumference; // 头围（cm）
    private Double bmi;                 // BMI值
    
    // 月龄信息
    private Integer ageInMonths;        // 月龄（整月）
    private Integer ageDays;            // 天数（如7个月9天中的9天）
    private Double exactAgeMonths;      // 精确月龄（如7.3）
    
    // 百分位数据
    private String heightPercentile;    // 身高百分位（如"96.6%"）
    private String weightPercentile;    // 体重百分位
    private String headPercentile;      // 头围百分位
    private String bmiPercentile;       // BMI百分位
    
    // 评价（根据百分位判断）
    private String heightEvaluation;    // 身高评价：正常/增长偏快/偏慢等
    private String weightEvaluation;    // 体重评价
    private String headEvaluation;      // 头围评价
    private String bmiEvaluation;       // BMI评价
    
    private String remark;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
