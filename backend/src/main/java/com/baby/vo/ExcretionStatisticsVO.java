package com.baby.vo;

import lombok.Data;
import java.util.List;
import java.util.Map;

/**
 * 换尿布统计VO
 */
@Data
public class ExcretionStatisticsVO {
    
    /**
     * 统计日期范围
     */
    private String dateRange;
    
    /**
     * 大便总次数
     */
    private Integer totalPoopCount;
    
    /**
     * 小便总次数
     */
    private Integer totalPeeCount;
    
    /**
     * 日均大便次数
     */
    private Double dailyAveragePoopCount;
    
    /**
     * 日均小便次数
     */
    private Double dailyAveragePeeCount;
    
    /**
     * 推荐日均大便次数范围
     */
    private String recommendedPoopCount;
    
    /**
     * 推荐日均小便次数范围
     */
    private String recommendedPeeCount;
    
    /**
     * 与推荐值的对比
     */
    private String comparisonWithRecommended;
    
    /**
     * 大便颜色分布（颜色 -> 百分比）
     */
    private Map<String, Double> colorDistribution;
    
    /**
     * 大便性状分布（性状 -> 百分比）
     */
    private Map<String, Double> textureDistribution;
    
    /**
     * 异常记录次数
     */
    private Integer abnormalCount;
    
    /**
     * 每日统计数据
     */
    private List<DailyExcretionData> dailyData;
    
    @Data
    public static class DailyExcretionData {
        private String date;
        private Integer poopCount;
        private Integer peeCount;
    }
}
