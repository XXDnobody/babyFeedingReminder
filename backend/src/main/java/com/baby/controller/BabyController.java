package com.baby.controller;

import com.baby.common.Result;
import com.baby.dto.BabyDTO;
import com.baby.entity.Baby;
import com.baby.service.BabyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 宝宝信息管理控制器
 */
@Tag(name = "宝宝信息管理")
@RestController
@RequestMapping("/baby")
@RequiredArgsConstructor
public class BabyController {
    
    private final BabyService babyService;
    
    @Operation(summary = "创建宝宝信息")
    @PostMapping
    public Result<Baby> create(@RequestHeader(value = "userId", defaultValue = "1") Long userId,
                               @Valid @RequestBody BabyDTO dto) {
        Baby baby = babyService.createBaby(userId, dto);
        return Result.success(baby);
    }
    
    @Operation(summary = "更新宝宝信息")
    @PutMapping("/{id}")
    public Result<Baby> update(@PathVariable Long id,
                               @Valid @RequestBody BabyDTO dto) {
        Baby baby = babyService.updateBaby(id, dto);
        return Result.success(baby);
    }
    
    @Operation(summary = "获取宝宝详情")
    @GetMapping("/{id}")
    public Result<Baby> getById(@PathVariable Long id) {
        Baby baby = babyService.getById(id);
        return Result.success(baby);
    }
    
    @Operation(summary = "获取用户的所有宝宝")
    @GetMapping("/list")
    public Result<List<Baby>> listByUser(@RequestHeader(value = "userId", defaultValue = "1") Long userId) {
        List<Baby> babies = babyService.getBabiesByUserId(userId);
        return Result.success(babies);
    }
    
    @Operation(summary = "更新生长指标")
    @PutMapping("/{id}/growth")
    public Result<Baby> updateGrowth(@PathVariable Long id,
                                     @RequestParam(required = false) Double height,
                                     @RequestParam(required = false) Double weight,
                                     @RequestParam(required = false) Double headCircumference) {
        Baby baby = babyService.updateGrowthMetrics(id, height, weight, headCircumference);
        return Result.success(baby);
    }
    
    @Operation(summary = "获取宝宝月龄")
    @GetMapping("/{id}/age")
    public Result<Integer> getAgeInMonths(@PathVariable Long id) {
        int ageInMonths = babyService.calculateAgeInMonths(id);
        return Result.success(ageInMonths);
    }
    
    @Operation(summary = "删除宝宝信息")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        babyService.removeById(id);
        return Result.success();
    }
}
