package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.SleepRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 睡眠记录Mapper
 */
@Mapper
public interface SleepRecordMapper extends BaseMapper<SleepRecord> {
    
    /**
     * 获取指定日期范围内的睡眠统计
     */
    @Select("SELECT DATE(start_time) as date, SUM(duration) as total_duration, COUNT(*) as count " +
            "FROM sleep_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND start_time BETWEEN #{startTime} AND #{endTime} " +
            "GROUP BY DATE(start_time) " +
            "ORDER BY date")
    List<Map<String, Object>> getDailyStatistics(@Param("babyId") Long babyId,
                                                  @Param("startTime") LocalDateTime startTime,
                                                  @Param("endTime") LocalDateTime endTime);
    
    /**
     * 获取今日睡眠总时长（分钟）
     * @deprecated 使用 getTotalDurationByDateRange 替代，避免时区问题
     */
    @Select("SELECT IFNULL(SUM(duration), 0) FROM sleep_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND DATE(start_time) = CURDATE()")
    Integer getTodayTotalDuration(@Param("babyId") Long babyId);
    
    /**
     * 获取今日睡眠次数
     * @deprecated 使用 getNapCountByDateRange 替代，避免时区问题
     */
    @Select("SELECT COUNT(*) FROM sleep_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND sleep_type = 1 " +
            "AND DATE(start_time) = CURDATE()")
    Integer getTodayNapCount(@Param("babyId") Long babyId);
    
    /**
     * 获取指定日期范围内的睡眠总时长（解决时区问题）
     */
    @Select("SELECT IFNULL(SUM(duration), 0) FROM sleep_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND start_time >= #{startTime} AND start_time < #{endTime}")
    Integer getTotalDurationByDateRange(@Param("babyId") Long babyId,
                                         @Param("startTime") LocalDateTime startTime,
                                         @Param("endTime") LocalDateTime endTime);
    
    /**
     * 获取指定日期范围内的睡眠次数（解决时区问题）
     */
    @Select("SELECT COUNT(*) FROM sleep_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "AND sleep_type = 1 " +
            "AND start_time >= #{startTime} AND start_time < #{endTime}")
    Integer getNapCountByDateRange(@Param("babyId") Long babyId,
                                    @Param("startTime") LocalDateTime startTime,
                                    @Param("endTime") LocalDateTime endTime);
}
