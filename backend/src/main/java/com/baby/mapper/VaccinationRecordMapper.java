package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.VaccinationRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.time.LocalDate;
import java.util.List;

/**
 * 疫苗接种记录Mapper
 */
@Mapper
public interface VaccinationRecordMapper extends BaseMapper<VaccinationRecord> {
    
    /**
     * 获取宝宝的所有接种记录
     */
    @Select("SELECT * FROM vaccination_record " +
            "WHERE baby_id = #{babyId} AND deleted = 0 " +
            "ORDER BY scheduled_date, dose_number")
    List<VaccinationRecord> getByBabyId(@Param("babyId") Long babyId);
    
    /**
     * 获取宝宝待接种的疫苗
     */
    @Select("SELECT * FROM vaccination_record " +
            "WHERE baby_id = #{babyId} AND status = 0 AND deleted = 0 " +
            "ORDER BY scheduled_date, dose_number")
    List<VaccinationRecord> getPendingByBabyId(@Param("babyId") Long babyId);
    
    /**
     * 获取即将到期的疫苗（未来指定天数内）
     */
    @Select("SELECT * FROM vaccination_record " +
            "WHERE baby_id = #{babyId} AND status = 0 AND deleted = 0 " +
            "AND scheduled_date BETWEEN #{startDate} AND #{endDate} " +
            "ORDER BY scheduled_date, dose_number")
    List<VaccinationRecord> getUpcoming(@Param("babyId") Long babyId, 
                                         @Param("startDate") LocalDate startDate,
                                         @Param("endDate") LocalDate endDate);
    
    /**
     * 获取已逾期的疫苗
     */
    @Select("SELECT * FROM vaccination_record " +
            "WHERE baby_id = #{babyId} AND status IN (0, 2) AND deleted = 0 " +
            "AND scheduled_date < #{today} " +
            "ORDER BY scheduled_date, dose_number")
    List<VaccinationRecord> getOverdue(@Param("babyId") Long babyId, @Param("today") LocalDate today);
}
