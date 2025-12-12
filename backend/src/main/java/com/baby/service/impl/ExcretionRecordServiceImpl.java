package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.ExcretionRecordDTO;
import com.baby.entity.ExcretionRecord;
import com.baby.mapper.ExcretionRecordMapper;
import com.baby.service.ExcretionRecordService;
import com.baby.vo.ExcretionStatisticsVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 换尿布记录服务实现类
 */
@Service
@RequiredArgsConstructor
public class ExcretionRecordServiceImpl extends ServiceImpl<ExcretionRecordMapper, ExcretionRecord> 
        implements ExcretionRecordService {
    
    private final ExcretionRecordMapper excretionRecordMapper;
    
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
    
    @Override
    public ExcretionStatisticsVO getStatistics(Long babyId, LocalDate startDate, LocalDate endDate) {
        ExcretionStatisticsVO vo = new ExcretionStatisticsVO();
        
        LocalDateTime startTime = startDate.atStartOfDay();
        LocalDateTime endTime = endDate.plusDays(1).atStartOfDay();
        long days = ChronoUnit.DAYS.between(startDate, endDate) + 1;
        
        // 设置日期范围
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM/dd");
        vo.setDateRange(startDate.format(formatter) + " - " + endDate.format(formatter));
        
        // 获取所有记录
        List<ExcretionRecord> records = list(new LambdaQueryWrapper<ExcretionRecord>()
                .eq(ExcretionRecord::getBabyId, babyId)
                .ge(ExcretionRecord::getRecordTime, startTime)
                .lt(ExcretionRecord::getRecordTime, endTime)
                .orderByAsc(ExcretionRecord::getRecordTime));
        
        // 统计大便和小便次数
        int poopCount = (int) records.stream().filter(r -> r.getExcretionType() == 1).count();
        int peeCount = (int) records.stream().filter(r -> r.getExcretionType() == 2).count();
        int abnormalCount = (int) records.stream().filter(r -> r.getHasAbnormal() != null && r.getHasAbnormal() == 1).count();
        
        vo.setTotalPoopCount(poopCount);
        vo.setTotalPeeCount(peeCount);
        vo.setAbnormalCount(abnormalCount);
        vo.setDailyAveragePoopCount(days > 0 ? Math.round(poopCount * 100.0 / days) / 100.0 : 0);
        vo.setDailyAveragePeeCount(days > 0 ? Math.round(peeCount * 100.0 / days) / 100.0 : 0);
        
        // 大便颜色分布
        List<ExcretionRecord> poopRecords = records.stream()
                .filter(r -> r.getExcretionType() == 1 && r.getColor() != null && !r.getColor().isEmpty())
                .collect(Collectors.toList());
        if (!poopRecords.isEmpty()) {
            Map<String, Long> colorCount = poopRecords.stream()
                    .collect(Collectors.groupingBy(ExcretionRecord::getColor, Collectors.counting()));
            Map<String, Double> colorDistribution = new HashMap<>();
            for (Map.Entry<String, Long> entry : colorCount.entrySet()) {
                colorDistribution.put(entry.getKey(), Math.round(entry.getValue() * 10000.0 / poopRecords.size()) / 100.0);
            }
            vo.setColorDistribution(colorDistribution);
        }
        
        // 大便性状分布
        List<ExcretionRecord> textureRecords = poopRecords.stream()
                .filter(r -> r.getTexture() != null && !r.getTexture().isEmpty())
                .collect(Collectors.toList());
        if (!textureRecords.isEmpty()) {
            Map<String, Long> textureCount = textureRecords.stream()
                    .collect(Collectors.groupingBy(ExcretionRecord::getTexture, Collectors.counting()));
            Map<String, Double> textureDistribution = new HashMap<>();
            for (Map.Entry<String, Long> entry : textureCount.entrySet()) {
                textureDistribution.put(entry.getKey(), Math.round(entry.getValue() * 10000.0 / textureRecords.size()) / 100.0);
            }
            vo.setTextureDistribution(textureDistribution);
        }
        
        // 每日数据
        List<ExcretionStatisticsVO.DailyExcretionData> dailyDataList = new ArrayList<>();
        Map<LocalDate, List<ExcretionRecord>> recordsByDate = records.stream()
                .collect(Collectors.groupingBy(r -> r.getRecordTime().toLocalDate()));
        
        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            ExcretionStatisticsVO.DailyExcretionData dailyData = new ExcretionStatisticsVO.DailyExcretionData();
            dailyData.setDate(date.toString());
            
            List<ExcretionRecord> dayRecords = recordsByDate.getOrDefault(date, Collections.emptyList());
            dailyData.setPoopCount((int) dayRecords.stream().filter(r -> r.getExcretionType() == 1).count());
            dailyData.setPeeCount((int) dayRecords.stream().filter(r -> r.getExcretionType() == 2).count());
            
            dailyDataList.add(dailyData);
        }
        vo.setDailyData(dailyDataList);
        
        return vo;
    }
    
    @Override
    public String getRecommendedPoopCount(int ageInMonths) {
        if (ageInMonths < 1) {
            return "3-8次";
        } else if (ageInMonths < 6) {
            return "2-5次";
        } else if (ageInMonths < 12) {
            return "1-3次";
        } else {
            return "1-2次";
        }
    }
    
    @Override
    public String getRecommendedPeeCount(int ageInMonths) {
        if (ageInMonths < 1) {
            return "6-10次";
        } else if (ageInMonths < 6) {
            return "6-8次";
        } else if (ageInMonths < 12) {
            return "5-7次";
        } else {
            return "4-6次";
        }
    }
}
