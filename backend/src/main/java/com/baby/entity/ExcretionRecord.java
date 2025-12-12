package com.baby.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 换尿布记录实体类
 */
@Data
@TableName("excretion_record")
public class ExcretionRecord {
    
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 宝宝ID
     */
    private Long babyId;
    
    /**
     * 排泄类型: 1-大便 2-小便
     */
    private Integer excretionType;
    
    /**
     * 记录时间
     */
    private LocalDateTime recordTime;
    
    /**
     * 颜色（大便）: 黄色、绿色、棕色、黑色等
     */
    private String color;
    
    /**
     * 性状（大便）: 稀、软、硬、颗粒状等
     */
    private String texture;
    
    /**
     * 量: 少量、适中、大量
     */
    private String amount;
    
    /**
     * 是否异常: 0-否 1-是
     */
    private Integer hasAbnormal;
    
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
