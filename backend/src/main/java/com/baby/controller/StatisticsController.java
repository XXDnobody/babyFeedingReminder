package com.baby.controller;

import com.baby.common.Result;
import com.baby.mapper.FeedingRecordMapper;
import com.baby.mapper.SleepRecordMapper;
import com.baby.service.BabyService;
import com.baby.service.FeedingRecordService;
import com.baby.service.SleepRecordService;
import com.baby.vo.FeedingStatisticsVO;
import com.baby.vo.SleepStatisticsVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
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
    private final FeedingRecordMapper feedingRecordMapper;
    private final SleepRecordMapper sleepRecordMapper;
    private final BabyService babyService;
    
    @Operation(summary = "获取今日概览")
    @GetMapping("/overview/{babyId}")
    public Result<Map<String, Object>> getTodayOverview(@PathVariable Long babyId) {
        Map<String, Object> overview = new HashMap<>();
        
        // 今日喂养数据
        Integer todayTotalAmount = feedingRecordMapper.getTodayTotalAmount(babyId);
        Integer todayFeedingCount = feedingRecordMapper.getTodayFeedingCount(babyId);
        
        // 今日睡眠数据
        Integer todaySleepDuration = sleepRecordMapper.getTodayTotalDuration(babyId);
        Integer todayNapCount = sleepRecordMapper.getTodayNapCount(babyId);
        
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
        overview.put("ageInMonths", ageInMonths);
        
        return Result.success(overview);
    }
    
    @Operation(summary = "获取喂养分析")
    @GetMapping("/feeding/{babyId}")
    public Result<FeedingStatisticsVO> getFeedingAnalysis(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        FeedingStatisticsVO statistics = feedingRecordService.getStatistics(babyId, startDate, endDate);
        return Result.success(statistics);
    }
    
    @Operation(summary = "获取睡眠分析")
    @GetMapping("/sleep/{babyId}")
    public Result<SleepStatisticsVO> getSleepAnalysis(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        SleepStatisticsVO statistics = sleepRecordService.getStatistics(babyId, startDate, endDate);
        return Result.success(statistics);
    }
    
    @Operation(summary = "获取智能洞察")
    @GetMapping("/insights/{babyId}")
    public Result<Map<String, Object>> getInsights(@PathVariable Long babyId) {
        Map<String, Object> insights = new HashMap<>();
        
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        LocalDate today = LocalDate.now();
        LocalDate weekAgo = today.minusDays(7);
        
        // 获取过去一周的数据
        FeedingStatisticsVO feedingStats = feedingRecordService.getStatistics(babyId, weekAgo, today);
        SleepStatisticsVO sleepStats = sleepRecordService.getStatistics(babyId, weekAgo, today);
        
        // 生成洞察
        StringBuilder feedingInsight = new StringBuilder();
        if (feedingStats.getDailyAverageAmount() != null) {
            feedingInsight.append("过去一周日均奶量").append(String.format("%.0f", feedingStats.getDailyAverageAmount())).append("ml，");
            feedingInsight.append(feedingStats.getComparisonWithRecommended());
        }
        
        StringBuilder sleepInsight = new StringBuilder();
        if (sleepStats.getDailyAverageHours() != null) {
            sleepInsight.append("过去一周日均睡眠").append(String.format("%.1f", sleepStats.getDailyAverageHours())).append("小时，");
            sleepInsight.append(sleepStats.getComparisonWithRecommended());
        }
        
        // 生成建议
        String suggestion = generateSuggestion(ageInMonths, feedingStats, sleepStats);
        
        insights.put("feedingInsight", feedingInsight.toString());
        insights.put("sleepInsight", sleepInsight.toString());
        insights.put("suggestion", suggestion);
        insights.put("ageInMonths", ageInMonths);
        insights.put("analysisDate", today.toString());
        
        return Result.success(insights);
    }
    
    private String generateSuggestion(int ageInMonths, FeedingStatisticsVO feedingStats, SleepStatisticsVO sleepStats) {
        StringBuilder suggestion = new StringBuilder();
        
        if (ageInMonths < 6) {
            suggestion.append("宝宝处于纯母乳/配方奶阶段，建议按需喂养。");
        } else if (ageInMonths < 12) {
            suggestion.append("宝宝已进入辅食添加阶段，可逐步增加辅食，奶量可适当减少。");
        } else {
            suggestion.append("宝宝已满1岁，可以开始尝试更多固体食物，但仍需保证充足的奶量。");
        }
        
        if (sleepStats.getDailyAverageHours() != null && sleepStats.getDailyAverageHours() < 12) {
            suggestion.append("注意保证宝宝充足的睡眠时间。");
        }
        
        return suggestion.toString();
    }
}
