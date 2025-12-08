package com.baby.controller;

import com.baby.common.Result;
import com.baby.dto.VaccinationRecordDTO;
import com.baby.entity.VaccinationRecord;
import com.baby.service.VaccinationService;
import com.baby.vo.VaccineScheduleVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 疫苗接种管理控制器
 */
@Tag(name = "疫苗接种管理")
@RestController
@RequestMapping("/vaccination")
@RequiredArgsConstructor
public class VaccinationController {
    
    private final VaccinationService vaccinationService;
    
    @Operation(summary = "获取国家免疫规划疫苗时间表")
    @GetMapping("/schedule")
    public Result<List<VaccineScheduleVO>> getVaccineSchedule() {
        List<VaccineScheduleVO> schedule = vaccinationService.getVaccineSchedule();
        return Result.success(schedule);
    }
    
    @Operation(summary = "初始化宝宝疫苗接种计划")
    @PostMapping("/init/{babyId}")
    public Result<Void> initVaccinationPlan(@PathVariable Long babyId) {
        vaccinationService.initVaccinationPlan(babyId);
        return Result.success();
    }
    
    @Operation(summary = "获取宝宝的所有接种记录")
    @GetMapping("/baby/{babyId}")
    public Result<List<VaccinationRecord>> getByBabyId(@PathVariable Long babyId) {
        List<VaccinationRecord> records = vaccinationService.getByBabyId(babyId);
        return Result.success(records);
    }
    
    @Operation(summary = "获取宝宝待接种的疫苗")
    @GetMapping("/pending/{babyId}")
    public Result<List<VaccinationRecord>> getPendingVaccinations(@PathVariable Long babyId) {
        List<VaccinationRecord> records = vaccinationService.getPendingVaccinations(babyId);
        return Result.success(records);
    }
    
    @Operation(summary = "获取即将到期的疫苗（未来30天内）")
    @GetMapping("/upcoming/{babyId}")
    public Result<List<VaccinationRecord>> getUpcomingVaccinations(@PathVariable Long babyId) {
        List<VaccinationRecord> records = vaccinationService.getUpcomingVaccinations(babyId);
        return Result.success(records);
    }
    
    @Operation(summary = "获取已逾期的疫苗")
    @GetMapping("/overdue/{babyId}")
    public Result<List<VaccinationRecord>> getOverdueVaccinations(@PathVariable Long babyId) {
        List<VaccinationRecord> records = vaccinationService.getOverdueVaccinations(babyId);
        return Result.success(records);
    }
    
    @Operation(summary = "记录疫苗接种")
    @PostMapping("/record")
    public Result<VaccinationRecord> recordVaccination(@RequestBody VaccinationRecordDTO dto) {
        VaccinationRecord record = vaccinationService.recordVaccination(dto);
        return Result.success(record);
    }
    
    @Operation(summary = "更新接种记录")
    @PutMapping("/{id}")
    public Result<VaccinationRecord> updateVaccination(@PathVariable Long id, @RequestBody VaccinationRecordDTO dto) {
        VaccinationRecord record = vaccinationService.updateVaccination(id, dto);
        return Result.success(record);
    }
    
    @Operation(summary = "跳过疫苗接种")
    @PostMapping("/skip/{id}")
    public Result<Void> skipVaccination(@PathVariable Long id) {
        vaccinationService.skipVaccination(id);
        return Result.success();
    }
    
    @Operation(summary = "删除接种记录")
    @DeleteMapping("/{id}")
    public Result<Void> deleteVaccination(@PathVariable Long id) {
        vaccinationService.deleteVaccination(id);
        return Result.success();
    }
    
    @Operation(summary = "手动生成疫苗接种提醒")
    @PostMapping("/generate-reminders/{babyId}")
    public Result<Void> generateReminders(@PathVariable Long babyId) {
        vaccinationService.generateVaccinationReminders(babyId);
        return Result.success();
    }
}
