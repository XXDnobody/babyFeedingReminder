package com.baby.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.baby.dto.ReminderDTO;
import com.baby.entity.FeedingRecord;
import com.baby.entity.Reminder;
import com.baby.entity.SleepRecord;
import java.util.List;

/**
 * 提醒服务接口
 */
public interface ReminderService extends IService<Reminder> {
    
    /**
     * 创建喂奶提醒
     */
    Reminder createFeedingReminder(FeedingRecord feedingRecord);
    
    /**
     * 创建解冻提醒
     */
    Reminder createThawReminder(FeedingRecord feedingRecord);
    
    /**
     * 创建小睡提醒
     */
    Reminder createNapReminder(SleepRecord sleepRecord);
    
    /**
     * 创建哄睡提醒
     */
    Reminder createSoothingReminder(SleepRecord sleepRecord);
    
    /**
     * 创建自定义提醒
     */
    Reminder createCustomReminder(ReminderDTO dto);
    
    /**
     * 更新提醒
     */
    Reminder updateReminder(Long id, ReminderDTO dto);
    
    /**
     * 获取用户今日的提醒
     */
    List<Reminder> getTodayReminders(Long userId);
    
    /**
     * 获取宝宝即将到来的提醒（未发送的）
     */
    List<Reminder> getUpcomingReminders(Long babyId);
    
    /**
     * 获取待发送的提醒
     */
    List<Reminder> getPendingReminders();
    
    /**
     * 发送提醒
     */
    void sendReminder(Reminder reminder);
    
    /**
     * 取消提醒
     */
    void cancelReminder(Long id);
    
    /**
     * 批量取消关联记录的提醒
     */
    void cancelRemindersByRelatedRecord(Long relatedRecordId, Integer reminderType);
    
    /**
     * 清理过期提醒
     */
    void cleanupExpiredReminders();
}
