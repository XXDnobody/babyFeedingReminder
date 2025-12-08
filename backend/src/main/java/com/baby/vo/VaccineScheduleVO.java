package com.baby.vo;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

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
     * 是否免费: true-国家免费 false-自费
     */
    private Boolean isFree;
    
    /**
     * 参考价格（元）
     */
    private BigDecimal price;
    
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
    
    /**
     * 可替代的付费疫苗列表
     */
    private List<AlternativeVaccineVO> alternatives;
    
    /**
     * 替代疫苗信息
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AlternativeVaccineVO {
        /**
         * 替代疫苗代码
         */
        private String vaccineCode;
        
        /**
         * 替代疫苗名称
         */
        private String vaccineName;
        
        /**
         * 疫苗全称
         */
        private String vaccineFullName;
        
        /**
         * 参考价格（元）
         */
        private BigDecimal price;
        
        /**
         * 优势说明
         */
        private String advantages;
        
        /**
         * 减少接种次数（联合疫苗的优势）
         */
        private Integer reducedDoses;
    }
}
