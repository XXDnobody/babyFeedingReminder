package com.baby.vo;

import lombok.Data;
import java.util.List;

/**
 * 睡眠统计VO
 */
@Data
public class SleepStatisticsVO {
    
    /**
     * 统计日期范围
     */
    private String dateRange;
    
    /**
     * 总睡眠时长（分钟）
     */
    private Integer totalDuration;
    
    /**
     * 小睡总次数
     */
    private Integer napCount;
    
    /**
     * 夜间睡眠次数
     */
    private Integer nightSleepCount;
    
    /**
     * 日均睡眠时长（小时）
     */
    private Double dailyAverageHours;
    
    /**
     * 日均小睡次数
     */
    private Double dailyAverageNapCount;
    
    /**
     * 平均每次小睡时长（分钟）
     */
    private Double averageNapDuration;
    
    /**
     * 推荐日均睡眠时长（小时）
     */
    private String recommendedDailyHours;
    
    /**
     * 推荐小睡次数
     */
    private String recommendedNapCount;
    
    /**
     * 与推荐值的对比
     */
    private String comparisonWithRecommended;
    
    /**
     * 睡眠质量分布
     */
    private QualityDistribution qualityDistribution;
    
    /**
     * 每日统计数据
     */
    private List<DailySleepData> dailyData;
    
    @Data
    public static class QualityDistribution {
        private Double goodPercent;
        private Double normalPercent;
        private Double poorPercent;
    }
    
    @Data
    public static class DailySleepData {
        private String date;
        private Integer napCount;
        private Integer totalMinutes;
        private Double totalHours;
    }
}
