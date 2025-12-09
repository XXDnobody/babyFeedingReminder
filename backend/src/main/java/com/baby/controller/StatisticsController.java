package com.baby.controller;

import com.baby.common.Result;
import com.baby.mapper.ExcretionRecordMapper;
import com.baby.mapper.FeedingRecordMapper;
import com.baby.mapper.SleepRecordMapper;
import com.baby.service.BabyService;
import com.baby.service.ExcretionRecordService;
import com.baby.service.FeedingRecordService;
import com.baby.service.SleepRecordService;
import com.baby.vo.ExcretionStatisticsVO;
import com.baby.vo.FeedingStatisticsVO;
import com.baby.vo.SleepStatisticsVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 统计分析控制器
 */
@Tag(name = "统计分析")
@RestController
@RequestMapping("/statistics")
@RequiredArgsConstructor
public class StatisticsController {
    
    private final FeedingRecordService feedingRecordService;
    private final SleepRecordService sleepRecordService;
    private final ExcretionRecordService excretionRecordService;
    private final FeedingRecordMapper feedingRecordMapper;
    private final SleepRecordMapper sleepRecordMapper;
    private final ExcretionRecordMapper excretionRecordMapper;
    private final BabyService babyService;
    
    @Operation(summary = "获取今日概览")
    @GetMapping("/overview/{babyId}")
    @Cacheable(value = "todayOverview", key = "#babyId + ':' + T(java.time.LocalDate).now().toString()")
    public Result<Map<String, Object>> getTodayOverview(@PathVariable Long babyId) {
        Map<String, Object> overview = new HashMap<>();
        
        // 使用 Java 计算今天的时间范围（解决时区问题）
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);
        
        // 今日喂养数据
        Integer todayTotalAmount = feedingRecordMapper.getTotalAmountByDateRange(babyId, startOfDay, endOfDay);
        Integer todayFeedingCount = feedingRecordMapper.getFeedingCountByDateRange(babyId, startOfDay, endOfDay);
        
        // 今日睡眠数据
        Integer todaySleepDuration = sleepRecordMapper.getTotalDurationByDateRange(babyId, startOfDay, endOfDay);
        Integer todayNapCount = sleepRecordMapper.getNapCountByDateRange(babyId, startOfDay, endOfDay);
        
        // 今日排便数据
        Integer todayPoopCount = excretionRecordMapper.getPoopCountByDateRange(babyId, startOfDay, endOfDay);
        Integer todayPeeCount = excretionRecordMapper.getPeeCountByDateRange(babyId, startOfDay, endOfDay);
        
        // 获取推荐值
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        int recommendedAmount = feedingRecordService.getRecommendedAmount(ageInMonths) * 6; // 估算日均
        int recommendedNapDuration = sleepRecordService.getRecommendedNapDuration(ageInMonths);
        
        overview.put("date", LocalDate.now().toString());
        overview.put("feeding", Map.of(
                "totalAmount", todayTotalAmount,
                "count", todayFeedingCount,
                "recommendedDailyAmount", recommendedAmount,
                "unit", "ml"
        ));
        overview.put("sleep", Map.of(
                "totalMinutes", todaySleepDuration,
                "totalHours", String.format("%.1f", todaySleepDuration / 60.0),
                "napCount", todayNapCount,
                "recommendedNapDuration", recommendedNapDuration,
                "unit", "分钟"
        ));
        overview.put("excretion", Map.of(
                "poopCount", todayPoopCount != null ? todayPoopCount : 0,
                "peeCount", todayPeeCount != null ? todayPeeCount : 0
        ));
        overview.put("ageInMonths", ageInMonths);
        
        return Result.success(overview);
    }
    
    @Operation(summary = "获取喂养分析")
    @GetMapping("/feeding/{babyId}")
    @Cacheable(value = "statistics", key = "'feeding:' + #babyId + ':' + #startDate + ':' + #endDate")
    public Result<FeedingStatisticsVO> getFeedingAnalysis(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        FeedingStatisticsVO statistics = feedingRecordService.getStatistics(babyId, startDate, endDate);
        return Result.success(statistics);
    }
    
    @Operation(summary = "获取睡眠分析")
    @GetMapping("/sleep/{babyId}")
    @Cacheable(value = "statistics", key = "'sleep:' + #babyId + ':' + #startDate + ':' + #endDate")
    public Result<SleepStatisticsVO> getSleepAnalysis(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        SleepStatisticsVO statistics = sleepRecordService.getStatistics(babyId, startDate, endDate);
        return Result.success(statistics);
    }
    
    @Operation(summary = "获取排便分析")
    @GetMapping("/excretion/{babyId}")
    @Cacheable(value = "statistics", key = "'excretion:' + #babyId + ':' + #startDate + ':' + #endDate")
    public Result<ExcretionStatisticsVO> getExcretionAnalysis(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        ExcretionStatisticsVO statistics = excretionRecordService.getStatistics(babyId, startDate, endDate);
        
        // 获取推荐值
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        statistics.setRecommendedPoopCount(excretionRecordService.getRecommendedPoopCount(ageInMonths));
        statistics.setRecommendedPeeCount(excretionRecordService.getRecommendedPeeCount(ageInMonths));
        
        // 生成对比评价
        String comparison = generateExcretionComparison(statistics, ageInMonths);
        statistics.setComparisonWithRecommended(comparison);
        
        return Result.success(statistics);
    }
    

    
    private String generateExcretionComparison(ExcretionStatisticsVO stats, int ageInMonths) {
        if (stats.getDailyAveragePoopCount() == null) {
            return "暂无数据";
        }
        
        double avgPoop = stats.getDailyAveragePoopCount();
        
        // 根据月龄判断排便情况
        if (ageInMonths < 1) {
            if (avgPoop >= 3 && avgPoop <= 8) {
                return "排便频率正常";
            } else if (avgPoop < 3) {
                return "排便频率偏低，建议关注";
            } else {
                return "排便频率较高，属正常范围";
            }
        } else if (ageInMonths < 6) {
            if (avgPoop >= 2 && avgPoop <= 5) {
                return "排便频率正常";
            } else if (avgPoop < 2) {
                return "排便频率偏低，建议关注";
            } else {
                return "排便频率较高，建议观察";
            }
        } else if (ageInMonths < 12) {
            if (avgPoop >= 1 && avgPoop <= 3) {
                return "排便频率正常";
            } else if (avgPoop < 1) {
                return "排便频率偏低，注意观察";
            } else {
                return "排便频率偏高，建议观察";
            }
        } else {
            if (avgPoop >= 1 && avgPoop <= 2) {
                return "排便频率正常";
            } else if (avgPoop < 1) {
                return "排便频率偏低，建议多吃纤维";
            } else {
                return "排便频率偏高，建议观察";
            }
        }
    }
}
