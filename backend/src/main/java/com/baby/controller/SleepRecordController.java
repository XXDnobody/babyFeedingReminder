package com.baby.controller;

import com.baby.common.Result;
import com.baby.dto.SleepRecordDTO;
import com.baby.entity.SleepRecord;
import com.baby.service.BabyService;
import com.baby.service.SleepRecordService;
import com.baby.vo.SleepStatisticsVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 睡眠记录管理控制器
 */
@Tag(name = "睡眠记录管理")
@RestController
@RequestMapping("/sleep")
@RequiredArgsConstructor
public class SleepRecordController {
    
    private final SleepRecordService sleepRecordService;
    private final BabyService babyService;
    
    @Operation(summary = "创建睡眠记录")
    @PostMapping
    public Result<SleepRecord> create(@Valid @RequestBody SleepRecordDTO dto) {
        SleepRecord record = sleepRecordService.createRecord(dto);
        return Result.success(record);
    }
    
    @Operation(summary = "手动添加睡眠记录")
    @PostMapping("/add")
    public Result<SleepRecord> addRecord(@Valid @RequestBody SleepRecordDTO dto) {
        SleepRecord record = sleepRecordService.createRecord(dto);
        return Result.success(record);
    }
    
    @Operation(summary = "开始睡眠")
    @PostMapping("/start/{babyId}")
    public Result<SleepRecord> startNap(@PathVariable Long babyId,
                                        @RequestParam(required = false) 
                                        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime) {
        SleepRecord record = sleepRecordService.startNap(babyId, startTime);
        return Result.success(record);
    }
    
    @Operation(summary = "结束睡眠")
    @PostMapping("/end/{id}")
    public Result<SleepRecord> endNap(@PathVariable Long id,
                                      @RequestParam(required = false)
                                      @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime,
                                      @RequestParam(required = false) Integer quality,
                                      @RequestParam(required = false) Boolean remind) {
        SleepRecord record = sleepRecordService.endNap(id, endTime, quality, remind);
        return Result.success(record);
    }
    
    @Operation(summary = "更新睡眠记录")
    @PutMapping("/{id}")
    public Result<SleepRecord> update(@PathVariable Long id,
                                      @Valid @RequestBody SleepRecordDTO dto) {
        SleepRecord record = sleepRecordService.updateRecord(id, dto);
        return Result.success(record);
    }
    
    @Operation(summary = "获取睡眠记录详情")
    @GetMapping("/{id}")
    public Result<SleepRecord> getById(@PathVariable Long id) {
        SleepRecord record = sleepRecordService.getById(id);
        return Result.success(record);
    }
    
    @Operation(summary = "获取宝宝今日睡眠记录")
    @GetMapping("/today/{babyId}")
    public Result<List<SleepRecord>> getTodayRecords(@PathVariable Long babyId) {
        List<SleepRecord> records = sleepRecordService.getTodayRecords(babyId);
        return Result.success(records);
    }
    
    @Operation(summary = "获取宝宝指定日期范围的睡眠记录")
    @GetMapping("/range/{babyId}")
    public Result<List<SleepRecord>> getRecordsByDateRange(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<SleepRecord> records = sleepRecordService.getRecordsByDateRange(babyId, startDate, endDate);
        return Result.success(records);
    }
    
    @Operation(summary = "获取最近一次睡眠记录")
    @GetMapping("/last/{babyId}")
    public Result<SleepRecord> getLastRecord(@PathVariable Long babyId) {
        SleepRecord record = sleepRecordService.getLastRecord(babyId);
        return Result.success(record);
    }
    
    @Operation(summary = "获取睡眠统计")
    @GetMapping("/statistics/{babyId}")
    public Result<SleepStatisticsVO> getStatistics(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        SleepStatisticsVO statistics = sleepRecordService.getStatistics(babyId, startDate, endDate);
        return Result.success(statistics);
    }
    
    @Operation(summary = "获取睡眠建议（基于国家卫健委指南）")
    @GetMapping("/recommendation/{babyId}")
    public Result<Map<String, Object>> getRecommendation(@PathVariable Long babyId) {
        int ageInMonths = babyService.calculateAgeInMonths(babyId);
        int recommendedNapDuration = sleepRecordService.getRecommendedNapDuration(ageInMonths);
        int recommendedAwakeInterval = sleepRecordService.getRecommendedAwakeInterval(ageInMonths);
        
        Map<String, Object> recommendation = new HashMap<>();
        recommendation.put("ageInMonths", ageInMonths);
        recommendation.put("recommendedNapDurationMinutes", recommendedNapDuration);
        recommendation.put("recommendedAwakeIntervalMinutes", recommendedAwakeInterval);
        recommendation.put("source", "国家卫健委《0岁～5岁儿童睡眠卫生指南》");
        
        return Result.success(recommendation);
    }
    
    @Operation(summary = "删除睡眠记录")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        sleepRecordService.removeById(id);
        return Result.success();
    }
}
