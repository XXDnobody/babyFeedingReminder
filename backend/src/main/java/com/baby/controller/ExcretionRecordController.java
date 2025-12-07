package com.baby.controller;

import com.baby.common.Result;
import com.baby.dto.ExcretionRecordDTO;
import com.baby.entity.ExcretionRecord;
import com.baby.service.ExcretionRecordService;
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
 * 排便排尿记录管理控制器
 */
@Tag(name = "排便排尿记录管理")
@RestController
@RequestMapping("/excretion")
@RequiredArgsConstructor
public class ExcretionRecordController {
    
    private final ExcretionRecordService excretionRecordService;
    
    @Operation(summary = "创建排泄记录")
    @PostMapping
    public Result<ExcretionRecord> create(@Valid @RequestBody ExcretionRecordDTO dto) {
        ExcretionRecord record = excretionRecordService.createRecord(dto);
        return Result.success(record);
    }
    
    @Operation(summary = "更新排泄记录")
    @PutMapping("/{id}")
    public Result<ExcretionRecord> update(@PathVariable Long id,
                                          @Valid @RequestBody ExcretionRecordDTO dto) {
        ExcretionRecord record = excretionRecordService.updateRecord(id, dto);
        return Result.success(record);
    }
    
    @Operation(summary = "获取排泄记录详情")
    @GetMapping("/{id}")
    public Result<ExcretionRecord> getById(@PathVariable Long id) {
        ExcretionRecord record = excretionRecordService.getById(id);
        return Result.success(record);
    }
    
    @Operation(summary = "获取宝宝今日排泄记录")
    @GetMapping("/today/{babyId}")
    public Result<List<ExcretionRecord>> getTodayRecords(@PathVariable Long babyId) {
        List<ExcretionRecord> records = excretionRecordService.getTodayRecords(babyId);
        return Result.success(records);
    }
    
    @Operation(summary = "获取宝宝指定日期范围的排泄记录")
    @GetMapping("/range/{babyId}")
    public Result<List<ExcretionRecord>> getRecordsByDateRange(
            @PathVariable Long babyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<ExcretionRecord> records = excretionRecordService.getRecordsByDateRange(babyId, startDate, endDate);
        return Result.success(records);
    }
    
    @Operation(summary = "获取今日排泄统计")
    @GetMapping("/today-stats/{babyId}")
    public Result<Map<String, Integer>> getTodayStats(@PathVariable Long babyId) {
        Map<String, Integer> stats = new HashMap<>();
        stats.put("poopCount", excretionRecordService.getTodayPoopCount(babyId));
        stats.put("peeCount", excretionRecordService.getTodayPeeCount(babyId));
        return Result.success(stats);
    }
    
    @Operation(summary = "删除排泄记录")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        excretionRecordService.removeById(id);
        return Result.success();
    }
}
