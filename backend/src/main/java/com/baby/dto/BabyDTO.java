package com.baby.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;

/**
 * 宝宝信息DTO
 */
@Data
public class BabyDTO {
    
    @NotBlank(message = "昵称不能为空")
    private String nickname;
    
    @NotNull(message = "出生日期不能为空")
    private LocalDate birthDate;
    
    @NotNull(message = "性别不能为空")
    private Integer gender;
    
    /**
     * 出生胎龄（周）
     */
    private Integer gestationalAge;
    
    /**
     * 身高（cm）
     */
    private Double height;
    
    /**
     * 体重（kg）
     */
    private Double weight;
    
    /**
     * 头围（cm）
     */
    private Double headCircumference;
    
    /**
     * 头像URL
     */
    private String avatarUrl;
}
