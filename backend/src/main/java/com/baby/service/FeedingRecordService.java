package com.baby.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.baby.dto.FeedingRecordDTO;
import com.baby.entity.FeedingRecord;
import com.baby.vo.FeedingStatisticsVO;
import java.time.LocalDate;
import java.util.List;

/**
 * 喂养记录服务接口
 */
public interface FeedingRecordService extends IService<FeedingRecord> {
    
    /**
     * 创建喂养记录
     */
    FeedingRecord createRecord(FeedingRecordDTO dto);
    
    /**
     * 更新喂养记录
     */
    FeedingRecord updateRecord(Long id, FeedingRecordDTO dto);
    
    /**
     * 获取宝宝今日的喂养记录
     */
    List<FeedingRecord> getTodayRecords(Long babyId);
    
    /**
     * 获取宝宝指定日期范围的喂养记录
     */
    List<FeedingRecord> getRecordsByDateRange(Long babyId, LocalDate startDate, LocalDate endDate);
    
    /**
     * 获取最近一次喂养记录
     */
    FeedingRecord getLastRecord(Long babyId);
    
    /**
     * 获取喂养统计
     */
    FeedingStatisticsVO getStatistics(Long babyId, LocalDate startDate, LocalDate endDate);
    
    /**
     * 计算下次喂奶时间
     */
    java.time.LocalDateTime calculateNextFeedingTime(Long babyId, java.time.LocalDateTime currentFeedingTime);
    
    /**
     * 根据宝宝月龄获取推荐奶量
     */
    int getRecommendedAmount(int ageInMonths);
    
    /**
     * 根据宝宝月龄获取推荐喂养间隔（分钟）
     */
    int getRecommendedInterval(int ageInMonths);
}
