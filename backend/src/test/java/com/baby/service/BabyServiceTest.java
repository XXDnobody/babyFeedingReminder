package com.baby.service;

import com.baby.dto.BabyDTO;
import com.baby.entity.Baby;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class BabyServiceTest {

    @Autowired
    private BabyService babyService;

    @Test
    void testCreateBaby() {
        BabyDTO dto = new BabyDTO();
        dto.setNickname("测试宝宝");
        dto.setBirthDate(LocalDate.now().minusMonths(3));
        dto.setGender(1);
        dto.setGestationalAge(40);
        dto.setHeight(60.0);
        dto.setWeight(6.5);
        dto.setHeadCircumference(38.0);

        Baby baby = babyService.createBaby(1L, dto);

        assertNotNull(baby);
        assertNotNull(baby.getId());
        assertEquals("测试宝宝", baby.getNickname());
        assertEquals(1, baby.getGender());
    }

    @Test
    void testCalculateAgeInMonths() {
        BabyDTO dto = new BabyDTO();
        dto.setNickname("测试宝宝");
        dto.setBirthDate(LocalDate.now().minusMonths(5));
        dto.setGender(0);

        Baby baby = babyService.createBaby(1L, dto);
        int ageInMonths = babyService.calculateAgeInMonths(baby.getId());

        assertEquals(5, ageInMonths);
    }

    @Test
    void testUpdateGrowthMetrics() {
        BabyDTO dto = new BabyDTO();
        dto.setNickname("测试宝宝");
        dto.setBirthDate(LocalDate.now().minusMonths(3));
        dto.setGender(1);

        Baby baby = babyService.createBaby(1L, dto);
        Baby updatedBaby = babyService.updateGrowthMetrics(
                baby.getId(), 65.0, 7.0, 40.0);

        assertEquals(65.0, updatedBaby.getHeight());
        assertEquals(7.0, updatedBaby.getWeight());
        assertEquals(40.0, updatedBaby.getHeadCircumference());
    }
}
