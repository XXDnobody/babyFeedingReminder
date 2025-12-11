package com.baby.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 生长标准类型实体
 */
@Data
@TableName("growth_standard_type")
public class GrowthStandardType {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /** 标准代码，如 CHINA_2025 */
    private String code;
    
    /** 标准名称 */
    private String name;
    
    /** 标准描述 */
    private String description;
    
    /** 数据来源 */
    private String source;
    
    /** 最小月龄 */
    private Integer minAgeMonths;
    
    /** 最大月龄 */
    private Integer maxAgeMonths;
    
    /** 是否支持身高 */
    private Integer supportsHeight;
    
    /** 是否支持体重 */
    private Integer supportsWeight;
    
    /** 是否支持BMI */
    private Integer supportsBmi;
    
    /** 是否支持头围 */
    private Integer supportsHeadCircumference;
    
    /** 是否默认标准 */
    private Integer isDefault;
    
    /** 排序顺序 */
    private Integer sortOrder;
    
    /** 状态: 1-启用 0-禁用 */
    private Integer status;
    
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
