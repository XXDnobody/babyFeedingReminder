package com.baby.vo;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * 疫苗时间表VO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VaccineScheduleVO {
    
    /**
     * 疫苗代码
     */
    private String vaccineCode;
    
    /**
     * 疫苗名称
     */
    private String vaccineName;
    
    /**
     * 疫苗全称
     */
    private String vaccineFullName;
    
    /**
     * 剂次
     */
    private Integer doseNumber;
    
    /**
     * 接种月龄（月）
     */
    private Integer ageInMonths;
    
    /**
     * 接种描述（如"出生24小时内"）
     */
    private String ageDescription;
    
    /**
     * 是否必须接种（国家免疫规划内）
     */
    private Boolean required;
    
    /**
     * 疫苗说明
     */
    private String description;
    
    /**
     * 接种部位
     */
    private String injectionSite;
    
    /**
     * 注意事项
     */
    private String notes;
}
