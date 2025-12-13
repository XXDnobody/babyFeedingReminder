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
import com.baby.vo.GrowthRecordVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
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
        
        // 计算精确月龄（包含天数）
        double exactAgeMonths = calculateExactAgeMonths(baby.getBirthDate(), latest.getMeasureDate());
        
        // 早产儿矫正月龄
        double correctedAgeMonths = calculateCorrectedAgeMonths(exactAgeMonths, baby.getGestationalAge());
        boolean isCorrected = correctedAgeMonths != exactAgeMonths;
        
        // 计算身高百分位（使用矫正月龄）
        if (latest.getHeight() != null) {
            double heightValue = latest.getHeight().doubleValue();
            String heightPercentile = growthStandardService.calculateExactPercentile(
                heightValue, standardType, gender, "HEIGHT", correctedAgeMonths);
            result.put("heightPercentile", heightPercentile);
            result.put("height", heightValue);
        }
        
        // 计算体重百分位
        if (latest.getWeight() != null) {
            double weightValue = latest.getWeight().doubleValue();
            String weightPercentile = growthStandardService.calculateExactPercentile(
                weightValue, standardType, gender, "WEIGHT", correctedAgeMonths);
            result.put("weightPercentile", weightPercentile);
            result.put("weight", weightValue);
        }
        
        // 计算BMI百分位
        if (latest.getHeight() != null && latest.getWeight() != null && latest.getHeight().doubleValue() > 0) {
            double heightM = latest.getHeight().doubleValue() / 100.0; // cm转m
            double bmi = latest.getWeight().doubleValue() / (heightM * heightM);
            String bmiPercentile = growthStandardService.calculateExactPercentile(
                bmi, standardType, gender, "BMI", correctedAgeMonths);
            result.put("bmiPercentile", bmiPercentile);
            result.put("bmi", Math.round(bmi * 10.0) / 10.0); // 保留1位小数
        }
                
        // 计算头围百分位
        if (latest.getHeadCircumference() != null) {
            double headValue = latest.getHeadCircumference().doubleValue();
            String headPercentile = growthStandardService.calculateExactPercentile(
                headValue, standardType, gender, "HEAD", correctedAgeMonths);
            result.put("headPercentile", headPercentile);
            result.put("headCircumference", headValue);
        }
        
        result.put("ageInMonths", ageInMonths);
        result.put("exactAgeMonths", exactAgeMonths);
        result.put("correctedAgeMonths", correctedAgeMonths);
        result.put("isCorrected", isCorrected);
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
    
    /**
     * 计算精确月龄（包含天数）
     * 例如：7个月9天 = 7.3月龄
     */
    private double calculateExactAgeMonths(LocalDate birthDate, LocalDate measureDate) {
        if (birthDate == null || measureDate == null) {
            return 0;
        }
        
        // 计算完整月数
        long totalDays = java.time.temporal.ChronoUnit.DAYS.between(birthDate, measureDate);
        
        // 使用平均每月30.44天计算精确月龄
        double exactMonths = totalDays / 30.44;
        
        return Math.round(exactMonths * 10.0) / 10.0; // 保留1位小数
    }
    
    /**
     * 计算早产儿矫正月龄
     * 矫正月龄 = 实际月龄 - (40周 - 出生胎龄周数)
     * 仅对早产儿（胎龄<37周）且实际年龄<24个月时进行矫正
     * 
     * @param exactAgeMonths 实际精确月龄
     * @param gestationalAgeDays 出生胎龄（天数）
     * @return 矫正后的月龄，足月儿返回原值
     */
    private double calculateCorrectedAgeMonths(double exactAgeMonths, Integer gestationalAgeDays) {
        // 胎龄为空或足月（>=37周=259天）不需要矫正
        if (gestationalAgeDays == null || gestationalAgeDays >= 259) {
            return exactAgeMonths;
        }
        
        // 超过24个月不再使用矫正月龄
        if (exactAgeMonths >= 24) {
            return exactAgeMonths;
        }
        
        // 足月标准为40周=280天
        int fullTermDays = 280;
        int pretermDays = fullTermDays - gestationalAgeDays;  // 早产天数
        double pretermMonths = pretermDays / 30.44;  // 早产月数
        
        // 矫正月龄 = 实际月龄 - 早产月数
        double correctedMonths = exactAgeMonths - pretermMonths;
        
        // 矫正月龄不能为负数
        return Math.max(0, Math.round(correctedMonths * 10.0) / 10.0);
    }
    
    /**
     * 计算剩余天数（X个月Y天中的Y）
     */
    private int calculateAgeDays(LocalDate birthDate, LocalDate measureDate) {
        if (birthDate == null || measureDate == null) {
            return 0;
        }
        long totalDays = ChronoUnit.DAYS.between(birthDate, measureDate);
        int months = (int) ChronoUnit.MONTHS.between(birthDate, measureDate);
        LocalDate monthStart = birthDate.plusMonths(months);
        return (int) ChronoUnit.DAYS.between(monthStart, measureDate);
    }
    
    @Override
    public List<GrowthRecordVO> getAllRecordsWithPercentile(Long babyId, String standardType) {
        Baby baby = babyService.getById(babyId);
        if (baby == null) {
            return new ArrayList<>();
        }
        
        int gender = baby.getGender() != null ? baby.getGender() : 1;
        LocalDate birthDate = baby.getBirthDate();
        
        List<GrowthRecord> records = getAllRecords(babyId);
        
        return records.stream().map(record -> {
            GrowthRecordVO vo = new GrowthRecordVO();
            vo.setId(record.getId());
            vo.setBabyId(record.getBabyId());
            vo.setMeasureDate(record.getMeasureDate());
            vo.setHeight(record.getHeight());
            vo.setWeight(record.getWeight());
            vo.setHeadCircumference(record.getHeadCircumference());
            vo.setRemark(record.getRemark());
            vo.setCreateTime(record.getCreateTime());
            vo.setUpdateTime(record.getUpdateTime());
            
            // 计算月龄信息
            if (birthDate != null && record.getMeasureDate() != null) {
                int ageMonths = (int) ChronoUnit.MONTHS.between(birthDate, record.getMeasureDate());
                vo.setAgeInMonths(ageMonths);
                vo.setAgeDays(calculateAgeDays(birthDate, record.getMeasureDate()));
                vo.setExactAgeMonths(calculateExactAgeMonths(birthDate, record.getMeasureDate()));
                
                double exactAge = vo.getExactAgeMonths();
                
                // 早产儿矫正月龄
                double correctedAge = calculateCorrectedAgeMonths(exactAge, baby.getGestationalAge());
                
                // 计算身高百分位（使用矫正月龄）
                if (record.getHeight() != null) {
                    double height = record.getHeight().doubleValue();
                    String heightP = growthStandardService.calculateExactPercentile(
                        height, standardType, gender, "HEIGHT", correctedAge);
                    vo.setHeightPercentile(heightP);
                    vo.setHeightEvaluation(getEvaluation(heightP));
                }
                
                // 计算体重百分位
                if (record.getWeight() != null) {
                    double weight = record.getWeight().doubleValue();
                    String weightP = growthStandardService.calculateExactPercentile(
                        weight, standardType, gender, "WEIGHT", correctedAge);
                    vo.setWeightPercentile(weightP);
                    vo.setWeightEvaluation(getEvaluation(weightP));
                }
                
                // 计算BMI百分位（使用矫正月龄）
                if (record.getHeight() != null && record.getWeight() != null && 
                    record.getHeight().doubleValue() > 0) {
                    double heightM = record.getHeight().doubleValue() / 100.0;
                    double bmi = record.getWeight().doubleValue() / (heightM * heightM);
                    vo.setBmi(Math.round(bmi * 10.0) / 10.0);
                    
                    String bmiP = growthStandardService.calculateExactPercentile(
                        bmi, standardType, gender, "BMI", correctedAge);
                    vo.setBmiPercentile(bmiP);
                    vo.setBmiEvaluation(getEvaluation(bmiP));
                }
                
                // 计算头围百分位（使用矫正月龄）
                if (record.getHeadCircumference() != null) {
                    double head = record.getHeadCircumference().doubleValue();
                    String headP = growthStandardService.calculateExactPercentile(
                        head, standardType, gender, "HEAD", correctedAge);
                    vo.setHeadPercentile(headP);
                    vo.setHeadEvaluation(getEvaluation(headP));
                }
            } else {
                vo.setAgeInMonths(record.getAgeInMonths());
            }
            
            return vo;
        }).collect(Collectors.toList());
    }
    
    /**
     * 根据百分位获取评价
     */
    private String getEvaluation(String percentile) {
        if (percentile == null || percentile.equals("-")) {
            return null;
        }
        
        try {
            // 解析百分位数值，如 "96.6%" -> 96.6
            String numStr = percentile.replace("%", "").replace("<", "").replace(">", "");
            double value = Double.parseDouble(numStr);
            
            if (value < 3) {
                return "偏低";
            } else if (value < 10) {
                return "略低";
            } else if (value <= 90) {
                return "正常";
            } else if (value <= 97) {
                return "增长偏快";
            } else {
                return "偏高";
            }
        } catch (Exception e) {
            return null;
        }
    }
}
