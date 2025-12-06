package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.BabyDTO;
import com.baby.entity.Baby;
import com.baby.entity.FeedingSetting;
import com.baby.entity.SleepSetting;
import com.baby.mapper.BabyMapper;
import com.baby.mapper.FeedingSettingMapper;
import com.baby.mapper.SleepSettingMapper;
import com.baby.service.BabyService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.Period;
import java.util.List;

/**
 * 宝宝信息服务实现类
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BabyServiceImpl extends ServiceImpl<BabyMapper, Baby> implements BabyService {
    
    private final FeedingSettingMapper feedingSettingMapper;
    private final SleepSettingMapper sleepSettingMapper;
    
    @Override
    @Transactional
    public Baby createBaby(Long userId, BabyDTO dto) {
        Baby baby = new Baby();
        baby.setUserId(userId);
        baby.setNickname(dto.getNickname());
        baby.setBirthDate(dto.getBirthDate());
        baby.setGender(dto.getGender());
        baby.setGestationalAge(dto.getGestationalAge());
        baby.setHeight(dto.getHeight());
        baby.setWeight(dto.getWeight());
        baby.setHeadCircumference(dto.getHeadCircumference());
        baby.setAvatarUrl(dto.getAvatarUrl());
        save(baby);
        
        // 创建默认的喂养设置
        initDefaultFeedingSetting(baby.getId());
        
        // 创建默认的睡眠设置
        initDefaultSleepSetting(baby.getId());
        
        log.info("创建宝宝成功，已初始化默认设置: babyId={}, nickname={}", baby.getId(), baby.getNickname());
        
        return baby;
    }
    
    /**
     * 初始化默认喂养设置
     */
    private void initDefaultFeedingSetting(Long babyId) {
        FeedingSetting setting = new FeedingSetting();
        setting.setBabyId(babyId);
        setting.setDefaultFeedingType(1);  // 默认母乳
        setting.setDefaultAmount(120);     // 默认120ml
        setting.setDefaultDuration(20);    // 默认20分钟
        setting.setDefaultInterval(180);   // 默认间隔3小时
        setting.setReminderStartTime("06:00:00");   // 06:00
        setting.setReminderEndTime("22:00:00");    // 22:00
        setting.setReminderEnabled(1);     // 默认开启提醒
        setting.setRefrigeratedThawMinutes(15);  // 冷藏解冻提前15分钟
        setting.setFrozenThawMinutes(30);        // 冷冻解冻提前30分钟
        feedingSettingMapper.insert(setting);
        log.info("初始化默认喂养设置: babyId={}", babyId);
    }
    
    /**
     * 初始化默认睡眠设置
     */
    private void initDefaultSleepSetting(Long babyId) {
        SleepSetting setting = new SleepSetting();
        setting.setBabyId(babyId);
        setting.setDefaultNapInterval(120);              // 默认小睡间隔2小时
        setting.setDefaultNapDuration(90);               // 默认小睡时长90分钟
        setting.setDefaultSoothingReminderMinutes(15);   // 默认哄睡提前15分钟
        setting.setReminderStartTime(LocalTime.of(6, 0));   // 06:00
        setting.setReminderEndTime(LocalTime.of(20, 0));    // 20:00
        setting.setReminderEnabled(1);                   // 默认开启提醒
        setting.setBedtimeTarget(LocalTime.of(20, 0));   // 晚间入睡目标20:00
        setting.setWakeTimeTarget(LocalTime.of(7, 0));   // 早晨起床目标07:00
        sleepSettingMapper.insert(setting);
        log.info("初始化默认睡眠设置: babyId={}", babyId);
    }
    
    @Override
    @Transactional
    public Baby updateBaby(Long id, BabyDTO dto) {
        Baby baby = getById(id);
        if (baby == null) {
            throw new RuntimeException("宝宝信息不存在");
        }
        baby.setNickname(dto.getNickname());
        baby.setBirthDate(dto.getBirthDate());
        baby.setGender(dto.getGender());
        baby.setGestationalAge(dto.getGestationalAge());
        baby.setHeight(dto.getHeight());
        baby.setWeight(dto.getWeight());
        baby.setHeadCircumference(dto.getHeadCircumference());
        baby.setAvatarUrl(dto.getAvatarUrl());
        updateById(baby);
        return baby;
    }
    
    @Override
    public List<Baby> getBabiesByUserId(Long userId) {
        return list(new LambdaQueryWrapper<Baby>()
                .eq(Baby::getUserId, userId)
                .orderByDesc(Baby::getCreateTime));
    }
    
    @Override
    @Transactional
    public Baby updateGrowthMetrics(Long id, Double height, Double weight, Double headCircumference) {
        Baby baby = getById(id);
        if (baby == null) {
            throw new RuntimeException("宝宝信息不存在");
        }
        if (height != null) baby.setHeight(height);
        if (weight != null) baby.setWeight(weight);
        if (headCircumference != null) baby.setHeadCircumference(headCircumference);
        updateById(baby);
        return baby;
    }
    
    @Override
    public int calculateAgeInMonths(Long babyId) {
        Baby baby = getById(babyId);
        if (baby == null || baby.getBirthDate() == null) {
            return 0;
        }
        Period period = Period.between(baby.getBirthDate(), LocalDate.now());
        return period.getYears() * 12 + period.getMonths();
    }
}
