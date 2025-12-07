package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.ExcretionRecordDTO;
import com.baby.entity.ExcretionRecord;
import com.baby.mapper.ExcretionRecordMapper;
import com.baby.service.ExcretionRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 排便排尿记录服务实现类
 */
@Service
@RequiredArgsConstructor
public class ExcretionRecordServiceImpl extends ServiceImpl<ExcretionRecordMapper, ExcretionRecord> 
        implements ExcretionRecordService {
    
    @Override
    @Transactional
    public ExcretionRecord createRecord(ExcretionRecordDTO dto) {
        ExcretionRecord record = new ExcretionRecord();
        record.setBabyId(dto.getBabyId());
        record.setExcretionType(dto.getExcretionType());
        record.setRecordTime(dto.getRecordTime());
        record.setColor(dto.getColor());
        record.setTexture(dto.getTexture());
        record.setAmount(dto.getAmount());
        record.setHasAbnormal(dto.getHasAbnormal() != null ? dto.getHasAbnormal() : 0);
        record.setRemark(dto.getRemark());
        
        save(record);
        return record;
    }
    
    @Override
    @Transactional
    public ExcretionRecord updateRecord(Long id, ExcretionRecordDTO dto) {
        ExcretionRecord record = getById(id);
        if (record == null) {
            throw new RuntimeException("排泄记录不存在");
        }
        
        record.setExcretionType(dto.getExcretionType());
        record.setRecordTime(dto.getRecordTime());
        record.setColor(dto.getColor());
        record.setTexture(dto.getTexture());
        record.setAmount(dto.getAmount());
        record.setHasAbnormal(dto.getHasAbnormal() != null ? dto.getHasAbnormal() : 0);
        record.setRemark(dto.getRemark());
        
        updateById(record);
        return record;
    }
    
    @Override
    public List<ExcretionRecord> getTodayRecords(Long babyId) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);
        
        return list(new LambdaQueryWrapper<ExcretionRecord>()
                .eq(ExcretionRecord::getBabyId, babyId)
                .between(ExcretionRecord::getRecordTime, startOfDay, endOfDay)
                .orderByDesc(ExcretionRecord::getRecordTime));
    }
    
    @Override
    public List<ExcretionRecord> getRecordsByDateRange(Long babyId, LocalDate startDate, LocalDate endDate) {
        return list(new LambdaQueryWrapper<ExcretionRecord>()
                .eq(ExcretionRecord::getBabyId, babyId)
                .between(ExcretionRecord::getRecordTime, startDate.atStartOfDay(), endDate.plusDays(1).atStartOfDay())
                .orderByDesc(ExcretionRecord::getRecordTime));
    }
    
    @Override
    public int getTodayPoopCount(Long babyId) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);
        
        return (int) count(new LambdaQueryWrapper<ExcretionRecord>()
                .eq(ExcretionRecord::getBabyId, babyId)
                .eq(ExcretionRecord::getExcretionType, 1)  // 1-大便
                .between(ExcretionRecord::getRecordTime, startOfDay, endOfDay));
    }
    
    @Override
    public int getTodayPeeCount(Long babyId) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);
        
        return (int) count(new LambdaQueryWrapper<ExcretionRecord>()
                .eq(ExcretionRecord::getBabyId, babyId)
                .eq(ExcretionRecord::getExcretionType, 2)  // 2-小便
                .between(ExcretionRecord::getRecordTime, startOfDay, endOfDay));
    }
}
