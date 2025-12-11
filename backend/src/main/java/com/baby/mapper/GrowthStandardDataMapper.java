package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.GrowthStandardData;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 生长标准数据Mapper
 */
@Mapper
public interface GrowthStandardDataMapper extends BaseMapper<GrowthStandardData> {
    
    /**
     * 根据标准类型代码、性别、指标获取数据
     */
    @Select("SELECT d.* FROM growth_standard_data d " +
            "JOIN growth_standard_type t ON d.standard_type_id = t.id " +
            "WHERE t.code = #{standardCode} AND d.gender = #{gender} AND d.indicator = #{indicator} " +
            "ORDER BY d.age_months")
    List<GrowthStandardData> findByStandardAndGenderAndIndicator(
            @Param("standardCode") String standardCode,
            @Param("gender") int gender,
            @Param("indicator") String indicator);
    
    /**
     * 获取指定月龄的标准数据（用于百分位计算）
     */
    @Select("SELECT d.* FROM growth_standard_data d " +
            "JOIN growth_standard_type t ON d.standard_type_id = t.id " +
            "WHERE t.code = #{standardCode} AND d.gender = #{gender} " +
            "AND d.indicator = #{indicator} AND d.age_months = #{ageMonths}")
    GrowthStandardData findByMonthAge(
            @Param("standardCode") String standardCode,
            @Param("gender") int gender,
            @Param("indicator") String indicator,
            @Param("ageMonths") int ageMonths);
}
