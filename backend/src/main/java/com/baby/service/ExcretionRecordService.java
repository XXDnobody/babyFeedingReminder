package com.baby.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.baby.dto.ExcretionRecordDTO;
import com.baby.entity.ExcretionRecord;
import com.baby.vo.ExcretionStatisticsVO;
import java.time.LocalDate;
import java.util.List;

/**
 * 排便排尿记录服务接口
 */
public interface ExcretionRecordService extends IService<ExcretionRecord> {
    
    /**
     * 创建排泄记录
     */
    ExcretionRecord createRecord(ExcretionRecordDTO dto);
    
    /**
     * 更新排泄记录
     */
    ExcretionRecord updateRecord(Long id, ExcretionRecordDTO dto);
    
    /**
     * 获取宝宝今日的排泄记录
     */
    List<ExcretionRecord> getTodayRecords(Long babyId);
    
    /**
     * 获取宝宝指定日期范围的排泄记录
     */
    List<ExcretionRecord> getRecordsByDateRange(Long babyId, LocalDate startDate, LocalDate endDate);
    
    /**
     * 获取今日大便次数
     */
    int getTodayPoopCount(Long babyId);
    
    /**
     * 获取今日小便次数
     */
    int getTodayPeeCount(Long babyId);
    
    /**
     * 获取排便统计数据
     */
    ExcretionStatisticsVO getStatistics(Long babyId, LocalDate startDate, LocalDate endDate);
    
    /**
     * 获取推荐大便次数范围（根据月龄）
     */
    String getRecommendedPoopCount(int ageInMonths);
    
    /**
     * 获取推荐小便次数范围（根据月龄）
     */
    String getRecommendedPeeCount(int ageInMonths);
}
