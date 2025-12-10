package com.baby.controller;

import com.baby.common.Result;
import com.baby.dto.GrowthRecordDTO;
import com.baby.entity.Baby;
import com.baby.entity.GrowthRecord;
import com.baby.service.BabyService;
import com.baby.service.GrowthRecordService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 身高体重测量记录控制器
 */
@Tag(name = "身高体重测量记录")
@RestController
@RequestMapping("/growth")
@RequiredArgsConstructor
public class GrowthRecordController {
    
    private final GrowthRecordService growthRecordService;
    private final BabyService babyService;
    
    @Operation(summary = "创建测量记录")
    @PostMapping
    public Result<GrowthRecord> create(@Valid @RequestBody GrowthRecordDTO dto) {
        GrowthRecord record = growthRecordService.createRecord(dto);
        return Result.success(record);
    }
    
    @Operation(summary = "更新测量记录")
    @PutMapping("/{id}")
    public Result<GrowthRecord> update(@PathVariable Long id,
                                       @Valid @RequestBody GrowthRecordDTO dto) {
        GrowthRecord record = growthRecordService.updateRecord(id, dto);
        return Result.success(record);
    }
    
    @Operation(summary = "获取测量记录详情")
    @GetMapping("/{id}")
    public Result<GrowthRecord> getById(@PathVariable Long id) {
        GrowthRecord record = growthRecordService.getById(id);
        return Result.success(record);
    }
    
    @Operation(summary = "获取宝宝所有测量记录")
    @GetMapping("/all/{babyId}")
    public Result<List<GrowthRecord>> getAllRecords(@PathVariable Long babyId) {
        List<GrowthRecord> records = growthRecordService.getAllRecords(babyId);
        return Result.success(records);
    }
    
    @Operation(summary = "删除测量记录")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        growthRecordService.removeById(id);
        return Result.success();
    }
    
    @Operation(summary = "获取WHO标准生长曲线数据")
    @GetMapping("/who-standard/{babyId}")
    public Result<Map<String, Object>> getWHOStandard(@PathVariable Long babyId) {
        Baby baby = babyService.getById(babyId);
        int gender = (baby != null && baby.getGender() != null) ? baby.getGender() : 1;
        
        Map<String, Object> result = new HashMap<>();
        result.put("height", growthRecordService.getWHOHeightStandard(gender));
        result.put("weight", growthRecordService.getWHOWeightStandard(gender));
        result.put("gender", gender);
        
        return Result.success(result);
    }
    
    @Operation(summary = "获取宝宝生长曲线数据（含标准和实际记录）")
    @GetMapping("/chart-data/{babyId}")
    public Result<Map<String, Object>> getChartData(
            @PathVariable Long babyId,
            @Parameter(description = "标准类型: WHO, CHINA_2025") 
            @RequestParam(defaultValue = "CHINA_2025") String standardType) {
        
        Baby baby = babyService.getById(babyId);
        int gender = (baby != null && baby.getGender() != null) ? baby.getGender() : 1;
        
        Map<String, Object> result = new HashMap<>();
        
        // 标准数据（根据指定标准类型）
        result.put("heightStandard", growthRecordService.getHeightStandard(gender, standardType));
        result.put("weightStandard", growthRecordService.getWeightStandard(gender, standardType));
        result.put("bmiStandard", growthRecordService.getBmiStandard(gender, standardType));
        
        // 兼容旧版本字段名
        result.put("whoHeight", result.get("heightStandard"));
        result.put("whoWeight", result.get("weightStandard"));
        
        // 宝宝实际记录
        List<GrowthRecord> records = growthRecordService.getAllRecords(babyId);
        result.put("records", records);
        
        // 百分位分析（使用指定标准）
        result.put("percentile", growthRecordService.calculatePercentile(babyId, standardType));
        
        result.put("gender", gender);
        result.put("standardType", standardType);
        
        return Result.success(result);
    }
    
    @Operation(summary = "获取最新百分位分析")
    @GetMapping("/percentile/{babyId}")
    public Result<Map<String, Object>> getPercentile(
            @PathVariable Long babyId,
            @Parameter(description = "标准类型: WHO, CHINA_2025")
            @RequestParam(defaultValue = "CHINA_2025") String standardType) {
        return Result.success(growthRecordService.calculatePercentile(babyId, standardType));
    }
    
    @Operation(summary = "获取可用的参考标准列表")
    @GetMapping("/standards")
    public Result<List<Map<String, Object>>> getAvailableStandards() {
        return Result.success(growthRecordService.getAvailableStandards());
    }
}
