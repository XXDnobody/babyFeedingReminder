package com.baby.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 疫苗接种记录DTO
 */
@Data
public class VaccinationRecordDTO {
    
    private Long id;
    
    /**
     * 宝宝ID
     */
    private Long babyId;
    
    /**
     * 疫苗代码
     */
    private String vaccineCode;
    
    /**
     * 疫苗名称
     */
    private String vaccineName;
    
    /**
     * 剂次
     */
    private Integer doseNumber;
    
    /**
     * 计划接种日期
     */
    private LocalDate scheduledDate;
    
    /**
     * 实际接种日期
     */
    private LocalDate actualDate;
    
    /**
     * 状态: 0-待接种 1-已接种 2-已逾期 3-已跳过
     */
    private Integer status;
    
    /**
     * 是否免费: 1-国家免费 0-自费
     */
    private Integer isFree;
    
    /**
     * 原始疫苗代码（如果选择了替代疫苗）
     */
    private String originalVaccineCode;
    
    /**
     * 疫苗价格（元）
     */
    private BigDecimal price;
    
    /**
     * 接种地点
     */
    private String vaccinationSite;
    
    /**
     * 疫苗批号
     */
    private String batchNumber;
    
    /**
     * 接种后反应
     */
    private String reaction;
    
    /**
     * 备注
     */
    private String remark;
}
