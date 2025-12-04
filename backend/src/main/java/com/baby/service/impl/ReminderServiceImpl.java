package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.entity.*;
import com.baby.mapper.BabyMapper;
import com.baby.mapper.ReminderMapper;
import com.baby.mapper.UserMapper;
import com.baby.service.ReminderService;
import com.baby.service.PushService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * 提醒服务实现类
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReminderServiceImpl extends ServiceImpl<ReminderMapper, Reminder> implements ReminderService {
    
    private final ReminderMapper reminderMapper;
    private final BabyMapper babyMapper;
    private final UserMapper userMapper;
    private final PushService pushService;
    
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");
    
    @Override
    @Transactional
    public Reminder createFeedingReminder(FeedingRecord feedingRecord) {
        if (feedingRecord.getNextFeedingTime() == null) {
            return null;
        }
        
        Baby baby = babyMapper.selectById(feedingRecord.getBabyId());
        if (baby == null) return null;
        
        Reminder reminder = new Reminder();
        reminder.setBabyId(feedingRecord.getBabyId());
        reminder.setUserId(baby.getUserId());
        reminder.setReminderType(1); // 喂奶提醒
        reminder.setTitle("喂奶提醒");
        reminder.setContent(String.format("%s该喝奶啦！预计时间：%s", 
                baby.getNickname(), 
                feedingRecord.getNextFeedingTime().format(TIME_FORMATTER)));
        reminder.setScheduledTime(feedingRecord.getNextFeedingTime());
        reminder.setSent(0);
        reminder.setStatus(0);
        reminder.setRelatedRecordId(feedingRecord.getId());
        
        save(reminder);
        
        // 如果需要解冻，创建解冻提醒
        if (feedingRecord.getNeedThaw() != null && feedingRecord.getNeedThaw() == 1) {
            createThawReminder(feedingRecord);
        }
        
        return reminder;
    }
    
    @Override
    @Transactional
    public Reminder createThawReminder(FeedingRecord feedingRecord) {
        if (feedingRecord.getNextFeedingTime() == null || feedingRecord.getThawReminderMinutes() == null) {
            return null;
        }
        
        Baby baby = babyMapper.selectById(feedingRecord.getBabyId());
        if (baby == null) return null;
        
        LocalDateTime thawTime = feedingRecord.getNextFeedingTime()
                .minusMinutes(feedingRecord.getThawReminderMinutes());
        
        String milkType = feedingRecord.getMilkSource() == 2 ? "冷藏母乳" : "冷冻母乳";
        
        Reminder reminder = new Reminder();
        reminder.setBabyId(feedingRecord.getBabyId());
        reminder.setUserId(baby.getUserId());
        reminder.setReminderType(2); // 解冻提醒
        reminder.setTitle("母乳解冻提醒");
        reminder.setContent(String.format("请提前准备%s解冻加热，%s将在%s喝奶", 
                milkType,
                baby.getNickname(),
                feedingRecord.getNextFeedingTime().format(TIME_FORMATTER)));
        reminder.setScheduledTime(thawTime);
        reminder.setSent(0);
        reminder.setStatus(0);
        reminder.setRelatedRecordId(feedingRecord.getId());
        
        save(reminder);
        return reminder;
    }
    
    @Override
    @Transactional
    public Reminder createNapReminder(SleepRecord sleepRecord) {
        if (sleepRecord.getNextNapTime() == null) {
            return null;
        }
        
        Baby baby = babyMapper.selectById(sleepRecord.getBabyId());
        if (baby == null) return null;
        
        Reminder reminder = new Reminder();
        reminder.setBabyId(sleepRecord.getBabyId());
        reminder.setUserId(baby.getUserId());
        reminder.setReminderType(3); // 小睡提醒
        reminder.setTitle("小睡时间到");
        reminder.setContent(String.format("%s该小睡啦！建议睡眠时长：%d分钟", 
                baby.getNickname(),
                sleepRecord.getPlannedDuration() != null ? sleepRecord.getPlannedDuration() : 60));
        reminder.setScheduledTime(sleepRecord.getNextNapTime());
        reminder.setSent(0);
        reminder.setStatus(0);
        reminder.setRelatedRecordId(sleepRecord.getId());
        
        save(reminder);
        
        // 创建哄睡提醒
        if (sleepRecord.getSoothingReminderMinutes() != null && sleepRecord.getSoothingReminderMinutes() > 0) {
            createSoothingReminder(sleepRecord);
        }
        
        return reminder;
    }
    
    @Override
    @Transactional
    public Reminder createSoothingReminder(SleepRecord sleepRecord) {
        if (sleepRecord.getNextNapTime() == null || sleepRecord.getSoothingReminderMinutes() == null) {
            return null;
        }
        
        Baby baby = babyMapper.selectById(sleepRecord.getBabyId());
        if (baby == null) return null;
        
        LocalDateTime soothingTime = sleepRecord.getNextNapTime()
                .minusMinutes(sleepRecord.getSoothingReminderMinutes());
        
        Reminder reminder = new Reminder();
        reminder.setBabyId(sleepRecord.getBabyId());
        reminder.setUserId(baby.getUserId());
        reminder.setReminderType(4); // 哄睡提醒
        reminder.setTitle("准备哄睡");
        reminder.setContent(String.format("请准备哄%s入睡，建议%d分钟后开始小睡", 
                baby.getNickname(),
                sleepRecord.getSoothingReminderMinutes()));
        reminder.setScheduledTime(soothingTime);
        reminder.setSent(0);
        reminder.setStatus(0);
        reminder.setRelatedRecordId(sleepRecord.getId());
        
        save(reminder);
        return reminder;
    }
    
    @Override
    public List<Reminder> getTodayReminders(Long userId) {
        return reminderMapper.getTodayReminders(userId);
    }
    
    @Override
    public List<Reminder> getPendingReminders() {
        return reminderMapper.getPendingReminders(LocalDateTime.now());
    }
    
    @Override
    @Transactional
    public void sendReminder(Reminder reminder) {
        User user = userMapper.selectById(reminder.getUserId());
        if (user == null || user.getDeviceToken() == null) {
            log.warn("无法发送提醒，用户不存在或设备Token为空: userId={}", reminder.getUserId());
            return;
        }
        
        try {
            // 调用推送服务
            pushService.sendPush(user.getDeviceToken(), reminder.getTitle(), reminder.getContent());
            
            // 更新提醒状态
            reminder.setSent(1);
            reminder.setSentTime(LocalDateTime.now());
            reminder.setStatus(1);
            updateById(reminder);
            
            log.info("提醒发送成功: reminderId={}, userId={}", reminder.getId(), reminder.getUserId());
        } catch (Exception e) {
            log.error("提醒发送失败: reminderId={}", reminder.getId(), e);
        }
    }
    
    @Override
    @Transactional
    public void cancelReminder(Long id) {
        update(new LambdaUpdateWrapper<Reminder>()
                .eq(Reminder::getId, id)
                .set(Reminder::getStatus, 2));
    }
    
    @Override
    @Transactional
    public void cancelRemindersByRelatedRecord(Long relatedRecordId, Integer reminderType) {
        update(new LambdaUpdateWrapper<Reminder>()
                .eq(Reminder::getRelatedRecordId, relatedRecordId)
                .eq(Reminder::getReminderType, reminderType)
                .eq(Reminder::getStatus, 0)
                .set(Reminder::getStatus, 2));
    }
    
    /**
     * 定时任务：每分钟检查并发送待发送的提醒
     */
    @Scheduled(fixedRate = 60000)
    public void processReminders() {
        List<Reminder> pendingReminders = getPendingReminders();
        for (Reminder reminder : pendingReminders) {
            sendReminder(reminder);
        }
    }
}
