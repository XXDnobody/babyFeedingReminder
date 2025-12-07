package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.GrowthRecord;
import org.apache.ibatis.annotations.Mapper;

/**
 * 身高体重测量记录Mapper
 */
@Mapper
public interface GrowthRecordMapper extends BaseMapper<GrowthRecord> {
}
