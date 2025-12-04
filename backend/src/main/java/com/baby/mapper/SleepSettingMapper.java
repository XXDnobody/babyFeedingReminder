package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.SleepSetting;
import org.apache.ibatis.annotations.Mapper;

/**
 * 睡眠设置Mapper
 */
@Mapper
public interface SleepSettingMapper extends BaseMapper<SleepSetting> {
}
