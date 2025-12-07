package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.ExcretionRecord;
import org.apache.ibatis.annotations.Mapper;

/**
 * 排便排尿记录Mapper
 */
@Mapper
public interface ExcretionRecordMapper extends BaseMapper<ExcretionRecord> {
}
