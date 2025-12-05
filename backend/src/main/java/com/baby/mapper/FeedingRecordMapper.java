package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.FeedingRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 喂养记录Mapper
 */
@Mapper
public interface FeedingRecordMapper extends BaseMapper<FeedingRecord> {
    
    /**
     * 获取指定日期范围内的喂养统计
     */
    @Select("SELECT DATE(start_time) as date, SUM(amount) as total_amount, COUNT(*) as count " +
            "FROM feeding_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND start_time BETWEEN #{startTime} AND #{endTime} " +
            "GROUP BY DATE(start_time) " +
            "ORDER BY date")
    List<Map<String, Object>> getDailyStatistics(@Param("babyId") Long babyId,
                                                  @Param("startTime") LocalDateTime startTime,
                                                  @Param("endTime") LocalDateTime endTime);
    
    /**
     * 获取今日喂养总量
     * @deprecated 使用 getTotalAmountByDateRange 替代，避免时区问题
     */
    @Select("SELECT IFNULL(SUM(amount), 0) FROM feeding_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND DATE(start_time) = CURDATE()")
    Integer getTodayTotalAmount(@Param("babyId") Long babyId);
    
    /**
     * 获取今日喂养次数
     * @deprecated 使用 getFeedingCountByDateRange 替代，避免时区问题
     */
    @Select("SELECT COUNT(*) FROM feeding_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND DATE(start_time) = CURDATE()")
    Integer getTodayFeedingCount(@Param("babyId") Long babyId);
    
    /**
     * 获取指定日期范围内的喂养总量（解决时区问题）
     */
    @Select("SELECT IFNULL(SUM(amount), 0) FROM feeding_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND start_time >= #{startTime} AND start_time < #{endTime}")
    Integer getTotalAmountByDateRange(@Param("babyId") Long babyId,
                                       @Param("startTime") LocalDateTime startTime,
                                       @Param("endTime") LocalDateTime endTime);
    
    /**
     * 获取指定日期范围内的喂养次数（解决时区问题）
     */
    @Select("SELECT COUNT(*) FROM feeding_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND start_time >= #{startTime} AND start_time < #{endTime}")
    Integer getFeedingCountByDateRange(@Param("babyId") Long babyId,
                                        @Param("startTime") LocalDateTime startTime,
                                        @Param("endTime") LocalDateTime endTime);
}
