package com.baby.vo;

import lombok.Data;
import java.util.List;
import java.util.Map;

/**
 * 喂养统计VO
 */
@Data
public class FeedingStatisticsVO {
    
    /**
     * 统计日期范围
     */
    private String dateRange;
    
    /**
     * 总喂养次数
     */
    private Integer totalCount;
    
    /**
     * 总奶量（毫升）
     */
    private Integer totalAmount;
    
    /**
     * 日均奶量（毫升）
     */
    private Double dailyAverageAmount;
    
    /**
     * 日均喂养次数
     */
    private Double dailyAverageCount;
    
    /**
     * 平均每次奶量（毫升）
     */
    private Double averagePerFeeding;
    
    /**
     * 推荐日均奶量（毫升）
     */
    private Integer recommendedDailyAmount;
    
    /**
     * 推荐喂养次数
     */
    private String recommendedDailyCount;
    
    /**
     * 与推荐值的对比
     */
    private String comparisonWithRecommended;
    
    /**
     * 母乳/奶粉比例
     */
    private Map<String, Double> feedingTypeRatio;
    
    /**
     * 每日统计数据
     */
    private List<DailyFeedingData> dailyData;
    
    /**
     * 喂奶时间分布（按时段统计）
     */
    private List<TimeDistributionData> timeDistribution;
    
    @Data
    public static class DailyFeedingData {
        private String date;
        private Integer count;
        private Integer totalAmount;
    }
    
    @Data
    public static class TimeDistributionData {
        private String label;   // 时段标签，如"0-3时"
        private Integer count;  // 该时段喂奶次数
    }
}
