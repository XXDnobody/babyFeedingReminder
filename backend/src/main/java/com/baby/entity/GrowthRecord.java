package com.baby.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 身高体重测量记录实体类
 */
@Data
@TableName("growth_record")
public class GrowthRecord {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 宝宝ID
     */
    private Long babyId;
    
    /**
     * 测量日期
     */
    private LocalDate measureDate;
    
    /**
     * 身高（cm）
     */
    private BigDecimal height;
    
    /**
     * 体重（kg）
     */
    private BigDecimal weight;
    
    /**
     * 头围（cm）
     */
    private BigDecimal headCircumference;
    
    /**
     * 测量时月龄
     */
    private Integer ageInMonths;
    
    /**
     * 备注
     */
    private String remark;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
    
    @TableLogic
    private Integer deleted;
}
