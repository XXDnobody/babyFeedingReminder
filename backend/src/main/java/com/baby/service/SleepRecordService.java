package com.baby.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.baby.dto.SleepRecordDTO;
import com.baby.entity.SleepRecord;
import com.baby.vo.SleepStatisticsVO;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 睡眠记录服务接口
 */
public interface SleepRecordService extends IService<SleepRecord> {
    
    /**
     * 创建睡眠记录
     */
    SleepRecord createRecord(SleepRecordDTO dto);
    
    /**
     * 更新睡眠记录（结束睡眠）
     */
    SleepRecord updateRecord(Long id, SleepRecordDTO dto);
    
    /**
     * 开始睡眠
     */
    SleepRecord startNap(Long babyId, LocalDateTime startTime);
    
    /**
     * 结束睡眠
     */
    SleepRecord endNap(Long id, LocalDateTime endTime, Integer quality, Boolean shouldRemind);
    
    /**
     * 获取宝宝今日的睡眠记录
     */
    List<SleepRecord> getTodayRecords(Long babyId);
    
    /**
     * 获取宝宝指定日期范围的睡眠记录
     */
    List<SleepRecord> getRecordsByDateRange(Long babyId, LocalDate startDate, LocalDate endDate);
    
    /**
     * 获取最近一次睡眠记录
     */
    SleepRecord getLastRecord(Long babyId);
    
    /**
     * 获取睡眠统计
     */
    SleepStatisticsVO getStatistics(Long babyId, LocalDate startDate, LocalDate endDate);
    
    /**
     * 计算下次睡眠时间
     */
    LocalDateTime calculateNextNapTime(Long babyId, LocalDateTime wakeUpTime);
    
    /**
     * 根据宝宝月龄获取推荐小睡时长（分钟）
     */
    int getRecommendedNapDuration(int ageInMonths);
    
    /**
     * 根据宝宝月龄获取推荐清醒间隔（分钟）
     */
    int getRecommendedAwakeInterval(int ageInMonths);
}
