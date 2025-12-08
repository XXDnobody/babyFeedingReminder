package com.baby.service;

import com.baby.dto.VaccinationRecordDTO;
import com.baby.entity.VaccinationRecord;
import com.baby.vo.VaccineScheduleVO;
import java.util.List;

/**
 * 疫苗接种服务接口
 */
public interface VaccinationService {
    
    /**
     * 获取国家免疫规划疫苗时间表
     */
    List<VaccineScheduleVO> getVaccineSchedule();
    
    /**
     * 根据宝宝出生日期初始化疫苗接种计划
     */
    void initVaccinationPlan(Long babyId);
    
    /**
     * 获取宝宝的所有接种记录
     */
    List<VaccinationRecord> getByBabyId(Long babyId);
    
    /**
     * 获取宝宝待接种的疫苗
     */
    List<VaccinationRecord> getPendingVaccinations(Long babyId);
    
    /**
     * 获取即将到期的疫苗（未来7天内）
     */
    List<VaccinationRecord> getUpcomingVaccinations(Long babyId);
    
    /**
     * 获取已逾期的疫苗
     */
    List<VaccinationRecord> getOverdueVaccinations(Long babyId);
    
    /**
     * 记录疫苗接种
     */
    VaccinationRecord recordVaccination(VaccinationRecordDTO dto);
    
    /**
     * 更新接种记录
     */
    VaccinationRecord updateVaccination(Long id, VaccinationRecordDTO dto);
    
    /**
     * 跳过疫苗接种
     */
    void skipVaccination(Long id);
    
    /**
     * 删除接种记录
     */
    void deleteVaccination(Long id);
    
    /**
     * 生成疫苗接种提醒
     */
    void generateVaccinationReminders(Long babyId);
}
