package com.baby.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.baby.dto.GrowthRecordDTO;
import com.baby.entity.GrowthRecord;
import java.util.List;
import java.util.Map;

/**
 * 身高体重测量记录服务接口
 */
public interface GrowthRecordService extends IService<GrowthRecord> {
    
    /**
     * 创建测量记录
     */
    GrowthRecord createRecord(GrowthRecordDTO dto);
    
    /**
     * 更新测量记录
     */
    GrowthRecord updateRecord(Long id, GrowthRecordDTO dto);
    
    /**
     * 获取宝宝所有测量记录
     */
    List<GrowthRecord> getAllRecords(Long babyId);
    
    /**
     * 获取WHO标准生长曲线数据（身高）
     * @param gender 0-女 1-男
     * @return 各百分位曲线数据
     */
    Map<String, List<double[]>> getWHOHeightStandard(int gender);
    
    /**
     * 获取WHO标准生长曲线数据（体重）
     * @param gender 0-女 1-男
     * @return 各百分位曲线数据
     */
    Map<String, List<double[]>> getWHOWeightStandard(int gender);
    
    /**
     * 计算宝宝身高体重百分位
     */
    Map<String, Object> calculatePercentile(Long babyId);
    
    /**
     * 获取指定标准的身高数据
     * @param gender 0-女 1-男
     * @param standardType 标准类型: WHO, CHINA_2025
     * @return 各百分位曲线数据
     */
    Map<String, List<double[]>> getHeightStandard(int gender, String standardType);
    
    /**
     * 获取指定标准的体重数据
     * @param gender 0-女 1-男
     * @param standardType 标准类型: WHO, CHINA_2025
     * @return 各百分位曲线数据
     */
    Map<String, List<double[]>> getWeightStandard(int gender, String standardType);
    
    /**
     * 获取BMI标准数据
     * @param gender 0-女 1-男
     * @param standardType 标准类型: CHINA_2025 (目前BMI仅支持中国标准)
     * @return 各百分位曲线数据
     */
    Map<String, List<double[]>> getBmiStandard(int gender, String standardType);
    
    /**
     * 计算宝宝百分位（指定标准）
     */
    Map<String, Object> calculatePercentile(Long babyId, String standardType);
    
    /**
     * 获取可用的标准类型列表及其说明
     */
    List<Map<String, Object>> getAvailableStandards();
}
