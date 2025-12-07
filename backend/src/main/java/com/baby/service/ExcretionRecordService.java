package com.baby.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.baby.dto.ExcretionRecordDTO;
import com.baby.entity.ExcretionRecord;
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
}
