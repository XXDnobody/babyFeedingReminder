package com.baby.controller;

import com.baby.common.Result;
import com.baby.dto.ReminderDTO;
import com.baby.entity.Reminder;
import com.baby.service.ReminderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 提醒管理控制器
 */
@Tag(name = "提醒管理")
@RestController
@RequestMapping("/reminder")
@RequiredArgsConstructor
public class ReminderController {
    
    private final ReminderService reminderService;
    
    @Operation(summary = "获取用户今日的提醒")
    @GetMapping("/today/{userId}")
    public Result<List<Reminder>> getTodayReminders(@PathVariable Long userId) {
        List<Reminder> reminders = reminderService.getTodayReminders(userId);
        return Result.success(reminders);
    }
    
    @Operation(summary = "获取宝宝即将到来的提醒")
    @GetMapping("/upcoming/{babyId}")
    public Result<List<Reminder>> getUpcomingReminders(@PathVariable Long babyId) {
        List<Reminder> reminders = reminderService.getUpcomingReminders(babyId);
        return Result.success(reminders);
    }
    
    @Operation(summary = "创建提醒")
    @PostMapping
    public Result<Reminder> createReminder(@RequestBody ReminderDTO dto) {
        Reminder reminder = reminderService.createCustomReminder(dto);
        return Result.success(reminder);
    }
    
    @Operation(summary = "更新提醒")
    @PutMapping("/{id}")
    public Result<Reminder> updateReminder(@PathVariable Long id, @RequestBody ReminderDTO dto) {
        Reminder reminder = reminderService.updateReminder(id, dto);
        return Result.success(reminder);
    }
    
    @Operation(summary = "取消提醒")
    @DeleteMapping("/{id}")
    public Result<Void> cancelReminder(@PathVariable Long id) {
        reminderService.cancelReminder(id);
        return Result.success();
    }
}
