package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.Baby;
import org.apache.ibatis.annotations.Mapper;

/**
 * 宝宝信息Mapper
 */
@Mapper
public interface BabyMapper extends BaseMapper<Baby> {
}
