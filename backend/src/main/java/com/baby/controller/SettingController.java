package com.baby.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baby.common.Result;
import com.baby.entity.FeedingSetting;
import com.baby.entity.SleepSetting;
import com.baby.mapper.FeedingSettingMapper;
import com.baby.mapper.SleepSettingMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 设置管理控制器
 */
@Tag(name = "设置管理")
@RestController
@RequestMapping("/setting")
@RequiredArgsConstructor
public class SettingController {
    
    private final FeedingSettingMapper feedingSettingMapper;
    private final SleepSettingMapper sleepSettingMapper;
    
    @Operation(summary = "获取宝宝的喂养设置")
    @GetMapping("/feeding/{babyId}")
    public Result<FeedingSetting> getFeedingSetting(@PathVariable Long babyId) {
        FeedingSetting setting = feedingSettingMapper.selectOne(
                new LambdaQueryWrapper<FeedingSetting>().eq(FeedingSetting::getBabyId, babyId));
        
        // 如果没有设置，返回默认值
        if (setting == null) {
            setting = new FeedingSetting();
            setting.setBabyId(babyId);
            setting.setDefaultFeedingType(1);
            setting.setDefaultAmount(120);
            setting.setDefaultDuration(20);
            setting.setDefaultInterval(180);
            setting.setReminderStartTime("06:00:00");
            setting.setReminderEndTime("22:00:00");
            setting.setRefrigeratedThawMinutes(15);
            setting.setFrozenThawMinutes(30);
            setting.setReminderEnabled(1);
            setting.setDefaultNextMilkSource(0);
        } else {
            // 如果存在设置但时间为null，设置默认值
            if (setting.getReminderStartTime() == null) {
                setting.setReminderStartTime("06:00:00");
            }
            if (setting.getReminderEndTime() == null) {
                setting.setReminderEndTime("22:00:00");
            }
        }
        
        return Result.success(setting);
    }
    
    @Operation(summary = "保存宝宝的喂养设置")
    @PostMapping("/feeding")
    public Result<FeedingSetting> saveFeedingSetting(@RequestBody FeedingSetting setting) {
        // 设置默认值（如果客户端没有发送）
        if (setting.getReminderStartTime() == null) {
            setting.setReminderStartTime("06:00:00");
        }
        if (setting.getReminderEndTime() == null) {
            setting.setReminderEndTime("22:00:00");
        }

        FeedingSetting existing = feedingSettingMapper.selectOne(
                new LambdaQueryWrapper<FeedingSetting>().eq(FeedingSetting::getBabyId, setting.getBabyId()));

        if (existing != null) {
            setting.setId(existing.getId());
            feedingSettingMapper.updateById(setting);
        } else {
            feedingSettingMapper.insert(setting);
        }

        // 确保返回的数据包含所有必要的字段
        if (setting.getReminderStartTime() == null) {
            setting.setReminderStartTime("06:00:00");
        }
        if (setting.getReminderEndTime() == null) {
            setting.setReminderEndTime("22:00:00");
        }

        return Result.success(setting);
    }
    
    @Operation(summary = "获取宝宝的睡眠设置")
    @GetMapping("/sleep/{babyId}")
    public Result<SleepSetting> getSleepSetting(@PathVariable Long babyId) {
        SleepSetting setting = sleepSettingMapper.selectOne(
                new LambdaQueryWrapper<SleepSetting>().eq(SleepSetting::getBabyId, babyId));
        
        // 如果没有设置，返回默认值
        if (setting == null) {
            setting = new SleepSetting();
            setting.setBabyId(babyId);
            setting.setDefaultNapInterval(120);
            setting.setDefaultNapDuration(90);
            setting.setDefaultSoothingReminderMinutes(15);
            setting.setReminderEnabled(1);
            setting.setNextNapReminderEnabled(1);
            setting.setReminderStartTime(java.time.LocalTime.of(6, 0));
            setting.setReminderEndTime(java.time.LocalTime.of(20, 0));
        }
        
        return Result.success(setting);
    }
    
    @Operation(summary = "保存宝宝的睡眠设置")
    @PostMapping("/sleep")
    public Result<SleepSetting> saveSleepSetting(@RequestBody SleepSetting setting) {
        SleepSetting existing = sleepSettingMapper.selectOne(
                new LambdaQueryWrapper<SleepSetting>().eq(SleepSetting::getBabyId, setting.getBabyId()));
        
        if (existing != null) {
            setting.setId(existing.getId());
            sleepSettingMapper.updateById(setting);
        } else {
            sleepSettingMapper.insert(setting);
        }
        
        return Result.success(setting);
    }
}
