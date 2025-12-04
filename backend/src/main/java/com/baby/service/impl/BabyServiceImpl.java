package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.BabyDTO;
import com.baby.entity.Baby;
import com.baby.mapper.BabyMapper;
import com.baby.service.BabyService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.Period;
import java.util.List;

/**
 * 宝宝信息服务实现类
 */
@Service
@RequiredArgsConstructor
public class BabyServiceImpl extends ServiceImpl<BabyMapper, Baby> implements BabyService {
    
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
        return baby;
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
