package com.baby.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baby.entity.Reminder;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 提醒Mapper
 */
@Mapper
public interface ReminderMapper extends BaseMapper<Reminder> {
    
    /**
     * 获取待发送的提醒
     */
    @Select("SELECT * FROM reminder " +
            "WHERE status = 0 AND deleted = 0 " +
            "AND scheduled_time <= #{time} " +
            "ORDER BY scheduled_time")
    List<Reminder> getPendingReminders(@Param("time") LocalDateTime time);
    
    /**
     * 获取用户今日待发送的提醒
     */
    @Select("SELECT * FROM reminder " +
            "WHERE user_id = #{userId} AND status = 0 AND deleted = 0 " +
            "AND DATE(scheduled_time) = CURDATE() " +
            "ORDER BY scheduled_time")
    List<Reminder> getTodayReminders(@Param("userId") Long userId);
}
