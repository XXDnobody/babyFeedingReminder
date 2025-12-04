package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.FeedingRecordDTO;
import com.baby.entity.FeedingRecord;
import com.baby.entity.FeedingSetting;
import com.baby.mapper.FeedingRecordMapper;
import com.baby.mapper.FeedingSettingMapper;
import com.baby.service.BabyService;
import com.baby.service.FeedingRecordService;
import com.baby.service.ReminderService;
import com.baby.vo.FeedingStatisticsVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * 喂养记录服务实现类
 * 参考：2025年国家卫生健康委婴幼儿营养喂养评估服务指南
 */
@Service
@RequiredArgsConstructor
public class FeedingRecordServiceImpl extends ServiceImpl<FeedingRecordMapper, FeedingRecord> 
        implements FeedingRecordService {
    
    private final FeedingSettingMapper feedingSettingMapper;
    private final BabyService babyService;
    private final ReminderService reminderService;
    
    // 喂养指南参数（基于国家卫健委标准）
    private static final Map<String, int[]> FEEDING_GUIDE = new HashMap<>() {{
        // 月龄范围 -> [每日次数下限, 每日次数上限, 每次奶量下限(ml), 每次奶量上限(ml), 间隔小时数]
        put("0-1", new int[]{8, 12, 60, 90, 2});       // 0-1个月
        put("1-3", new int[]{6, 8, 90, 120, 3});       // 1-3个月
        put("3-6", new int[]{5, 6, 120, 180, 3});      // 3-6个月
        put("6-9", new int[]{4, 5, 180, 210, 4});      // 6-9个月
        put("9-12", new int[]{3, 4, 200, 240, 4});     // 9-12个月
        put("12-24", new int[]{2, 3, 200, 300, 5});    // 12-24个月
    }};
    
    @Override
    @Transactional
    public FeedingRecord createRecord(FeedingRecordDTO dto) {
        FeedingRecord record = new FeedingRecord();
        record.setBabyId(dto.getBabyId());
        record.setFeedingType(dto.getFeedingType());
        record.setMilkSource(dto.getMilkSource());
        record.setStartTime(dto.getStartTime());
        record.setEndTime(dto.getEndTime());
        record.setAmount(dto.getAmount());
        record.setRemark(dto.getRemark());
        
        // 计算喂养时长
        if (dto.getEndTime() != null && dto.getStartTime() != null) {
            long minutes = ChronoUnit.MINUTES.between(dto.getStartTime(), dto.getEndTime());
            record.setDuration((int) minutes);
        } else {
            record.setDuration(dto.getDuration());
        }
        
        // 计算下次喂奶时间
        LocalDateTime nextFeedingTime = calculateNextFeedingTime(dto.getBabyId(), dto.getStartTime());
        record.setNextFeedingTime(nextFeedingTime);
        
        // 检查是否需要提前解冻
        if (dto.getNextMilkSource() != null && dto.getNextMilkSource() >= 2) {
            record.setNeedThaw(1);
            FeedingSetting setting = getFeedingSetting(dto.getBabyId());
            if (dto.getNextMilkSource() == 2) {
                // 冷藏母乳，默认提前15分钟
                record.setThawReminderMinutes(setting != null ? setting.getRefrigeratedThawMinutes() : 15);
            } else {
                // 冷冻母乳，默认提前30分钟
                record.setThawReminderMinutes(setting != null ? setting.getFrozenThawMinutes() : 30);
            }
        }
        
        save(record);
        
        // 创建喂奶提醒
        reminderService.createFeedingReminder(record);
        
        return record;
    }
    
    @Override
    @Transactional
    public FeedingRecord updateRecord(Long id, FeedingRecordDTO dto) {
        FeedingRecord record = getById(id);
        if (record == null) {
            throw new RuntimeException("喂养记录不存在");
        }
        
        record.setFeedingType(dto.getFeedingType());
        record.setMilkSource(dto.getMilkSource());
        record.setStartTime(dto.getStartTime());
        record.setEndTime(dto.getEndTime());
        record.setAmount(dto.getAmount());
        record.setRemark(dto.getRemark());
        
        if (dto.getEndTime() != null && dto.getStartTime() != null) {
            long minutes = ChronoUnit.MINUTES.between(dto.getStartTime(), dto.getEndTime());
            record.setDuration((int) minutes);
        }
        
        updateById(record);
        return record;
    }
    
    @Override
    public List<FeedingRecord> getTodayRecords(Long babyId) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);
        
        return list(new LambdaQueryWrapper<FeedingRecord>()
                .eq(FeedingRecord::getBabyId, babyId)
                .between(FeedingRecord::getStartTime, startOfDay, endOfDay)
                .orderByDesc(FeedingRecord::getStartTime));
    }
    
    @Override
    public List<FeedingRecord> getRecordsByDateRange(Long babyId, LocalDate startDate, LocalDate endDate) {
        return list(new LambdaQueryWrapper<FeedingRecord>()
                .eq(FeedingRecord::getBabyId, babyId)
                .between(FeedingRecord::getStartTime, startDate.atStartOfDay(), endDate.plusDays(1).atStartOfDay())
                .orderByDesc(FeedingRecord::getStartTime));
    }
    
    @Override
    public FeedingRecord getLastRecord(Long babyId) {
        return getOne(new LambdaQueryWrapper<FeedingRecord>()
                .eq(FeedingRecord::getBabyId, babyId)
                .orderByDesc(FeedingRecord::getStartTime)
                .last("LIMIT 1"));
    }
    
    @Override
    public FeedingStatisticsVO getStatistics(Long babyId, LocalDate startDate, LocalDate endDate) {
        List<FeedingRecord> records = getRecordsByDateRange(babyId, startDate, endDate);
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        
        FeedingStatisticsVO vo = new FeedingStatisticsVO();
        vo.setDateRange(startDate + " ~ " + endDate);
        vo.setTotalCount(records.size());
        
        int totalAmount = records.stream().mapToInt(r -> r.getAmount() != null ? r.getAmount() : 0).sum();
        vo.setTotalAmount(totalAmount);
        
        long days = ChronoUnit.DAYS.between(startDate, endDate) + 1;
        vo.setDailyAverageAmount((double) totalAmount / days);
        vo.setDailyAverageCount((double) records.size() / days);
        vo.setAveragePerFeeding(records.isEmpty() ? 0 : (double) totalAmount / records.size());
        
        // 设置推荐值
        int[] guide = getGuideByAge(ageInMonths);
        int recommendedDaily = (guide[2] + guide[3]) / 2 * (guide[0] + guide[1]) / 2;
        vo.setRecommendedDailyAmount(recommendedDaily);
        vo.setRecommendedDailyCount(guide[0] + "-" + guide[1] + "次");
        
        // 对比分析
        double ratio = vo.getDailyAverageAmount() / recommendedDaily;
        if (ratio < 0.8) {
            vo.setComparisonWithRecommended("偏低，建议适当增加奶量");
        } else if (ratio > 1.2) {
            vo.setComparisonWithRecommended("偏高，注意控制奶量");
        } else {
            vo.setComparisonWithRecommended("正常范围");
        }
        
        // 喂养类型比例
        Map<String, Double> typeRatio = new HashMap<>();
        long breastMilk = records.stream().filter(r -> r.getFeedingType() == 1).count();
        long formula = records.stream().filter(r -> r.getFeedingType() == 2).count();
        long mixed = records.stream().filter(r -> r.getFeedingType() == 3).count();
        if (!records.isEmpty()) {
            typeRatio.put("母乳", (double) breastMilk / records.size() * 100);
            typeRatio.put("奶粉", (double) formula / records.size() * 100);
            typeRatio.put("混合", (double) mixed / records.size() * 100);
        }
        vo.setFeedingTypeRatio(typeRatio);
        
        return vo;
    }
    
    @Override
    public LocalDateTime calculateNextFeedingTime(Long babyId, LocalDateTime currentFeedingTime) {
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        int intervalMinutes = getRecommendedInterval(ageInMonths);
        
        // 检查用户自定义设置
        FeedingSetting setting = getFeedingSetting(babyId);
        if (setting != null && setting.getDefaultInterval() != null) {
            intervalMinutes = setting.getDefaultInterval();
        }
        
        return currentFeedingTime.plusMinutes(intervalMinutes);
    }
    
    @Override
    public int getRecommendedAmount(int ageInMonths) {
        int[] guide = getGuideByAge(ageInMonths);
        return (guide[2] + guide[3]) / 2;
    }
    
    @Override
    public int getRecommendedInterval(int ageInMonths) {
        int[] guide = getGuideByAge(ageInMonths);
        return guide[4] * 60; // 转换为分钟
    }
    
    private int[] getGuideByAge(int ageInMonths) {
        if (ageInMonths < 1) return FEEDING_GUIDE.get("0-1");
        if (ageInMonths < 3) return FEEDING_GUIDE.get("1-3");
        if (ageInMonths < 6) return FEEDING_GUIDE.get("3-6");
        if (ageInMonths < 9) return FEEDING_GUIDE.get("6-9");
        if (ageInMonths < 12) return FEEDING_GUIDE.get("9-12");
        return FEEDING_GUIDE.get("12-24");
    }
    
    private FeedingSetting getFeedingSetting(Long babyId) {
        return feedingSettingMapper.selectOne(
                new LambdaQueryWrapper<FeedingSetting>().eq(FeedingSetting::getBabyId, babyId));
    }
}
