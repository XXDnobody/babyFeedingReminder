package com.baby.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 生长标准数据实体
 */
@Data
@TableName("growth_standard_data")
public class GrowthStandardData {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /** 标准类型ID */
    private Long standardTypeId;
    
    /** 性别: 1-男 0-女 */
    private Integer gender;
    
    /** 指标类型: height/weight/bmi */
    private String indicator;
    
    /** 月龄 */
    private Integer ageMonths;
    
    /** LMS-L参数(Box-Cox power) */
    private BigDecimal lValue;
    
    /** LMS-M参数(中位数) */
    private BigDecimal mValue;
    
    /** LMS-S参数(变异系数) */
    private BigDecimal sValue;
    
    /** 第3百分位 */
    private BigDecimal p3;
    
    /** 第10百分位 */
    private BigDecimal p10;
    
    /** 第15百分位 */
    private BigDecimal p15;
    
    /** 第25百分位 */
    private BigDecimal p25;
    
    /** 第50百分位(中位数) */
    private BigDecimal p50;
    
    /** 第75百分位 */
    private BigDecimal p75;
    
    /** 第85百分位 */
    private BigDecimal p85;
    
    /** 第90百分位 */
    private BigDecimal p90;
    
    /** 第97百分位 */
    private BigDecimal p97;
    
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
