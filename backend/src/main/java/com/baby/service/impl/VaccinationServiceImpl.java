package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baby.dto.VaccinationRecordDTO;
import com.baby.entity.Baby;
import com.baby.entity.Reminder;
import com.baby.entity.VaccinationRecord;
import com.baby.mapper.BabyMapper;
import com.baby.mapper.VaccinationRecordMapper;
import com.baby.service.ReminderService;
import com.baby.service.VaccinationService;
import com.baby.vo.VaccineScheduleVO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/**
 * 疫苗接种服务实现类
 * 基于《国家免疫规划疫苗儿童免疫程序表》
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class VaccinationServiceImpl implements VaccinationService {
    
    private final VaccinationRecordMapper vaccinationRecordMapper;
    private final BabyMapper babyMapper;
    private final ReminderService reminderService;
    
    /**
     * 国家免疫规划疫苗时间表
     * 基于2021版《国家免疫规划疫苗儿童免疫程序表》
     */
    private static final List<VaccineScheduleVO> VACCINE_SCHEDULE = new ArrayList<>();
    
    /**
     * 可替代的付费疫苗映射
     */
    private static final Map<String, List<VaccineScheduleVO.AlternativeVaccineVO>> ALTERNATIVE_VACCINES = new HashMap<>();
    
    static {
        // 先初始化替代疫苗列表
        initAlternativeVaccines();
        
        // 乙肝疫苗 (HepB)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("HepB").vaccineName("乙肝疫苗").vaccineFullName("重组乙型肝炎疫苗")
                .doseNumber(1).ageInMonths(0).ageDescription("出生24小时内")
                .required(true).isFree(true).description("预防乙型肝炎").injectionSite("上臂三角肌")
                .notes("出生后24小时内尽早接种").build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("HepB").vaccineName("乙肝疫苗").vaccineFullName("重组乙型肝炎疫苗")
                .doseNumber(2).ageInMonths(1).ageDescription("1月龄")
                .required(true).isFree(true).description("预防乙型肝炎").injectionSite("上臂三角肌").build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("HepB").vaccineName("乙肝疫苗").vaccineFullName("重组乙型肝炎疫苗")
                .doseNumber(3).ageInMonths(6).ageDescription("6月龄")
                .required(true).isFree(true).description("预防乙型肝炎").injectionSite("上臂三角肌").build());
        
        // 卡介苗 (BCG)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("BCG").vaccineName("卡介苗").vaccineFullName("皮内注射用卡介苗")
                .doseNumber(1).ageInMonths(0).ageDescription("出生时")
                .required(true).isFree(true).description("预防结核病").injectionSite("上臂三角肌中部略下处")
                .notes("出生时接种，早产儿待体重达2500g后接种").build());
        
        // 脊灰疫苗 (IPV/bOPV)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("IPV").vaccineName("脊灰灭活疫苗").vaccineFullName("脊髓灰质炎灭活疫苗")
                .doseNumber(1).ageInMonths(2).ageDescription("2月龄")
                .required(true).isFree(true).description("预防脊髓灰质炎").injectionSite("上臂外侧三角肌")
                .alternatives(ALTERNATIVE_VACCINES.get("IPV")).build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("bOPV").vaccineName("脊灰减毒活疫苗").vaccineFullName("二价脊髓灰质炎减毒活疫苗")
                .doseNumber(2).ageInMonths(3).ageDescription("3月龄")
                .required(true).isFree(true).description("预防脊髓灰质炎").injectionSite("口服")
                .alternatives(ALTERNATIVE_VACCINES.get("bOPV")).build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("bOPV").vaccineName("脊灰减毒活疫苗").vaccineFullName("二价脊髓灰质炎减毒活疫苗")
                .doseNumber(3).ageInMonths(4).ageDescription("4月龄")
                .required(true).isFree(true).description("预防脊髓灰质炎").injectionSite("口服")
                .alternatives(ALTERNATIVE_VACCINES.get("bOPV")).build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("bOPV").vaccineName("脊灰减毒活疫苗").vaccineFullName("二价脊髓灰质炎减毒活疫苗")
                .doseNumber(4).ageInMonths(48).ageDescription("4周岁")
                .required(true).isFree(true).description("预防脊髓灰质炎").injectionSite("口服")
                .alternatives(ALTERNATIVE_VACCINES.get("bOPV")).build());
        
        // 百白破疫苗 (DTaP)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("DTaP").vaccineName("百白破疫苗").vaccineFullName("吸附无细胞百白破联合疫苗")
                .doseNumber(1).ageInMonths(3).ageDescription("3月龄")
                .required(true).isFree(true).description("预防百日咳、白喉、破伤风").injectionSite("上臂外侧三角肌")
                .alternatives(ALTERNATIVE_VACCINES.get("DTaP")).build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("DTaP").vaccineName("百白破疫苗").vaccineFullName("吸附无细胞百白破联合疫苗")
                .doseNumber(2).ageInMonths(4).ageDescription("4月龄")
                .required(true).isFree(true).description("预防百日咳、白喉、破伤风").injectionSite("上臂外侧三角肌")
                .alternatives(ALTERNATIVE_VACCINES.get("DTaP")).build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("DTaP").vaccineName("百白破疫苗").vaccineFullName("吸附无细胞百白破联合疫苗")
                .doseNumber(3).ageInMonths(5).ageDescription("5月龄")
                .required(true).isFree(true).description("预防百日咳、白喉、破伤风").injectionSite("上臂外侧三角肌")
                .alternatives(ALTERNATIVE_VACCINES.get("DTaP")).build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("DTaP").vaccineName("百白破疫苗").vaccineFullName("吸附无细胞百白破联合疫苗")
                .doseNumber(4).ageInMonths(18).ageDescription("18月龄")
                .required(true).isFree(true).description("预防百日咳、白喉、破伤风").injectionSite("上臂外侧三角肌")
                .alternatives(ALTERNATIVE_VACCINES.get("DTaP")).build());
        
        // 白破疫苗 (DT)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("DT").vaccineName("白破疫苗").vaccineFullName("吸附白喉破伤风联合疫苗")
                .doseNumber(1).ageInMonths(72).ageDescription("6周岁")
                .required(true).isFree(true).description("预防白喉、破伤风").injectionSite("上臂外侧三角肌").build());
        
        // 麻腮风疫苗 (MMR)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("MR").vaccineName("麻风疫苗").vaccineFullName("麻疹风疹联合减毒活疫苗")
                .doseNumber(1).ageInMonths(8).ageDescription("8月龄")
                .required(true).isFree(true).description("预防麻疹、风疹").injectionSite("上臂外侧三角肌").build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("MMR").vaccineName("麻腮风疫苗").vaccineFullName("麻疹腮腺炎风疹联合减毒活疫苗")
                .doseNumber(1).ageInMonths(18).ageDescription("18月龄")
                .required(true).isFree(true).description("预防麻疹、腮腺炎、风疹").injectionSite("上臂外侧三角肌").build());
        
        // 乙脑疫苗 (JE)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("JE-L").vaccineName("乙脑减毒活疫苗").vaccineFullName("乙型脑炎减毒活疫苗")
                .doseNumber(1).ageInMonths(8).ageDescription("8月龄")
                .required(true).description("预防流行性乙型脑炎").injectionSite("上臂外侧三角肌").build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("JE-L").vaccineName("乙脑减毒活疫苗").vaccineFullName("乙型脑炎减毒活疫苗")
                .doseNumber(2).ageInMonths(24).ageDescription("2周岁")
                .required(true).description("预防流行性乙型脑炎").injectionSite("上臂外侧三角肌").build());
        
        // A群流脑多糖疫苗 (MPSV-A)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("MPSV-A").vaccineName("A群流脑多糖疫苗").vaccineFullName("A群脑膜炎球菌多糖疫苗")
                .doseNumber(1).ageInMonths(6).ageDescription("6月龄")
                .required(true).description("预防A群脑膜炎球菌引起的流行性脑脊髓膜炎").injectionSite("上臂外侧三角肌").build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("MPSV-A").vaccineName("A群流脑多糖疫苗").vaccineFullName("A群脑膜炎球菌多糖疫苗")
                .doseNumber(2).ageInMonths(9).ageDescription("9月龄")
                .required(true).description("预防A群脑膜炎球菌引起的流行性脑脊髓膜炎").injectionSite("上臂外侧三角肌").build());
        
        // A+C群流脑多糖疫苗 (MPSV-AC)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("MPSV-AC").vaccineName("A+C群流脑多糖疫苗").vaccineFullName("A群C群脑膜炎球菌多糖疫苗")
                .doseNumber(1).ageInMonths(36).ageDescription("3周岁")
                .required(true).description("预防A群和C群脑膜炎球菌引起的流行性脑脊髓膜炎").injectionSite("上臂外侧三角肌").build());
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("MPSV-AC").vaccineName("A+C群流脑多糖疫苗").vaccineFullName("A群C群脑膜炎球菌多糖疫苗")
                .doseNumber(2).ageInMonths(72).ageDescription("6周岁")
                .required(true).description("预防A群和C群脑膜炎球菌引起的流行性脑脊髓膜炎").injectionSite("上臂外侧三角肌").build());
        
        // 甲肝疫苗 (HepA)
        VACCINE_SCHEDULE.add(VaccineScheduleVO.builder()
                .vaccineCode("HepA-L").vaccineName("甲肝减毒活疫苗").vaccineFullName("甲型肝炎减毒活疫苗")
                .doseNumber(1).ageInMonths(18).ageDescription("18月龄")
                .required(true).description("预防甲型肝炎").injectionSite("上臂外侧三角肌")
                .alternatives(ALTERNATIVE_VACCINES.get("HepA")).build());
    }
    
    /**
     * 初始化替代疫苗列表
     */
    private static void initAlternativeVaccines() {
        // 脊灰疫苗替代方案：进口五联疫苗或全程IPV
        ALTERNATIVE_VACCINES.put("IPV", Arrays.asList(
                VaccineScheduleVO.AlternativeVaccineVO.builder()
                        .vaccineCode("Pentaxim")
                        .vaccineName("五联疫苗")
                        .vaccineFullName("百白破-脊灰-Hib联合疫苗")
                        .price(new BigDecimal("600"))
                        .advantages("一针防五病，减少接种次数，进口品质")
                        .reducedDoses(8)
                        .build(),
                VaccineScheduleVO.AlternativeVaccineVO.builder()
                        .vaccineCode("IPV-Full")
                        .vaccineName("全程脊灰灭活疫苗")
                        .vaccineFullName("全程脊髓灰质炎灭活疫苗")
                        .price(new BigDecimal("200"))
                        .advantages("更安全，无疫苗相关麻痹风险")
                        .reducedDoses(0)
                        .build()
        ));
        
        ALTERNATIVE_VACCINES.put("bOPV", ALTERNATIVE_VACCINES.get("IPV"));
        
        // 百白破替代方案：四联/五联/六联疫苗
        ALTERNATIVE_VACCINES.put("DTaP", Arrays.asList(
                VaccineScheduleVO.AlternativeVaccineVO.builder()
                        .vaccineCode("Pentaxim")
                        .vaccineName("五联疫苗")
                        .vaccineFullName("百白破-脊灰-Hib联合疫苗")
                        .price(new BigDecimal("600"))
                        .advantages("一针防五病，减少接种次数，减轻宝宝痛苦")
                        .reducedDoses(8)
                        .build(),
                VaccineScheduleVO.AlternativeVaccineVO.builder()
                        .vaccineCode("Hexaxim")
                        .vaccineName("六联疫苗")
                        .vaccineFullName("百白破-脊灰-Hib-乙肝联合疫苗")
                        .price(new BigDecimal("1200"))
                        .advantages("一针防六病，最大化减少接种次数")
                        .reducedDoses(11)
                        .build(),
                VaccineScheduleVO.AlternativeVaccineVO.builder()
                        .vaccineCode("DTaP-Hib")
                        .vaccineName("四联疫苗")
                        .vaccineFullName("百白破-Hib联合疫苗")
                        .price(new BigDecimal("350"))
                        .advantages("一针防四病，中等价位")
                        .reducedDoses(4)
                        .build()
        ));
        
        // A群流脑替代方案：AC结合疫苗
        ALTERNATIVE_VACCINES.put("MPSV-A", Arrays.asList(
                VaccineScheduleVO.AlternativeVaccineVO.builder()
                        .vaccineCode("MenAC-C")
                        .vaccineName("AC结合疫苗")
                        .vaccineFullName("A群C群脑膜炎球菌结合疫苗")
                        .price(new BigDecimal("280"))
                        .advantages("结合疫苗免疫效果更好，适合小月龄宝宝")
                        .reducedDoses(0)
                        .build(),
                VaccineScheduleVO.AlternativeVaccineVO.builder()
                        .vaccineCode("MenACYW135")
                        .vaccineName("四价流脑结合疫苗")
                        .vaccineFullName("ACYW135群脑膜炎球菌多糖结合疫苗")
                        .price(new BigDecimal("400"))
                        .advantages("保护范围更广，覆盖4种血清群")
                        .reducedDoses(0)
                        .build()
        ));
        
        // 乙脑替代方案：乙脑灭活疫苗
        ALTERNATIVE_VACCINES.put("JE-L", Arrays.asList(
                VaccineScheduleVO.AlternativeVaccineVO.builder()
                        .vaccineCode("JE-I")
                        .vaccineName("乙脑灭活疫苗")
                        .vaccineFullName("乙型脑炎灭活疫苗")
                        .price(new BigDecimal("300"))
                        .advantages("灭活疫苗更安全，适合免疫功能较弱宝宝")
                        .reducedDoses(0)
                        .build()
        ));
        
        // 甲肝替代方案：甲肝灭活疫苗
        ALTERNATIVE_VACCINES.put("HepA", Arrays.asList(
                VaccineScheduleVO.AlternativeVaccineVO.builder()
                        .vaccineCode("HepA-I")
                        .vaccineName("甲肝灭活疫苗")
                        .vaccineFullName("甲型肝炎灭活疫苗")
                        .price(new BigDecimal("200"))
                        .advantages("灭活疫苗更安全，需接种2剂")
                        .reducedDoses(-1) // 实际需要多接种1剂
                        .build()
        ));
    }
    
    @Override
    public List<VaccineScheduleVO> getVaccineSchedule() {
        return VACCINE_SCHEDULE;
    }
    
    @Override
    @Transactional
    public void initVaccinationPlan(Long babyId) {
        Baby baby = babyMapper.selectById(babyId);
        if (baby == null || baby.getBirthDate() == null) {
            log.warn("初始化疫苗计划失败：宝宝不存在或缺少出生日期, babyId={}", babyId);
            return;
        }
        
        // 检查是否已初始化
        List<VaccinationRecord> existing = vaccinationRecordMapper.getByBabyId(babyId);
        if (!existing.isEmpty()) {
            log.info("宝宝已有疫苗接种计划，跳过初始化: babyId={}", babyId);
            return;
        }
        
        LocalDate birthDate = baby.getBirthDate();
        
        for (VaccineScheduleVO schedule : VACCINE_SCHEDULE) {
            VaccinationRecord record = new VaccinationRecord();
            record.setBabyId(babyId);
            record.setVaccineCode(schedule.getVaccineCode());
            record.setVaccineName(schedule.getVaccineName());
            record.setDoseNumber(schedule.getDoseNumber());
            
            // 计算计划接种日期
            LocalDate scheduledDate = birthDate.plusMonths(schedule.getAgeInMonths());
            // 如果是出生时接种的疫苗，设置为出生日期
            if (schedule.getAgeInMonths() == 0) {
                scheduledDate = birthDate;
            }
            record.setScheduledDate(scheduledDate);
            
            // 设置状态：如果计划日期已过，标记为逾期
            if (scheduledDate.isBefore(LocalDate.now())) {
                record.setStatus(2); // 已逾期
            } else {
                record.setStatus(0); // 待接种
            }
            
            vaccinationRecordMapper.insert(record);
        }
        
        log.info("初始化疫苗接种计划完成: babyId={}, 共{}条记录", babyId, VACCINE_SCHEDULE.size());
        
        // 生成提醒
        generateVaccinationReminders(babyId);
    }
    
    @Override
    public List<VaccinationRecord> getByBabyId(Long babyId) {
        // 先检查是否已初始化
        List<VaccinationRecord> records = vaccinationRecordMapper.getByBabyId(babyId);
        if (records.isEmpty()) {
            // 自动初始化
            initVaccinationPlan(babyId);
            records = vaccinationRecordMapper.getByBabyId(babyId);
        }
        return records;
    }
    
    @Override
    public List<VaccinationRecord> getPendingVaccinations(Long babyId) {
        return vaccinationRecordMapper.getPendingByBabyId(babyId);
    }
    
    @Override
    public List<VaccinationRecord> getUpcomingVaccinations(Long babyId) {
        LocalDate today = LocalDate.now();
        LocalDate endDate = today.plusDays(30); // 未来30天内
        return vaccinationRecordMapper.getUpcoming(babyId, today, endDate);
    }
    
    @Override
    public List<VaccinationRecord> getOverdueVaccinations(Long babyId) {
        return vaccinationRecordMapper.getOverdue(babyId, LocalDate.now());
    }
    
    @Override
    @Transactional
    public VaccinationRecord recordVaccination(VaccinationRecordDTO dto) {
        VaccinationRecord record;
        
        if (dto.getId() != null) {
            // 更新已有记录
            record = vaccinationRecordMapper.selectById(dto.getId());
            if (record == null) {
                throw new RuntimeException("接种记录不存在");
            }
        } else {
            // 查找匹配的待接种记录
            record = vaccinationRecordMapper.selectOne(new LambdaQueryWrapper<VaccinationRecord>()
                    .eq(VaccinationRecord::getBabyId, dto.getBabyId())
                    .eq(VaccinationRecord::getVaccineCode, dto.getVaccineCode())
                    .eq(VaccinationRecord::getDoseNumber, dto.getDoseNumber())
                    .eq(VaccinationRecord::getDeleted, 0));
            
            if (record == null) {
                // 创建新记录
                record = new VaccinationRecord();
                record.setBabyId(dto.getBabyId());
                record.setVaccineCode(dto.getVaccineCode());
                record.setVaccineName(dto.getVaccineName());
                record.setDoseNumber(dto.getDoseNumber());
                record.setScheduledDate(dto.getScheduledDate());
            }
        }
        
        record.setActualDate(dto.getActualDate());
        record.setStatus(1); // 已接种
        record.setVaccinationSite(dto.getVaccinationSite());
        record.setBatchNumber(dto.getBatchNumber());
        record.setReaction(dto.getReaction());
        record.setRemark(dto.getRemark());
        
        if (record.getId() == null) {
            vaccinationRecordMapper.insert(record);
        } else {
            vaccinationRecordMapper.updateById(record);
        }
        
        // 取消相关提醒
        cancelVaccinationReminder(record);
        
        return record;
    }
    
    @Override
    @Transactional
    public VaccinationRecord updateVaccination(Long id, VaccinationRecordDTO dto) {
        VaccinationRecord record = vaccinationRecordMapper.selectById(id);
        if (record == null) {
            throw new RuntimeException("接种记录不存在");
        }
        
        if (dto.getActualDate() != null) {
            record.setActualDate(dto.getActualDate());
            record.setStatus(1); // 已接种
        }
        if (dto.getVaccinationSite() != null) {
            record.setVaccinationSite(dto.getVaccinationSite());
        }
        if (dto.getBatchNumber() != null) {
            record.setBatchNumber(dto.getBatchNumber());
        }
        if (dto.getReaction() != null) {
            record.setReaction(dto.getReaction());
        }
        if (dto.getRemark() != null) {
            record.setRemark(dto.getRemark());
        }
        
        vaccinationRecordMapper.updateById(record);
        return record;
    }
    
    @Override
    @Transactional
    public void skipVaccination(Long id) {
        VaccinationRecord record = vaccinationRecordMapper.selectById(id);
        if (record == null) {
            throw new RuntimeException("接种记录不存在");
        }
        record.setStatus(3); // 已跳过
        vaccinationRecordMapper.updateById(record);
        
        // 取消相关提醒
        cancelVaccinationReminder(record);
    }
    
    @Override
    @Transactional
    public void deleteVaccination(Long id) {
        vaccinationRecordMapper.deleteById(id);
    }
    
    @Override
    @Transactional
    public void generateVaccinationReminders(Long babyId) {
        Baby baby = babyMapper.selectById(babyId);
        if (baby == null) {
            return;
        }
        
        // 获取未来7天内待接种的疫苗
        LocalDate today = LocalDate.now();
        LocalDate endDate = today.plusDays(7);
        List<VaccinationRecord> upcoming = vaccinationRecordMapper.getUpcoming(babyId, today, endDate);
        
        for (VaccinationRecord record : upcoming) {
            // 检查是否已有提醒
            Reminder existing = findExistingReminder(record);
            if (existing != null) {
                continue;
            }
            
            // 创建提醒 - 提前1天提醒
            LocalDateTime reminderTime = record.getScheduledDate()
                    .minusDays(1)
                    .atTime(9, 0); // 上午9点提醒
            
            // 如果提醒时间已过，设置为当天9点
            if (reminderTime.isBefore(LocalDateTime.now())) {
                reminderTime = record.getScheduledDate().atTime(9, 0);
            }
            
            Reminder reminder = new Reminder();
            reminder.setBabyId(babyId);
            reminder.setUserId(baby.getUserId());
            reminder.setReminderType(6); // 疫苗接种提醒
            reminder.setTitle("疫苗接种提醒");
            reminder.setContent(String.format("%s需要接种%s（第%d剂），计划日期：%s",
                    baby.getNickname(),
                    record.getVaccineName(),
                    record.getDoseNumber(),
                    record.getScheduledDate().toString()));
            reminder.setScheduledTime(reminderTime);
            reminder.setSent(0);
            reminder.setStatus(0);
            reminder.setRelatedRecordId(record.getId());
            
            reminderService.save(reminder);
            log.info("创建疫苗接种提醒: babyId={}, vaccine={}, scheduledDate={}", 
                    babyId, record.getVaccineName(), record.getScheduledDate());
        }
    }
    
    /**
     * 查找已有的疫苗提醒
     */
    private Reminder findExistingReminder(VaccinationRecord record) {
        // 通过关联记录ID和提醒类型查找
        return null; // 简化实现，实际应查询数据库
    }
    
    /**
     * 取消疫苗接种提醒
     */
    private void cancelVaccinationReminder(VaccinationRecord record) {
        if (record.getId() != null) {
            reminderService.cancelRemindersByRelatedRecord(record.getId(), 6);
        }
    }
    
    /**
     * 定时任务：每天检查并更新逾期状态，生成新提醒
     */
    @Scheduled(cron = "0 0 8 * * ?") // 每天早上8点执行
    public void dailyVaccinationCheck() {
        log.info("开始执行每日疫苗检查任务");
        
        // 获取所有宝宝
        List<Baby> babies = babyMapper.selectList(new LambdaQueryWrapper<Baby>()
                .eq(Baby::getDeleted, 0));
        
        for (Baby baby : babies) {
            // 更新逾期状态
            updateOverdueStatus(baby.getId());
            
            // 生成新提醒
            generateVaccinationReminders(baby.getId());
        }
        
        log.info("每日疫苗检查任务完成");
    }
    
    /**
     * 更新逾期状态
     */
    private void updateOverdueStatus(Long babyId) {
        List<VaccinationRecord> pending = vaccinationRecordMapper.getPendingByBabyId(babyId);
        LocalDate today = LocalDate.now();
        
        for (VaccinationRecord record : pending) {
            if (record.getScheduledDate() != null && record.getScheduledDate().isBefore(today)) {
                record.setStatus(2); // 标记为逾期
                vaccinationRecordMapper.updateById(record);
            }
        }
    }
    
    @Override
    @Transactional
    public VaccinationRecord switchToAlternativeVaccine(Long id, String alternativeVaccineCode, String alternativeVaccineName, BigDecimal price) {
        VaccinationRecord record = vaccinationRecordMapper.selectById(id);
        if (record == null) {
            throw new RuntimeException("接种记录不存在");
        }
        
        // 保存原始疫苗信息
        if (record.getOriginalVaccineCode() == null) {
            record.setOriginalVaccineCode(record.getVaccineCode());
        }
        
        // 切换为替代疫苗
        record.setVaccineCode(alternativeVaccineCode);
        record.setVaccineName(alternativeVaccineName);
        record.setIsFree(0); // 自费
        record.setPrice(price);
        
        vaccinationRecordMapper.updateById(record);
        log.info("切换为替代疫苗: id={}, from={} to={}", id, record.getOriginalVaccineCode(), alternativeVaccineCode);
        
        return record;
    }
    
    @Override
    @Transactional
    public VaccinationRecord restoreToFreeVaccine(Long id) {
        VaccinationRecord record = vaccinationRecordMapper.selectById(id);
        if (record == null) {
            throw new RuntimeException("接种记录不存在");
        }
        
        if (record.getOriginalVaccineCode() == null) {
            throw new RuntimeException("该记录未切换过替代疫苗");
        }
        
        // 查找原始疫苗信息
        String originalCode = record.getOriginalVaccineCode();
        VaccineScheduleVO originalVaccine = VACCINE_SCHEDULE.stream()
                .filter(v -> v.getVaccineCode().equals(originalCode) && v.getDoseNumber().equals(record.getDoseNumber()))
                .findFirst()
                .orElse(null);
        
        if (originalVaccine != null) {
            record.setVaccineCode(originalVaccine.getVaccineCode());
            record.setVaccineName(originalVaccine.getVaccineName());
        } else {
            record.setVaccineCode(originalCode);
        }
        
        record.setIsFree(1); // 免费
        record.setPrice(null);
        record.setOriginalVaccineCode(null);
        
        vaccinationRecordMapper.updateById(record);
        log.info("恢复为免费疫苗: id={}, code={}", id, record.getVaccineCode());
        
        return record;
    }
    
    @Override
    public List<VaccineScheduleVO.AlternativeVaccineVO> getAlternativeVaccines(String vaccineCode) {
        List<VaccineScheduleVO.AlternativeVaccineVO> alternatives = ALTERNATIVE_VACCINES.get(vaccineCode);
        return alternatives != null ? alternatives : new ArrayList<>();
    }
}
