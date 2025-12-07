package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.GrowthRecordDTO;
import com.baby.entity.Baby;
import com.baby.entity.GrowthRecord;
import com.baby.mapper.GrowthRecordMapper;
import com.baby.service.BabyService;
import com.baby.service.GrowthRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * 身高体重测量记录服务实现类
 * WHO标准数据来源：WHO Child Growth Standards
 */
@Service
@RequiredArgsConstructor
public class GrowthRecordServiceImpl extends ServiceImpl<GrowthRecordMapper, GrowthRecord> 
        implements GrowthRecordService {
    
    private final BabyService babyService;
    
    // WHO男婴身高标准(0-24月龄): [月龄, P3, P15, P50, P85, P97]
    private static final double[][] WHO_HEIGHT_BOYS = {
        {0, 46.1, 47.9, 49.9, 51.8, 53.7},
        {1, 50.8, 52.8, 54.7, 56.7, 58.6},
        {2, 54.4, 56.4, 58.4, 60.4, 62.4},
        {3, 57.3, 59.4, 61.4, 63.5, 65.5},
        {4, 59.7, 61.8, 63.9, 66.0, 68.0},
        {5, 61.7, 63.8, 65.9, 68.0, 70.1},
        {6, 63.3, 65.5, 67.6, 69.8, 71.9},
        {7, 64.8, 67.0, 69.2, 71.3, 73.5},
        {8, 66.2, 68.4, 70.6, 72.8, 75.0},
        {9, 67.5, 69.7, 72.0, 74.2, 76.5},
        {10, 68.7, 71.0, 73.3, 75.6, 77.9},
        {11, 69.9, 72.2, 74.5, 76.9, 79.2},
        {12, 71.0, 73.4, 75.7, 78.1, 80.5},
        {15, 74.1, 76.6, 79.1, 81.7, 84.2},
        {18, 76.9, 79.6, 82.3, 85.0, 87.7},
        {21, 79.4, 82.3, 85.1, 88.0, 90.9},
        {24, 81.7, 84.8, 87.8, 90.9, 93.9}
    };
    
    // WHO女婴身高标准(0-24月龄): [月龄, P3, P15, P50, P85, P97]
    private static final double[][] WHO_HEIGHT_GIRLS = {
        {0, 45.4, 47.3, 49.1, 51.0, 52.9},
        {1, 49.8, 51.7, 53.7, 55.6, 57.6},
        {2, 53.0, 55.0, 57.1, 59.1, 61.1},
        {3, 55.6, 57.7, 59.8, 61.9, 64.0},
        {4, 57.8, 59.9, 62.1, 64.3, 66.4},
        {5, 59.6, 61.8, 64.0, 66.2, 68.5},
        {6, 61.2, 63.5, 65.7, 68.0, 70.3},
        {7, 62.7, 65.0, 67.3, 69.6, 71.9},
        {8, 64.0, 66.4, 68.7, 71.1, 73.5},
        {9, 65.3, 67.7, 70.1, 72.6, 75.0},
        {10, 66.5, 69.0, 71.5, 74.0, 76.4},
        {11, 67.7, 70.3, 72.8, 75.3, 77.8},
        {12, 68.9, 71.4, 74.0, 76.6, 79.2},
        {15, 72.0, 74.8, 77.5, 80.2, 83.0},
        {18, 74.9, 77.8, 80.7, 83.6, 86.5},
        {21, 77.5, 80.6, 83.7, 86.7, 89.8},
        {24, 80.0, 83.2, 86.4, 89.6, 92.9}
    };
    
    // WHO男婴体重标准(0-24月龄): [月龄, P3, P15, P50, P85, P97]
    private static final double[][] WHO_WEIGHT_BOYS = {
        {0, 2.5, 2.9, 3.3, 3.9, 4.4},
        {1, 3.4, 3.9, 4.5, 5.1, 5.8},
        {2, 4.3, 4.9, 5.6, 6.3, 7.1},
        {3, 5.0, 5.7, 6.4, 7.2, 8.0},
        {4, 5.6, 6.2, 7.0, 7.8, 8.7},
        {5, 6.0, 6.7, 7.5, 8.4, 9.3},
        {6, 6.4, 7.1, 7.9, 8.8, 9.8},
        {7, 6.7, 7.4, 8.3, 9.2, 10.3},
        {8, 6.9, 7.7, 8.6, 9.6, 10.7},
        {9, 7.1, 7.9, 8.9, 9.9, 11.0},
        {10, 7.4, 8.2, 9.2, 10.2, 11.4},
        {11, 7.6, 8.4, 9.4, 10.5, 11.7},
        {12, 7.7, 8.6, 9.6, 10.8, 12.0},
        {15, 8.3, 9.2, 10.3, 11.5, 12.8},
        {18, 8.8, 9.8, 10.9, 12.2, 13.7},
        {21, 9.2, 10.3, 11.5, 12.9, 14.5},
        {24, 9.7, 10.8, 12.2, 13.6, 15.3}
    };
    
    // WHO女婴体重标准(0-24月龄): [月龄, P3, P15, P50, P85, P97]
    private static final double[][] WHO_WEIGHT_GIRLS = {
        {0, 2.4, 2.8, 3.2, 3.7, 4.2},
        {1, 3.2, 3.6, 4.2, 4.8, 5.5},
        {2, 3.9, 4.5, 5.1, 5.8, 6.6},
        {3, 4.5, 5.2, 5.8, 6.6, 7.5},
        {4, 5.0, 5.7, 6.4, 7.3, 8.2},
        {5, 5.4, 6.1, 6.9, 7.8, 8.8},
        {6, 5.7, 6.5, 7.3, 8.2, 9.3},
        {7, 6.0, 6.8, 7.6, 8.6, 9.8},
        {8, 6.3, 7.0, 7.9, 9.0, 10.2},
        {9, 6.5, 7.3, 8.2, 9.3, 10.5},
        {10, 6.7, 7.5, 8.5, 9.6, 10.9},
        {11, 6.9, 7.7, 8.7, 9.9, 11.2},
        {12, 7.0, 7.9, 8.9, 10.1, 11.5},
        {15, 7.6, 8.5, 9.6, 10.9, 12.4},
        {18, 8.1, 9.1, 10.2, 11.6, 13.2},
        {21, 8.6, 9.6, 10.9, 12.3, 14.0},
        {24, 9.0, 10.2, 11.5, 13.0, 14.8}
    };
    
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
    
    @Override
    public Map<String, List<double[]>> getWHOHeightStandard(int gender) {
        double[][] data = gender == 1 ? WHO_HEIGHT_BOYS : WHO_HEIGHT_GIRLS;
        return convertToPercentileMap(data);
    }
    
    @Override
    public Map<String, List<double[]>> getWHOWeightStandard(int gender) {
        double[][] data = gender == 1 ? WHO_WEIGHT_BOYS : WHO_WEIGHT_GIRLS;
        return convertToPercentileMap(data);
    }
    
    private Map<String, List<double[]>> convertToPercentileMap(double[][] data) {
        Map<String, List<double[]>> result = new LinkedHashMap<>();
        List<double[]> p3 = new ArrayList<>();
        List<double[]> p15 = new ArrayList<>();
        List<double[]> p50 = new ArrayList<>();
        List<double[]> p85 = new ArrayList<>();
        List<double[]> p97 = new ArrayList<>();
        
        for (double[] row : data) {
            double month = row[0];
            p3.add(new double[]{month, row[1]});
            p15.add(new double[]{month, row[2]});
            p50.add(new double[]{month, row[3]});
            p85.add(new double[]{month, row[4]});
            p97.add(new double[]{month, row[5]});
        }
        
        result.put("p3", p3);
        result.put("p15", p15);
        result.put("p50", p50);
        result.put("p85", p85);
        result.put("p97", p97);
        
        return result;
    }
    
    @Override
    public Map<String, Object> calculatePercentile(Long babyId) {
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
        
        // 计算身高百分位
        if (latest.getHeight() != null) {
            double heightValue = latest.getHeight().doubleValue();
            String heightPercentile = calculateValuePercentile(heightValue, ageInMonths, 
                    gender == 1 ? WHO_HEIGHT_BOYS : WHO_HEIGHT_GIRLS);
            result.put("heightPercentile", heightPercentile);
            result.put("height", heightValue);
        }
        
        // 计算体重百分位
        if (latest.getWeight() != null) {
            double weightValue = latest.getWeight().doubleValue();
            String weightPercentile = calculateValuePercentile(weightValue, ageInMonths,
                    gender == 1 ? WHO_WEIGHT_BOYS : WHO_WEIGHT_GIRLS);
            result.put("weightPercentile", weightPercentile);
            result.put("weight", weightValue);
        }
        
        result.put("ageInMonths", ageInMonths);
        result.put("measureDate", latest.getMeasureDate());
        
        return result;
    }
    
    private String calculateValuePercentile(double value, int ageInMonths, double[][] standards) {
        // 找到对应月龄的标准值
        double[] standard = null;
        for (double[] row : standards) {
            if ((int) row[0] == ageInMonths) {
                standard = row;
                break;
            }
        }
        
        if (standard == null) {
            // 如果没有精确匹配，找最近的
            for (double[] row : standards) {
                if ((int) row[0] <= ageInMonths) {
                    standard = row;
                } else {
                    break;
                }
            }
        }
        
        if (standard == null) {
            return "未知";
        }
        
        // 判断百分位区间
        if (value < standard[1]) return "<3%";
        if (value < standard[2]) return "3%-15%";
        if (value < standard[3]) return "15%-50%";
        if (value < standard[4]) return "50%-85%";
        if (value < standard[5]) return "85%-97%";
        return ">97%";
    }
}
