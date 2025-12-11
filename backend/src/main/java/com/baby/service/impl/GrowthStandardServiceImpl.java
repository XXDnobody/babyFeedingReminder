package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baby.entity.GrowthStandardData;
import com.baby.entity.GrowthStandardType;
import com.baby.mapper.GrowthStandardDataMapper;
import com.baby.mapper.GrowthStandardTypeMapper;
import com.baby.service.GrowthStandardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;

/**
 * 生长标准服务实现类
 * 
 * 实现LMS算法计算Z-Score和百分位
 * LMS方法：L(Lambda) - Box-Cox变换指数，M(Mu) - 中位数，S(Sigma) - 变异系数
 * 
 * Z-Score计算公式:
 * - 当 L ≠ 0 时: Z = [((value/M)^L) - 1] / (L × S)
 * - 当 L = 0 时: Z = ln(value/M) / S
 * 
 * 百分位 = Φ(Z) × 100，其中Φ是标准正态分布的累积分布函数
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GrowthStandardServiceImpl implements GrowthStandardService {
    
    private final GrowthStandardTypeMapper standardTypeMapper;
    private final GrowthStandardDataMapper standardDataMapper;
    
    // 默认标准代码
    private static final String DEFAULT_STANDARD = "CHINA_2025";
    
    @Override
    public List<GrowthStandardType> getAvailableStandards() {
        return standardTypeMapper.selectList(
            new LambdaQueryWrapper<GrowthStandardType>()
                .eq(GrowthStandardType::getStatus, 1)
                .orderByAsc(GrowthStandardType::getSortOrder)
        );
    }
    
    @Override
    public GrowthStandardType getDefaultStandard() {
        GrowthStandardType defaultType = standardTypeMapper.selectOne(
            new LambdaQueryWrapper<GrowthStandardType>()
                .eq(GrowthStandardType::getIsDefault, 1)
                .eq(GrowthStandardType::getStatus, 1)
        );
        
        if (defaultType == null) {
            // 如果没有设置默认，返回第一个可用的
            return standardTypeMapper.selectOne(
                new LambdaQueryWrapper<GrowthStandardType>()
                    .eq(GrowthStandardType::getStatus, 1)
                    .orderByAsc(GrowthStandardType::getSortOrder)
                    .last("LIMIT 1")
            );
        }
        return defaultType;
    }
    
    @Override
    public GrowthStandardType getStandardByCode(String code) {
        return standardTypeMapper.selectOne(
            new LambdaQueryWrapper<GrowthStandardType>()
                .eq(GrowthStandardType::getCode, code)
                .eq(GrowthStandardType::getStatus, 1)
        );
    }
    
    @Override
    public Map<String, List<double[]>> getStandardCurveData(String standardCode, int gender, String indicator) {
        String code = standardCode != null ? standardCode : DEFAULT_STANDARD;
        List<GrowthStandardData> dataList = standardDataMapper.findByStandardAndGenderAndIndicator(code, gender, indicator);
        
        Map<String, List<double[]>> result = new LinkedHashMap<>();
        List<double[]> p3List = new ArrayList<>();
        List<double[]> p10List = new ArrayList<>();
        List<double[]> p15List = new ArrayList<>();
        List<double[]> p25List = new ArrayList<>();
        List<double[]> p50List = new ArrayList<>();
        List<double[]> p75List = new ArrayList<>();
        List<double[]> p85List = new ArrayList<>();
        List<double[]> p90List = new ArrayList<>();
        List<double[]> p97List = new ArrayList<>();
        
        for (GrowthStandardData data : dataList) {
            double month = data.getAgeMonths();
            p3List.add(new double[]{month, toDouble(data.getP3())});
            if (data.getP10() != null) {
                p10List.add(new double[]{month, toDouble(data.getP10())});
            }
            if (data.getP15() != null) {
                p15List.add(new double[]{month, toDouble(data.getP15())});
            }
            if (data.getP25() != null) {
                p25List.add(new double[]{month, toDouble(data.getP25())});
            }
            p50List.add(new double[]{month, toDouble(data.getP50())});
            if (data.getP75() != null) {
                p75List.add(new double[]{month, toDouble(data.getP75())});
            }
            if (data.getP85() != null) {
                p85List.add(new double[]{month, toDouble(data.getP85())});
            }
            if (data.getP90() != null) {
                p90List.add(new double[]{month, toDouble(data.getP90())});
            }
            p97List.add(new double[]{month, toDouble(data.getP97())});
        }
        
        result.put("p3", p3List);
        if (!p10List.isEmpty()) result.put("p10", p10List);
        if (!p15List.isEmpty()) result.put("p15", p15List);
        if (!p25List.isEmpty()) result.put("p25", p25List);
        result.put("p50", p50List);
        if (!p75List.isEmpty()) result.put("p75", p75List);
        if (!p85List.isEmpty()) result.put("p85", p85List);
        if (!p90List.isEmpty()) result.put("p90", p90List);
        result.put("p97", p97List);
        
        return result;
    }
    
    @Override
    public Double calculateZScore(double value, String standardCode, int gender, String indicator, int ageMonths) {
        String code = standardCode != null ? standardCode : DEFAULT_STANDARD;
        GrowthStandardData data = getStandardDataByMonth(code, gender, indicator, ageMonths);
        
        if (data == null) {
            // 尝试找最近的月龄数据进行插值
            data = findNearestData(code, gender, indicator, ageMonths);
            if (data == null) {
                log.warn("未找到标准数据: standard={}, gender={}, indicator={}, age={}", 
                    code, gender, indicator, ageMonths);
                return null;
            }
        }
        
        // 如果有LMS参数，使用LMS算法
        if (data.getLValue() != null && data.getMValue() != null && data.getSValue() != null) {
            return calculateZScoreWithLMS(value, 
                toDouble(data.getLValue()), 
                toDouble(data.getMValue()), 
                toDouble(data.getSValue()));
        }
        
        // 如果没有LMS参数，使用百分位数据估算Z-Score
        return estimateZScoreFromPercentiles(value, data);
    }
    
    /**
     * 使用LMS参数计算Z-Score
     */
    private double calculateZScoreWithLMS(double value, double L, double M, double S) {
        if (M <= 0 || S <= 0) {
            return 0.0;
        }
        
        if (Math.abs(L) < 0.0001) {
            // L ≈ 0 时使用对数形式
            return Math.log(value / M) / S;
        } else {
            // 标准LMS公式
            return (Math.pow(value / M, L) - 1) / (L * S);
        }
    }
    
    /**
     * 从百分位数据估算Z-Score（当没有LMS参数时使用）
     * 使用线性插值方法
     */
    private Double estimateZScoreFromPercentiles(double value, GrowthStandardData data) {
        double p3 = toDouble(data.getP3());
        double p15 = toDouble(data.getP15());
        double p50 = toDouble(data.getP50());
        double p85 = toDouble(data.getP85());
        double p97 = toDouble(data.getP97());
        
        // 标准差对应的Z值
        // P3 ≈ -1.88, P15 ≈ -1.04, P50 = 0, P85 ≈ 1.04, P97 ≈ 1.88
        double z3 = -1.88;
        double z15 = -1.04;
        double z50 = 0.0;
        double z85 = 1.04;
        double z97 = 1.88;
        
        // 线性插值计算Z-Score
        if (value <= p3) {
            // 外推（低于P3）
            double slope = (z15 - z3) / (p15 - p3);
            return z3 + slope * (value - p3);
        } else if (value <= p15) {
            return interpolate(value, p3, p15, z3, z15);
        } else if (value <= p50) {
            return interpolate(value, p15, p50, z15, z50);
        } else if (value <= p85) {
            return interpolate(value, p50, p85, z50, z85);
        } else if (value <= p97) {
            return interpolate(value, p85, p97, z85, z97);
        } else {
            // 外推（高于P97）
            double slope = (z97 - z85) / (p97 - p85);
            return z97 + slope * (value - p97);
        }
    }
    
    /**
     * 线性插值
     */
    private double interpolate(double x, double x1, double x2, double y1, double y2) {
        if (x2 == x1) return y1;
        return y1 + (y2 - y1) * (x - x1) / (x2 - x1);
    }
    
    @Override
    public Double zScoreToPercentile(double zScore) {
        // 使用标准正态分布累积函数的近似算法
        // Abramowitz and Stegun 近似公式
        return normalCDF(zScore) * 100;
    }
    
    /**
     * 标准正态分布累积分布函数（CDF）
     * 使用Abramowitz and Stegun的近似公式
     */
    private double normalCDF(double z) {
        double t = 1.0 / (1.0 + 0.2316419 * Math.abs(z));
        double d = 0.3989422804014327; // 1/sqrt(2*PI)
        double p = d * Math.exp(-z * z / 2.0) * 
            (0.319381530 * t 
             - 0.356563782 * t * t 
             + 1.781477937 * t * t * t 
             - 1.821255978 * t * t * t * t 
             + 1.330274429 * t * t * t * t * t);
        
        if (z > 0) {
            return 1.0 - p;
        }
        return p;
    }
    
    @Override
    public String calculatePercentileDescription(double value, String standardCode, int gender, String indicator, int ageMonths) {
        String code = standardCode != null ? standardCode : DEFAULT_STANDARD;
        GrowthStandardData data = getStandardDataByMonth(code, gender, indicator, ageMonths);
        
        if (data == null) {
            data = findNearestData(code, gender, indicator, ageMonths);
            if (data == null) {
                return "-";
            }
        }
        
        double p3 = toDouble(data.getP3());
        double p15 = toDouble(data.getP15());
        double p50 = toDouble(data.getP50());
        double p85 = toDouble(data.getP85());
        double p97 = toDouble(data.getP97());
        
        // 根据值落在的区间返回描述
        if (value < p3) {
            return "<3%";
        } else if (value < p15) {
            return "3-15%";
        } else if (value < p50) {
            return "15-50%";
        } else if (value < p85) {
            return "50-85%";
        } else if (value < p97) {
            return "85-97%";
        } else {
            return ">97%";
        }
    }
    
    @Override
    public GrowthStandardData getStandardDataByMonth(String standardCode, int gender, String indicator, int ageMonths) {
        return standardDataMapper.findByMonthAge(standardCode, gender, indicator, ageMonths);
    }
    
    /**
     * 查找最近的月龄数据（用于非标准月龄的插值）
     */
    private GrowthStandardData findNearestData(String standardCode, int gender, String indicator, int ageMonths) {
        List<GrowthStandardData> dataList = standardDataMapper.findByStandardAndGenderAndIndicator(standardCode, gender, indicator);
        
        if (dataList.isEmpty()) {
            return null;
        }
        
        // 找到最近的月龄
        GrowthStandardData nearest = null;
        int minDiff = Integer.MAX_VALUE;
        
        for (GrowthStandardData data : dataList) {
            int diff = Math.abs(data.getAgeMonths() - ageMonths);
            if (diff < minDiff) {
                minDiff = diff;
                nearest = data;
            }
        }
        
        return nearest;
    }
    
    private double toDouble(BigDecimal value) {
        return value != null ? value.doubleValue() : 0.0;
    }
}
