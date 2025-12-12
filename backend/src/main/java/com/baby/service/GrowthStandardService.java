package com.baby.service;

import com.baby.entity.GrowthStandardData;
import com.baby.entity.GrowthStandardType;

import java.util.List;
import java.util.Map;

/**
 * 生长标准服务接口
 */
public interface GrowthStandardService {
    
    /**
     * 获取所有可用的标准类型
     */
    List<GrowthStandardType> getAvailableStandards();
    
    /**
     * 获取默认标准类型
     */
    GrowthStandardType getDefaultStandard();
    
    /**
     * 根据代码获取标准类型
     */
    GrowthStandardType getStandardByCode(String code);
    
    /**
     * 获取标准曲线数据（用于绘制曲线）
     * @param standardCode 标准代码
     * @param gender 性别
     * @param indicator 指标类型
     * @return 百分位曲线数据
     */
    Map<String, List<double[]>> getStandardCurveData(String standardCode, int gender, String indicator);
    
    /**
     * 使用LMS算法计算Z-Score
     * @param value 实测值
     * @param standardCode 标准代码
     * @param gender 性别
     * @param indicator 指标类型
     * @param ageMonths 月龄
     * @return Z-Score值
     */
    Double calculateZScore(double value, String standardCode, int gender, String indicator, int ageMonths);
    
    /**
     * 根据Z-Score计算百分位
     * @param zScore Z-Score值
     * @return 百分位（0-100）
     */
    Double zScoreToPercentile(double zScore);
    
    /**
     * 计算百分位描述（如 "50-85%"）
     * @param value 实测值
     * @param standardCode 标准代码
     * @param gender 性别
     * @param indicator 指标类型
     * @param ageMonths 月龄
     * @return 百分位描述
     */
    String calculatePercentileDescription(double value, String standardCode, int gender, String indicator, int ageMonths);
    
    /**
     * 计算百分位描述（支持精确日龄插值）
     * @param value 实测值
     * @param standardCode 标准代码
     * @param gender 性别
     * @param indicator 指标类型
     * @param exactAgeMonths 精确月龄（包含小数，如7.3表示7个月9天）
     * @return 精确百分位（如"96.6%"）
     */
    String calculateExactPercentile(double value, String standardCode, int gender, String indicator, double exactAgeMonths);
    
    /**
     * 获取指定月龄的标准数据
     */
    GrowthStandardData getStandardDataByMonth(String standardCode, int gender, String indicator, int ageMonths);
}
