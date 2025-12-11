package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.GrowthRecordDTO;
import com.baby.entity.Baby;
import com.baby.entity.GrowthRecord;
import com.baby.entity.GrowthStandardType;
import com.baby.mapper.GrowthRecordMapper;
import com.baby.service.BabyService;
import com.baby.service.GrowthRecordService;
import com.baby.service.GrowthStandardService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 身高体重测量记录服务实现类
 * 
 * 生长标准数据现已存储在数据库中，通过 GrowthStandardService 获取
 * 支持多标准切换，便于后续扩展
 */
@Service
@RequiredArgsConstructor
public class GrowthRecordServiceImpl extends ServiceImpl<GrowthRecordMapper, GrowthRecord> 
        implements GrowthRecordService {
    
    private final BabyService babyService;
    private final GrowthStandardService growthStandardService;

    
    @Override
    @Transactional
    public GrowthRecord createRecord(GrowthRecordDTO dto) {
        GrowthRecord record = new GrowthRecord();
        record.setBabyId(dto.getBabyId());
        record.setMeasureDate(dto.getMeasureDate());
        record.setHeight(dto.getHeight());
        record.setWeight(dto.getWeight());
        record.setHeadCircumference(dto.getHeadCircumference());
        record.setRemark(dto.getRemark());
        
        // 计算测量时月龄
        Baby baby = babyService.getById(dto.getBabyId());
        if (baby != null && baby.getBirthDate() != null) {
            long months = ChronoUnit.MONTHS.between(baby.getBirthDate(), dto.getMeasureDate());
            record.setAgeInMonths((int) months);
        }
        
        save(record);
        return record;
    }
    
    @Override
    @Transactional
    public GrowthRecord updateRecord(Long id, GrowthRecordDTO dto) {
        GrowthRecord record = getById(id);
        if (record == null) {
            throw new RuntimeException("测量记录不存在");
        }
        
        record.setMeasureDate(dto.getMeasureDate());
        record.setHeight(dto.getHeight());
        record.setWeight(dto.getWeight());
        record.setHeadCircumference(dto.getHeadCircumference());
        record.setRemark(dto.getRemark());
        
        // 重新计算月龄
        Baby baby = babyService.getById(dto.getBabyId());
        if (baby != null && baby.getBirthDate() != null) {
            long months = ChronoUnit.MONTHS.between(baby.getBirthDate(), dto.getMeasureDate());
            record.setAgeInMonths((int) months);
        }
        
        updateById(record);
        return record;
    }
    
    @Override
    public List<GrowthRecord> getAllRecords(Long babyId) {
        return list(new LambdaQueryWrapper<GrowthRecord>()
                .eq(GrowthRecord::getBabyId, babyId)
                .orderByAsc(GrowthRecord::getMeasureDate));
    }
    
    // ==================== 多标准支持方法（数据从数据库获取） ====================
    
    @Override
    public Map<String, List<double[]>> getWHOHeightStandard(int gender) {
        // WHO标准已移除，返回默认标准
        return getHeightStandard(gender, null);
    }
    
    @Override
    public Map<String, List<double[]>> getWHOWeightStandard(int gender) {
        // WHO标准已移除，返回默认标准
        return getWeightStandard(gender, null);
    }
    
    @Override
    public Map<String, List<double[]>> getHeightStandard(int gender, String standardType) {
        return growthStandardService.getStandardCurveData(standardType, gender, "HEIGHT");
    }
    
    @Override
    public Map<String, List<double[]>> getWeightStandard(int gender, String standardType) {
        return growthStandardService.getStandardCurveData(standardType, gender, "WEIGHT");
    }
    
    @Override
    public Map<String, List<double[]>> getBmiStandard(int gender, String standardType) {
        return growthStandardService.getStandardCurveData(standardType, gender, "BMI");
    }
    
    @Override
    public Map<String, List<double[]>> getHeadStandard(int gender, String standardType) {
        return growthStandardService.getStandardCurveData(standardType, gender, "HEAD");
    }
    
    @Override
    public Map<String, Object> calculatePercentile(Long babyId) {
        // 使用默认标准
        return calculatePercentile(babyId, null);
    }
    
    @Override
    public Map<String, Object> calculatePercentile(Long babyId, String standardType) {
        Map<String, Object> result = new HashMap<>();
        
        Baby baby = babyService.getById(babyId);
        if (baby == null) {
            return result;
        }
        
        // 获取最新记录
        GrowthRecord latest = getOne(new LambdaQueryWrapper<GrowthRecord>()
                .eq(GrowthRecord::getBabyId, babyId)
                .orderByDesc(GrowthRecord::getMeasureDate)
                .last("LIMIT 1"));
        
        if (latest == null) {
            return result;
        }
        
        int gender = baby.getGender() != null ? baby.getGender() : 1;
        int ageInMonths = latest.getAgeInMonths() != null ? latest.getAgeInMonths() : 0;
        
        // 计算身高百分位（使用 GrowthStandardService）
        if (latest.getHeight() != null) {
            double heightValue = latest.getHeight().doubleValue();
            String heightPercentile = growthStandardService.calculatePercentileDescription(
                heightValue, standardType, gender, "HEIGHT", ageInMonths);
            result.put("heightPercentile", heightPercentile);
            result.put("height", heightValue);
        }
        
        // 计算体重百分位
        if (latest.getWeight() != null) {
            double weightValue = latest.getWeight().doubleValue();
            String weightPercentile = growthStandardService.calculatePercentileDescription(
                weightValue, standardType, gender, "WEIGHT", ageInMonths);
            result.put("weightPercentile", weightPercentile);
            result.put("weight", weightValue);
        }
        
        // 计算BMI百分位
        if (latest.getHeight() != null && latest.getWeight() != null && latest.getHeight().doubleValue() > 0) {
            double heightM = latest.getHeight().doubleValue() / 100.0; // cm转m
            double bmi = latest.getWeight().doubleValue() / (heightM * heightM);
            String bmiPercentile = growthStandardService.calculatePercentileDescription(
                bmi, standardType, gender, "BMI", ageInMonths);
            result.put("bmiPercentile", bmiPercentile);
            result.put("bmi", Math.round(bmi * 10.0) / 10.0); // 保留1位小数
        }
        
        result.put("ageInMonths", ageInMonths);
        result.put("measureDate", latest.getMeasureDate());
        result.put("standardType", standardType != null ? standardType : "CHINA_2025");
        
        return result;
    }
    
    @Override
    public List<Map<String, Object>> getAvailableStandards() {
        // 从数据库获取可用标准列表
        List<GrowthStandardType> standards = growthStandardService.getAvailableStandards();
        
        return standards.stream().map(s -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("code", s.getCode());
            map.put("name", s.getName());
            map.put("description", s.getDescription());
            map.put("source", s.getSource());
            map.put("ageRange", s.getMinAgeMonths() + "-" + s.getMaxAgeMonths() + "月龄");
            map.put("supportsBmi", s.getSupportsBmi() != null && s.getSupportsBmi() == 1);
            map.put("isDefault", s.getIsDefault() != null && s.getIsDefault() == 1);
            return map;
        }).collect(Collectors.toList());
    }
}
