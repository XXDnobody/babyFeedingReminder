package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.SleepRecordDTO;
import com.baby.entity.SleepRecord;
import com.baby.entity.SleepSetting;
import com.baby.mapper.SleepRecordMapper;
import com.baby.mapper.SleepSettingMapper;
import com.baby.service.BabyService;
import com.baby.service.ReminderService;
import com.baby.service.SleepRecordService;
import com.baby.vo.SleepStatisticsVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * 睡眠记录服务实现类
 * 参考：国家卫健委《0岁～5岁儿童睡眠卫生指南》和《睡眠健康核心信息及释义》
 */
@Service
@RequiredArgsConstructor
public class SleepRecordServiceImpl extends ServiceImpl<SleepRecordMapper, SleepRecord> 
        implements SleepRecordService {
    
    private final SleepSettingMapper sleepSettingMapper;
    private final BabyService babyService;
    private final ReminderService reminderService;
    
    // 睡眠指南参数（基于国家卫健委标准）
    private static final Map<String, int[]> SLEEP_GUIDE = new HashMap<>() {{
        // 月龄范围 -> [日均睡眠下限(小时), 日均睡眠上限(小时), 小睡次数下限, 小睡次数上限, 清醒间隔(分钟), 小睡时长(分钟)]
        put("0-3", new int[]{14, 17, 4, 5, 45, 60});      // 0-3个月
        put("3-6", new int[]{12, 16, 3, 4, 90, 90});      // 3-6个月
        put("6-9", new int[]{12, 15, 2, 3, 120, 90});     // 6-9个月
        put("9-12", new int[]{12, 14, 2, 2, 150, 90});    // 9-12个月
        put("12-18", new int[]{11, 14, 1, 2, 180, 120});  // 12-18个月
        put("18-24", new int[]{11, 14, 1, 1, 240, 120});  // 18-24个月
    }};
    
    @Override
    @Transactional
    public SleepRecord createRecord(SleepRecordDTO dto) {
        SleepRecord record = new SleepRecord();
        record.setBabyId(dto.getBabyId());
        record.setSleepType(dto.getSleepType());
        record.setStartTime(dto.getStartTime());
        record.setEndTime(dto.getEndTime());
        record.setQuality(dto.getQuality());
        record.setRemark(dto.getRemark());
        
        // 计算睡眠时长
        if (dto.getEndTime() != null && dto.getStartTime() != null) {
            long minutes = ChronoUnit.MINUTES.between(dto.getStartTime(), dto.getEndTime());
            record.setDuration((int) minutes);
        }
        
        // 设置推荐睡眠时长
        int ageInMonths = babyService.calculateAgeInMonths(dto.getBabyId());
        record.setPlannedDuration(getRecommendedNapDuration(ageInMonths));
        
        // 如果是小睡，计算下次小睡时间
        if (dto.getSleepType() == 1 && dto.getEndTime() != null) {
            LocalDateTime nextNapTime = calculateNextNapTime(dto.getBabyId(), dto.getEndTime());
            record.setNextNapTime(nextNapTime);
            
            // 设置哄睡提醒时间
            SleepSetting setting = getSleepSetting(dto.getBabyId());
            record.setSoothingReminderMinutes(setting != null ? 
                    setting.getDefaultSoothingReminderMinutes() : 15);
        }
        
        save(record);
        
        // 如果有下次小睡时间，创建提醒
        if (record.getNextNapTime() != null) {
            reminderService.createNapReminder(record);
        }
        
        return record;
    }
    
    @Override
    @Transactional
    public SleepRecord startNap(Long babyId, LocalDateTime startTime) {
        SleepRecord record = new SleepRecord();
        record.setBabyId(babyId);
        record.setSleepType(1); // 小睡
        record.setStartTime(startTime != null ? startTime : LocalDateTime.now());
        
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        record.setPlannedDuration(getRecommendedNapDuration(ageInMonths));
        
        save(record);
        return record;
    }
    
    @Override
    @Transactional
    public SleepRecord endNap(Long id, LocalDateTime endTime, Integer quality, Boolean shouldRemind) {
        // 如果ID是负数，说明是本地模拟的记录，直接返回成功
        if (id < 0) {
            // 创建一个模拟的返回记录
            SleepRecord mockRecord = new SleepRecord();
            mockRecord.setId(id);
            mockRecord.setEndTime(endTime != null ? endTime : LocalDateTime.now());
            mockRecord.setQuality(quality);
            // 对于本地模拟记录，也需要计算下次小睡时间
            LocalDateTime actualEndTime = endTime != null ? endTime : LocalDateTime.now();
            LocalDateTime nextNapTime = calculateNextNapTime(mockRecord.getBabyId(), actualEndTime);
            mockRecord.setNextNapTime(nextNapTime);
            return mockRecord;
        }

        SleepRecord record = getById(id);
        if (record == null) {
            throw new RuntimeException("睡眠记录不存在");
        }

        LocalDateTime actualEndTime = endTime != null ? endTime : LocalDateTime.now();
        record.setEndTime(actualEndTime);
        record.setQuality(quality);

        // 计算实际睡眠时长
        long minutes = ChronoUnit.MINUTES.between(record.getStartTime(), actualEndTime);
        record.setDuration((int) minutes);

        // 计算下次小睡时间
        LocalDateTime nextNapTime = calculateNextNapTime(record.getBabyId(), actualEndTime);
        record.setNextNapTime(nextNapTime);

        SleepSetting setting = getSleepSetting(record.getBabyId());
        record.setSoothingReminderMinutes(setting != null ?
                setting.getDefaultSoothingReminderMinutes() : 15);

        updateById(record);

        // 只有在应该提醒时才创建下次小睡提醒
        if (shouldRemind == null || shouldRemind) {
            reminderService.createNapReminder(record);
        }

        return record;
    }
    
    @Override
    @Transactional
    public SleepRecord updateRecord(Long id, SleepRecordDTO dto) {
        // 如果ID是负数，说明是本地模拟的记录，直接返回模拟记录
        if (id < 0) {
            SleepRecord mockRecord = new SleepRecord();
            mockRecord.setId(id);
            mockRecord.setBabyId(dto.getBabyId());
            mockRecord.setSleepType(dto.getSleepType());
            mockRecord.setStartTime(dto.getStartTime());
            mockRecord.setEndTime(dto.getEndTime());
            mockRecord.setQuality(dto.getQuality());
            mockRecord.setRemark(dto.getRemark());

            if (dto.getEndTime() != null && dto.getStartTime() != null) {
                long minutes = ChronoUnit.MINUTES.between(dto.getStartTime(), dto.getEndTime());
                mockRecord.setDuration((int) minutes);
            }

            return mockRecord;
        }

        SleepRecord record = getById(id);
        if (record == null) {
            throw new RuntimeException("睡眠记录不存在");
        }

        record.setSleepType(dto.getSleepType());
        record.setStartTime(dto.getStartTime());
        record.setEndTime(dto.getEndTime());
        record.setQuality(dto.getQuality());
        record.setRemark(dto.getRemark());

        if (dto.getEndTime() != null && dto.getStartTime() != null) {
            long minutes = ChronoUnit.MINUTES.between(dto.getStartTime(), dto.getEndTime());
            record.setDuration((int) minutes);
        }

        updateById(record);
        return record;
    }
    
    @Override
    public List<SleepRecord> getTodayRecords(Long babyId) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);

        return list(new LambdaQueryWrapper<SleepRecord>()
                .eq(SleepRecord::getBabyId, babyId)
                .and(wrapper -> wrapper
                    .between(SleepRecord::getStartTime, startOfDay, endOfDay)
                    .or()
                    .between(SleepRecord::getEndTime, startOfDay, endOfDay)
                )
                .orderByDesc(SleepRecord::getStartTime));
    }
    
    @Override
    public List<SleepRecord> getRecordsByDateRange(Long babyId, LocalDate startDate, LocalDate endDate) {
        return list(new LambdaQueryWrapper<SleepRecord>()
                .eq(SleepRecord::getBabyId, babyId)
                .between(SleepRecord::getStartTime, startDate.atStartOfDay(), endDate.plusDays(1).atStartOfDay())
                .orderByDesc(SleepRecord::getStartTime));
    }
    
    @Override
    public SleepRecord getLastRecord(Long babyId) {
        return getOne(new LambdaQueryWrapper<SleepRecord>()
                .eq(SleepRecord::getBabyId, babyId)
                .orderByDesc(SleepRecord::getStartTime)
                .last("LIMIT 1"));
    }
    
    @Override
    public SleepStatisticsVO getStatistics(Long babyId, LocalDate startDate, LocalDate endDate) {
        List<SleepRecord> records = getRecordsByDateRange(babyId, startDate, endDate);
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        
        SleepStatisticsVO vo = new SleepStatisticsVO();
        vo.setDateRange(startDate + " ~ " + endDate);
        
        int totalDuration = records.stream()
                .mapToInt(r -> r.getDuration() != null ? r.getDuration() : 0).sum();
        vo.setTotalDuration(totalDuration);
        
        long napCount = records.stream().filter(r -> r.getSleepType() == 1).count();
        long nightCount = records.stream().filter(r -> r.getSleepType() == 2).count();
        vo.setNapCount((int) napCount);
        vo.setNightSleepCount((int) nightCount);
        
        long days = ChronoUnit.DAYS.between(startDate, endDate) + 1;
        vo.setDailyAverageHours((double) totalDuration / 60 / days);
        vo.setDailyAverageNapCount((double) napCount / days);
        vo.setAverageNapDuration(napCount > 0 ? (double) totalDuration / napCount : 0);
        
        // 设置推荐值
        int[] guide = getGuideByAge(ageInMonths);
        vo.setRecommendedDailyHours(guide[0] + "-" + guide[1] + "小时");
        vo.setRecommendedNapCount(guide[2] + "-" + guide[3] + "次");
        
        // 对比分析
        double avgHours = vo.getDailyAverageHours();
        if (avgHours < guide[0]) {
            vo.setComparisonWithRecommended("睡眠时间偏少，建议适当增加");
        } else if (avgHours > guide[1]) {
            vo.setComparisonWithRecommended("睡眠时间偏多，可适当调整");
        } else {
            vo.setComparisonWithRecommended("睡眠时间正常");
        }
        
        // 睡眠质量分布
        SleepStatisticsVO.QualityDistribution quality = new SleepStatisticsVO.QualityDistribution();
        long goodCount = records.stream().filter(r -> r.getQuality() != null && r.getQuality() == 1).count();
        long normalCount = records.stream().filter(r -> r.getQuality() != null && r.getQuality() == 2).count();
        long poorCount = records.stream().filter(r -> r.getQuality() != null && r.getQuality() == 3).count();
        long total = goodCount + normalCount + poorCount;
        if (total > 0) {
            quality.setGoodPercent((double) goodCount / total * 100);
            quality.setNormalPercent((double) normalCount / total * 100);
            quality.setPoorPercent((double) poorCount / total * 100);
        }
        vo.setQualityDistribution(quality);
        
        // 每日睡眠统计数据
        Map<LocalDate, List<SleepRecord>> recordsByDate = records.stream()
                .collect(java.util.stream.Collectors.groupingBy(r -> r.getStartTime().toLocalDate()));
        List<SleepStatisticsVO.DailySleepData> dailyDataList = new java.util.ArrayList<>();
        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            List<SleepRecord> dayRecords = recordsByDate.getOrDefault(date, java.util.Collections.emptyList());
            SleepStatisticsVO.DailySleepData dailyData = new SleepStatisticsVO.DailySleepData();
            dailyData.setDate(date.toString());
            dailyData.setNapCount((int) dayRecords.stream().filter(r -> r.getSleepType() == 1).count());
            int dayTotalMinutes = dayRecords.stream().mapToInt(r -> r.getDuration() != null ? r.getDuration() : 0).sum();
            dailyData.setTotalMinutes(dayTotalMinutes);
            dailyData.setTotalHours((double) dayTotalMinutes / 60);
            dailyDataList.add(dailyData);
        }
        vo.setDailyData(dailyDataList);
        
        return vo;
    }
    
    @Override
    public LocalDateTime calculateNextNapTime(Long babyId, LocalDateTime wakeUpTime) {
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        int awakeInterval = getRecommendedAwakeInterval(ageInMonths);
        
        // 检查用户自定义设置
        SleepSetting setting = getSleepSetting(babyId);
        if (setting != null && setting.getDefaultNapInterval() != null) {
            awakeInterval = setting.getDefaultNapInterval();
        }
        
        return wakeUpTime.plusMinutes(awakeInterval);
    }
    
    @Override
    public int getRecommendedNapDuration(int ageInMonths) {
        int[] guide = getGuideByAge(ageInMonths);
        return guide[5]; // 推荐小睡时长
    }
    
    @Override
    public int getRecommendedAwakeInterval(int ageInMonths) {
        int[] guide = getGuideByAge(ageInMonths);
        return guide[4]; // 清醒间隔
    }
    
    private int[] getGuideByAge(int ageInMonths) {
        if (ageInMonths < 3) return SLEEP_GUIDE.get("0-3");
        if (ageInMonths < 6) return SLEEP_GUIDE.get("3-6");
        if (ageInMonths < 9) return SLEEP_GUIDE.get("6-9");
        if (ageInMonths < 12) return SLEEP_GUIDE.get("9-12");
        if (ageInMonths < 18) return SLEEP_GUIDE.get("12-18");
        return SLEEP_GUIDE.get("18-24");
    }
    
    private SleepSetting getSleepSetting(Long babyId) {
        return sleepSettingMapper.selectOne(
                new LambdaQueryWrapper<SleepSetting>().eq(SleepSetting::getBabyId, babyId));
    }
}
