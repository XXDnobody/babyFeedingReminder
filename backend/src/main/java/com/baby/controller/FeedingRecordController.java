package com.baby.controller;

import com.baby.common.Result;
import com.baby.dto.FeedingRecordDTO;
import com.baby.entity.FeedingRecord;
import com.baby.service.BabyService;
import com.baby.service.FeedingRecordService;
import com.baby.vo.FeedingStatisticsVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 喂养记录管理控制器
 */
@Tag(name = "喂养记录管理")
@RestController
@RequestMapping("/feeding")
@RequiredArgsConstructor
public class FeedingRecordController {
    
    private final FeedingRecordService feedingRecordService;
    private final BabyService babyService;
    
    @Operation(summary = "创建喂养记录")
    @PostMapping
    public Result<FeedingRecord> create(@Valid @RequestBody FeedingRecordDTO dto) {
        FeedingRecord record = feedingRecordService.createRecord(dto);
        return Result.success(record);
    }
    
    @Operation(summary = "更新喂养记录")
    @PutMapping("/{id}")
    public Result<FeedingRecord> update(@PathVariable Long id,
                                        @Valid @RequestBody FeedingRecordDTO dto) {
        FeedingRecord record = feedingRecordService.updateRecord(id, dto);
        return Result.success(record);
    }
    
    @Operation(summary = "获取喂养记录详情")
    @GetMapping("/{id}")
    public Result<FeedingRecord> getById(@PathVariable Long id) {
        FeedingRecord record = feedingRecordService.getById(id);
        return Result.success(record);
    }
    
    @Operation(summary = "获取宝宝今日喂养记录")
    @GetMapping("/today/{babyId}")
    public Result<List<FeedingRecord>> getTodayRecords(@PathVariable Long babyId) {
        List<FeedingRecord> records = feedingRecordService.getTodayRecords(babyId);
        return Result.success(records);
    }
    
    @Operation(summary = "获取宝宝指定日期范围的喂养记录")
    @GetMapping("/range/{babyId}")
    public Result<List<FeedingRecord>> getRecordsByDateRange(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<FeedingRecord> records = feedingRecordService.getRecordsByDateRange(babyId, startDate, endDate);
        return Result.success(records);
    }
    
    @Operation(summary = "获取最近一次喂养记录")
    @GetMapping("/last/{babyId}")
    public Result<FeedingRecord> getLastRecord(@PathVariable Long babyId) {
        FeedingRecord record = feedingRecordService.getLastRecord(babyId);
        return Result.success(record);
    }
    
    @Operation(summary = "获取喂养统计")
    @GetMapping("/statistics/{babyId}")
    public Result<FeedingStatisticsVO> getStatistics(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        FeedingStatisticsVO statistics = feedingRecordService.getStatistics(babyId, startDate, endDate);
        return Result.success(statistics);
    }
    
    @Operation(summary = "获取喂养建议（基于国家卫健委指南）")
    @GetMapping("/recommendation/{babyId}")
    public Result<Map<String, Object>> getRecommendation(@PathVariable Long babyId) {
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        int recommendedAmount = feedingRecordService.getRecommendedAmount(ageInMonths);
        int recommendedInterval = feedingRecordService.getRecommendedInterval(ageInMonths);
        
        Map<String, Object> recommendation = new HashMap<>();
        recommendation.put("ageInMonths", ageInMonths);
        recommendation.put("recommendedAmountPerFeeding", recommendedAmount);
        recommendation.put("recommendedIntervalMinutes", recommendedInterval);
        recommendation.put("source", "2025年国家卫生健康委婴幼儿营养喂养评估服务指南");
        
        return Result.success(recommendation);
    }
    
    @Operation(summary = "删除喂养记录")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        feedingRecordService.removeById(id);
        return Result.success();
    }
}
