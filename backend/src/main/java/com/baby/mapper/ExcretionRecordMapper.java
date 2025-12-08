package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.ExcretionRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.time.LocalDateTime;

/**
 * 排便排尿记录Mapper
 */
@Mapper
public interface ExcretionRecordMapper extends BaseMapper<ExcretionRecord> {
    
    /**
     * 获取指定时间范围内的大便次数
     */
    @Select("SELECT COUNT(*) FROM excretion_record WHERE baby_id = #{babyId} AND excretion_type = 1 AND record_time >= #{startTime} AND record_time < #{endTime} AND deleted = 0")
    Integer getPoopCountByDateRange(@Param("babyId") Long babyId, @Param("startTime") LocalDateTime startTime, @Param("endTime") LocalDateTime endTime);
    
    /**
     * 获取指定时间范围内的小便次数
     */
    @Select("SELECT COUNT(*) FROM excretion_record WHERE baby_id = #{babyId} AND excretion_type = 2 AND record_time >= #{startTime} AND record_time < #{endTime} AND deleted = 0")
    Integer getPeeCountByDateRange(@Param("babyId") Long babyId, @Param("startTime") LocalDateTime startTime, @Param("endTime") LocalDateTime endTime);
    
    /**
     * 获取指定时间范围内的异常记录次数
     */
    @Select("SELECT COUNT(*) FROM excretion_record WHERE baby_id = #{babyId} AND has_abnormal = 1 AND record_time >= #{startTime} AND record_time < #{endTime} AND deleted = 0")
    Integer getAbnormalCountByDateRange(@Param("babyId") Long babyId, @Param("startTime") LocalDateTime startTime, @Param("endTime") LocalDateTime endTime);
}
