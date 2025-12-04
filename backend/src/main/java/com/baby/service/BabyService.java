package com.baby.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.baby.entity.Baby;
import com.baby.dto.BabyDTO;
import java.util.List;

/**
 * 宝宝信息服务接口
 */
public interface BabyService extends IService<Baby> {
    
    /**
     * 创建宝宝信息
     */
    Baby createBaby(Long userId, BabyDTO dto);
    
    /**
     * 更新宝宝信息
     */
    Baby updateBaby(Long id, BabyDTO dto);
    
    /**
     * 获取用户的所有宝宝
     */
    List<Baby> getBabiesByUserId(Long userId);
    
    /**
     * 更新生长指标
     */
    Baby updateGrowthMetrics(Long id, Double height, Double weight, Double headCircumference);
    
    /**
     * 计算宝宝月龄
     */
    int calculateAgeInMonths(Long babyId);
}
