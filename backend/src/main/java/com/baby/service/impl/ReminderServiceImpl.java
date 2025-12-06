package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.ReminderDTO;
import com.baby.entity.*;
import com.baby.mapper.BabyMapper;
import com.baby.mapper.FeedingSettingMapper;
import com.baby.mapper.ReminderMapper;
import com.baby.mapper.SleepSettingMapper;
import com.baby.mapper.UserMapper;
import com.baby.service.ReminderService;
import com.baby.service.PushService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.LocalTime;
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
    private final FeedingSettingMapper feedingSettingMapper;
    private final SleepSettingMapper sleepSettingMapper;
    
    @Override
    @Transactional
    public Reminder createFeedingReminder(FeedingRecord feedingRecord) {
        if (feedingRecord.getNextFeedingTime() == null) {
            return null;
        }
        
        Baby baby = babyMapper.selectById(feedingRecord.getBabyId());
        if (baby == null) return null;
        
        // 检查喂养提醒设置
        FeedingSetting setting = getFeedingSetting(feedingRecord.getBabyId());
        if (!isFeedingReminderAllowed(setting, feedingRecord.getNextFeedingTime())) {
            log.info("喂奶提醒时间不在设定时段内，跳过创建: babyId={}, scheduledTime={}", 
                    feedingRecord.getBabyId(), feedingRecord.getNextFeedingTime());
            return null;
        }
        
        Reminder reminder = new Reminder();
        reminder.setBabyId(feedingRecord.getBabyId());
        reminder.setUserId(baby.getUserId());
        reminder.setReminderType(1); // 喂奶提醒
        reminder.setTitle("喂奶提醒");
        reminder.setContent(String.format("%s该喝奶啦！", baby.getNickname()));
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
        
        // 检查喂养提醒设置
        FeedingSetting setting = getFeedingSetting(feedingRecord.getBabyId());
        if (!isFeedingReminderAllowed(setting, thawTime)) {
            log.info("解冻提醒时间不在设定时段内，跳过创建: babyId={}, scheduledTime={}", 
                    feedingRecord.getBabyId(), thawTime);
            return null;
        }
        
        // 根据解冻提前时间判断奶源类型：15分钟左右为冷藏，30分钟左右为冷冻
        String milkType;
        int thawMinutes = feedingRecord.getThawReminderMinutes();
        if (thawMinutes <= 20) {
            milkType = "冷藏母乳";
        } else {
            milkType = "冷冻母乳";
        }
        
        Reminder reminder = new Reminder();
        reminder.setBabyId(feedingRecord.getBabyId());
        reminder.setUserId(baby.getUserId());
        reminder.setReminderType(2); // 解冻提醒
        reminder.setTitle("母乳解冻提醒");
        reminder.setContent(String.format("请提前准备%s解冻加热", milkType));
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
        
        // 检查睡眠提醒设置
        SleepSetting setting = getSleepSetting(sleepRecord.getBabyId());
        if (!isSleepReminderAllowed(setting, sleepRecord.getNextNapTime())) {
            log.info("小睡提醒时间不在设定时段内，跳过创建: babyId={}, scheduledTime={}", 
                    sleepRecord.getBabyId(), sleepRecord.getNextNapTime());
            return null;
        }
        
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
        
        // 检查睡眠提醒设置
        SleepSetting setting = getSleepSetting(sleepRecord.getBabyId());
        if (!isSleepReminderAllowed(setting, soothingTime)) {
            log.info("哄睡提醒时间不在设定时段内，跳过创建: babyId={}, scheduledTime={}", 
                    sleepRecord.getBabyId(), soothingTime);
            return null;
        }
        
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
    public List<Reminder> getUpcomingReminders(Long babyId) {
        // 获取宝宝未发送且未取消的提醒，按时间排序
        return list(new LambdaQueryWrapper<Reminder>()
                .eq(Reminder::getBabyId, babyId)
                .eq(Reminder::getStatus, 0)  // 待发送
                .eq(Reminder::getSent, 0)    // 未发送
                .ge(Reminder::getScheduledTime, LocalDateTime.now())  // 未来的时间
                .orderByAsc(Reminder::getScheduledTime)
                .last("LIMIT 10"));  // 限制数量
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
    
    @Override
    @Transactional
    public Reminder createCustomReminder(ReminderDTO dto) {
        Reminder reminder = new Reminder();
        reminder.setBabyId(dto.getBabyId());
        reminder.setUserId(dto.getUserId());
        reminder.setReminderType(dto.getReminderType() != null ? dto.getReminderType() : 5); // 默认自定义类型
        reminder.setTitle(dto.getTitle());
        reminder.setContent(dto.getContent());
        reminder.setScheduledTime(dto.getScheduledTime());
        reminder.setSent(0);
        reminder.setStatus(0);
        
        save(reminder);
        return reminder;
    }
    
    @Override
    @Transactional
    public Reminder updateReminder(Long id, ReminderDTO dto) {
        Reminder reminder = getById(id);
        if (reminder == null) {
            throw new RuntimeException("提醒不存在");
        }
        
        if (dto.getTitle() != null) {
            reminder.setTitle(dto.getTitle());
        }
        if (dto.getContent() != null) {
            reminder.setContent(dto.getContent());
        }
        if (dto.getScheduledTime() != null) {
            reminder.setScheduledTime(dto.getScheduledTime());
        }
        
        updateById(reminder);
        return reminder;
    }
    
    @Override
    @Transactional
    public void cleanupExpiredReminders() {
        // 删除已发送或已取消且超过24小时的提醒
        LocalDateTime cutoffTime = LocalDateTime.now().minusHours(24);
        
        update(new LambdaUpdateWrapper<Reminder>()
                .in(Reminder::getStatus, 1, 2)  // 已发送或已取消
                .lt(Reminder::getScheduledTime, cutoffTime)
                .set(Reminder::getDeleted, 1));
        
        log.info("清理过期提醒完成");
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
    
    /**
     * 定时任务：每小时清理过期提醒
     */
    @Scheduled(fixedRate = 3600000)
    public void cleanupTask() {
        cleanupExpiredReminders();
    }
    
    /**
     * 获取喂养设置
     */
    private FeedingSetting getFeedingSetting(Long babyId) {
        return feedingSettingMapper.selectOne(
                new LambdaQueryWrapper<FeedingSetting>().eq(FeedingSetting::getBabyId, babyId));
    }
    
    /**
     * 获取睡眠设置
     */
    private SleepSetting getSleepSetting(Long babyId) {
        return sleepSettingMapper.selectOne(
                new LambdaQueryWrapper<SleepSetting>().eq(SleepSetting::getBabyId, babyId));
    }
    
    /**
     * 检查喂养提醒是否允许（是否启用且在时间段内）
     */
    private boolean isFeedingReminderAllowed(FeedingSetting setting, LocalDateTime scheduledTime) {
        // 如果没有设置，默认允许
        if (setting == null) {
            return true;
        }
        
        // 检查是否启用提醒
        if (setting.getReminderEnabled() != null && setting.getReminderEnabled() == 0) {
            log.info("喂养提醒已禁用");
            return false;
        }
        
        // 检查时间段
        return isTimeInRange(scheduledTime, setting.getReminderStartTime(), setting.getReminderEndTime());
    }
    
    /**
     * 检查睡眠提醒是否允许（是否启用且在时间段内）
     */
    private boolean isSleepReminderAllowed(SleepSetting setting, LocalDateTime scheduledTime) {
        // 如果没有设置，默认允许
        if (setting == null) {
            return true;
        }
        
        // 检查是否启用提醒
        if (setting.getReminderEnabled() != null && setting.getReminderEnabled() == 0) {
            log.info("睡眠提醒已禁用");
            return false;
        }
        
        // 检查时间段
        return isTimeInRange(scheduledTime, setting.getReminderStartTime(), setting.getReminderEndTime());
    }
    
    /**
     * 判断给定时间是否在指定的时间范围内
     * @param dateTime 要判断的日期时间
     * @param startTimeStr 开始时间字符串（格式：HH:mm:ss）
     * @param endTimeStr 结束时间字符串（格式：HH:mm:ss）
     * @return 是否在范围内
     */
    private boolean isTimeInRange(LocalDateTime dateTime, String startTimeStr, String endTimeStr) {
        if (startTimeStr == null || endTimeStr == null) {
            // 如果没有设置时间段，默认允许
            return true;
        }

        try {
            LocalTime startTime = LocalTime.parse(startTimeStr);
            LocalTime endTime = LocalTime.parse(endTimeStr);
            LocalTime time = dateTime.toLocalTime();

            // 处理跨午夜的情况（如 22:00 - 06:00）
            if (startTime.isAfter(endTime)) {
                // 跨午夜：时间在startTime之后 或 在endTime之前都算在范围内
                return !time.isBefore(startTime) || !time.isAfter(endTime);
            } else {
                // 正常情况：时间在startTime和endTime之间
                return !time.isBefore(startTime) && !time.isAfter(endTime);
            }
        } catch (Exception e) {
            // 解析失败，默认允许
            log.warn("时间解析失败: startTime={}, endTime={}", startTimeStr, endTimeStr, e);
            return true;
        }
    }

    /**
     * 判断给定时间是否在指定的时间范围内（兼容 LocalTime 参数的版本）
     */
    private boolean isTimeInRange(LocalDateTime dateTime, LocalTime startTime, LocalTime endTime) {
        if (startTime == null || endTime == null) {
            return true;
        }

        LocalTime time = dateTime.toLocalTime();

        // 处理跨午夜的情况（如 22:00 - 06:00）
        if (startTime.isAfter(endTime)) {
            return !time.isBefore(startTime) || !time.isAfter(endTime);
        } else {
            return !time.isBefore(startTime) && !time.isAfter(endTime);
        }
    }
}
